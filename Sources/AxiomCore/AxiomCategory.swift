import Foundation

public enum AxiomCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case intent
    case constraint
    case boundary
    case nonGoal = "non_goal"
    case success
    case openQuestion = "open_question"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .intent:        return "Intent"
        case .constraint:    return "Constraints"
        case .boundary:      return "Boundaries"
        case .nonGoal:       return "Non-goals"
        case .success:       return "Success criteria"
        case .openQuestion:  return "Open questions"
        }
    }

    public var singular: String {
        switch self {
        case .intent:        return "Intent"
        case .constraint:    return "Constraint"
        case .boundary:      return "Boundary"
        case .nonGoal:       return "Non-goal"
        case .success:       return "Success criterion"
        case .openQuestion:  return "Open question"
        }
    }

    public var systemImage: String {
        switch self {
        case .intent:        return "target"
        case .constraint:    return "lock"
        case .boundary:      return "square.dashed"
        case .nonGoal:       return "nosign"
        case .success:       return "checkmark.seal"
        case .openQuestion:  return "questionmark.circle"
        }
    }

    public var blurb: String {
        switch self {
        case .intent:       return "What we are fundamentally trying to bring into being."
        case .constraint:   return "Things that must remain true throughout implementation."
        case .boundary:     return "Where the work stops. What's in scope, what isn't."
        case .nonGoal:      return "Things we explicitly choose not to do."
        case .success:      return "How we will know the result is correct."
        case .openQuestion: return "What we don't yet know. Resolve before relying on it."
        }
    }
}
