//
//  TeamView.swift
//  Catalyze
//
//  Team grid view — shows all team members as cards in a responsive grid.
//  Tapping a card navigates to the member detail. "+" button opens the
//  add/edit member form.
//
//  Equivalent to `src/components/TeamMembers/TeamView.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct TeamView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: \TeamMember.name) private var members: [TeamMember]

    @State private var showingAddMember = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Team overview (only show when team is not empty)
                if !members.isEmpty {
                    TeamOverview()
                        .padding(.horizontal)
                }

                // Member grid
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 280), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(members) { member in
                        MemberCard(member: member)
                            .onTapGesture {
                                store.setSelectedMember(member.id)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(teamTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddMember = true
                } label: {
                    Label("Add Member", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMember) {
            MemberForm(memberToEdit: nil)
        }
        // Empty state
        .overlay {
            if members.isEmpty {
                EmptyTeamView(onAddMember: { showingAddMember = true })
            }
        }
    }

    private var teamTitle: String {
        if let teamName = store.emProfile.teamName, !teamName.isEmpty {
            return teamName
        }
        return "Team"
    }
}

// MARK: - Member Card --------------------------------------------------------

private struct MemberCard: View {
    let member: TeamMember

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: avatar + name + seniority
            HStack(spacing: 12) {
                // Avatar
                Group {
                    if let avatarImage = member.avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                    } else if let urlString = member.photoUrl,
                              let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            placeholderAvatar
                        }
                    } else {
                        placeholderAvatar
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())

                // Name + role
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(member.role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Seniority chip
                Text(member.seniority.label)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.15), in: Capsule())
                    .foregroundStyle(.tint)
            }

            // Top 2 strengths
            if !member.strengths.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Top Strengths")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    FlowLayout(spacing: 6) {
                        ForEach(topStrengths, id: \.id) { strength in
                            StrengthChip(strength: strength)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .hoverEffect(.lift)
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint.opacity(0.5))
    }

    private var topStrengths: [StrengthWeakness] {
        Array(member.strengths.prefix(2))
    }
}

// MARK: - Strength Chip ------------------------------------------------------

private struct StrengthChip: View {
    let strength: StrengthWeakness

    var body: some View {
        HStack(spacing: 4) {
            // Intensity indicator (dots)
            HStack(spacing: 2) {
                ForEach(0..<intensityDotCount, id: \.self) { _ in
                    Circle()
                        .fill(.green)
                        .frame(width: 4, height: 4)
                }
            }

            Text(strength.category)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.green.opacity(0.1), in: Capsule())
        .foregroundStyle(.green)
    }

    private var intensityDotCount: Int {
        switch strength.intensity {
        case .emerging:   return 1
        case .solid:      return 2
        case .strong:     return 3
        default:          return 1
        }
    }
}

// MARK: - Flow Layout --------------------------------------------------------
//
// Simple flow layout for chips. In iOS 16+ we'd use `Layout` protocol,
// but for broader compatibility we use a simple HStack + wrapping logic.
// This is a simplified version — just wraps horizontally.

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        // For now, use HStack — a proper flow layout would calculate
        // available width and wrap. This is good enough for top 2 tags.
        HStack(spacing: spacing) {
            content()
        }
    }
}

// MARK: - Empty State --------------------------------------------------------

private struct EmptyTeamView: View {
    let onAddMember: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text("No Team Members Yet")
                    .font(.title2.bold())

                Text("Add your first team member to get started")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button {
                onAddMember()
            } label: {
                Label("Add Team Member", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: 400)
        .padding()
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("Team View — With Members") {
    NavigationStack {
        TeamView()
            .environment(AppStore())
            .modelContainer(previewContainerWithMembers())
    }
}

#Preview("Team View — Empty") {
    NavigationStack {
        TeamView()
            .environment(AppStore())
            .modelContainer(try! PersistenceController.makePreviewContainer())
    }
}

// MARK: - Preview Helpers ----------------------------------------------------

private func previewContainerWithMembers() -> ModelContainer {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    // Sample members
    let alice = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    let aliceStrength1 = StrengthWeakness(
        kind: .strength,
        category: "Code Quality",
        intensity: .strong
    )
    aliceStrength1.member = alice

    let aliceStrength2 = StrengthWeakness(
        kind: .strength,
        category: "Leadership",
        intensity: .solid
    )
    aliceStrength2.member = alice

    alice.tags = [aliceStrength1, aliceStrength2]

    let bob = TeamMember(
        name: "Bob Silva",
        role: "Backend Engineer",
        seniority: .t2_2
    )

    let bobStrength = StrengthWeakness(
        kind: .strength,
        category: "Problem Solving",
        intensity: .solid
    )
    bobStrength.member = bob
    bob.tags = [bobStrength]

    let carol = TeamMember(
        name: "Carol Martins",
        role: "Full Stack Engineer",
        seniority: .t2_1
    )

    context.insert(alice)
    context.insert(bob)
    context.insert(carol)

    try? context.save()

    return container
}
