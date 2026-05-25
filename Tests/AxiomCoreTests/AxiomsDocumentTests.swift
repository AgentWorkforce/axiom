import XCTest
@testable import AxiomCore

final class AxiomsDocumentTests: XCTestCase {
    func testApprovedOnlyMarkdownOmitsUnapproved() {
        let doc = AxiomsDocument(axioms: [
            Axiom(text: "Must never touch the network", category: .constraint, approved: true,  order: 0),
            Axiom(text: "Maybe support an editor flag", category: .openQuestion, approved: false, order: 0)
        ])
        let md = doc.markdown(approvedOnly: true)
        XCTAssertTrue(md.contains("Must never touch the network"))
        XCTAssertFalse(md.contains("Maybe support an editor flag"))
    }

    func testFullMarkdownIncludesCheckboxes() {
        let doc = AxiomsDocument(axioms: [
            Axiom(text: "Approved item", category: .intent, approved: true,  order: 0),
            Axiom(text: "Unapproved item", category: .intent, approved: false, order: 1)
        ])
        let md = doc.markdown(approvedOnly: false)
        XCTAssertTrue(md.contains("- [x] Approved item"))
        XCTAssertTrue(md.contains("- [ ] Unapproved item"))
    }

    func testMarkdownSectionsAppearInCategoryOrder() {
        let doc = AxiomsDocument(axioms: [
            Axiom(text: "S",  category: .success,    approved: true, order: 0),
            Axiom(text: "I",  category: .intent,     approved: true, order: 0),
            Axiom(text: "C",  category: .constraint, approved: true, order: 0)
        ])
        let md = doc.markdown()
        let intentIdx     = md.range(of: "## Intent")!.lowerBound
        let constraintIdx = md.range(of: "## Constraints")!.lowerBound
        let successIdx    = md.range(of: "## Success criteria")!.lowerBound
        XCTAssertTrue(intentIdx < constraintIdx)
        XCTAssertTrue(constraintIdx < successIdx)
    }

    func testAxiomsInCategoryAreOrderSorted() {
        let doc = AxiomsDocument(axioms: [
            Axiom(text: "second", category: .intent, order: 1),
            Axiom(text: "first",  category: .intent, order: 0),
            Axiom(text: "third",  category: .intent, order: 2)
        ])
        let ordered = doc.axioms(in: .intent).map(\.text)
        XCTAssertEqual(ordered, ["first", "second", "third"])
    }

    func testEmptyDocMarkdownStillRenders() {
        let md = AxiomsDocument().markdown()
        XCTAssertTrue(md.contains("# Axioms"))
        XCTAssertTrue(md.contains("No axioms yet"))
    }
}
