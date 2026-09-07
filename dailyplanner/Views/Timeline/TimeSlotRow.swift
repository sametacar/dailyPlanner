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
            // Time label - vertically centered on the hour boundary line, not
            // top-aligned to it, so it reads as "this hour starts here" like
            // Apple Calendar's hour labels.
            Text(themeManager.formattedTime(hour: timeSlot.hour))
                .font(.system(size: themeManager.timeFormat == .twelveHour ? 11 : 14, weight: .medium))
                .foregroundStyle(Color.dpSecondaryText)
                .frame(width: 60, alignment: .trailing)
                .padding(.trailing, 12)
                .alignmentGuide(.top) { dimensions in
                    // Nudged up slightly from the pure geometric center: digit
                    // glyphs have no descenders, so their optical center sits
                    // a bit above the font's full line-height midpoint.
                    dimensions[VerticalAlignment.center] + 8
                }

            // Divider line
            Rectangle()
                .fill(Color.dpTimelineLine)
                .frame(width: 1)

            // Drop zone
            Color.clear
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
        .overlay(alignment: .top) {
            // Dashed drop indicator when any drag is in progress - anchored the
            // exact same way as the hour boundary line above so the two can
            // never drift apart.
            if dragStateManager.isDraggingTask && !isTargeted {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .frame(height: 2)
                    .foregroundStyle(Color.blue.opacity(0.5))
                    .padding(.leading, 85)
                    .padding(.trailing, 12)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .center) {
            // Background highlight when dragging over - centering (instead of
            // top-anchor + manual top padding) guarantees a symmetric 4pt gap
            // top and bottom with no offset arithmetic to get wrong.
            if isTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))
                    .padding(.leading, 77)
                    .padding(.trailing, 4)
                    .frame(height: 52)
                    .allowsHitTesting(false)
            }
        }
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
