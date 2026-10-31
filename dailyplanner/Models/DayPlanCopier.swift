//
//  DayPlanCopier.swift
//  dailyplanner
//
//  Created by vili on 12.08.2026.
//

import Foundation
import SwiftData

/// Copies a day's tasks onto another day (used to duplicate yesterday's plan onto today).
enum DayPlanCopier {
    static func tasks(in dayTasks: [DayTaskModel], on date: Date, calendar: Calendar = .current) -> [DayTaskModel] {
        dayTasks.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// Deletes any existing tasks on `targetDate` and replaces them with copies of `sourceTasks`.
    static func copy(_ sourceTasks: [DayTaskModel], to targetDate: Date, replacing existingTasks: [DayTaskModel], modelContext: ModelContext) {
        for task in existingTasks {
            modelContext.delete(task)
        }

        for task in sourceTasks {
            let copy = DayTaskModel(
                taskId: task.taskId,
                name: task.name,
                desc: task.desc,
                color: task.color,
                icon: task.icon,
                date: targetDate,
                startHour: task.startHour,
                endHour: task.endHour,
                startMinute: task.startMinute,
                endMinute: task.endMinute
            )
            modelContext.insert(copy)
        }
    }
}
