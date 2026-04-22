import SwiftUI

struct SettingsView: View {
    @State private var optIn = AIService.shared.isOptedIn()
    @State private var apiKey = AIService.shared.getAPIKey() ?? ""
    @State private var status = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI") {
                    Toggle("Enable AI Assistance", isOn: $optIn)
                        .onChange(of: optIn) { newValue in
                            AIService.shared.setOptIn(newValue)
                        }

                    SecureField("OpenAI API Key", text: $apiKey)

                    Button("Save API Key") {
                        AIService.shared.storeAPIKey(apiKey)
                        status = "Saved"
                    }

                    if !status.isEmpty {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
