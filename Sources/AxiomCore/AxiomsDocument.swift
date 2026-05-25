import Foundation

public struct AxiomsDocument: Codable, Hashable, Sendable {
    public var title: String
    public var axioms: [Axiom]
    public var updatedAt: Date

    public init(title: String = "Axioms", axioms: [Axiom] = [], updatedAt: Date = Date()) {
        self.title = title
        self.axioms = axioms
        self.updatedAt = updatedAt
    }

    public func axioms(in category: AxiomCategory) -> [Axiom] {
        axioms
            .filter { $0.category == category }
            .sorted { $0.order < $1.order }
    }

    public var approvedCount: Int { axioms.filter(\.approved).count }
    public var totalCount: Int { axioms.count }

    /// Renders the canonical Axioms.md document.
    ///
    /// - Parameter approvedOnly: When true (default), only approved axioms appear —
    ///   the document is meant to be the durable truths the implementer relies on.
    public func markdown(approvedOnly: Bool = true) -> String {
        var out = "# \(title)\n\n"
        out += "_Durable truths the implementation must respect. "
        out += "Not a task list — what must remain true, not how to do it._\n\n"

        var emittedAny = false
        for category in AxiomCategory.allCases {
            let items = self.axioms(in: category).filter { !approvedOnly || $0.approved }
            guard !items.isEmpty else { continue }
            emittedAny = true
            out += "## \(category.title)\n\n"
            for axiom in items {
                if approvedOnly {
                    out += "- \(axiom.text)\n"
                } else {
                    let marker = axiom.approved ? "- [x]" : "- [ ]"
                    out += "\(marker) \(axiom.text)\n"
                }
            }
            out += "\n"
        }

        if !emittedAny {
            out += "_(No axioms yet. Extract from a planning conversation to populate.)_\n"
        }

        return out
    }
}
