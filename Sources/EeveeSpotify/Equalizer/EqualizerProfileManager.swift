import Foundation
import AVFoundation
import UIKit

struct EqualizerProfile: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    // normalized gains -1.0 ... 1.0 (Spotify style), typically 6 bands
    var values: [Double]
    var createdAt: Date
}

final class EqualizerProfileManager {
    static let shared = EqualizerProfileManager()

    private let profilesKey = "eevee.eq.profiles"
    private let deviceMapKey = "eevee.eq.deviceMap" // deviceUID -> profileId
    private let enabledKey = "eevee.eq.perDeviceEnabled"

    private var routeObserver: NSObjectProtocol?

    var profiles: [EqualizerProfile] {
        get {
            guard let data = UserDefaults.standard.data(forKey: profilesKey),
                  let list = try? JSONDecoder().decode([EqualizerProfile].self, from: data) else {
                return []
            }
            return list
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: profilesKey)
            }
        }
    }

    var deviceMap: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: deviceMapKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: deviceMapKey) }
    }

    var perDeviceEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    func startRouteObserver() {
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyProfileForCurrentRoute()
        }
        // initial apply shortly after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.applyProfileForCurrentRoute()
        }
    }

    func currentRouteKey() -> String {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        if let first = outputs.first {
            // UID is stable for many BT devices; fall back to portName
            let uid = first.uid
            if !uid.isEmpty { return uid }
            return first.portName
        }
        return "builtin"
    }

    func currentRouteDisplayName() -> String {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.first?.portName ?? "Built-in"
    }

    func saveCurrentAsProfile(name: String) {
        let values = readSpotifyEqualizerValues() ?? Array(repeating: 0.0, count: 6)
        var list = profiles
        let profile = EqualizerProfile(
            id: UUID().uuidString,
            name: name,
            values: values,
            createdAt: Date()
        )
        list.append(profile)
        profiles = list
    }

    func applyProfile(_ profile: EqualizerProfile) {
        writeSpotifyEqualizerValues(profile.values)
        // nudge model if present
        if let model = NSClassFromString("SPTEqualizerModel") as? NSObject.Type {
            // best effort – actual instance is managed by Spotify
        }
    }

    func bindCurrentDevice(to profileId: String) {
        var map = deviceMap
        map[currentRouteKey()] = profileId
        deviceMap = map
        if let p = profiles.first(where: { $0.id == profileId }) {
            applyProfile(p)
        }
    }

    func unbindCurrentDevice() {
        var map = deviceMap
        map.removeValue(forKey: currentRouteKey())
        deviceMap = map
    }

    func applyProfileForCurrentRoute() {
        guard perDeviceEnabled else { return }
        let key = currentRouteKey()
        guard let profileId = deviceMap[key],
              let profile = profiles.first(where: { $0.id == profileId }) else {
            return
        }
        applyProfile(profile)
    }

    // MARK: - Spotify preference I/O

    private func equalizerValuesKeys() -> [String] {
        // Spotify stores per-user: <userId>.com.spotify.feature.equalizer.values
        let defaults = UserDefaults.standard
        let all = defaults.dictionaryRepresentation()
        return all.keys.filter { $0.contains("com.spotify.feature.equalizer.values") }
    }

    func readSpotifyEqualizerValues() -> [Double]? {
        let keys = equalizerValuesKeys()
        for key in keys {
            if let arr = UserDefaults.standard.array(forKey: key) as? [Double] {
                return arr
            }
            if let arr = UserDefaults.standard.array(forKey: key) as? [NSNumber] {
                return arr.map { $0.doubleValue }
            }
        }
        return nil
    }

    func writeSpotifyEqualizerValues(_ values: [Double]) {
        let keys = equalizerValuesKeys()
        let numbers = values.map { NSNumber(value: $0) }
        if keys.isEmpty {
            // fallback key pattern – will be picked up once user opens EQ once
            UserDefaults.standard.set(numbers, forKey: "com.spotify.feature.equalizer.values")
        } else {
            for key in keys {
                UserDefaults.standard.set(numbers, forKey: key)
            }
        }
        UserDefaults.standard.synchronize()
    }
}