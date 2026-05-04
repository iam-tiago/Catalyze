//
//  InsightsView.swift
//  Catalyze
//
//  AI Insights view with 5 tabs. Each tab has input controls (member picker,
//  situation textarea, etc.) and an output area that shows the streaming
//  response from Claude. Completed insights are saved to the database.
//
//  Equivalent to `src/components/Insights/InsightsView.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @State private var selectedTab: InsightType = .individual

    var body: some View {
        Group {
            switch selectedTab {
            case .individual:
                IndividualInsightTab()
            case .situational:
                SituationalAdviceTab()
            case .team:
                TeamInsightTab()
            case .oneOnOnePrep:
                OneOnOnePrepTab()
            case .perfReview:
                PerformanceReviewTab()
            }
        }
        .navigationTitle("AI Insights")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Insight Type", selection: $selectedTab) {
                    Text("Individual").tag(InsightType.individual)
                    Text("Situational").tag(InsightType.situational)
                    Text("Team").tag(InsightType.team)
                    Text("1:1 Prep").tag(InsightType.oneOnOnePrep)
                    Text("Review").tag(InsightType.perfReview)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 600)
            }
        }
    }
}

// MARK: - Individual Insight Tab ---------------------------------------------

private struct IndividualInsightTab: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: \TeamMember.name) private var members: [TeamMember]

    @State private var selectedMemberId: String? = nil
    @State private var streamingText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil

    var body: some View {
        CatalystInsightLayout(
            inputTitle: "Generate Insight",
            streamingText: streamingText,
            isGenerating: isGenerating,
            errorMessage: errorMessage
        ) {
            if members.isEmpty {
                CatalystEmptyState(
                    icon: "person.3.slash",
                    title: "No team members yet",
                    message: "Add members in the Team tab to generate insights."
                )
            } else {
                VStack(spacing: CatalystSpacing.lg) {
                    // Member picker
                    VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                        CatalystFieldLabel("Team Member")
                        
                        Picker("Select Member", selection: $selectedMemberId) {
                            Text("Choose a member...").tag(nil as String?)

                            ForEach(members) { member in
                                Text(member.name).tag(member.id as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Generate button
                    CatalystPrimaryButton(
                        "Generate AI Insight",
                        icon: "sparkles",
                        isLoading: isGenerating,
                        isEnabled: selectedMemberId != nil
                    ) {
                        Task { await generate() }
                    }
                }
            }
        }
    }

    private func generate() async {
        guard let memberId = selectedMemberId,
              let member = members.first(where: { $0.id == memberId })
        else { return }

        errorMessage = nil
        streamingText = ""
        isGenerating = true

        let client = ClaudeClient(apiKey: store.apiKey, baseURL: store.baseURL)
        let observations = member.observations ?? []

        do {
            let finalText = try await ClaudePrompts.generateIndividualInsight(
                client: client,
                member: member,
                observations: observations
            ) { accumulated in
                Task { @MainActor in
                    streamingText = accumulated
                }
            }

            // Save completed insight
            let insight = Insight(
                type: .individual,
                memberId: member.id,
                prompt: "Individual insight for \(member.name)",
                response: finalText
            )
            context.insert(insight)
            try? context.save()

            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }
}

// MARK: - Situational Advice Tab ---------------------------------------------

private struct SituationalAdviceTab: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: \TeamMember.name) private var members: [TeamMember]

    @State private var selectedMemberId: String? = nil
    @State private var situation = ""
    @State private var streamingText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil

    var body: some View {
        CatalystSimpleInsightLayout(
            inputTitle: "Situational Advice",
            inputIcon: "lightbulb.fill",
            streamingText: streamingText,
            isGenerating: isGenerating,
            errorMessage: errorMessage
        ) {
            VStack(spacing: CatalystSpacing.lg) {
                // Description
                Text("Describe a situation and optionally link it to a team member.")
                    .font(CatalystTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Situation text editor
                VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                    CatalystFieldLabel("Situation")
                    
                    TextEditor(text: $situation)
                        .frame(minHeight: 100)
                        .padding(CatalystSpacing.sm)
                        .background(
                            .quaternary.opacity(CatalystOpacity.strong),
                            in: RoundedRectangle(cornerRadius: CatalystRadius.sm)
                        )
                }

                // Related member picker
                VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                    CatalystFieldLabel("Related Member (Optional)")
                    
                    Picker("Related Member", selection: $selectedMemberId) {
                        Text("None").tag(nil as String?)

                        ForEach(members) { member in
                            Text(member.name).tag(member.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Generate button
                CatalystPrimaryButton(
                    "Get Advice",
                    icon: "brain.fill",
                    isLoading: isGenerating,
                    isEnabled: !situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    Task { await generate() }
                }
            }
        }
    }

    private func generate() async {
        let trimmedSituation = situation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSituation.isEmpty else { return }

        errorMessage = nil
        streamingText = ""
        isGenerating = true

        let client = ClaudeClient(apiKey: store.apiKey, baseURL: store.baseURL)
        let member = selectedMemberId.flatMap { id in
            members.first { $0.id == id }
        }

        do {
            let finalText = try await ClaudePrompts.generateSituationalAdvice(
                client: client,
                member: member,
                situation: trimmedSituation
            ) { accumulated in
                Task { @MainActor in
                    streamingText = accumulated
                }
            }

            // Save completed insight
            let insight = Insight(
                type: .situational,
                memberId: member?.id,
                prompt: trimmedSituation,
                response: finalText
            )
            context.insert(insight)
            try? context.save()

            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }
}

// MARK: - Team Insight Tab ---------------------------------------------------

private struct TeamInsightTab: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: \TeamMember.name) private var members: [TeamMember]

    @State private var streamingText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil

    var body: some View {
        CatalystSimpleInsightLayout(
            inputTitle: "Team Analysis",
            inputIcon: "person.3.fill",
            streamingText: streamingText,
            isGenerating: isGenerating,
            errorMessage: errorMessage
        ) {
            VStack(spacing: CatalystSpacing.lg) {
                // Description
                Text("Analyze patterns, strengths, and gaps across your entire team.")
                    .font(CatalystTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if members.isEmpty {
                    CatalystEmptyState(
                        icon: "person.3.slash",
                        title: "No team members yet",
                        message: "Add members in the Team tab to generate team insights."
                    )
                } else {
                    // Team info card
                    HStack {
                        VStack(alignment: .leading, spacing: CatalystSpacing.xs) {
                            Text("Team size: \(members.count)")
                                .font(CatalystTypography.subheadline)
                            Text("Will analyze all members")
                                .font(CatalystTypography.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(CatalystSpacing.lg)
                    .background(
                        .quaternary.opacity(CatalystOpacity.strong),
                        in: RoundedRectangle(cornerRadius: CatalystRadius.sm)
                    )

                    // Generate button
                    CatalystPrimaryButton(
                        "Analyze Team",
                        icon: "brain.fill",
                        isLoading: isGenerating
                    ) {
                        Task { await generate() }
                    }
                }
            }
        }
    }

    private func generate() async {
        guard !members.isEmpty else { return }

        errorMessage = nil
        streamingText = ""
        isGenerating = true

        let client = ClaudeClient(apiKey: store.apiKey, baseURL: store.baseURL)

        do {
            let finalText = try await ClaudePrompts.generateTeamInsight(
                client: client,
                members: Array(members)
            ) { accumulated in
                Task { @MainActor in
                    streamingText = accumulated
                }
            }

            // Save completed insight
            let insight = Insight(
                type: .team,
                memberId: nil,
                prompt: "Team analysis for \(members.count) members",
                response: finalText
            )
            context.insert(insight)
            try? context.save()

            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }
}

// MARK: - 1:1 Prep Tab -------------------------------------------------------

private struct OneOnOnePrepTab: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: \TeamMember.name) private var members: [TeamMember]

    @State private var selectedMemberId: String? = nil
    @State private var streamingText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil

    var body: some View {
        CatalystSimpleInsightLayout(
            inputTitle: "1:1 Preparation",
            inputIcon: "person.2.fill",
            streamingText: streamingText,
            isGenerating: isGenerating,
            errorMessage: errorMessage
        ) {
            VStack(spacing: CatalystSpacing.lg) {
                // Description
                Text("Prepare talking points and agenda for an upcoming one-on-one.")
                    .font(CatalystTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if members.isEmpty {
                    CatalystEmptyState(
                        icon: "person.2.slash",
                        title: "No team members yet",
                        message: "Add members in the Team tab to prepare for 1:1 meetings."
                    )
                } else {
                    VStack(spacing: CatalystSpacing.lg) {
                        // Member picker
                        VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                            CatalystFieldLabel("Team Member")
                            
                            Picker("Select Member", selection: $selectedMemberId) {
                                Text("Choose a member...").tag(nil as String?)

                                ForEach(members) { member in
                                    Text(member.name).tag(member.id as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Generate button
                        CatalystPrimaryButton(
                            "Prepare 1:1",
                            icon: "brain.fill",
                            isLoading: isGenerating,
                            isEnabled: selectedMemberId != nil
                        ) {
                            Task { await generate() }
                        }
                    }
                }
            }
        }
    }

    private func generate() async {
        guard let memberId = selectedMemberId,
              let member = members.first(where: { $0.id == memberId })
        else { return }

        errorMessage = nil
        streamingText = ""
        isGenerating = true

        let client = ClaudeClient(apiKey: store.apiKey, baseURL: store.baseURL)
        let observations = member.observations ?? []

        do {
            let finalText = try await ClaudePrompts.generateOneOnOnePrep(
                client: client,
                member: member,
                recentObservations: observations
            ) { accumulated in
                Task { @MainActor in
                    streamingText = accumulated
                }
            }

            // Save completed insight
            let insight = Insight(
                type: .oneOnOnePrep,
                memberId: member.id,
                prompt: "1:1 prep for \(member.name)",
                response: finalText
            )
            context.insert(insight)
            try? context.save()

            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }
}

// MARK: - Performance Review Tab ---------------------------------------------

private struct PerformanceReviewTab: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: \TeamMember.name) private var members: [TeamMember]

    @State private var selectedMemberId: String? = nil
    @State private var streamingText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil

    var body: some View {
        CatalystSimpleInsightLayout(
            inputTitle: "Performance Review",
            inputIcon: "doc.text.fill",
            streamingText: streamingText,
            isGenerating: isGenerating,
            errorMessage: errorMessage
        ) {
            VStack(spacing: CatalystSpacing.lg) {
                // Description
                Text("Generate a performance review draft based on observations and development activity.")
                    .font(CatalystTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if members.isEmpty {
                    CatalystEmptyState(
                        icon: "doc.text.slash",
                        title: "No team members yet",
                        message: "Add members in the Team tab to generate performance reviews."
                    )
                } else {
                    VStack(spacing: CatalystSpacing.lg) {
                        // Member picker
                        VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                            CatalystFieldLabel("Team Member")
                            
                            Picker("Select Member", selection: $selectedMemberId) {
                                Text("Choose a member...").tag(nil as String?)

                                ForEach(members) { member in
                                    Text(member.name).tag(member.id as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Generate button
                        CatalystPrimaryButton(
                            "Generate Review",
                            icon: "brain.fill",
                            isLoading: isGenerating,
                            isEnabled: selectedMemberId != nil
                        ) {
                            Task { await generate() }
                        }
                    }
                }
            }
        }
    }

    private func generate() async {
        guard let memberId = selectedMemberId,
              let member = members.first(where: { $0.id == memberId })
        else { return }

        errorMessage = nil
        streamingText = ""
        isGenerating = true

        let client = ClaudeClient(apiKey: store.apiKey, baseURL: store.baseURL)
        let observations = member.observations ?? []
        let idps = member.idps ?? []

        do {
            let finalText = try await ClaudePrompts.generatePerformanceReview(
                client: client,
                member: member,
                observations: observations,
                idps: idps
            ) { accumulated in
                Task { @MainActor in
                    streamingText = accumulated
                }
            }

            // Save completed insight
            let insight = Insight(
                type: .perfReview,
                memberId: member.id,
                prompt: "Performance review for \(member.name)",
                response: finalText
            )
            context.insert(insight)
            try? context.save()

            isGenerating = false
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    NavigationStack {
        InsightsView()
            .environment(AppStore())
            .modelContainer(try! PersistenceController.makePreviewContainer())
    }
}
