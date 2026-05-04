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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Input section - larger card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Generate Insight", systemImage: "brain.fill")
                                .font(.title2.bold())
                            Spacer()
                        }
                        
                        Divider()

                        if members.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.3.slash")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No team members yet")
                                    .font(.headline)
                                Text("Add members in the Team tab to generate insights.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            VStack(spacing: 16) {
                                // Member picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Team Member")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    
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
                                Button {
                                    Task { await generate() }
                                } label: {
                                    if isGenerating {
                                        HStack {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("Generating Insight...")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                    } else {
                                        Label("Generate AI Insight", systemImage: "sparkles")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .disabled(selectedMemberId == nil || isGenerating)
                            }
                        }

                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.callout)
                                    .foregroundStyle(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Output section
                    if !streamingText.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("AI Response", systemImage: "sparkles")
                                    .font(.title2.bold())

                                Spacer()

                                if isGenerating {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text("Streaming...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            Divider()

                            Text(streamingText)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(24)
                .frame(minWidth: geometry.size.width)
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
        ScrollView {
            VStack(spacing: 24) {
                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Situational Advice")
                        .font(.headline)

                    Text("Describe a situation and optionally link it to a team member.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $situation)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))

                    Picker("Related Member (Optional)", selection: $selectedMemberId) {
                        Text("None").tag(nil as String?)

                        ForEach(members) { member in
                            Text(member.name).tag(member.id as String?)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        Task { await generate() }
                    } label: {
                        if isGenerating {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Generating...")
                            }
                        } else {
                            Label("Get Advice", systemImage: "brain.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Output section
                if !streamingText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Response", systemImage: "sparkles")
                                .font(.headline)

                            Spacer()

                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        Divider()

                        Text(streamingText)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
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
        ScrollView {
            VStack(spacing: 24) {
                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Team Analysis")
                        .font(.headline)

                    Text("Analyze patterns, strengths, and gaps across your entire team.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if members.isEmpty {
                        Text("No team members yet. Add members in the Team tab.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Team size: \(members.count)")
                                    .font(.subheadline)
                                Text("Will analyze all members")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))

                        Button {
                            Task { await generate() }
                        } label: {
                            if isGenerating {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Analyzing...")
                                }
                            } else {
                                Label("Analyze Team", systemImage: "brain.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isGenerating)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Output section
                if !streamingText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Response", systemImage: "sparkles")
                                .font(.headline)

                            Spacer()

                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        Divider()

                        Text(streamingText)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
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
        ScrollView {
            VStack(spacing: 24) {
                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("1:1 Preparation")
                        .font(.headline)

                    Text("Prepare talking points and agenda for an upcoming one-on-one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if members.isEmpty {
                        Text("No team members yet. Add members in the Team tab.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        Picker("Select Member", selection: $selectedMemberId) {
                            Text("Choose a member...").tag(nil as String?)

                            ForEach(members) { member in
                                Text(member.name).tag(member.id as String?)
                            }
                        }
                        .pickerStyle(.menu)

                        Button {
                            Task { await generate() }
                        } label: {
                            if isGenerating {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Preparing...")
                                }
                            } else {
                                Label("Prepare 1:1", systemImage: "brain.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedMemberId == nil || isGenerating)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Output section
                if !streamingText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Response", systemImage: "sparkles")
                                .font(.headline)

                            Spacer()

                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        Divider()

                        Text(streamingText)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
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
        ScrollView {
            VStack(spacing: 24) {
                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Review")
                        .font(.headline)

                    Text("Generate a performance review draft based on observations and development activity.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if members.isEmpty {
                        Text("No team members yet. Add members in the Team tab.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        Picker("Select Member", selection: $selectedMemberId) {
                            Text("Choose a member...").tag(nil as String?)

                            ForEach(members) { member in
                                Text(member.name).tag(member.id as String?)
                            }
                        }
                        .pickerStyle(.menu)

                        Button {
                            Task { await generate() }
                        } label: {
                            if isGenerating {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Generating...")
                                }
                            } else {
                                Label("Generate Review", systemImage: "brain.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedMemberId == nil || isGenerating)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Output section
                if !streamingText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Response", systemImage: "sparkles")
                                .font(.headline)

                            Spacer()

                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        Divider()

                        Text(streamingText)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
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
