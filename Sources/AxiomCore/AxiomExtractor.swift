import Foundation

public protocol AxiomExtractor: Sendable {
    func extract(from transcript: String) async throws -> [Axiom]
}
