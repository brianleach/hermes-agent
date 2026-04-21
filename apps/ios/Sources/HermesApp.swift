import SwiftUI

@main
struct HermesApp: App {
    @State private var settings: SettingsStore
    @State private var client: HermesClient

    init() {
        let store = SettingsStore()
        _settings = State(initialValue: store)
        _client = State(initialValue: HermesClient(settings: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(client)
        }
    }
}
