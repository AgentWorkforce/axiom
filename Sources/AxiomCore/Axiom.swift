import Foundation

public struct Axiom: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var category: AxiomCategory
    public var approved: Bool
    public var order: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        category: AxiomCategory,
        approved: Bool = false,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.approved = approved
        self.order = order
        self.createdAt = createdAt
    }
}
