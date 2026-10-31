//
//  Color+Hex.swift
//  dailyplanner
//
//  Shared by the app and the widget extension.
//

import SwiftUI

extension Color {
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
