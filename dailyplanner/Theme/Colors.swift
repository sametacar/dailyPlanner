//
//  Colors.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI

extension Color {
    // MARK: - Background Colors
    static let dpAppBackground = Color("AppBackground")
    static let dpCardBackground = Color("CardBackground")
    static let dpTimelineBackground = Color("TimelineBackground")

    // MARK: - Text Colors
    static let dpPrimaryText = Color("PrimaryText")
    static let dpSecondaryText = Color("SecondaryText")
    static let dpAccentText = Color("AccentText")

    // MARK: - UI Element Colors
    static let dpSeparator = Color("SeparatorColor")
    static let dpTimelineLine = Color("TimelineLine")

    // MARK: - Task Colors
    static let dpTaskBlue = Color("TaskBlue")
    static let dpTaskGreen = Color("TaskGreen")
    static let dpTaskOrange = Color("TaskOrange")
    static let dpTaskPurple = Color("TaskPurple")
    static let dpTaskRed = Color("TaskRed")

    // MARK: - Hex Color Initializer
    init(hex: String) {
        var cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        cleanedHex = cleanedHex.hasPrefix("#") ? String(cleanedHex.dropFirst()) : cleanedHex

        let scanner = Scanner(string: cleanedHex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
