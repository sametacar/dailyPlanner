//
//  WidgetSnapshot.swift
//  dailyplanner
//
//  Shared by the app and the widget extension. The app keeps its SwiftData
//  store private and instead writes this small JSON summary into the App
//  Group, which is all the widget ever reads.
//

import Foundation
import WidgetKit

struct WidgetTask: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var color: String
    var icon: String?
    var start: Date
    var end: Date
}

struct WidgetSnapshot: Codable, Equatable {
    /// Tasks from today through the next few days, sorted by start time.
    /// Holding more than today lets the widget roll over at midnight
    /// without the app having to be opened.
    var tasks: [WidgetTask]
    var languageCode: String
    var uses24HourTime: Bool

    static let empty = WidgetSnapshot(tasks: [], languageCode: "en", uses24HourTime: true)

    func formattedTime(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        guard !uses24HourTime else {
            return String(format: "%02d:%02d", hour, minute)
        }
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, minute, hour < 12 ? "AM" : "PM")
    }
}

enum WidgetSnapshotStore {
    static let appGroupID = "group.com.acar.dailyplanner"
    static let widgetKind = "DailyPlannerWidget"
    private static let snapshotKey = "widgetSnapshot"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Writes the snapshot and asks WidgetKit to refresh - but only when
    /// something actually changed, since reloads are budgeted by the system.
    static func save(_ snapshot: WidgetSnapshot) {
        guard snapshot != load(),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
