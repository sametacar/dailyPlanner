//
//  AppWhatsNew.swift
//  dailyplanner
//

import SwiftUI
import WhatsNewKit

/// Central declaration of the app's "What's New" content per version.
/// Used both for automatic presentation (WhatsNewEnvironment, shown once per
/// new version) and manual presentation (a "What's New" row in Settings).
enum AppWhatsNew {
    /// Shared layout for all WhatsNew presentations (auto and manual), with
    /// extra breathing room between feature rows.
    static let layout = WhatsNew.Layout(featureListSpacing: 36)

    /// The big "What's New" title with a smaller, muted "Version x.y" line
    /// underneath it. WhatsNewView renders `WhatsNew.Title.text` with a
    /// blanket `.largeTitle.bold()` modifier, so the version run needs its
    /// own explicit font/color attributes (via AttributedString) to
    /// override that and render smaller/secondary instead.
    static func titleWithVersion(_ versionNumber: String) -> AttributedString {
        var title = AttributedString("whatsnew.title".localized + "\n")
        var version = AttributedString("whatsnew.version".localized(with: versionNumber))
        version.font = .subheadline
        version.foregroundColor = .secondary
        title.append(version)
        return title
    }

    /// One WhatsNew entry per released version, oldest first. Add a new
    /// entry here whenever a version ships with user-facing changes worth
    /// showcasing - no changes needed anywhere else for it to be picked up.
    ///
    /// Computed (not a stored `let`) so the `.localized` lookups inside
    /// re-run every time the in-app language changes, instead of caching
    /// whichever language was active the first time this was accessed.
    static var all: [WhatsNew] {
        [
            WhatsNew(
                version: "1.4",
                title: WhatsNew.Title(
                    text: WhatsNew.Text(AppWhatsNew.titleWithVersion("1.4"))
                ),
                features: [
                    WhatsNew.Feature(
                        image: .init(systemName: "timer", foregroundColor: .blue),
                        title: .init("whatsnew.1.4.feature1.title".localized),
                        subtitle: .init("whatsnew.1.4.feature1.subtitle".localized)
                    ),
                    WhatsNew.Feature(
                        image: .init(systemName: "paintpalette.fill", foregroundColor: .orange),
                        title: .init("whatsnew.1.4.feature2.title".localized),
                        subtitle: .init("whatsnew.1.4.feature2.subtitle".localized)
                    ),
                    WhatsNew.Feature(
                        image: .init {
                            ZStack {
                                Rectangle()
                                    .fill(Color.white)
                                    .overlay(Rectangle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 18, height: 18)
                            }
                            .frame(width: 40, height: 26)
                        },
                        title: .init("whatsnew.1.4.feature3.title".localized),
                        subtitle: .init("whatsnew.1.4.feature3.subtitle".localized)
                    )
                ],
                primaryAction: WhatsNew.PrimaryAction(
                    title: .init("whatsnew.button.continue".localized),
                    backgroundColor: .accentColor,
                    foregroundColor: .white
                )
            ),
            WhatsNew(
                version: "1.5",
                title: WhatsNew.Title(
                    text: WhatsNew.Text(AppWhatsNew.titleWithVersion("1.5"))
                ),
                features: [
                    WhatsNew.Feature(
                        image: .init(systemName: "rectangle.3.group.fill", foregroundColor: .blue),
                        title: .init("whatsnew.1.5.feature1.title".localized),
                        subtitle: .init("whatsnew.1.5.feature1.subtitle".localized)
                    )
                ],
                primaryAction: WhatsNew.PrimaryAction(
                    title: .init("whatsnew.button.continue".localized),
                    backgroundColor: .accentColor,
                    foregroundColor: .white
                )
            )
        ]
    }

    /// The most recently declared entry, for manual presentation
    /// (e.g. tapping "What's New" in Settings shows this regardless of
    /// whether it was already auto-presented).
    static var latest: WhatsNew? {
        all.last
    }
}
