import SwiftUI
import AxiomCore

struct ContentView: View {
    @EnvironmentObject var model: AxiomViewModel

    var body: some View {
        NavigationSplitView {
            SourcePane()
                .navigationSplitViewColumnWidth(min: 360, ideal: 460, max: 640)
        } detail: {
            AxiomsPane()
        }
        .navigationTitle("Axiom")
        .navigationSubtitle(subtitle)
        .toolbar { toolbarContent }
        .overlay(alignment: .bottom) {
            StatusBar()
        }
        .alert("Something went wrong",
               isPresented: Binding(
                get: { model.lastError != nil },
                set: { if !$0 { model.lastError = nil } }
               ),
               actions: {
                   Button("OK") { model.lastError = nil }
               },
               message: {
                   Text(model.lastError ?? "")
               })
    }

    private var subtitle: String {
        "\(model.document.approvedCount) approved · \(model.document.totalCount) total"
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                model.copyMarkdownToPasteboard()
            } label: {
                Label("Copy Axioms.md", systemImage: "doc.on.clipboard")
            }
            .help("Copy approved axioms as Markdown for Claude Code, Codex, etc.")

            Button {
                model.exportToFile()
            } label: {
                Label("Export…", systemImage: "square.and.arrow.up")
            }
            .help("Save Axioms.md to disk")

            Button {
                model.approveAll()
            } label: {
                Label("Approve all", systemImage: "checkmark.seal")
            }
            .help("Mark every axiom approved")
        }
    }
}

private struct StatusBar: View {
    @EnvironmentObject var model: AxiomViewModel

    var body: some View {
        Group {
            if let msg = model.statusMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .task(id: msg) {
                        try? await Task.sleep(for: .seconds(4))
                        if model.statusMessage == msg {
                            withAnimation { model.statusMessage = nil }
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.15), value: model.statusMessage)
    }
}
