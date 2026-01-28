import SwiftUI

struct EeveeSettingsVersionView: View {
    @State private var latestVersion: String?
    @State private var isPresentingContributorsSheet = false
    
    private func loadVersion() async throws {
        let release = try await GitHubHelper.shared.getLatestRelease()
        // Remove prefixes to get pure version number
        latestVersion = release.tagName
            .replacingOccurrences(of: "swift", with: "")
            .replacingOccurrences(of: "v", with: "")
    }
    
    private var isUpdateAvailable: Bool {
        guard let latest = latestVersion else { return false }
        return latest != EeveeSpotify.version
    }
    
    var body: some View {
        Section {
            if isUpdateAvailable {
                Link(
                    "update_available".localized,
                    destination: URL(string: "https://github.com/Bitte-ein-Git/ios_spot/releases")!
                )
            }
        } footer: {
            VStack(alignment: .leading) {
                Text("v\(EeveeSpotify.version)")
                
                if latestVersion == nil {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("checking_for_update".localized)
                    }
                }
                else {
                    Button("\("contributors".localized)...") {
                        isPresentingContributorsSheet = true
                    }
                    .foregroundColor(.gray)
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
        .sheet(isPresented: $isPresentingContributorsSheet) {
            EeveeContributorsSheetView()
        }
        
        .animation(.default, value: latestVersion)
        
        .onAppear {
            Task {
                try await loadVersion()
            }
        }
    }
}