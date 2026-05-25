import Foundation

enum ExtractionPrompt {
    static func build(transcript: String) -> String {
        """
        You are reading a planning conversation between a human and a coding agent.
        Your job is to extract the AXIOMS — durable truths that must remain true
        during implementation. You are not writing a task list.

        Rules:
        - Capture intent, constraints, boundaries, non-goals, success criteria, and open questions.
        - Do NOT capture implementation details unless they are an explicit constraint
          (e.g. "must be a single Bash script" is a constraint; "we'll use a for loop" is not).
        - Prefer short, declarative statements. One idea per axiom.
        - Make uncertainty explicit as an open question.
        - Separate "what must be true" from "how to implement it."

        Output: a single JSON object, wrapped in a fenced ```json``` block, matching:
        {
          "axioms": [
            { "category": "intent" | "constraint" | "boundary" | "non-goal" | "success" | "open-question",
              "text": "..." }
          ]
        }

        Do not output anything else. No commentary, no preamble. Just the JSON block.

        Planning conversation:
        ---
        \(transcript)
        ---
        """
    }

    static func containsJSONResult(_ body: String) -> Bool {
        body.contains("```json") || body.contains("\"axioms\"")
    }

    static func extractJSON(from body: String) throws -> String {
        if let range = body.range(of: "```json"),
           let end = body.range(of: "```", range: range.upperBound..<body.endIndex) {
            return String(body[range.upperBound..<end.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = body.firstIndex(of: "{"),
           let end = body.lastIndex(of: "}") {
            return String(body[start...end])
        }
        throw NSError(
            domain: "RelayAxiomExtractor",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Agent reply did not contain JSON axioms."]
        )
    }
}
