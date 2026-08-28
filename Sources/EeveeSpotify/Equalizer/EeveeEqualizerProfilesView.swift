import SwiftUI

struct EeveeEqualizerProfilesView: View {
    @State private var profiles = EqualizerProfileManager.shared.profiles
    @State private var perDevice = EqualizerProfileManager.shared.perDeviceEnabled
    @State private var newName = ""
    @State private var showSave = false

    private var currentDevice: String {
        EqualizerProfileManager.shared.currentRouteDisplayName()
    }

    private var boundProfileId: String? {
        EqualizerProfileManager.shared.deviceMap[EqualizerProfileManager.shared.currentRouteKey()]
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current output")) {
                    Text(currentDevice)
                        .foregroundColor(.secondary)
                    Toggle("Auto EQ per device", isOn: $perDevice)
                        .onChange(of: perDevice) { val in
                            EqualizerProfileManager.shared.perDeviceEnabled = val
                            if val {
                                EqualizerProfileManager.shared.applyProfileForCurrentRoute()
                            }
                        }
                }

                Section(header: Text("Profiles")) {
                    if profiles.isEmpty {
                        Text("No saved profiles yet")
                            .foregroundColor(.secondary)
                    }
                    ForEach(profiles) { profile in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                Text("\(profile.values.count) bands")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if boundProfileId == profile.id {
                                Image(systemName: "headphones")
                                    .foregroundColor(.green)
                            }
                            Button("Apply") {
                                EqualizerProfileManager.shared.applyProfile(profile)
                            }
                        }
                        .contextMenu {
                            Button("Bind to current device") {
                                EqualizerProfileManager.shared.bindCurrentDevice(to: profile.id)
                                refresh()
                            }
                            Button("Delete") {
                                var list = EqualizerProfileManager.shared.profiles
                                list.removeAll { $0.id == profile.id }
                                EqualizerProfileManager.shared.profiles = list
                                refresh()
                            }
                        }
                    }
                    .onDelete { idx in
                        var list = EqualizerProfileManager.shared.profiles
                        list.remove(atOffsets: idx)
                        EqualizerProfileManager.shared.profiles = list
                        refresh()
                    }
                }

                Section {
                    Button("Save current EQ as profile…") {
                        showSave = true
                    }
                    Button("Unbind current device") {
                        EqualizerProfileManager.shared.unbindCurrentDevice()
                        refresh()
                    }
                }

                Section(footer: Text("Shortcut / URL: open spotify:equalizer or eevee:equalizer — lands in this sheet. Profiles write into Spotify’s equalizer preference keys.")) {
                    EmptyView()
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("EQ Profiles", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                dismissHost()
            })
            .alert(isPresented: $showSave) {
                Alert(
                    title: Text("Profile name"),
                    message: TextFieldAlertMessage(),
                    primaryButton: .default(Text("Save")) {
                        let name = newName.isEmpty ? "Profile \(profiles.count + 1)" : newName
                        EqualizerProfileManager.shared.saveCurrentAsProfile(name: name)
                        newName = ""
                        refresh()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear { refresh() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func TextFieldAlertMessage() -> Text {
        // simple alert without TextField on iOS 14; name auto-generated if empty
        Text("Leave empty for auto name, or set via next save after rename in a future build.")
    }

    private func dismissHost() {
        UIApplication.shared.windows
            .first { $0.isKeyWindow }?
            .rootViewController?
            .dismiss(animated: true)
    }

    private func refresh() {
        profiles = EqualizerProfileManager.shared.profiles
        perDevice = EqualizerProfileManager.shared.perDeviceEnabled
    }
}