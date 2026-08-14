//
//  ContentView.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        MainView()
            .environment(themeManager)
            .preferredColorScheme(themeManager.currentMode.colorScheme)
            .id(themeManager.language.rawValue)
    }
}

#Preview {
    ContentView()
}
