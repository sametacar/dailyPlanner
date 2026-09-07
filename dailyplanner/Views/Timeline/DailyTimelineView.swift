//
//  DailyTimelineView.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI
import SwiftData
import Combine

/// Symmetric gap kept between a task card and the hour lines above/below it,
/// so the card reads as centered/inset within its slot rather than touching
/// the grid lines. Shared between the Y-offset calculation and the card's
/// own height so both sides of the gap stay equal.
private let taskVerticalPadding: CGFloat = 0.5

struct DailyTimelineView: View {
    @State private var viewModel = TimelineViewModel()
    @State private var currentTime = Date()
    @State private var showEmptyYesterdayAlert = false
    @State private var showOverwriteConfirmAlert = false
    @State private var highlightedTaskId: UUID?
    @State private var highlightEpoch: Int = 0
    @State private var lastHighlightComputeTime: Date = .distantPast
    @State private var isBulkDeleting = false
    @Binding var showTasks: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ThemeManager.self) private var themeManager
    @Query private var dayTasks: [DayTaskModel]

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Date Header with Tasks Toggle
            HStack {
                Text(viewModel.currentDate, format: .dateTime.day().month(.abbreviated))
                    .environment(\.locale, themeManager.currentLocale)
                    .font(.title2)
                    .fontWeight(.semibold)

                Button(action: {
                    copyYesterdayTasks()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3)
                        .foregroundStyle(Color.dpPrimaryText)
                }
                .padding(.leading, 8)

                Spacer()
                if !showTasks {
                    NavigationLink {
                        SettingsView()
                            .environment(themeManager)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(Color.dpPrimaryText)
                    }
                    .padding(.trailing, 8)

                    Spacer()
                        .frame(width: 16)

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showTasks.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.right")
                            .font(.title3)
                            .foregroundStyle(Color.dpPrimaryText)
                    }
                }
            }
            .padding()
            .background(Color.dpAppBackground)
            .foregroundStyle(Color.dpPrimaryText)
            .alert("copyplan.empty.title".localized, isPresented: $showEmptyYesterdayAlert) {
                Button("copyplan.button.ok".localized, role: .cancel) {}
            } message: {
                Text("copyplan.empty.message".localized)
            }
            .alert("copyplan.overwrite.title".localized, isPresented: $showOverwriteConfirmAlert) {
                Button("delete.button.cancel".localized, role: .cancel) {}
                Button("copyplan.button.overwrite".localized, role: .destructive) {
                    performCopyYesterdayTasks()
                }
            } message: {
                Text("copyplan.overwrite.message".localized)
            }

            Divider()
                .background(Color.dpSeparator)

            // Timeline
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Background: Time slots
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.timeSlots) { slot in
                            TimeSlotRow(
                                timeSlot: slot,
                                currentDate: viewModel.currentDate
                            ) { taskTransfer in
                                createDayTask(from: taskTransfer, at: slot.hour)
                            }
                        }
                    }
                    .background(Color.dpTimelineBackground)

                    // Foreground: Tasks overlay
                    ForEach(todayTasks) { task in
                        DayTaskCard(task: task, allTasks: todayTasks, isHighlighted: task.id == highlightedTaskId, highlightEpoch: highlightEpoch, isBulkDeleting: isBulkDeleting)
                            .offset(y: calculateYOffset(for: task))
                    }

                    // Current time indicator
                    if let offset = calculateCurrentTimeOffset() {
                        CurrentTimeIndicator()
                            .offset(y: offset)
                    }

                    // Short hour tick marks - an independent, always-static top
                    // layer, so they're never affected by per-row drag/hover state.
                    ForEach(Array(viewModel.timeSlots.enumerated()), id: \.element.id) { index, _ in
                        Rectangle()
                            .fill(Color.dpTimelineLine.opacity(0.4))
                            .frame(width: 8, height: 1.5)
                            .padding(.leading, 68)
                            .offset(y: CGFloat(index) * 60)
                            .allowsHitTesting(false)
                    }

                    // Single continuous vertical divider spanning the entire
                    // page (including the top padding above 06:00), instead
                    // of relying on each row's own divider lining up seamlessly.
                    Rectangle()
                        .fill(Color.dpTimelineLine)
                        .frame(width: 1, height: CGFloat(viewModel.timeSlots.count) * 60 + 12)
                        .padding(.leading, 72)
                        .offset(y: -12)
                        .allowsHitTesting(false)
                }
                .padding(.top, 12)
            }
            .onReceive(timer) { _ in
                currentTime = Date()
                // Check if day changed (e.g., past midnight)
                viewModel.checkAndUpdateDate()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // App came to foreground - check if day changed
                    viewModel.checkAndUpdateDate()
                    computeHighlightedTask()
                }
            }
        }
        .background(Color.dpTimelineBackground)
        .onAppear {
            computeHighlightedTask()
        }
        .task {
            await cleanupOldTasks()
        }
    }

    /// Picks the task that's happening right now, or the nearest upcoming one today,
    /// so the launch animation can spotlight it instead of animating every icon.
    ///
    /// Debounced: cold launch fires both .onAppear and the scenePhase -> .active
    /// transition within milliseconds of each other, and their exact ordering isn't
    /// guaranteed. Skipping calls that land within 1s of the previous one collapses
    /// that double-fire into one, while a genuine return from the background (seconds
    /// or minutes later) always passes through.
    private func computeHighlightedTask() {
        let now = Date()
        guard now.timeIntervalSince(lastHighlightComputeTime) > 1.0 else { return }
        lastHighlightComputeTime = now

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        if let current = todayTasks.first(where: { $0.startHour <= hour && hour < $0.endHour }) {
            highlightedTaskId = current.id
        } else if let next = todayTasks.filter({ $0.startHour > hour }).sorted(by: { $0.startHour < $1.startHour }).first {
            highlightedTaskId = next.id
        } else {
            highlightedTaskId = nil
        }
        highlightEpoch += 1
    }

    /// Clean up DayTasks older than 90 days (runs async in background, once per day)
    private func cleanupOldTasks() async {
        let calendar = Calendar.current
        let today = Date()

        // Check if cleanup already ran today
        let lastCleanupKey = "lastTaskCleanupDate"
        if let lastCleanup = UserDefaults.standard.object(forKey: lastCleanupKey) as? Date,
           calendar.isDate(lastCleanup, inSameDayAs: today) {
            return
        }

        guard let cutoffDate = calendar.date(byAdding: .day, value: -90, to: today) else {
            return
        }

        let oldTasks = dayTasks.filter { $0.date < cutoffDate }

        // Mark cleanup as done for today (even if no tasks to delete)
        UserDefaults.standard.set(today, forKey: lastCleanupKey)

        if oldTasks.isEmpty {
            return
        }

        // Delete on main actor since modelContext is main-thread bound
        await MainActor.run {
            for task in oldTasks {
                modelContext.delete(task)
            }
            print("🧹 Cleaned up \(oldTasks.count) tasks older than 90 days")
        }
    }

    /// Get tasks for today
    private var todayTasks: [DayTaskModel] {
        let calendar = Calendar.current
        return dayTasks.filter { task in
            calendar.isDate(task.date, inSameDayAs: viewModel.currentDate)
        }
    }

    /// Calculate Y offset for task based on start hour
    private func calculateYOffset(for task: DayTaskModel) -> CGFloat {
        let slotHeight: CGFloat = 60
        let firstHour = 6 // Timeline starts at 6:00

        // Calculate slot index (0 for 6:00, 1 for 7:00, etc.)
        let slotIndex = task.startHour >= firstHour
            ? task.startHour - firstHour
            : (24 - firstHour) + task.startHour

        // Small symmetric gap from the hour line, matching the equal gap
        // subtracted from the card's height so it sits centered/inset within
        // its slot instead of touching the hour lines above and below.
        return CGFloat(slotIndex) * slotHeight + taskVerticalPadding
    }

    /// Calculate Y offset for current time indicator
    private func calculateCurrentTimeOffset() -> CGFloat? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: currentTime)
        guard let hour = components.hour, let minute = components.minute else { return nil }

        let slotHeight: CGFloat = 60
        let firstHour = 6  // Timeline starts at 6:00

        // Only show indicator during timeline hours (6:00 - 23:59)
        // Hide indicator from 00:00 to 05:59
        guard hour >= firstHour else { return nil }

        // Calculate slot index (0 for 6:00, 1 for 7:00, etc.)
        let slotIndex = hour - firstHour

        // Calculate offset within the hour based on minutes
        let minuteOffset = (CGFloat(minute) / 60.0) * slotHeight

        return CGFloat(slotIndex) * slotHeight + minuteOffset
    }

    /// Create and save a new DayTaskModel from dropped task
    private func createDayTask(from transfer: TaskTransfer, at hour: Int) {
        let dayTask = DayTaskModel(
            from: transfer,
            date: viewModel.currentDate,
            startHour: hour,
            endHour: hour + 1
        )
        modelContext.insert(dayTask)
        print("DayTaskModel created: \(dayTask.name) at \(hour):00")
    }

    /// Entry point for the "copy yesterday" button. Decides whether to copy directly,
    /// warn that yesterday has nothing to copy, or ask before overwriting today's plan.
    private func copyYesterdayTasks() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: viewModel.currentDate) else { return }

        let yesterdayTasks = DayPlanCopier.tasks(in: dayTasks, on: yesterday, calendar: calendar)
        guard !yesterdayTasks.isEmpty else {
            showEmptyYesterdayAlert = true
            return
        }

        if todayTasks.isEmpty {
            performCopyYesterdayTasks()
        } else {
            showOverwriteConfirmAlert = true
        }
    }

    /// Actually performs the copy: deletes today's tasks (if any) and copies yesterday's plan.
    private func performCopyYesterdayTasks() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: viewModel.currentDate) else { return }

        let yesterdayTasks = DayPlanCopier.tasks(in: dayTasks, on: yesterday, calendar: calendar)
        let tasksToReplace = todayTasks

        guard !tasksToReplace.isEmpty else {
            DayPlanCopier.copy(yesterdayTasks, to: viewModel.currentDate, replacing: tasksToReplace, modelContext: modelContext)
            print("Copied \(yesterdayTasks.count) task(s) from yesterday to today")
            return
        }

        // Play the shatter/dissolve effect on today's existing cards before replacing them
        isBulkDeleting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            DayPlanCopier.copy(yesterdayTasks, to: viewModel.currentDate, replacing: tasksToReplace, modelContext: modelContext)
            isBulkDeleting = false
            print("Copied \(yesterdayTasks.count) task(s) from yesterday to today")
        }
    }
}

/// Card view for displaying a DayTaskModel in the timeline
struct DayTaskCard: View {
    let task: DayTaskModel
    let allTasks: [DayTaskModel]
    let isHighlighted: Bool
    let highlightEpoch: Int
    let isBulkDeleting: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSelected = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var pulsedEpoch: Int = -1
    @State private var iconPulseScale: CGFloat = 1.0

    private let slotHeight: CGFloat = 60

    private var iconOpacity: Double {
        colorScheme == .light ? 0.55 : 0.42
    }

    private func triggerPopInIfNeeded() {
        guard isHighlighted, pulsedEpoch != highlightEpoch else { return }
        pulsedEpoch = highlightEpoch
        withAnimation(.spring(response: 0.3, dampingFraction: 0.45).delay(0.3)) {
            iconPulseScale = 1.35
        } completion: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                iconPulseScale = 1.0
            }
        }
    }

    private var taskHeight: CGFloat {
        let duration = task.endHour - task.startHour
        return CGFloat(duration) * slotHeight - (taskVerticalPadding * 2)
    }

    private var taskFontSize: CGFloat {
        let duration = task.endHour - task.startHour
        let baseSize: CGFloat = 14

        switch duration {
        case 1:
            return baseSize // 1x
        case 2:
            return baseSize * 1.25 // 1.25x
        case 3:
            return baseSize * 1.5 // 1.5x
        default: // 4+
            return baseSize * 2.0 // 2x
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 2)

            // Main task content
            ZStack {
                HStack {
                    Text(task.name)
                        .font(.system(size: taskFontSize, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.92))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Top resize handle (inside the card)
                if isSelected {
                    VStack {
                        ResizeHandle(position: .top)
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        applyResize(mode: .top, offset: value.translation.height)
                                    }
                            )
                        Spacer()
                    }
                }

                // Bottom resize handle (inside the card)
                if isSelected {
                    VStack {
                        Spacer()
                        ResizeHandle(position: .bottom)
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        applyResize(mode: .bottom, offset: value.translation.height)
                                    }
                            )
                    }
                }

                // Delete button (only when selected)
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white)
                                    .padding(9)
                                    .background(
                                        ZStack {
                                            Color.black.opacity(0.4)
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.15),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        }
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(
                ZStack {
                    // Base color with transparency for glass effect
                    Color(hex: task.color)
                        .opacity(0.75)

                    // Watermark icon embedded in the background
                    if let icon = task.icon {
                        GeometryReader { geo in
                            let iconSize = min(min(geo.size.width, geo.size.height) * 0.68, 59)
                            let baseSize: CGFloat = 41
                            let leftShift = max(0, iconSize - baseSize) * 0.5

                            Image(systemName: icon)
                                .font(.system(size: iconSize, weight: .bold))
                                .foregroundStyle(.white.opacity(iconOpacity))
                                .rotationEffect(.degrees(-24))
                                .scaleEffect(isHighlighted ? iconPulseScale : 1.0)
                                .position(x: geo.size.width - 20 - leftShift, y: geo.size.height - 20)
                                .onAppear {
                                    triggerPopInIfNeeded()
                                }
                                .onChange(of: isHighlighted) { _, _ in
                                    triggerPopInIfNeeded()
                                }
                                .onChange(of: highlightEpoch) { _, _ in
                                    triggerPopInIfNeeded()
                                }
                        }
                    }

                    // Gradient overlay for depth
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.09),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Blur effect for frosted glass
                    Color(hex: task.color)
                        .opacity(0.2)
                        .blur(radius: 8)

                    // Liquid glass reflection - diagonal light streak (subtle)
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.09),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: geo.size.width * 0.35)
                        .blur(radius: 10)
                        .offset(x: geo.size.width * 0.1, y: -geo.size.height * 0.05)
                        .blendMode(.overlay)
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                // Main border with gradient
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.6 : 0.3),
                                Color.white.opacity(isSelected ? 0.3 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1.5
                    )
            )
            .overlay(
                // Inner glow for glass effect
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 0.5)
            )
            .shadow(color: Color(hex: task.color).opacity(0.25), radius: 8, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.08), radius: 2, x: 0, y: -1)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSelected.toggle()
                }
            }

            Spacer().frame(height: 2)
        }
        .frame(height: taskHeight)
        .padding(.leading, 73) // Time label width (60) + spacing (12) + divider (1)
        .padding(.trailing, 8)
        .opacity(isDeleting ? 0.0 : 1.0)
        .overlay {
            if isDeleting {
                ShatterView(task: task, taskHeight: taskHeight)
            }
        }
        .onChange(of: isBulkDeleting) { _, newValue in
            if newValue {
                isDeleting = true
            }
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete '\(task.name)'?")
        }
    }

    private func applyResize(mode: ResizeMode, offset: CGFloat) {
        let slotChange = Int(round(offset / slotHeight))

        switch mode {
        case .top:
            let newStartHour = max(0, min(23, task.startHour + slotChange))
            if newStartHour < task.endHour && canResize(newStartHour: newStartHour, newEndHour: task.endHour) {
                task.startHour = newStartHour
                print("Task resized: \(task.name) now starts at \(newStartHour):00")
            } else {
                print("Cannot resize: would overlap with another task")
            }
        case .bottom:
            let newEndHour = max(0, min(24, task.endHour + slotChange))
            if newEndHour > task.startHour && canResize(newStartHour: task.startHour, newEndHour: newEndHour) {
                task.endHour = newEndHour
                print("Task resized: \(task.name) now ends at \(newEndHour):00")
            } else {
                print("Cannot resize: would overlap with another task")
            }
        }
    }

    /// Check if resizing to the new time range would cause a conflict with other tasks
    private func canResize(newStartHour: Int, newEndHour: Int) -> Bool {
        // Check if any other task overlaps with the proposed time range
        let hasConflict = allTasks.contains { otherTask in
            // Skip checking against self
            guard otherTask.id != task.id else { return false }

            // Two time ranges overlap if:
            // range1.start < range2.end AND range1.end > range2.start
            return newStartHour < otherTask.endHour && newEndHour > otherTask.startHour
        }

        return !hasConflict
    }

    private func deleteTask() {
        // Start dissolve animation
        isDeleting = true

        // Perform actual deletion after dissolve animation completes
        // Wait for all pieces to fall all the way to bottom of screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                modelContext.delete(task)
                print("Task deleted: \(task.name)")
            }
        }
    }
}

enum ResizeMode {
    case top, bottom
}

/// Handle view for resizing tasks
struct ResizeHandle: View {
    let position: ResizeMode

    var body: some View {
        VStack(spacing: 3) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 32, height: 3.5)
                .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 32, height: 3.5)
                .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle().size(width: 50, height: 24))
    }
}

/// Current time indicator view
struct CurrentTimeIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 60) // Time label width

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.green)
                .shadow(color: .green.opacity(0.4), radius: 3, x: 0, y: 0)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            Spacer()
        }
        .frame(height: 14)
        .offset(y: -7) // Center the icon's own bounding box on the hour line
    }
}

/// Dissolve effect view - task dissolves into pixels like dust
struct ShatterView: View {
    let task: DayTaskModel
    let taskHeight: CGFloat
    @State private var animate = false

    // Grid configuration - more pixels for dissolve effect
    private let columns = 12
    private let rows = 8

    var body: some View {
        GeometryReader { geometry in
            let pieceWidth = geometry.size.width / CGFloat(columns)
            let pieceHeight = taskHeight / CGFloat(rows)

            ForEach(0..<(columns * rows), id: \.self) { index in
                let column = index % columns
                let row = index / columns

                DissolvePiece(
                    task: task,
                    width: pieceWidth,
                    height: pieceHeight,
                    offsetX: CGFloat(column) * pieceWidth,
                    offsetY: CGFloat(row) * pieceHeight,
                    animate: animate
                )
            }
        }
        .frame(height: taskHeight)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animate = true
            }
        }
    }
}

/// Individual pixel piece for dissolve effect
struct DissolvePiece: View {
    let task: DayTaskModel
    let width: CGFloat
    let height: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat
    let animate: Bool

    // Random values for dissolve (computed once per piece)
    // Fall all the way to bottom of screen - like broken glass falling to the ground
    // Use HUGE value to guarantee pieces reach bottom regardless of task position in timeline
    private let randomY: CGFloat = CGFloat.random(in: 1200...2000) // Very far fall
    private let randomX: CGFloat = CGFloat.random(in: -50...50) // More horizontal drift
    private let randomDelay: Double = Double.random(in: 0...0.3) // Staggered dissolve
    private let randomDuration: Double = Double.random(in: 1.2...1.6) // Longer fall for gravity effect
    private let randomRotation: Double = Double.random(in: -90...90) // More tumbling as they fall

    var body: some View {
        Rectangle()
            .fill(
                Color(hex: task.color)
                    .opacity(0.85)
            )
            .frame(width: width - 0.5, height: height - 0.5)
            .overlay(
                // Sparkle effect on each pixel
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(1)
            .shadow(color: Color(hex: task.color).opacity(0.6), radius: animate ? 0 : 2)
            .position(
                x: offsetX + width/2 + (animate ? randomX : 0),
                y: offsetY + height/2 + (animate ? randomY : 0)
            )
            .rotationEffect(.degrees(animate ? randomRotation : 0)) // Tumble as they fall
            .scaleEffect(animate ? 0.2 : 1.0) // Shrink more as they fall
            .opacity(animate ? 0.0 : 1.0)
            .blur(radius: animate ? 5 : 0) // More blur
            .animation(
                .easeIn(duration: randomDuration)
                    .delay(randomDelay),
                value: animate
            )
    }
}
