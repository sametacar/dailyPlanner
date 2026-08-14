//
//  Localization.swift
//  dailyplanner
//
//  Created by vili on 26.01.2026.
//

import Foundation

extension String {
    var localized: String {
        let themeManager = ThemeManager.shared
        let languageCode = themeManager.language.languageCode

        guard let bundle = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let langBundle = Bundle(path: bundle) else {
            return NSLocalizedString(self, comment: "")
        }

        return NSLocalizedString(self, tableName: nil, bundle: langBundle, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
