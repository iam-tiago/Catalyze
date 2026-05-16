//
//  TeamView.swift
//  Catalyze
//
//  Team grid view — shows all team members as cards in a responsive grid.
//  Tapping a card navigates to the member detail. "+" button opens the
//  add/edit member form.
//
//  ✨ Migrated to Catalyze Design System v1.0
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
            VStack(spacing: CSpace.x3l) {
                // Team overview (only show when team is not empty)
                if !members.isEmpty {
                    TeamOverview()
                        .padding(.horizontal, CSpace.x2l)
                }

                // Member grid
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 280), spacing: CSpace.lg)],
                    spacing: CSpace.lg
                ) {
                    ForEach(members) { member in
                        TeamMemberCard(member: member)
                            .onTapGesture {
                                store.setSelectedMember(member.id)
                            }
                    }
                }
                .padding(.horizontal, CSpace.x2l)
            }
            .padding(.vertical, CSpace.x2l)
        }
        .background {
            // Gradiente sutil de background
            CGradient.pageBackground
                .ignoresSafeArea()
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

// MARK: - Team Member Card --------------------------------------------------
// Using Catalyze Design System v1.0

private struct TeamMemberCard: View {
    let member: TeamMember
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: CSpace.md) {
            // Header: avatar + name + tier
            HStack(spacing: CSpace.md) {
                // Avatar com borda colorida
                avatarView
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [CColor.brandPrimary, CColor.brandPrimary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }

                // Name + role
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(CFont.headline)
                        .foregroundStyle(CColor.neutral900)
                        .lineLimit(1)

                    Text(member.role)
                        .font(CFont.subheadline)
                        .foregroundStyle(CColor.neutral600)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Tier badge
                TierBadge(tier: member.seniority.label)
            }

            // Top 2 strengths
            if !topStrengths.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: CSpace.sm) {
                    Text("TOP STRENGTHS")
                        .font(CFont.caption2)
                        .foregroundStyle(CColor.neutral400)

                    FlowLayout(spacing: CSpace.sm) {
                        ForEach(topStrengths, id: \.id) { strength in
                            SkillChip(
                                name: strength.category,
                                intensity: mapIntensity(strength.intensity)
                            )
                        }
                    }
                }
            }
        }
        .padding(CSpace.lg)
        .background {
            // Background com gradiente sutil no hover
            RoundedRectangle(cornerRadius: CRadius.md)
                .fill(isHovered ? CGradient.cardHover : LinearGradient(colors: [CColor.neutral0], startPoint: .top, endPoint: .bottom))
        }
        .overlay {
            // Borda sutil que aparece no hover
            RoundedRectangle(cornerRadius: CRadius.md)
                .strokeBorder(
                    isHovered ? CColor.brandPrimary.opacity(0.3) : Color.clear,
                    lineWidth: 1.5
                )
        }
        .cardShadow()
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var avatarView: some View {
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
    }

    private var placeholderAvatar: some View {
        ZStack {
            Circle()
                .fill(CColor.brandPrimaryLight)
            Image(systemName: "person.fill")
                .font(.system(size: 28))
                .foregroundStyle(CColor.brandPrimary)
        }
    }

    private var topStrengths: [StrengthWeakness] {
        Array(member.strengths.prefix(2))
    }
    
    private func mapIntensity(_ intensity: Intensity) -> SkillIntensity {
        switch intensity {
        case .emerging: return .emerging
        case .solid: return .solid
        case .strong: return .strong
        case .developing, .blocking: return .emerging // Weaknesses map to emerging
        }
    }
}

// MARK: - Flow Layout --------------------------------------------------------
// Simple flow layout for chips

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: spacing) {
            content()
        }
    }
}

// MARK: - Empty State --------------------------------------------------------
// Using Catalyze Design System v1.0

private struct EmptyTeamView: View {
    let onAddMember: () -> Void

    var body: some View {
        EmptyState(
            icon: "person.3.sequence",
            message: "Add your first team member to get started",
            actionTitle: "Add Team Member",
            actionIcon: "plus",
            onAction: onAddMember
        )
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
