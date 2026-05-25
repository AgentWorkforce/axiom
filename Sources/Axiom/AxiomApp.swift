import SwiftUI

@main
struct AxiomApp: App {
    @StateObject private var model = AxiomViewModel()

    var body: some Scene {
        WindowGroup("Axiom") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1000, minHeight: 640)
                .task {
                    await model.bootstrap()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .saveItem) {
                Button("Copy Axioms.md") {
                    model.copyMarkdownToPasteboard()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}
