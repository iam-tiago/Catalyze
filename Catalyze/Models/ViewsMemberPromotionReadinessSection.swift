//
//  PromotionReadinessSection.swift
//  Catalyze
//
//  Promotion readiness section for the member detail page. Shows current
//  promotion target, criteria checklist with met/not-met status, AI-generated
//  assessment, and notes.
//
//  Equivalent to `src/components/TeamMembers/PromotionReadinessSection.tsx`
//  in the web app.
//

import SwiftUI
import SwiftData

struct PromotionReadinessSection: View {
    @Environment(\.modelContext) private var context

    let member: TeamMember

    @State private var showingPromotionForm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label("Promotion Readiness", systemImage: "arrow.up.circle.fill")
                    .font(.headline)

                Spacer()

                if promotionRecord != nil {
                    Button {
                        showingPromotionForm = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        showingPromotionForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Content
            if let record = promotionRecord {
                PromotionRecordView(record: record)
            } else {
                EmptyPromotionView(onStart: { showingPromotionForm = true })
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingPromotionForm) {
            PromotionReadinessForm(member: member, recordToEdit: promotionRecord)
        }
    }

    private var promotionRecord: PromotionReadiness? {
        // Return the most recent promotion record
        member.promotionRecords?
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
}

// MARK: - Promotion Record View ----------------------------------------------

private struct PromotionRecordView: View {
    let record: PromotionReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Target tier + status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target: \(record.targetTier.label)")
                        .font(.subheadline.weight(.semibold))

                    Text("Status: \(record.status.rawValue)")
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

                Spacer()

                // Status badge
                Text(record.status.rawValue)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor)
            }

            // Criteria checklist
            if !record.sortedCriteria.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Criteria (\(metCount)/\(totalCount) met)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    VStack(spacing: 6) {
                        ForEach(record.sortedCriteria.prefix(5)) { criterion in
                            CriterionRow(criterion: criterion)
                        }

                        if record.sortedCriteria.count > 5 {
                            Text("+ \(record.sortedCriteria.count - 5) more")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            // AI Assessment snippet
            if let assessment = record.aiAssessment, !assessment.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label("AI Assessment", systemImage: "brain.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(assessment)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
            }

            // Notes
            if let notes = record.notes, !notes.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
            }
        }
    }

    private var statusColor: Color {
        switch record.status {
        case .notReady:   return .red
        case .inProgress: return .orange
        case .ready:      return .green
        }
    }

    private var totalCount: Int {
        record.sortedCriteria.count
    }

    private var metCount: Int {
        record.sortedCriteria.filter { $0.met }.count
    }
}

// MARK: - Criterion Row ------------------------------------------------------

private struct CriterionRow: View {
    let criterion: PromotionCriterion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: criterion.met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(criterion.met ? .green : .secondary)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(criterion.label)
                    .font(.caption)
                    .foregroundStyle(.primary)

                if !criterion.category.isEmpty {
                    Text(criterion.category)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Empty Promotion View -----------------------------------------------

private struct EmptyPromotionView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.circle")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)

            Text("Not tracking promotion yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                onStart()
            } label: {
                Label("Start Tracking", systemImage: "plus.circle.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
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
        aiAssessment: "Alice demonstrates strong technical leadership and has been mentoring junior engineers effectively. Consider focusing on system design skills for the next level.",
        notes: "Target Q3 2026 for promotion review."
    )
    record.member = member

    let criterion1 = PromotionCriterion(
        category: "Technical",
        label: "Demonstrates expertise in iOS architecture",
        met: true,
        sortIndex: 0
    )
    criterion1.record = record

    let criterion2 = PromotionCriterion(
        category: "Leadership",
        label: "Mentors junior team members",
        met: true,
        sortIndex: 1
    )
    criterion2.record = record

    let criterion3 = PromotionCriterion(
        category: "Impact",
        label: "Leads critical projects end-to-end",
        met: false,
        sortIndex: 2
    )
    criterion3.record = record

    record.criteria = [criterion1, criterion2, criterion3]
    member.promotionRecords = [record]

    context.insert(member)
    try? context.save()

    return ScrollView {
        PromotionReadinessSection(member: member)
            .padding()
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Bob Silva",
        role: "Backend Engineer",
        seniority: .t2_2
    )

    context.insert(member)
    try? context.save()

    return ScrollView {
        PromotionReadinessSection(member: member)
            .padding()
    }
    .modelContainer(container)
}
