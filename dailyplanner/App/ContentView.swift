//
//  ContentView.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI
import SwiftData
import WhatsNewKit

struct ContentView: View {
    @State private var themeManager = ThemeManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @Query private var existingTasks: [TaskModel]
    @Query private var dayTasks: [DayTaskModel]

    var body: some View {
        MainView()
            .environment(themeManager)
            // Only expose the What's New collection once onboarding is out
            // of the way, so a brand-new user never gets the onboarding
            // sheet and the What's New sheet fighting for presentation at
            // the same time - What's New simply has nothing to show until then.
            .environment(\.whatsNew, WhatsNewEnvironment(defaultLayout: AppWhatsNew.layout, whatsNewCollection: hasCompletedOnboarding ? AppWhatsNew.all : []))
            .whatsNewSheet()
            .preferredColorScheme(themeManager.currentMode.colorScheme)
            .id(themeManager.language.rawValue)
            .onAppear {
                guard !hasCompletedOnboarding else { return }
                if existingTasks.isEmpty {
                    showOnboarding = true
                } else {
                    // Already has tasks - an existing user updating to this
                    // version, not a fresh install. Skip the walkthrough silently.
                    hasCompletedOnboarding = true
                }
            }
            .sheet(isPresented: $showOnboarding) {
                HowItWorksView {
                    hasCompletedOnboarding = true
                }
            }
            // Restarts on every change, so a drag or resize that mutates a
            // task many times a second only writes once it settles.
            .task(id: widgetSnapshot) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                WidgetSnapshotStore.save(widgetSnapshot)
            }
    }

    /// Today's and the coming week's tasks, in the shape the widget reads.
    private var widgetSnapshot: WidgetSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let horizon = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        let tasks = dayTasks.compactMap { task -> WidgetTask? in
            let day = calendar.startOfDay(for: task.date)
            guard day >= today, day < horizon,
                  let start = calendar.date(byAdding: .minute, value: task.startTotalMinutes, to: day),
                  let end = calendar.date(byAdding: .minute, value: task.endTotalMinutes, to: day) else {
                return nil
            }
            return WidgetTask(id: task.id, name: task.name, color: task.color, icon: task.icon, start: start, end: end)
        }

        return WidgetSnapshot(
            tasks: tasks.sorted { $0.start < $1.start },
            languageCode: themeManager.language.languageCode,
            uses24HourTime: themeManager.timeFormat == .twentyFourHour
        )
    }
}

#Preview {
    ContentView()
}
