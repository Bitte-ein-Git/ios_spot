import Orion
import UIKit

class UIOpenURLContextHook: ClassHook<UIOpenURLContext> {
    func URL() -> URL {
        let url = orig.URL()

        if url.isOpenSpotifySafariExtension {
            return Foundation.URL(string: "https:/\(url.path)")!
        }

        if EqualizerDeepLinkHandler.handle(url) {
            return Foundation.URL(string: "spotify:")!
        }

        return url
    }
}

class UIApplicationOpenURLHook: ClassHook<UIApplication> {
    func openURL(
        _ url: URL,
        options: [UIApplication.OpenExternalURLOptionsKey: Any],
        completionHandler completion: @escaping ((Bool) -> Void)?
    ) {
        if EqualizerDeepLinkHandler.handle(url) {
            completion?(true)
            return
        }
        orig.openURL(url, options: options, completionHandler: completion)
    }
}