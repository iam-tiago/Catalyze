//
//  ClaudePrompts.swift
//  Catalyze
//
//  High-level prompt functions equivalent to the named exports in
//  `src/lib/claude.ts`. Each function:
//   1. Builds a system + user prompt from app data,
//   2. Calls `ClaudeClient.complete(...)` with streaming,
//   3. Forwards each accumulated-text chunk to `onChunk`,
//   4. Returns the final full text.
//
//  Only `generateIndividualInsight` was specified in detail in the
//  app spec. The other slots (situational, team, 1on1-prep, perf-review)
//  are scaffolded with TODO markers so the call sites compile and we
//  can fill in the prompts incrementally.
//

import Foundation

enum ClaudePrompts {

    // MARK: - Individual insight --------------------------------------------

    /// Analyze a single member. The prompt asks for:
    ///   - Key patterns (2–3)
    ///   - Coaching recommendations (2–3)
    ///   - Watch-outs
    /// Limited to 300 words. Passes up to 10 most recent observations.
    static func generateIndividualInsight(
        client: ClaudeClient,
        member: TeamMember,
        observations: [Observation],
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {

        let recent = observations
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)

        let system = """
        You are an expert engineering management coach helping an EM
        understand and develop a single direct report. Be concrete,
        specific, and actionable. Hard limit: 300 words total.
        """

        var prompt = """
        Analyze this team member and produce three sections:
        1. **Key patterns** (2–3 bullets) — what trends emerge from their
           strengths, growth areas, and observations?
        2. **Coaching recommendations** (2–3 bullets) — what should the EM
           do next?
        3. **Watch-outs** — what risks or blind spots to keep an eye on?

        ## Member
        Name: \(member.name)
        Role: \(member.role)
        Seniority: \(member.seniority.rawValue)

        ## Strengths
        \(formatTags(member.strengths))

        ## Growth areas
        \(formatTags(member.weaknesses))

        ## Recent observations (up to 10 most recent)
        """

        for obs in recent {
            prompt += "\n- [\(obs.context.rawValue)] \(obs.text)"
        }

        return try await client.complete(
            system: system,
            messages: [ChatMessage(role: "user", content: prompt)],
            maxTokens: 800,
            onChunk: onChunk
        )
    }

    // MARK: - Stubs for the remaining 4 insight types -----------------------
    //
    // The app spec mentions these by name in the InsightsView (5 tabs)
    // but doesn't specify the prompts in the same detail as the
    // individual one. Stubbed so the InsightsView can compile against
    // them today — fill in the prompt bodies as those views are built.

    static func generateSituationalAdvice(
        client: ClaudeClient,
        member: TeamMember?,
        situation: String,
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        // TODO: fill in prompt per spec when the Insights view lands.
        let system = "You are an EM coach. Give grounded, specific advice."
        let user = """
        Situation: \(situation)
        Member context: \(member?.name ?? "not member-specific")
        """
        return try await client.complete(
            system: system,
            messages: [ChatMessage(role: "user", content: user)],
            maxTokens: 800,
            onChunk: onChunk
        )
    }

    static func generateTeamInsight(
        client: ClaudeClient,
        members: [TeamMember],
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        // TODO
        let user = "Analyze this team:\n" +
            members.map { "- \($0.name) (\($0.seniority.rawValue))" }
                   .joined(separator: "\n")
        return try await client.complete(
            messages: [ChatMessage(role: "user", content: user)],
            onChunk: onChunk
        )
    }

    static func generateOneOnOnePrep(
        client: ClaudeClient,
        member: TeamMember,
        recentObservations: [Observation],
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        // TODO
        let user = "Prepare a 1:1 agenda for \(member.name)."
        return try await client.complete(
            messages: [ChatMessage(role: "user", content: user)],
            onChunk: onChunk
        )
    }

    static func generatePerformanceReview(
        client: ClaudeClient,
        member: TeamMember,
        observations: [Observation],
        idps: [DevelopmentPlan],
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        // TODO
        let user = "Draft a performance review for \(member.name)."
        return try await client.complete(
            messages: [ChatMessage(role: "user", content: user)],
            onChunk: onChunk
        )
    }

    // MARK: - Helpers -------------------------------------------------------

    private static func formatTags(_ tags: [StrengthWeakness]) -> String {
        guard !tags.isEmpty else { return "(none)" }
        return tags
            .sorted { $0.createdAt < $1.createdAt }
            .map { tag in
                let note = (tag.note?.isEmpty == false) ? " — \(tag.note!)" : ""
                return "- \(tag.category) (\(tag.intensity.rawValue))\(note)"
            }
            .joined(separator: "\n")
    }
}
