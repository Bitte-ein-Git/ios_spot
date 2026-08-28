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
