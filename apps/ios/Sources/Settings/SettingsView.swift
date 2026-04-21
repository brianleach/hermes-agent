import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Gateway") {
                    TextField("Base URL", text: $settings.baseURLString)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField(
                        "API Key (optional)",
                        text: Binding(
                            get: { settings.apiKey ?? "" },
                            set: { settings.apiKey = $0.isEmpty ? nil : $0 }
                        )
                    )
                    .textContentType(.password)
                }
                Section("Model") {
                    TextField("Model", text: $settings.model)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                Section {
                    Text(
                        "Run `hermes gateway start` on your host and point Base URL at its address " +
                        "(default http://localhost:8642). Set API_SERVER_KEY on the gateway " +
                        "to enable session continuity."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
