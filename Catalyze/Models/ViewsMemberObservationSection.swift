//
//  ObservationSection.swift
//  Catalyze
//
//  Observations section for the member detail page. Shows a list of
//  observations sorted by date, grouped by month or context. Swipe-to-delete
//  and "+" button to add new observations.
//
//  Equivalent to `src/components/TeamMembers/ObservationSection.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct ObservationSection: View {
    @Environment(\.modelContext) private var context

    let member: TeamMember

    @State private var showingAddObservation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label("Observations", systemImage: "note.text")
                    .font(.headline)

                Spacer()

                Button {
                    showingAddObservation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Observations list
            if sortedObservations.isEmpty {
                Text("No observations yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedObservations) { observation in
                        ObservationRow(observation: observation)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteObservation(observation)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingAddObservation) {
            ObservationForm(member: member, observationToEdit: nil)
        }
    }

    private var sortedObservations: [TeamObservation] {
        (member.observations ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    private func deleteObservation(_ observation: TeamObservation) {
        context.delete(observation)
        try? context.save()
    }
}

// MARK: - Observation Row ----------------------------------------------------

private struct ObservationRow: View {
    let observation: TeamObservation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: context badge + date
            HStack {
                // Context badge
                Text(observation.context.rawValue)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(contextColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(contextColor)

                Spacer()

                // Date
                Text(observation.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Observation text
            Text(observation.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }

    private var contextColor: Color {
        switch observation.context {
        case .oneOnOne:         return .blue
        case .incident:         return .red
        case .sprintReview:     return .green
        case .performanceCycle: return .purple
        case .other:            return .gray
        }
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

    let obs1 = TeamObservation(
        memberId: member.id,
        text: "Led the refactoring of the authentication module with excellent documentation and team communication.",
        context: .sprintReview,
        createdAt: Date().addingTimeInterval(-86400 * 7) // 1 week ago
    )
    obs1.member = member

    let obs2 = TeamObservation(
        memberId: member.id,
        text: "Handled production incident calmly and methodically. Post-mortem was thorough.",
        context: .incident,
        createdAt: Date().addingTimeInterval(-86400 * 14) // 2 weeks ago
    )
    obs2.member = member

    let obs3 = TeamObservation(
        memberId: member.id,
        text: "Expressed interest in learning more about system design. Considering pairing with senior architect.",
        context: .oneOnOne,
        createdAt: Date().addingTimeInterval(-86400 * 3) // 3 days ago
    )
    obs3.member = member

    member.observations = [obs1, obs2, obs3]

    context.insert(member)
    try? context.save()

    return ScrollView {
        ObservationSection(member: member)
            .padding()
    }
    .modelContainer(container)
}
