//
//  IDPSection.swift
//  Catalyze
//
//  Individual Development Plans section for the member detail page. Shows
//  a list of IDPs grouped by status, with progress indicators and actions.
//
//  Equivalent to `src/components/TeamMembers/IDPSection.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct IDPSection: View {
    let member: TeamMember

    @State private var showingAddIDP = false
    @State private var idpToEdit: DevelopmentPlan? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label("Development Plans", systemImage: "list.bullet.clipboard")
                    .font(.headline)

                Spacer()

                Button {
                    showingAddIDP = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // IDPs grouped by status
            if allIDPs.isEmpty {
                Text("No development plans yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Active IDPs
                    if !activeIDPs.isEmpty {
                        IDPStatusGroup(
                            title: "Active",
                            icon: "play.circle.fill",
                            color: .blue,
                            idps: activeIDPs,
                            onTap: { idpToEdit = $0 }
                        )
                    }

                    // On Hold IDPs
                    if !onHoldIDPs.isEmpty {
                        IDPStatusGroup(
                            title: "On Hold",
                            icon: "pause.circle.fill",
                            color: .orange,
                            idps: onHoldIDPs,
                            onTap: { idpToEdit = $0 }
                        )
                    }

                    // Completed IDPs
                    if !completedIDPs.isEmpty {
                        IDPStatusGroup(
                            title: "Completed",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            idps: completedIDPs,
                            onTap: { idpToEdit = $0 }
                        )
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingAddIDP) {
            IDPForm(member: member, idpToEdit: nil)
        }
        .sheet(item: $idpToEdit) { idp in
            IDPForm(member: member, idpToEdit: idp)
        }
    }

    private var allIDPs: [DevelopmentPlan] {
        member.idps ?? []
    }

    private var activeIDPs: [DevelopmentPlan] {
        allIDPs.filter { $0.status == .active }
    }

    private var onHoldIDPs: [DevelopmentPlan] {
        allIDPs.filter { $0.status == .onHold }
    }

    private var completedIDPs: [DevelopmentPlan] {
        allIDPs.filter { $0.status == .completed }
    }
}

// MARK: - IDP Status Group ---------------------------------------------------

private struct IDPStatusGroup: View {
    let title: String
    let icon: String
    let color: Color
    let idps: [DevelopmentPlan]
    let onTap: (DevelopmentPlan) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Group header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text("(\(idps.count))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // IDPs
            VStack(spacing: 8) {
                ForEach(idps) { idp in
                    IDPCard(idp: idp)
                        .onTapGesture {
                            onTap(idp)
                        }
                }
            }
        }
    }
}

// MARK: - IDP Card -----------------------------------------------------------

private struct IDPCard: View {
    let idp: DevelopmentPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title + progress
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(idp.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    if let targetDate = idp.targetDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(targetDate, style: .date)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Progress indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)

                    ProgressView(value: progress)
                        .frame(width: 50)
                }
            }

            // Objective (truncated)
            if !idp.objective.isEmpty {
                Text(idp.objective)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }

    private var totalCount: Int {
        idp.sortedActions.count
    }

    private var completedCount: Int {
        idp.sortedActions.filter { $0.done }.count
    }

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
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

    // Active IDP
    let idp1 = DevelopmentPlan(
        memberId: member.id,
        title: "iOS Architecture Mastery",
        objective: "Become proficient in designing scalable iOS architectures (MVVM, Coordinator pattern, Clean Architecture).",
        targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
        status: .active
    )
    idp1.member = member

    let action1 = IDPAction(text: "Read 'Advanced iOS App Architecture' book", done: true, sortIndex: 0)
    action1.plan = idp1
    let action2 = IDPAction(text: "Implement Coordinator pattern in one feature", done: false, sortIndex: 1)
    action2.plan = idp1
    let action3 = IDPAction(text: "Present architecture findings to team", done: false, sortIndex: 2)
    action3.plan = idp1

    idp1.actions = [action1, action2, action3]

    // Completed IDP
    let idp2 = DevelopmentPlan(
        memberId: member.id,
        title: "SwiftUI Fundamentals",
        objective: "Learn SwiftUI basics and build sample projects.",
        status: .completed
    )
    idp2.member = member

    let action4 = IDPAction(text: "Complete Stanford CS193p course", done: true, sortIndex: 0)
    action4.plan = idp2
    let action5 = IDPAction(text: "Build personal SwiftUI app", done: true, sortIndex: 1)
    action5.plan = idp2

    idp2.actions = [action4, action5]

    member.idps = [idp1, idp2]

    context.insert(member)
    try? context.save()

    return ScrollView {
        IDPSection(member: member)
            .padding()
    }
    .modelContainer(container)
}
