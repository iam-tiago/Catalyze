//
//  PromotionReadinessForm.swift
//  Catalyze
//
//  Form for creating or editing a promotion readiness record. Includes
//  target tier, status, criteria checklist (with add/remove), AI assessment
//  generation, and notes.
//
//  Equivalent to promotion form functionality in the web app.
//

import SwiftUI
import SwiftData

struct PromotionReadinessForm: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.seniorityService) private var seniorityService

    let member: TeamMember
    let recordToEdit: PromotionReadiness?

    @State private var targetTier: Seniority = .t2_2
    @State private var selectedTargetCode: String = ""
    @State private var status: PromotionStatus = .notReady
    @State private var criteria: [CriterionFormData] = []
    @State private var aiAssessment = ""
    @State private var notes = ""
    @State private var isGeneratingAssessment = false
    @State private var assessmentError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                // Current level display
                Section("Current Level") {
                    HStack {
                        Text(member.name)
                            .font(CFont.headline)
                        Spacer()
                        if let service = seniorityService,
                           let currentLevel = service.level(byCode: member.seniority.rawValue) {
                            TierBadge(level: currentLevel)
                        } else {
                            TierBadge(tier: member.seniority.rawValue)
                        }
                    }
                    
                    if let service = seniorityService,
                       let currentLevel = service.level(byCode: member.seniority.rawValue) {
                        Text(currentLevel.displayName)
                            .font(CFont.subheadline)
                            .foregroundStyle(CColor.neutral600)
                    }
                }
                
                // Target tier section with suggestions
                Section {
                    // ✅ UPDATED: Picker with custom levels
                    if let service = seniorityService {
                        let higherLevels = service.higherLevels(than: member.seniority.rawValue)
                        
                        if !higherLevels.isEmpty {
                            Picker("Target Level", selection: $selectedTargetCode) {
                                ForEach(higherLevels, id: \.code) { level in
                                    HStack {
                                        Circle()
                                            .fill(level.color)
                                            .frame(width: 8, height: 8)
                                        Text(level.displayName)
                                    }
                                    .tag(level.code)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            // Show description of selected level
                            if let selectedLevel = service.level(byCode: selectedTargetCode),
                               let description = selectedLevel.levelDescription {
                                Text(description)
                                    .font(CFont.caption1)
                                    .foregroundStyle(CColor.neutral600)
                                    .padding(.top, CSpace.xs)
                            }
                            
                            // Suggested next level
                            if let nextLevel = service.nextLevel(after: member.seniority.rawValue),
                               nextLevel.code != selectedTargetCode {
                                HStack(spacing: CSpace.sm) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(CColor.growth)
                                        .font(.system(size: 12))
                                    Text("Suggested: \(nextLevel.displayName)")
                                        .font(CFont.caption1)
                                        .foregroundStyle(CColor.neutral700)
                                    Spacer()
                                    Button("Use") {
                                        selectedTargetCode = nextLevel.code
                                    }
                                    .font(CFont.caption2)
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.top, CSpace.xs)
                            }
                        } else {
                            Text("No higher levels available")
                                .foregroundStyle(CColor.neutral600)
                                .font(CFont.callout)
                        }
                    } else {
                        // Fallback to legacy enum
                        Picker("Target Tier", selection: $targetTier) {
                            ForEach(higherSeniorities, id: \.self) { tier in
                                Text(tier.label).tag(tier)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Target Promotion Level")
                } footer: {
                    Text("Select the level you're preparing this member for.")
                }

                // Status section
                Section("Status") {
                    Picker("Promotion Status", selection: $status) {
                        ForEach(PromotionStatus.allCases) { s in
                            HStack {
                                statusIcon(s)
                                Text(s.rawValue)
                            }
                            .tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Criteria section
                Section {
                    ForEach($criteria) { $criterion in
                        CriterionRow(
                            criterion: $criterion,
                            onDelete: { removeCriterion(criterion) }
                        )
                    }

                    Button {
                        addCriterion()
                    } label: {
                        Label("Add Criterion", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Criteria")
                        Spacer()
                        if !criteria.isEmpty {
                            Text("\(metCount)/\(criteria.count) met")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Define the criteria needed for this promotion. Tap the circle to mark as met.")
                }

                // AI Assessment section
                Section {
                    if aiAssessment.isEmpty {
                        Button {
                            Task { await generateAssessment() }
                        } label: {
                            if isGeneratingAssessment {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Generating...")
                                }
                            } else {
                                Label("Generate AI Assessment", systemImage: "brain.fill")
                            }
                        }
                        .disabled(isGeneratingAssessment)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(aiAssessment)
                                .font(.subheadline)

                            HStack {
                                Button {
                                    Task { await generateAssessment() }
                                } label: {
                                    Label("Regenerate", systemImage: "arrow.clockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(isGeneratingAssessment)

                                Button(role: .destructive) {
                                    aiAssessment = ""
                                } label: {
                                    Label("Clear", systemImage: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }

                    if let error = assessmentError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("AI Assessment")
                } footer: {
                    Text("Let AI analyze the member's readiness based on their profile and progress.")
                }

                // Notes section
                Section {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add any additional context or timeline information.")
                }
            }
            .navigationTitle(isEditing ? "Edit Promotion" : "Start Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Start") {
                        saveRecord()
                    }
                }

                // Delete button (only when editing)
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            deleteRecord()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }

    // MARK: - Helpers --------------------------------------------------------

    private var isEditing: Bool {
        recordToEdit != nil
    }

    private var higherSeniorities: [Seniority] {
        // Show only seniorities higher than the member's current level
        let currentIndex = Seniority.allCases.firstIndex(of: member.seniority) ?? 0
        return Array(Seniority.allCases.dropFirst(currentIndex + 1))
    }

    private var metCount: Int {
        criteria.filter { $0.met }.count
    }

    private func statusIcon(_ s: PromotionStatus) -> some View {
        let iconName: String
        switch s {
        case .notReady:   iconName = "xmark.circle.fill"
        case .inProgress: iconName = "clock.fill"
        case .ready:      iconName = "checkmark.circle.fill"
        }
        return Image(systemName: iconName)
            .foregroundStyle(.secondary)
    }

    private func loadInitialData() {
        guard let record = recordToEdit else {
            // New record — set default target to next level
            if let service = seniorityService {
                // Use custom levels
                if let nextLevel = service.nextLevel(after: member.seniority.rawValue) {
                    selectedTargetCode = nextLevel.code
                } else if let firstHigher = service.higherLevels(than: member.seniority.rawValue).first {
                    selectedTargetCode = firstHigher.code
                }
            } else {
                // Fallback to enum
                if let currentIndex = Seniority.allCases.firstIndex(of: member.seniority),
                   currentIndex + 1 < Seniority.allCases.count {
                    targetTier = Seniority.allCases[currentIndex + 1]
                    selectedTargetCode = targetTier.rawValue
                }
            }

            // Add default criteria
            criteria = [
                CriterionFormData(
                    category: "Technical",
                    label: "Demonstrates expertise in required technologies",
                    met: false
                ),
                CriterionFormData(
                    category: "Leadership",
                    label: "Mentors and supports team members",
                    met: false
                ),
                CriterionFormData(
                    category: "Impact",
                    label: "Delivers significant business value",
                    met: false
                )
            ]
            return
        }

        // Editing existing record
        targetTier = record.targetTier
        selectedTargetCode = record.targetTierRaw
        status = record.status
        aiAssessment = record.aiAssessment ?? ""
        notes = record.notes ?? ""

        criteria = record.sortedCriteria.map {
            CriterionFormData(
                category: $0.category,
                label: $0.label,
                met: $0.met,
                note: $0.note
            )
        }

        // If no criteria, add defaults
        if criteria.isEmpty {
            criteria = [
                CriterionFormData(
                    category: "Technical",
                    label: "Demonstrates expertise in required technologies",
                    met: false
                )
            ]
        }
    }

    private func addCriterion() {
        criteria.append(CriterionFormData(
            category: "",
            label: "",
            met: false
        ))
    }

    private func removeCriterion(_ criterion: CriterionFormData) {
        criteria.removeAll { $0.id == criterion.id }
    }

    private func generateAssessment() async {
        assessmentError = nil
        isGeneratingAssessment = true

        let client = ClaudeClient(apiKey: store.apiKey, baseURL: store.baseURL)

        // Build prompt
        let system = """
        You are an expert engineering management coach. Analyze this team member's
        promotion readiness and provide a brief, actionable assessment (max 200 words).
        """

        var prompt = """
        Assess promotion readiness for:
        
        **Member:** \(member.name)
        **Current Level:** \(member.seniority.rawValue)
        **Target Level:** \(targetTier.rawValue)
        
        **Strengths:**
        """

        for strength in member.strengths.prefix(5) {
            prompt += "\n- \(strength.category) (\(strength.intensity.rawValue))"
        }

        prompt += "\n\n**Growth Areas:**"
        for weakness in member.weaknesses.prefix(5) {
            prompt += "\n- \(weakness.category) (\(weakness.intensity.rawValue))"
        }

        prompt += "\n\n**Criteria Progress:** \(metCount)/\(criteria.count) met"

        prompt += """
        
        
        Provide:
        1. Overall readiness assessment
        2. Key strengths supporting promotion
        3. Gaps to address before promotion
        4. Recommended timeline
        """

        do {
            var accumulated = ""
            let finalText = try await client.complete(
                system: system,
                messages: [ChatMessage(role: "user", content: prompt)],
                maxTokens: 500
            ) { chunk in
                Task { @MainActor in
                    accumulated = chunk
                    aiAssessment = chunk
                }
            }

            aiAssessment = finalText
            isGeneratingAssessment = false
        } catch {
            assessmentError = error.localizedDescription
            isGeneratingAssessment = false
        }
    }

    private func saveRecord() {
        // Filter out empty criteria
        let validCriteria = criteria.filter {
            !$0.label.trimmingCharacters(in: .whitespaces).isEmpty
        }

        if let existing = recordToEdit {
            // Update existing
            // ✅ UPDATED: Use selectedTargetCode for custom levels
            existing.targetTierRaw = selectedTargetCode
            existing.status = status
            existing.aiAssessment = aiAssessment.isEmpty ? nil : aiAssessment
            existing.notes = notes.isEmpty ? nil : notes

            // Delete old criteria
            if let oldCriteria = existing.criteria {
                for c in oldCriteria {
                    context.delete(c)
                }
            }

            // Create new criteria
            let newCriteria = validCriteria.enumerated().map { index, formData in
                PromotionCriterion(
                    category: formData.category.trimmingCharacters(in: .whitespaces),
                    label: formData.label.trimmingCharacters(in: .whitespaces),
                    met: formData.met,
                    note: formData.note?.trimmingCharacters(in: .whitespaces),
                    sortIndex: index
                )
            }

            for c in newCriteria {
                c.record = existing
                context.insert(c)
            }

            existing.criteria = newCriteria

            store.updatePromotionReadiness(existing, in: context)
        } else {
            // Create new
            // ✅ UPDATED: Map selectedTargetCode to Seniority enum or use default
            let targetEnum = Seniority(rawValue: selectedTargetCode) ?? .t2_2
            
            let newRecord = PromotionReadiness(
                memberId: member.id,
                targetTier: targetEnum,
                status: status,
                aiAssessment: aiAssessment.isEmpty ? nil : aiAssessment,
                notes: notes.isEmpty ? nil : notes
            )
            
            // Override with custom code if different
            if selectedTargetCode != targetEnum.rawValue {
                newRecord.targetTierRaw = selectedTargetCode
            }

            newRecord.member = member

            let newCriteria = validCriteria.enumerated().map { index, formData in
                PromotionCriterion(
                    category: formData.category.trimmingCharacters(in: .whitespaces),
                    label: formData.label.trimmingCharacters(in: .whitespaces),
                    met: formData.met,
                    note: formData.note?.trimmingCharacters(in: .whitespaces),
                    sortIndex: index
                )
            }

            for c in newCriteria {
                c.record = newRecord
                context.insert(c)
            }

            newRecord.criteria = newCriteria

            // Add to member
            if member.promotionRecords == nil {
                member.promotionRecords = []
            }
            member.promotionRecords?.append(newRecord)

            store.addPromotionReadiness(newRecord, in: context)
        }

        dismiss()
    }

    private func deleteRecord() {
        guard let record = recordToEdit else { return }
        store.deletePromotionReadiness(record, in: context)
        dismiss()
    }
}

// MARK: - Criterion Row ------------------------------------------------------

private struct CriterionRow: View {
    @Binding var criterion: CriterionFormData
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Met checkbox
                Button {
                    criterion.met.toggle()
                } label: {
                    Image(systemName: criterion.met ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(criterion.met ? .green : .secondary)
                }
                .buttonStyle(.plain)

                // Label
                TextField("Criterion label", text: $criterion.label)
                    .textFieldStyle(.plain)

                // Expand/collapse
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                // Delete
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            // Expanded details
            if isExpanded {
                VStack(spacing: 8) {
                    TextField("Category (e.g., Technical, Leadership)", text: $criterion.category)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)

                    TextField("Optional note", text: Binding(
                        get: { criterion.note ?? "" },
                        set: { criterion.note = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Criterion Form Data ------------------------------------------------

private struct CriterionFormData: Identifiable {
    let id = UUID()
    var category: String
    var label: String
    var met: Bool
    var note: String?
}

// MARK: - Preview ------------------------------------------------------------

#Preview("New Promotion") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    let strength = StrengthWeakness(
        kind: .strength,
        category: "Code Quality",
        intensity: .strong
    )
    strength.member = member
    member.tags = [strength]

    context.insert(member)
    try? context.save()

    return PromotionReadinessForm(member: member, recordToEdit: nil)
        .environment(AppStore())
        .modelContainer(container)
}

#Preview("Edit Promotion") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    let record = PromotionReadiness(
        memberId: member.id,
        targetTier: .t3_2,
        status: .inProgress,
        aiAssessment: "Alice is making strong progress toward T3-2. Her technical skills are solid.",
        notes: "Target Q3 2026"
    )
    record.member = member

    let criterion = PromotionCriterion(
        category: "Technical",
        label: "Demonstrates expertise in iOS architecture",
        met: true,
        sortIndex: 0
    )
    criterion.record = record
    record.criteria = [criterion]

    member.promotionRecords = [record]

    context.insert(member)
    try? context.save()

    return PromotionReadinessForm(member: member, recordToEdit: record)
        .environment(AppStore())
        .modelContainer(container)
}
