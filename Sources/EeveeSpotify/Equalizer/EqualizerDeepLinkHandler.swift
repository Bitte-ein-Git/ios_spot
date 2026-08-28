import UIKit
import SwiftUI

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
            presentEqualizerProfiles()
        }
        return true
    }

    private static func presentEqualizerProfiles() {
        guard let root = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        let host = UIHostingController(rootView: EeveeEqualizerProfilesView())
        host.modalPresentationStyle = .pageSheet
        top.present(host, animated: true)
    }
}