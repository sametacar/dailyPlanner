//
//  DailyPlannerWidget.swift
//  DailyPlannerWidget
//
//  Created by vili on 25.10.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

struct PlanEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot

    func localized(_ key: String) -> String {
        WidgetStrings.localized(key, languageCode: snapshot.languageCode)
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PlanEntry {
        PlanEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlanEntry) -> ()) {
        let snapshot = WidgetSnapshotStore.load()
        // The widget gallery shows a sample plan rather than an empty card.
        let useSample = context.isPreview && (snapshot?.tasks.isEmpty ?? true)
        completion(PlanEntry(date: .now, snapshot: useSample ? .preview : snapshot ?? .empty))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlanEntry>) -> ()) {
        let snapshot = WidgetSnapshotStore.load() ?? .empty
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let horizon = now.addingTimeInterval(24 * 60 * 60)

        // A new entry is needed when a task starts or ends and at midnight;
        // progress bars and countdowns animate on their own. The large
        // widget's "now" line also has to move, so add a quarter-hour tick.
        var dates: Set<Date> = [now, tomorrow]
        for task in snapshot.tasks {
            for date in [task.start, task.end] where date > now && date <= horizon {
                dates.insert(date)
            }
        }
        let quarterHour: TimeInterval = 15 * 60
        var tick = (now.timeIntervalSinceReferenceDate / quarterHour).rounded(.up) * quarterHour
        while tick <= now.addingTimeInterval(6 * 60 * 60).timeIntervalSinceReferenceDate {
            dates.insert(Date(timeIntervalSinceReferenceDate: tick))
            tick += quarterHour
        }

        let entries = dates.sorted().map { PlanEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Shared pieces

private struct TaskIcon: View {
    let task: WidgetTask
    var size: CGFloat = 13

    var body: some View {
        Image(systemName: task.icon ?? "circle.fill")
            .font(.system(size: size, weight: .semibold))
            .frame(width: size + 6)
    }
}

// MARK: - Timeline view

/// A slice of the day drawn like the app's timeline: cards sized by
/// duration, free time left as gaps, and a line marking the current time.
/// The medium widget shows three hours, the large one six.
struct TimelinePlanView: View {
    let entry: PlanEntry
    /// How many hours the slice spans.
    let windowHours: Int
    /// Whole hours shown before the current one, so a task that just
    /// started (or just ended) is still in view.
    let hoursBefore: Int
    let showsDate: Bool

    private let labelWidth: CGFloat = 44
    private let minCardHeight: CGFloat = 20

    /// Kept inside the app's timeline hours (06:00 to midnight): late in the
    /// evening the slice slides back instead of spilling into tomorrow, and
    /// before 06:00 it shows the start of the day.
    private var windowStart: Date {
        let calendar = Calendar.current
        let hourStart = calendar.dateInterval(of: .hour, for: entry.date)?.start ?? entry.date
        let preferred = calendar.date(byAdding: .hour, value: -hoursBefore, to: hourStart) ?? hourStart
        let midnight = calendar.startOfDay(for: entry.date)
        let earliestStart = calendar.date(byAdding: .hour, value: Self.firstHour, to: midnight) ?? midnight
        let latestStart = calendar.date(byAdding: .hour, value: 24 - windowHours, to: midnight) ?? midnight
        return min(max(preferred, earliestStart), latestStart)
    }

    /// Matches the first hour of the app's timeline.
    private static let firstHour = 6

    private var windowEnd: Date {
        windowStart.addingTimeInterval(TimeInterval(windowHours) * 3600)
    }

    private var visibleTasks: [WidgetTask] {
        entry.snapshot.tasks.filter { $0.end > windowStart && $0.start < windowEnd }
    }

    private var nextTaskAfterWindow: WidgetTask? {
        entry.snapshot.tasks.first {
            $0.start >= windowEnd && Calendar.current.isDate($0.start, inSameDayAs: entry.date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: showsDate ? 10 : 6) {
            if showsDate {
                Text(entry.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 15, weight: .bold))
            }

            GeometryReader { geo in
                timeline(height: geo.size.height, width: geo.size.width)
            }

            if let later = nextTaskAfterWindow {
                HStack(spacing: 4) {
                    Text(entry.localized("widget.later"))
                        .fontWeight(.semibold)
                    Text("\(entry.snapshot.formattedTime(later.start)) · \(later.name)")
                        .lineLimit(1)
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
    }

    private func timeline(height: CGFloat, width: CGFloat) -> some View {
        let pointsPerSecond = height / CGFloat(windowHours * 3600)
        func y(_ date: Date) -> CGFloat {
            CGFloat(date.timeIntervalSince(windowStart)) * pointsPerSecond
        }
        let cardX = labelWidth + 8
        let cardWidth = width - cardX

        return ZStack(alignment: .topLeading) {
            // Hour labels and grid lines
            ForEach(0..<windowHours, id: \.self) { offset in
                let hour = windowStart.addingTimeInterval(TimeInterval(offset) * 3600)
                HStack(spacing: 6) {
                    Text(entry.snapshot.formattedTime(hour))
                        .font(.system(size: 10, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: labelWidth, alignment: .leading)
                    Rectangle()
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 0.5)
                }
                .offset(y: y(hour) - 6)
            }

            // Task cards, clipped to the window
            ForEach(visibleTasks) { task in
                let top = y(max(task.start, windowStart))
                let bottom = y(min(task.end, windowEnd))
                let cardHeight = max(bottom - top - 2, minCardHeight)
                TimelineTaskCard(task: task, entry: entry, height: cardHeight)
                    .frame(width: cardWidth, height: cardHeight)
                    .offset(x: cardX, y: top + 1)
            }

            // Current time line, hidden before the timeline's first hour
            if entry.date >= windowStart && entry.date <= windowEnd {
                HStack(spacing: 0) {
                    Circle()
                        .fill(.red)
                        .frame(width: 7, height: 7)
                    Rectangle()
                        .fill(.red)
                        .frame(height: 1.5)
                }
                .frame(width: cardWidth + 4)
                .offset(x: cardX - 4, y: y(entry.date) - 3.5)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }
}

/// A task card on the large widget's timeline; drops the time line when the
/// task is too short to fit two lines.
private struct TimelineTaskCard: View {
    let task: WidgetTask
    let entry: PlanEntry
    let height: CGFloat

    var body: some View {
        let timeRange = "\(entry.snapshot.formattedTime(task.start)) – \(entry.snapshot.formattedTime(task.end))"
        Group {
            if height >= 40 {
                VStack(alignment: .leading, spacing: 2) {
                    title
                    Text(timeRange)
                        .font(.system(size: 11, weight: .medium))
                        .opacity(0.9)
                }
                .padding(.vertical, 6)
            } else {
                HStack {
                    title
                    Spacer(minLength: 4)
                    if height >= minimumTimeHeight {
                        Text(entry.snapshot.formattedTime(task.start))
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.9)
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: task.color).opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
    }

    private var minimumTimeHeight: CGFloat { 18 }

    private var title: some View {
        HStack(spacing: 5) {
            TaskIcon(task: task, size: height >= 40 ? 13 : 11)
            Text(task.name)
                .font(.system(size: height >= 40 ? 13 : 11, weight: .semibold))
                .lineLimit(1)
        }
        .frame(maxHeight: height >= 40 ? nil : .infinity)
    }
}

// MARK: - Widget

struct DailyPlannerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemLarge:
                TimelinePlanView(entry: entry, windowHours: 6, hoursBefore: 1, showsDate: true)
            default:
                TimelinePlanView(entry: entry, windowHours: 3, hoursBefore: 0, showsDate: false)
            }
        }
        // Follow the language picked inside the app, not just the system one.
        .environment(\.locale, Locale(identifier: entry.snapshot.languageCode))
    }
}

struct DailyPlannerWidget: Widget {
    let kind: String = WidgetSnapshotStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyPlannerWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("widget.gallery.name")
        .description("widget.gallery.description")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Localization

enum WidgetStrings {
    /// Looks the key up in the language chosen in the app's settings,
    /// mirroring the app's own `String.localized`.
    static func localized(_ key: String, languageCode: String) -> String {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, tableName: nil, bundle: bundle, comment: "")
    }
}

// MARK: - Previews

extension WidgetSnapshot {
    static var preview: WidgetSnapshot {
        let now = Date()
        func task(_ name: String, _ icon: String, _ color: String, _ startOffset: Double, _ minutes: Double) -> WidgetTask {
            let start = now.addingTimeInterval(startOffset * 60)
            return WidgetTask(id: UUID(), name: name, color: color, icon: icon, start: start, end: start.addingTimeInterval(minutes * 60))
        }
        return WidgetSnapshot(
            tasks: [
                task("Morning workout", "figure.run", "#FF8A65", -20, 60),
                task("Read a book", "book.fill", "#85B8FF", 50, 45),
                task("Cook dinner", "frying.pan.fill", "#81C784", 120, 60),
                task("Call mom", "phone.fill", "#BA68C8", 190, 30),
                task("Movie night", "tv.fill", "#E57373", 240, 120),
            ],
            languageCode: "en",
            uses24HourTime: true
        )
    }
}

#Preview(as: .systemMedium) {
    DailyPlannerWidget()
} timeline: {
    PlanEntry(date: .now, snapshot: .preview)
    PlanEntry(date: .now.addingTimeInterval(45 * 60), snapshot: .preview)
    PlanEntry(date: .now, snapshot: .empty)
}

#Preview(as: .systemLarge) {
    DailyPlannerWidget()
} timeline: {
    PlanEntry(date: .now, snapshot: .preview)
}
