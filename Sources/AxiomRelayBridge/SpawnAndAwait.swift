// SDK gap filler — would be upstreamed to AgentRelaySDK.
//
// The Swift SDK currently exposes `spawnAgent`, channel subscriptions, and
// raw `brokerEvents` / `inboundMessages` streams. It does NOT expose a
// convenience for the common "ask an agent something, get its reply"
// pattern. Every caller has to:
//
//   1. invent a channel name
//   2. subscribe to it
//   3. spawn the agent on that channel with an initial task
//   4. iterate channel events and decide when the agent is "done"
//   5. release the agent
//
// `spawnAndAwait` collapses that into one call. It lives here because we
// own the SDK and intend to upstream it.

import Foundation
import AgentRelaySDK

public enum SpawnAwaitError: Error, Sendable {
    case timeout
    case agentReleased
    case predicateFailed(String)
}

public extension RelayCast {
    /// Spawn an agent on a private channel, hand it `prompt`, and return
    /// the first message it posts that satisfies `until`.
    ///
    /// The agent is always released before this returns, even on error.
    ///
    /// - Parameters:
    ///   - spec: Agent to spawn. `channels` is overridden with a fresh ephemeral channel.
    ///   - prompt: Initial task handed to the agent.
    ///   - until: Predicate over each inbound message body. Default: any non-empty body from the agent.
    ///   - timeout: How long to wait before giving up.
    func spawnAndAwait(
        spec: AgentSpec,
        prompt: String,
        until: @Sendable (String) -> Bool = { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
        timeout: Duration = .seconds(120)
    ) async throws -> String {
        let channelName = "axiom-extract-\(UUID().uuidString.lowercased())"
        var specWithChannel = spec
        specWithChannel.channels = [channelName]

        let channel = self.channel(channelName)
        try await channel.subscribe()
        try await self.spawnAgent(specWithChannel, initialTask: prompt, skipRelayPrompt: false)

        defer {
            Task { [weak self] in
                try? await self?.releaseAgent(name: spec.name, reason: "spawnAndAwait completed")
            }
        }

        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                for await event in channel.events where event.from == spec.name {
                    if until(event.body) {
                        return event.body
                    }
                }
                throw SpawnAwaitError.agentReleased
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw SpawnAwaitError.timeout
            }

            guard let result = try await group.next() else {
                throw SpawnAwaitError.agentReleased
            }
            group.cancelAll()
            return result
        }
    }
}
