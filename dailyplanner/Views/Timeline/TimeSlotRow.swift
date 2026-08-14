//
//  TimeSlotRow.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TimeSlotRow: View {
    let timeSlot: TimeSlot
    let currentDate: Date
    let onTaskDrop: (TaskTransfer) -> Void
    @State private var isTargeted = false
    @Environment(DragStateManager.self) private var dragStateManager
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Time label
            Text(themeManager.formattedTime(hour: timeSlot.hour))
                .font(.system(size: themeManager.timeFormat == .twelveHour ? 11 : 14, weight: .medium))
                .foregroundStyle(Color.dpSecondaryText)
                .frame(width: 60, alignment: .trailing)
                .padding(.trailing, 12)

            // Divider line
            Rectangle()
                .fill(Color.dpTimelineLine)
                .frame(width: 1)

            // Drop zone
            ZStack {
                // Background highlight when dragging over
                if isTargeted {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.15))
                        .padding(4)
                }

                // Dashed drop indicator when any drag is in progress
                // Hide on the targeted row to avoid visual clutter with the highlight
                if dragStateManager.isDraggingTask && !isTargeted {
                    VStack(spacing: 0) {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            .frame(height: 2)
                            .foregroundStyle(Color.blue.opacity(0.5))
                            .padding(.horizontal, 12)
                            .transition(.opacity)
                            .offset(y: 8)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
            .dropDestination(for: TaskTransfer.self) { items, location in
                guard let taskTransfer = items.first else { return false }
                print("Task dropped: \(taskTransfer.name) at \(timeSlot.hour):00")
                onTaskDrop(taskTransfer)
                return true
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTargeted = targeted
                    // Update global drag state
                    dragStateManager.setSlotTargeted(timeSlot.hour, targeted)
                }
            }
        }
        .frame(height: 60)
        .animation(.easeInOut(duration: 0.25), value: dragStateManager.isDraggingTask)
    }
}

/// Dashed line shape for drop zone indicators
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
