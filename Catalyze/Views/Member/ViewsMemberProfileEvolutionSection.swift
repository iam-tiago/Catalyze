//
//  ProfileEvolutionSection.swift
//  Catalyze
//
//  Profile evolution timeline section. Shows an append-only history of
//  strength/weakness changes (added/updated/removed) in reverse chronological
//  order.
//
//  Equivalent to `src/components/TeamMembers/ProfileEvolutionSection.tsx`
//  in the web app.
//

import SwiftUI
import SwiftData

struct ProfileEvolutionSection: View {
    let member: TeamMember

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label("Profile Evolution", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)

                Spacer()

                if !sortedEvents.isEmpty {
                    Text("\(sortedEvents.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Timeline
            if sortedEvents.isEmpty {
                Text("No profile changes yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedEvents.prefix(10)) { event in
                        ProfileEventRow(event: event)
                    }

                    if sortedEvents.count > 10 {
                        Text("+ \(sortedEvents.count - 10) earlier events")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var sortedEvents: [ProfileEvent] {
        (member.profileEvents ?? []).sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Profile Event Row --------------------------------------------------

private struct ProfileEventRow: View {
    let event: ProfileEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Description
                HStack(spacing: 4) {
                    Text(actionText)
                        .font(.subheadline.weight(.medium))

                    Text(event.category)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                // Intensity change (if applicable)
                if let before = event.intensityBefore, let after = event.intensityAfter {
                    HStack(spacing: 4) {
                        Text(before.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Text(after.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Date
                Text(event.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch event.type {
        case .strengthAdded:   return "plus.circle.fill"
        case .strengthUpdated: return "arrow.triangle.2.circlepath"
        case .strengthRemoved: return "minus.circle.fill"
        case .weaknessAdded:   return "plus.circle.fill"
        case .weaknessUpdated: return "arrow.triangle.2.circlepath"
        case .weaknessRemoved: return "minus.circle.fill"
        }
    }

    private var iconColor: Color {
        switch event.type {
        case .strengthAdded, .strengthUpdated:
            return .green
        case .strengthRemoved:
            return .red
        case .weaknessAdded, .weaknessUpdated:
            return .orange
        case .weaknessRemoved:
            return .blue
        }
    }

    private var actionText: String {
        switch event.type {
        case .strengthAdded:   return "Added strength:"
        case .strengthUpdated: return "Updated strength:"
        case .strengthRemoved: return "Removed strength:"
        case .weaknessAdded:   return "Added growth area:"
        case .weaknessUpdated: return "Updated growth area:"
        case .weaknessRemoved: return "Removed growth area:"
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

    let event1 = ProfileEvent(
        memberId: member.id,
        type: .strengthAdded,
        category: "Code Quality",
        intensityAfter: .strong,
        createdAt: Date().addingTimeInterval(-86400 * 2) // 2 days ago
    )
    event1.member = member

    let event2 = ProfileEvent(
        memberId: member.id,
        type: .strengthUpdated,
        category: "Leadership",
        intensityBefore: .solid,
        intensityAfter: .strong,
        createdAt: Date().addingTimeInterval(-86400 * 7) // 1 week ago
    )
    event2.member = member

    let event3 = ProfileEvent(
        memberId: member.id,
        type: .weaknessAdded,
        category: "Testing",
        intensityAfter: .developing,
        createdAt: Date().addingTimeInterval(-86400 * 14) // 2 weeks ago
    )
    event3.member = member

    let event4 = ProfileEvent(
        memberId: member.id,
        type: .weaknessRemoved,
        category: "Communication",
        createdAt: Date().addingTimeInterval(-86400 * 30) // 1 month ago
    )
    event4.member = member

    member.profileEvents = [event1, event2, event3, event4]

    context.insert(member)
    try? context.save()

    return ScrollView {
        ProfileEvolutionSection(member: member)
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
        ProfileEvolutionSection(member: member)
            .padding()
    }
    .modelContainer(container)
}
