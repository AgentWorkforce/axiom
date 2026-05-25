import Foundation

/// A small, dependency-free extractor. It is intentionally conservative:
/// it would rather skip a sentence than misclassify one. Use it offline,
/// for the seeded example, and as a fast first pass before refinement.
public struct HeuristicAxiomExtractor: AxiomExtractor {
    public init() {}

    public func extract(from transcript: String) async throws -> [Axiom] {
        let sentences = Self.sentences(in: transcript)

        var results: [Axiom] = []
        var orderPerCategory: [AxiomCategory: Int] = [:]
        var seen = Set<String>()

        for sentence in sentences {
            guard sentence.count > 6, sentence.count < 400 else { continue }
            guard let category = Self.classify(sentence) else { continue }
            let normalized = Self.normalize(sentence, for: category)
            let key = normalized.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)

            let order = orderPerCategory[category, default: 0]
            orderPerCategory[category] = order + 1
            results.append(Axiom(text: normalized, category: category, order: order))
        }
        return results
    }

    // MARK: - Public helpers (exposed for tests)

    public static func sentences(in transcript: String) -> [String] {
        var out: [String] = []
        let lines = transcript
            .split(whereSeparator: { $0.isNewline })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in lines {
            let stripped = stripSpeakerPrefix(line)
            out.append(contentsOf: splitSentences(stripped))
        }
        return out
    }

    public static func classify(_ raw: String) -> AxiomCategory? {
        let s = raw.lowercased()

        // Open questions — questions or explicit uncertainty markers.
        if s.hasSuffix("?")
            || s.contains("not sure")
            || s.contains("unclear")
            || s.contains("tbd")
            || s.contains("undecided")
            || s.contains("open question") {
            return .openQuestion
        }

        // Non-goals — explicit "we won't / out of scope" cues.
        let nonGoalCues = [
            "we don't need", "we do not need", "no need to", "out of scope",
            "not a goal", "not in scope", "won't support", "won't ship",
            "not handling", "non-goal", "skip ", "we won't", "we will not",
            "not now", "not yet a priority"
        ]
        if nonGoalCues.contains(where: { s.contains($0) }) { return .nonGoal }

        // Success criteria.
        let successCues = [
            "success is", "done when", "definition of done", "we'll know it works when",
            "we will know it works when", "succeeds when", "we ship when", "ready when",
            "acceptance criteria", "users can ", "the user can ", "should result in"
        ]
        if successCues.contains(where: { s.contains($0) }) { return .success }

        // Boundaries — scope/limit cues.
        let boundaryCues = [
            "only ", "limited to", "limit to", "scope is", "in scope:",
            "stays within", "stay within", "the boundary", "boundary is",
            "we restrict", "restricted to"
        ]
        if boundaryCues.contains(where: { s.contains($0) }) { return .boundary }

        // Constraints — invariants.
        let constraintCues = [
            "must ", "must not", "never ", "cannot ", "can't ",
            "required ", "is required", "needs to be", "should always",
            "should never", "always "
        ]
        if constraintCues.contains(where: { s.contains($0) }) { return .constraint }

        // Intent — what we're building.
        let intentCues = [
            "we want", "the goal is", "goal is", "we're building", "we are building",
            "build a", "build an", "we should build", "objective is", "intent is",
            "purpose is", "we're trying to", "we are trying to", "the idea is"
        ]
        if intentCues.contains(where: { s.contains($0) }) { return .intent }

        return nil
    }

    // MARK: - Private helpers

    private static func stripSpeakerPrefix(_ line: String) -> String {
        let pattern = #"^\s*([A-Za-z][A-Za-z0-9_ -]{0,30}?)\s*:\s+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return line }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range), match.range.location == 0,
              let r = Range(match.range, in: line) else {
            return line
        }
        return String(line[r.upperBound...])
    }

    private static func splitSentences(_ text: String) -> [String] {
        var parts: [String] = []
        var current = ""
        for ch in text {
            current.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { parts.append(trimmed) }
                current = ""
            }
        }
        let tail = current.trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty { parts.append(tail) }
        return parts
    }

    static func normalize(_ sentence: String, for category: AxiomCategory) -> String {
        var s = sentence

        if category != .openQuestion {
            while let last = s.last, ".!,;".contains(last) { s.removeLast() }
        }

        let leadingPrefixes = [
            "and ", "but ", "so ", "well ", "okay ", "ok ", "also ",
            "i think ", "we think ", "honestly "
        ]
        let lower = s.lowercased()
        for p in leadingPrefixes where lower.hasPrefix(p) {
            s = String(s.dropFirst(p.count))
            break
        }

        if let first = s.first, first.isLetter {
            s = first.uppercased() + s.dropFirst()
        }
        return s.trimmingCharacters(in: .whitespaces)
    }
}
