//
//  TimelineViewModel.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import Foundation

@Observable
class TimelineViewModel {
    var currentDate: Date = Date()
    var timeSlots: [TimeSlot] = []

    init() {
        // Initialize time slots (6:00 - 23:00)
        // Last slot is 23:00-00:00
        for hour in 6...23 {
            timeSlots.append(TimeSlot(hour: hour))
        }
    }

    /// Check if the day has changed and update currentDate if needed
    /// Returns true if the date was updated
    @discardableResult
    func checkAndUpdateDate() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        if !calendar.isDate(currentDate, inSameDayAs: now) {
            currentDate = now
            return true
        }
        return false
    }
}

struct TimeSlot: Identifiable {
    let id = UUID()
    let hour: Int
}
