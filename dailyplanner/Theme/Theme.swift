//
//  Theme.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI

enum TimeFormat: String, CaseIterable {
    case twelveHour = "12h"
    case twentyFourHour = "24h"

    var localizedName: String {
        switch self {
        case .twelveHour:
            return "settings.timeformat.12h".localized
        case .twentyFourHour:
            return "settings.timeformat.24h".localized
        }
    }
}

enum LanguageMode: String, CaseIterable {
    case english = "en"
    case turkish = "tr"
    case german = "de"
    case spanish = "es"
    case swedish = "sv"
    case italian = "it"
    case dutch = "nl"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case danish = "da"
    case norwegian = "nb"
    case japanese = "ja"
    /*
    case polish = "pl"
    case french = "fr"
    case hungarian = "hu"
    case romanian = "ro"*/

    var localizedName: String {
        switch self {
        case .english:
            return "settings.language.english".localized
        case .turkish:
            return "settings.language.turkish".localized
        case .german:
            return "settings.language.german".localized
        case .spanish:
            return "settings.language.spanish".localized
        case .swedish:
            return "settings.language.swedish".localized
        case .italian:
            return "settings.language.italian".localized
        case .dutch:
            return "settings.language.dutch".localized
        case .chineseSimplified:
            return "settings.language.chinese_simplified".localized
        case .chineseTraditional:
            return "settings.language.chinese_traditional".localized
        case .danish:
            return "settings.language.danish".localized
        case .norwegian:
             return "settings.language.norwegian".localized
        case .japanese:
            return "settings.language.japanese".localized
       /*
        case .polish:
            return "settings.language.polish".localized
        case .french:
            return "settings.language.french".localized
        
        case .hungarian:
            return "settings.language.hungarian".localized
        case .romanian:
            return "settings.language.romanian".localized*/
        }
    }

    var languageCode: String {
        return self.rawValue
    }
}

enum ThemeMode: String, CaseIterable {
    case light
    case dark
    case system

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    var localizedName: String {
        switch self {
        case .light:
            return "settings.theme.light".localized
        case .dark:
            return "settings.theme.dark".localized
        case .system:
            return "settings.theme.system".localized
        }
    }
}

@Observable
class ThemeManager {
    static let shared = ThemeManager()

    var currentMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "themeMode")
        }
    }

    var timeFormat: TimeFormat {
        didSet {
            UserDefaults.standard.set(timeFormat.rawValue, forKey: "timeFormat")
        }
    }

    var language: LanguageMode {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "language")
        }
    }

    private init() {
        // Load saved preferences or use defaults
        if let savedTheme = UserDefaults.standard.string(forKey: "themeMode"),
           let theme = ThemeMode(rawValue: savedTheme) {
            self.currentMode = theme
        } else {
            self.currentMode = .system
        }

        if let savedTimeFormat = UserDefaults.standard.string(forKey: "timeFormat"),
           let format = TimeFormat(rawValue: savedTimeFormat) {
            self.timeFormat = format
        } else {
            self.timeFormat = .twentyFourHour
        }

        if let savedLanguage = UserDefaults.standard.string(forKey: "language"),
           let lang = LanguageMode(rawValue: savedLanguage) {
            self.language = lang
        } else {
            // Default to system language if supported, otherwise English
            let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            switch systemLang {

            case "de":
                self.language = .german
            case "es":
                self.language = .spanish
            case "tr":
                self.language = .turkish
            case "sv":
                self.language = .swedish
            case "it":
                self.language = .italian
            case "nl":
                self.language = .dutch
            case "da":
                self.language = .danish
            case "nb", "no":
                 self.language = .norwegian
            case "ja":
                self.language = .japanese
            case "zh":
                // Detect if Traditional or Simplified based on region
                let region = Locale.current.region?.identifier ?? ""
                if region == "TW" || region == "HK" || region == "MO" {
                    self.language = .chineseTraditional
                } else {
                    self.language = .chineseSimplified
                }
           /*
            case "pl":
                self.language = .polish

            case "fr":
                self.language = .french
           

            case "hu":
                self.language = .hungarian
            case "ro":
                self.language = .romanian*/
            default:
                self.language = .english
            }
        }
    }

    func setTheme(_ mode: ThemeMode) {
        currentMode = mode
    }

    func setTimeFormat(_ format: TimeFormat) {
        timeFormat = format
    }

    func setLanguage(_ lang: LanguageMode) {
        language = lang
    }

    var currentLocale: Locale {
        return Locale(identifier: language.languageCode)
    }

    func formattedTime(hour: Int) -> String {
        switch timeFormat {
        case .twelveHour:
            if hour == 0 {
                return "12:00 AM"
            } else if hour < 12 {
                return String(format: "%d:00 AM", hour)
            } else if hour == 12 {
                return "12:00 PM"
            } else {
                return String(format: "%d:00 PM", hour - 12)
            }
        case .twentyFourHour:
            return String(format: "%02d:00", hour)
        }
    }

    func formattedTime(hour: Int, minute: Int) -> String {
        switch timeFormat {
        case .twelveHour:
            if hour == 0 {
                return String(format: "12:%02d AM", minute)
            } else if hour < 12 {
                return String(format: "%d:%02d AM", hour, minute)
            } else if hour == 12 {
                return String(format: "12:%02d PM", minute)
            } else {
                return String(format: "%d:%02d PM", hour - 12, minute)
            }
        case .twentyFourHour:
            return String(format: "%02d:%02d", hour, minute)
        }
    }
}
