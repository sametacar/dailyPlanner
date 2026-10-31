//
//  DayTask.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import Foundation
import SwiftData

@Model
class DayTaskModel {
    var id: UUID
    var taskId: UUID? // Reference to the TaskModel this was created from
    var name: String
    var desc: String
    var color: String
    var icon: String?
    var date: Date
    var startHour: Int
    var endHour: Int
    var startMinute: Int = 0
    var endMinute: Int = 0

    init(
        taskId: UUID? = nil,
        name: String,
        desc: String,
        color: String,
        icon: String?,
        date: Date,
        startHour: Int,
        endHour: Int,
        startMinute: Int = 0,
        endMinute: Int = 0
    ) {
        self.id = UUID()
        self.taskId = taskId
        self.name = name
        self.desc = desc
        self.color = color
        self.icon = icon
        self.date = date
        self.startHour = startHour
        self.endHour = endHour
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    /// Create a DayTaskModel from a TaskModel template
    convenience init(from task: TaskModel, date: Date, startHour: Int, endHour: Int, startMinute: Int = 0, endMinute: Int = 0) {
        self.init(
            taskId: task.id,
            name: task.name,
            desc: task.desc,
            color: task.color,
            icon: task.icon,
            date: date,
            startHour: startHour,
            endHour: endHour,
            startMinute: startMinute,
            endMinute: endMinute
        )
    }

    /// Create from TaskTransfer (for drag-drop)
    convenience init(from transfer: TaskTransfer, date: Date, startHour: Int, endHour: Int, startMinute: Int = 0, endMinute: Int = 0) {
        self.init(
            taskId: transfer.id,
            name: transfer.name,
            desc: transfer.desc,
            color: transfer.color,
            icon: transfer.icon,
            date: date,
            startHour: startHour,
            endHour: endHour,
            startMinute: startMinute,
            endMinute: endMinute
        )
    }

    var startTotalMinutes: Int { startHour * 60 + startMinute }
    var endTotalMinutes: Int { endHour * 60 + endMinute }
    var durationMinutes: Int { endTotalMinutes - startTotalMinutes }
}
