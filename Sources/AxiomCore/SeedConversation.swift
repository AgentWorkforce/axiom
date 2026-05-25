import Foundation

public enum SeedConversation {
    /// A planning conversation between a user and a coding agent for a small
    /// real-world feature. Short enough to read in a glance, varied enough
    /// to exercise every axiom category.
    public static let transcript: String = """
    User: I want to build a small CLI called `note` that captures quick text notes from the terminal into a local file. The idea is to lower friction — I should be able to capture a thought in under two seconds.

    Agent: Got it. So the goal is fast capture rather than a full note-taking app. Should it support search and editing too, or strictly capture?

    User: For now, just capture. We don't need search yet. No tags, no folders, no rich text. If I need search I'll grep the file.

    Agent: Understood. Where should notes be stored? Single file or per-day file?

    User: Single file — `~/notes.md`. Notes must always be appended, never overwritten. Each note gets an ISO 8601 timestamp on its own line above the body.

    Agent: Does it need to work offline? Anything network-related?

    User: It must never touch the network. No sync, no telemetry, no auto-update checks. The user runs `note "thought"` and it returns immediately.

    Agent: How do we know it's working? What's the bar for done?

    User: Done when I can run `note "buy milk"` from any directory and the line shows up at the bottom of `~/notes.md` within 100ms, with the timestamp. Users can also pipe stdin: `echo hi | note`. That's success.

    Agent: A few edge cases — what if `~/notes.md` doesn't exist? What about an empty argument?

    User: If the file doesn't exist, create it. Empty input should print usage and exit non-zero — don't write a blank entry. We're not handling concurrent writers — single-user tool, single process at a time is fine.

    Agent: What about config? Should the file path be configurable?

    User: Not sure yet — maybe later via an env var. Don't add it now. Also I'm undecided on whether to support a `--edit` flag that opens `$EDITOR`. Leave that open.

    Agent: Implementation language?

    User: Whatever's fastest to invoke. Probably a single Bash or Python script. But the implementation choice is yours — what matters is the 100ms budget and that it has zero install steps beyond dropping a file in `$PATH`.

    Agent: Got it. I'll keep it as a single-file script with no dependencies outside the standard library.

    User: Right. The boundary is: one file, no dependencies, no network, no daemon. If we ever need more than that, we'll revisit.
    """
}
