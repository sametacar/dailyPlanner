//
//  MainView.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel = MainViewModel()
    @State private var dragStateManager = DragStateManager()
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Timeline
                DailyTimelineView(showTasks: $viewModel.showTasks)
                    .frame(maxWidth: .infinity)

                // Tasks Panel
                if viewModel.showTasks {
                    Divider()
                        .background(Color.dpSeparator)

                    TasksView(isVisible: $viewModel.showTasks)
                        .frame(maxWidth: .infinity)
                        .background(Color.dpAppBackground)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showTasks)
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(dragStateManager)
        .id(themeManager.language.rawValue)
    }
}
