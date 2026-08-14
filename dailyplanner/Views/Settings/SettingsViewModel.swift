import Foundation
import Combine
import SwiftUI

@MainActor
@Observable
class SettingsViewModel {
    let themeManager = ThemeManager.shared

    var timeFormat: TimeFormat {
        get { themeManager.timeFormat }
        set { themeManager.setTimeFormat(newValue) }
    }

    var themeMode: ThemeMode {
        get { themeManager.currentMode }
        set { themeManager.setTheme(newValue) }
    }
}
