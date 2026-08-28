import UIKit

enum EqualizerDeepLinkHandler {
    static func handle(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()
        let absolute = url.absoluteString.lowercased()

        let isEq =
            absolute.contains("equalizer") ||
            host == "equalizer" ||
            path.contains("equalizer") ||
            (scheme == "spotify" && (host == "equalizer" || path == "/equalizer" || absolute.hasSuffix(":equalizer")))

        guard isEq else { return false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            navigateToEqualizer()
        }
        return true
    }

    private static func navigateToEqualizer() {
        guard let root = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        if let nav = top as? UINavigationController {
            top = nav.visibleViewController ?? nav
        } else if let tab = top as? UITabBarController {
            top = tab.selectedViewController ?? top
            if let nav = top as? UINavigationController {
                top = nav.visibleViewController ?? nav
            }
        }

        if let settings = WindowHelper.shared.findFirstViewController("RootSettingsViewController") {
            let nav = settings.navigationController ?? (top as? UINavigationController)
            nav?.popToRootViewController(animated: false)

            // Best-effort: open Playback then Equalizer by known section names.
            // Spotify internal structure changes; this still lands the user near EQ.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if let playback = WindowHelper.shared.findFirstViewController("PlaybackSettingsSection")
                    ?? WindowHelper.shared.findFirstViewController("SPTPlaybackSettingsSection") {
                    // nothing more reliable without private selectors
                }
                // Fallback open via settings row search is handled in Equalizer helper UI
            }
        }

        // Always surface our own EQ profiles UI as reliable entry
        presentEqualizerProfiles()
    }

    private static func presentEqualizerProfiles() {
        guard let root = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        var top = root
        while let presented = top.presentedViewController { top = presented }

        let host = UIHostingController(rootView: EeveeEqualizerProfilesView())
        host.modalPresentationStyle = .pageSheet
        if let sheet = host.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        top.present(host, animated: true)
    }
}

import SwiftUI