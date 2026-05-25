import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AxiomCore
import AxiomRelayBridge
import AgentRelaySDK

enum SettingsKeys {
    static let apiKey  = "relay.apiKey"
    static let baseURL = "relay.baseURL"
    static let model   = "relay.model"
}

@MainActor
final class AxiomViewModel: ObservableObject {
    @Published var transcript: String = ""
    @Published var document: AxiomsDocument = AxiomsDocument()
    @Published var isExtracting: Bool = false
    @Published var lastError: String? = nil
    @Published var statusMessage: String? = nil

    var apiKey: String  { UserDefaults.standard.string(forKey: SettingsKeys.apiKey) ?? "" }
    var baseURL: String { UserDefaults.standard.string(forKey: SettingsKeys.baseURL) ?? "http://localhost:3889" }
    var model: String   { UserDefaults.standard.string(forKey: SettingsKeys.model) ?? "" }

    private let store = AxiomsStore()
    private let heuristic = HeuristicAxiomExtractor()

    func bootstrap() async {
        do {
            if let loaded = try store.load() {
                document = loaded
            } else {
                transcript = SeedConversation.transcript
                await extractWithHeuristic()
                statusMessage = "Seeded with example conversation. Edit, approve, and export."
            }
        } catch {
            lastError = "Could not load saved axioms: \(error.localizedDescription)"
        }
    }

    // MARK: - Extraction

    func extractWithHeuristic() async {
        guard !transcript.isEmpty else {
            lastError = "Paste a conversation first."
            return
        }
        isExtracting = true
        defer { isExtracting = false }
        do {
            let extracted = try await heuristic.extract(from: transcript)
            merge(extracted)
            persist()
            statusMessage = "Extracted \(extracted.count) candidate axioms with the local extractor."
        } catch {
            lastError = error.localizedDescription
        }
    }

    func extractWithRelay() async {
        guard !apiKey.isEmpty else {
            lastError = "Set your Agent Relay API key in Settings before refining."
            return
        }
        guard let base = URL(string: baseURL) else {
            lastError = "Settings base URL isn't valid."
            return
        }
        guard !transcript.isEmpty else {
            lastError = "Paste a conversation first."
            return
        }
        isExtracting = true
        defer { isExtracting = false }

        let relay = RelayCast(apiKey: apiKey, baseURL: base)
        let extractor = RelayAxiomExtractor(
            relay: relay,
            model: model.isEmpty ? nil : model
        )
        do {
            let extracted = try await extractor.extract(from: transcript)
            merge(extracted)
            persist()
            statusMessage = "Refined with Relay — \(extracted.count) axioms returned."
        } catch {
            lastError = "Relay extraction failed: \(error.localizedDescription)"
        }
        await relay.disconnect()
    }

    private func merge(_ new: [Axiom]) {
        var existingKeys = Set(document.axioms.map { keyFor($0) })
        var nextOrders: [AxiomCategory: Int] = [:]
        for cat in AxiomCategory.allCases {
            nextOrders[cat] = (document.axioms(in: cat).map(\.order).max() ?? -1) + 1
        }
        for axiom in new {
            let key = keyFor(axiom)
            if existingKeys.contains(key) { continue }
            existingKeys.insert(key)
            var copy = axiom
            copy.order = nextOrders[axiom.category, default: 0]
            nextOrders[axiom.category] = copy.order + 1
            document.axioms.append(copy)
        }
        document.updatedAt = Date()
    }

    private func keyFor(_ a: Axiom) -> String {
        "\(a.category.rawValue)::\(a.text.lowercased())"
    }

    // MARK: - CRUD

    func add(category: AxiomCategory) {
        let order = (document.axioms(in: category).map(\.order).max() ?? -1) + 1
        let axiom = Axiom(text: "New \(category.singular.lowercased())", category: category, order: order)
        document.axioms.append(axiom)
        persist()
    }

    func delete(_ axiom: Axiom) {
        document.axioms.removeAll { $0.id == axiom.id }
        persist()
    }

    func updateText(_ axiom: Axiom, to newText: String) {
        guard let i = document.axioms.firstIndex(where: { $0.id == axiom.id }) else { return }
        document.axioms[i].text = newText
        persist()
    }

    func toggleApproved(_ axiom: Axiom) {
        guard let i = document.axioms.firstIndex(where: { $0.id == axiom.id }) else { return }
        document.axioms[i].approved.toggle()
        persist()
    }

    func setCategory(_ axiom: Axiom, to newCategory: AxiomCategory) {
        guard let i = document.axioms.firstIndex(where: { $0.id == axiom.id }) else { return }
        document.axioms[i].category = newCategory
        let maxOrder = document.axioms(in: newCategory).map(\.order).max() ?? -1
        document.axioms[i].order = maxOrder + 1
        persist()
    }

    func move(in category: AxiomCategory, from source: IndexSet, to destination: Int) {
        var slice = document.axioms(in: category)
        slice.move(fromOffsets: source, toOffset: destination)
        renumber(slice)
    }

    func moveUp(_ axiom: Axiom) {
        var slice = document.axioms(in: axiom.category)
        guard let i = slice.firstIndex(where: { $0.id == axiom.id }), i > 0 else { return }
        slice.swapAt(i, i - 1)
        renumber(slice)
    }

    func moveDown(_ axiom: Axiom) {
        var slice = document.axioms(in: axiom.category)
        guard let i = slice.firstIndex(where: { $0.id == axiom.id }), i < slice.count - 1 else { return }
        slice.swapAt(i, i + 1)
        renumber(slice)
    }

    private func renumber(_ slice: [Axiom]) {
        for (i, axiom) in slice.enumerated() {
            if let idx = document.axioms.firstIndex(where: { $0.id == axiom.id }) {
                document.axioms[idx].order = i
            }
        }
        persist()
    }

    func approveAll() {
        for i in document.axioms.indices { document.axioms[i].approved = true }
        persist()
    }

    func clearAll() {
        document.axioms.removeAll()
        persist()
    }

    func loadSeed() {
        transcript = SeedConversation.transcript
        statusMessage = "Loaded the example planning conversation."
    }

    // MARK: - Export

    var markdown: String {
        document.markdown(approvedOnly: true)
    }

    var markdownAllAxioms: String {
        document.markdown(approvedOnly: false)
    }

    func copyMarkdownToPasteboard() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(markdown, forType: .string)
        statusMessage = "Axioms.md copied to the clipboard."
    }

    func exportToFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Axioms.md"
        if let mdType = UTType(filenameExtension: "md") {
            panel.allowedContentTypes = [mdType]
        }
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try markdown.data(using: .utf8)?.write(to: url, options: .atomic)
            statusMessage = "Exported to \(url.path)"
        } catch {
            lastError = "Export failed: \(error.localizedDescription)"
        }
    }

    private func persist() {
        document.updatedAt = Date()
        do { try store.save(document) }
        catch { lastError = "Save failed: \(error.localizedDescription)" }
    }
}
