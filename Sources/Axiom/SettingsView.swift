import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.apiKey)  private var apiKey: String  = ""
    @AppStorage(SettingsKeys.baseURL) private var baseURL: String = "http://localhost:3889"
    @AppStorage(SettingsKeys.model)   private var model: String   = ""

    var body: some View {
        TabView {
            Form {
                Section {
                    SecureField("API key", text: $apiKey, prompt: Text("rk_live_…"))
                    TextField("Base URL", text: $baseURL, prompt: Text("http://localhost:3889"))
                    TextField("Model (optional)", text: $model, prompt: Text("claude-sonnet-4-6"))
                } header: {
                    Text("Agent Relay")
                } footer: {
                    Text("Used to spawn a Claude agent through Agent Relay for higher-quality extraction. Leave the API key empty to stay fully offline.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Agent Relay", systemImage: "antenna.radiowaves.left.and.right") }
            .padding()
        }
        .frame(width: 460, height: 320)
    }
}
