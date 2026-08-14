//
//  SettingsView.swift
//  dailyplanner
//
//  Created by vili on 26.01.2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Form {
                Section {
                    // Theme Picker
                    Picker("settings.theme.label".localized,
                           selection: Binding(
                               get: { themeManager.currentMode },
                               set: { themeManager.currentMode = $0 }
                           )) {
                        ForEach(ThemeMode.allCases, id: \.self) { theme in
                            Text(theme.localizedName)
                                .tag(theme)
                        }
                    }

                    // Time Format Picker
                    Picker("settings.timeformat.label".localized,
                           selection: Binding(
                               get: { themeManager.timeFormat },
                               set: { themeManager.timeFormat = $0 }
                           )) {
                        ForEach(TimeFormat.allCases, id: \.self) { format in
                            Text(format.localizedName)
                                .tag(format)
                        }
                    }

                    // Language Picker
                    Picker("settings.language.label".localized,
                           selection: Binding(
                               get: { themeManager.language },
                               set: { themeManager.language = $0 }
                           )) {
                        // English always first
                        Text(LanguageMode.english.localizedName)
                            .tag(LanguageMode.english)

                        // Other languages sorted alphabetically
                        ForEach(LanguageMode.allCases.filter { $0 != .english }.sorted { $0.localizedName < $1.localizedName }, id: \.self) { lang in
                            Text(lang.localizedName)
                                .tag(lang)
                        }
                    }
                } header: {
                    Text("settings.section.appearance".localized)
                }

                // Support Section
                Section {
                    NavigationLink {
                        TipsView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.pink.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Text("💝")
                                    .font(.title3)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.support.title".localized)
                                    .font(.body)

                                Text("settings.support.subtitle".localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                } header: {
                    Text("settings.section.support".localized)
                }
            }
            .navigationTitle("settings.title".localized)
            .preferredColorScheme(themeManager.currentMode.colorScheme)
            .id(themeManager.language.rawValue)
    }
}

#Preview {
    SettingsView()
}
