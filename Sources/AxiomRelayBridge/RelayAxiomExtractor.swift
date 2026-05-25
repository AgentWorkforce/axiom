import Foundation
import AgentRelaySDK
import AxiomCore

/// Extracts axioms by spawning a Claude agent through Agent Relay and
/// asking it to return JSON in a fixed schema.
public struct RelayAxiomExtractor: AxiomExtractor {
    public let relay: RelayCast
    public let agentName: String
    public let model: String?
    public let timeout: Duration

    public init(
        relay: RelayCast,
        agentName: String = "axiom-extractor",
        model: String? = nil,
        timeout: Duration = .seconds(180)
    ) {
        self.relay = relay
        self.agentName = agentName
        self.model = model
        self.timeout = timeout
    }

    public func extract(from transcript: String) async throws -> [Axiom] {
        let spec = AgentSpec(
            name: agentName,
            runtime: .headless,
            provider: .claude,
            model: model
        )

        let prompt = ExtractionPrompt.build(transcript: transcript)

        let reply = try await relay.spawnAndAwait(
            spec: spec,
            prompt: prompt,
            until: { body in ExtractionPrompt.containsJSONResult(body) },
            timeout: timeout
        )

        let jsonString = try ExtractionPrompt.extractJSON(from: reply)
        let decoded = try JSONDecoder().decode(ExtractedAxioms.self, from: Data(jsonString.utf8))
        return decoded.toAxioms()
    }
}

// MARK: - Wire format

struct ExtractedAxiom: Codable {
    let category: String
    let text: String
}

struct ExtractedAxioms: Codable {
    let axioms: [ExtractedAxiom]

    func toAxioms() -> [Axiom] {
        var orderPerCategory: [AxiomCategory: Int] = [:]
        return axioms.compactMap { item in
            guard let category = mapCategory(item.category) else { return nil }
            let order = orderPerCategory[category, default: 0]
            orderPerCategory[category] = order + 1
            return Axiom(text: item.text, category: category, order: order)
        }
    }

    private func mapCategory(_ raw: String) -> AxiomCategory? {
        switch raw.lowercased().replacingOccurrences(of: "_", with: "-") {
        case "intent":                          return .intent
        case "constraint", "constraints":       return .constraint
        case "boundary", "boundaries":          return .boundary
        case "non-goal", "non-goals", "nongoal": return .nonGoal
        case "success", "success-criteria":     return .success
        case "open-question", "open-questions",
             "question", "questions":           return .openQuestion
        default:                                return nil
        }
    }
}
