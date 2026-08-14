//
//  DragStateManager.swift
//  dailyplanner
//
//  Created by vili on 26.01.2026.
//

import SwiftUI

@Observable
class DragStateManager {
    private(set) var isDraggingTask = false
    private var targetedSlots: Set<Int> = []
    private var clearTask: DispatchWorkItem?

    func setSlotTargeted(_ hour: Int, _ targeted: Bool) {
        // Cancel any pending clear task
        clearTask?.cancel()

        if targeted {
            targetedSlots.insert(hour)
            // First slot targeted - show indicators immediately
            if !isDraggingTask {
                isDraggingTask = true
            }
        } else {
            targetedSlots.remove(hour)

            // If no more slots are targeted, schedule clearing after delay
            if targetedSlots.isEmpty {
                let task = DispatchWorkItem { [weak self] in
                    self?.isDraggingTask = false
                }
                clearTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
            }
        }
    }
}
