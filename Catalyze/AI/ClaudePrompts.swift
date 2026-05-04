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
        observations: [TeamObservation],
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

    // MARK: - Situational advice -------------------------------------------

    /// Provide coaching advice for a specific situation, optionally
    /// contextualized with a team member's profile.
    static func generateSituationalAdvice(
        client: ClaudeClient,
        member: TeamMember?,
        situation: String,
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let system = """
        You are an expert engineering management coach. Provide specific,
        actionable advice for the situation described. If a team member is
        mentioned, tailor the advice to their profile. Hard limit: 300 words.
        """

        var prompt = """
        Situation:
        \(situation)
        """

        if let member = member {
            prompt += """
            
            
            Related team member:
            Name: \(member.name)
            Role: \(member.role)
            Seniority: \(member.seniority.rawValue)
            
            Strengths:
            \(formatTags(member.strengths))
            
            Growth areas:
            \(formatTags(member.weaknesses))
            """
        }

        prompt += """
        
        
        Provide:
        1. **Recommended approach** — how to handle this situation
        2. **Key considerations** — what to watch out for
        3. **Next steps** — concrete actions to take
        """

        return try await client.complete(
            system: system,
            messages: [ChatMessage(role: "user", content: prompt)],
            maxTokens: 800,
            onChunk: onChunk
        )
    }

    // MARK: - Team insight --------------------------------------------------

    /// Analyze the entire team for patterns, health signals, and
    /// recommendations.
    static func generateTeamInsight(
        client: ClaudeClient,
        members: [TeamMember],
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let system = """
        You are an expert engineering management coach analyzing an entire
        team. Identify patterns, health signals, and provide strategic
        recommendations. Hard limit: 400 words.
        """

        var prompt = """
        Analyze this team and provide insights:
        
        ## Team Composition
        Total members: \(members.count)
        """

        // Seniority distribution
        let seniorityGroups = Dictionary(grouping: members) { $0.seniority }
        for (seniority, memberList) in seniorityGroups.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            prompt += "\n- \(seniority.rawValue): \(memberList.count)"
        }

        // Top team strengths (most common strength categories)
        let allStrengths = members.flatMap { $0.strengths }
        let strengthCounts = Dictionary(grouping: allStrengths) { $0.category }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)

        prompt += "\n\n## Common Team Strengths"
        for (category, count) in strengthCounts {
            prompt += "\n- \(category) (\(count) members)"
        }

        // Top team growth areas
        let allWeaknesses = members.flatMap { $0.weaknesses }
        let weaknessCounts = Dictionary(grouping: allWeaknesses) { $0.category }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)

        prompt += "\n\n## Common Growth Areas"
        for (category, count) in weaknessCounts {
            prompt += "\n- \(category) (\(count) members)"
        }

        // IDP stats
        let activeIDPs = members.flatMap { $0.idps ?? [] }
            .filter { $0.status == .active }

        prompt += """
        
        
        ## Development Activity
        - Active IDPs: \(activeIDPs.count)
        - Members with active plans: \(members.filter { !($0.idps ?? []).filter { $0.status == .active }.isEmpty }.count)
        
        Provide:
        1. **Team health assessment** — overall strengths and risks
        2. **Capability gaps** — what skills/areas need attention
        3. **Recommended actions** — strategic next steps for the EM
        """

        return try await client.complete(
            system: system,
            messages: [ChatMessage(role: "user", content: prompt)],
            maxTokens: 1000,
            onChunk: onChunk
        )
    }

    // MARK: - 1:1 prep ------------------------------------------------------

    /// Prepare talking points and agenda items for an upcoming one-on-one
    /// with a specific team member.
    static func generateOneOnOnePrep(
        client: ClaudeClient,
        member: TeamMember,
        recentObservations: [TeamObservation],
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let system = """
        You are an expert engineering management coach helping prepare for
        a one-on-one meeting. Suggest agenda items, talking points, and
        questions to ask. Hard limit: 300 words.
        """

        let recent = recentObservations
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)

        let activeIDPs = (member.idps ?? []).filter { $0.status == .active }

        var prompt = """
        Prepare a 1:1 agenda for:
        
        **Member:** \(member.name)
        **Role:** \(member.role)
        **Seniority:** \(member.seniority.rawValue)
        
        **Recent observations (\(recent.count)):**
        """

        for obs in recent {
            prompt += "\n- [\(obs.context.rawValue)] \(obs.text)"
        }

        prompt += "\n\n**Active development plans:** \(activeIDPs.count)"

        for idp in activeIDPs.prefix(3) {
            let progress = "\(idp.sortedActions.filter { $0.done }.count)/\(idp.sortedActions.count)"
            prompt += "\n- \(idp.title) (progress: \(progress))"
        }

        prompt += """
        
        
        **Strengths:**
        \(formatTags(member.strengths))
        
        **Growth areas:**
        \(formatTags(member.weaknesses))
        
        Provide:
        1. **Key topics** — what to discuss based on recent activity
        2. **Questions to ask** — open-ended questions for the member
        3. **Follow-ups** — items to check on from previous 1:1s
        """

        return try await client.complete(
            system: system,
            messages: [ChatMessage(role: "user", content: prompt)],
            maxTokens: 800,
            onChunk: onChunk
        )
    }

    // MARK: - Performance review --------------------------------------------

    /// Generate a performance review draft based on observations, IDPs,
    /// and the member's profile.
    static func generatePerformanceReview(
        client: ClaudeClient,
        member: TeamMember,
        observations: [TeamObservation],
        idps: [DevelopmentPlan],
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let system = """
        You are an expert engineering management coach helping draft a
        performance review. Be specific, balanced, and actionable. Include
        both accomplishments and growth opportunities. Hard limit: 500 words.
        """

        let recentObs = observations
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(15)

        let completedIDPs = idps.filter { $0.status == .completed }
        let activeIDPs = idps.filter { $0.status == .active }

        var prompt = """
        Draft a performance review for:
        
        **Member:** \(member.name)
        **Role:** \(member.role)
        **Seniority:** \(member.seniority.rawValue)
        
        **Strengths:**
        \(formatTags(member.strengths))
        
        **Growth areas:**
        \(formatTags(member.weaknesses))
        
        **Recent observations (\(recentObs.count)):**
        """

        for obs in recentObs {
            prompt += "\n- [\(obs.context.rawValue)] \(obs.text)"
        }

        prompt += "\n\n**Development activity:**"
        prompt += "\n- Completed plans: \(completedIDPs.count)"
        prompt += "\n- Active plans: \(activeIDPs.count)"

        for idp in completedIDPs.prefix(3) {
            prompt += "\n  - ✓ \(idp.title)"
        }

        for idp in activeIDPs.prefix(3) {
            let progress = "\(idp.sortedActions.filter { $0.done }.count)/\(idp.sortedActions.count)"
            prompt += "\n  - → \(idp.title) (\(progress))"
        }

        prompt += """
        
        
        Provide a structured review with:
        1. **Summary** — overall performance this period
        2. **Key accomplishments** — specific wins and impact (3-4 bullets)
        3. **Areas for growth** — constructive feedback (2-3 bullets)
        4. **Goals for next period** — what to focus on next
        """

        return try await client.complete(
            system: system,
            messages: [ChatMessage(role: "user", content: prompt)],
            maxTokens: 1200,
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
