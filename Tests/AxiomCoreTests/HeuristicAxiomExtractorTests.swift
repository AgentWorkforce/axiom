import XCTest
@testable import AxiomCore

final class HeuristicAxiomExtractorTests: XCTestCase {
    func testClassifiesIntent() {
        XCTAssertEqual(HeuristicAxiomExtractor.classify("We want to build a note CLI."), .intent)
        XCTAssertEqual(HeuristicAxiomExtractor.classify("The goal is fast capture."), .intent)
    }

    func testClassifiesConstraint() {
        XCTAssertEqual(HeuristicAxiomExtractor.classify("Notes must always be appended."), .constraint)
        XCTAssertEqual(HeuristicAxiomExtractor.classify("It must never touch the network."), .constraint)
    }

    func testClassifiesBoundary() {
        XCTAssertEqual(HeuristicAxiomExtractor.classify("Stays within a single script."), .boundary)
        XCTAssertEqual(HeuristicAxiomExtractor.classify("The scope is one file."), .boundary)
    }

    func testClassifiesNonGoal() {
        XCTAssertEqual(HeuristicAxiomExtractor.classify("We don't need search yet."), .nonGoal)
        XCTAssertEqual(HeuristicAxiomExtractor.classify("Out of scope: tags."), .nonGoal)
    }

    func testClassifiesSuccess() {
        XCTAssertEqual(HeuristicAxiomExtractor.classify("Done when the timestamp shows up."), .success)
        XCTAssertEqual(HeuristicAxiomExtractor.classify("Users can pipe stdin."), .success)
    }

    func testClassifiesOpenQuestion() {
        XCTAssertEqual(HeuristicAxiomExtractor.classify("Should the path be configurable?"), .openQuestion)
        XCTAssertEqual(HeuristicAxiomExtractor.classify("I'm undecided on the editor flag."), .openQuestion)
    }

    func testSkipsAmbiguous() {
        XCTAssertNil(HeuristicAxiomExtractor.classify("Hi there."))
        XCTAssertNil(HeuristicAxiomExtractor.classify("Got it."))
    }

    func testSeedConversationProducesAxiomsAcrossCategories() async throws {
        let extractor = HeuristicAxiomExtractor()
        let axioms = try await extractor.extract(from: SeedConversation.transcript)

        XCTAssertGreaterThan(axioms.count, 6, "Seed should yield several axioms")

        let categories = Set(axioms.map { $0.category })
        XCTAssertTrue(categories.contains(.intent),       "expected intent in seed")
        XCTAssertTrue(categories.contains(.constraint),   "expected constraint in seed")
        XCTAssertTrue(categories.contains(.nonGoal),      "expected non-goal in seed")
        XCTAssertTrue(categories.contains(.success),      "expected success in seed")
        XCTAssertTrue(categories.contains(.openQuestion), "expected open question in seed")
    }

    func testStripsSpeakerPrefixBeforeClassifying() async throws {
        let transcript = "User: We don't need search yet."
        let axioms = try await HeuristicAxiomExtractor().extract(from: transcript)
        XCTAssertEqual(axioms.count, 1)
        XCTAssertEqual(axioms.first?.category, .nonGoal)
        XCTAssertFalse(axioms.first?.text.hasPrefix("User:") ?? true)
    }

    func testDeduplicates() async throws {
        let transcript = "We must always append. We must always append."
        let axioms = try await HeuristicAxiomExtractor().extract(from: transcript)
        XCTAssertEqual(axioms.count, 1)
    }
}
