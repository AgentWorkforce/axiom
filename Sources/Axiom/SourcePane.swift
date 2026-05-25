import SwiftUI
import AxiomCore

struct SourcePane: View {
    @EnvironmentObject var model: AxiomViewModel
    @AppStorage(SettingsKeys.apiKey) private var apiKey: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            ScrollView {
                TextEditor(text: $model.transcript)
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 320)
            }
            .background(Color(nsColor: .textBackgroundColor))

            Divider()
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Planning conversation")
                .font(.headline)
            Text("Paste or stream a transcript between you and a coding agent. Axiom will read it for intents, constraints, boundaries, non-goals, success criteria, and open questions — not for implementation details.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                Task { await model.extractWithHeuristic() }
            } label: {
                if model.isExtracting {
                    ProgressView().controlSize(.small)
                    Text("Extracting…")
                } else {
                    Image(systemName: "sparkles")
                    Text("Extract")
                }
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(model.isExtracting || model.transcript.isEmpty)
            .help("Run the local heuristic extractor")

            Button {
                Task { await model.extractWithRelay() }
            } label: {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("Refine with Relay")
            }
            .disabled(model.isExtracting || model.transcript.isEmpty || apiKey.isEmpty)
            .help(apiKey.isEmpty
                  ? "Set your Agent Relay API key in Settings to enable"
                  : "Spawn a Claude agent through Agent Relay to refine the extraction")

            Spacer()

            Menu {
                Button("Load example conversation") { model.loadSeed() }
                Divider()
                Button("Clear transcript") { model.transcript = "" }
                Button(role: .destructive) {
                    model.clearAll()
                } label: { Text("Clear all axioms") }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
