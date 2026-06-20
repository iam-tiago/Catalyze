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

// MARK: - Seniority Color Helper

private func seniorityAccentColor(for seniority: Seniority) -> Color {
    switch seniority {
    case .t1_3:
        return Color(red: 0.851, green: 0.467, blue: 0.024)
    case .t2_1, .t2_2, .t2_3:
        return Color(red: 0.231, green: 0.510, blue: 0.965)
    case .t3_1, .t3_2, .t3_3:
        return CColor.brandPrimary
    case .t4:
        return Color(red: 0.063, green: 0.624, blue: 0.506)
    }
}

// MARK: - Team Member Card --------------------------------------------------

private struct TeamMemberCard: View {
    let member: TeamMember
    @State private var isHovered = false

    private var accentColor: Color { seniorityAccentColor(for: member.seniority) }

    var body: some View {
        VStack(alignment: .leading, spacing: CSpace.md) {
            HStack(spacing: CSpace.md) {
                avatarView
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }

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

                TierBadge(tier: member.seniority.label, foreground: accentColor, background: accentColor.opacity(0.10))
            }

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
            RoundedRectangle(cornerRadius: CRadius.md)
                .fill(isHovered ? CGradient.cardHover : LinearGradient(colors: [CColor.neutral0], startPoint: .top, endPoint: .bottom))
        }
        .overlay {
            RoundedRectangle(cornerRadius: CRadius.md)
                .strokeBorder(
                    isHovered ? accentColor.opacity(0.35) : Color.clear,
                    lineWidth: 1.5
                )
        }
        .cardShadow()
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }

    private var avatarView: some View {
        Group {
            if let avatarImage = member.avatarImage {
                avatarImage.resizable().scaledToFill()
            } else if let urlString = member.photoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
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
            Circle().fill(accentColor.opacity(0.12))
            Image(systemName: "person.fill")
                .font(.system(size: 28))
                .foregroundStyle(accentColor)
        }
    }

    private var topStrengths: [StrengthWeakness] { Array(member.strengths.prefix(2)) }

    private func mapIntensity(_ intensity: Intensity) -> SkillIntensity {
        switch intensity {
        case .emerging: return .emerging
        case .solid: return .solid
        case .strong: return .strong
        case .developing, .blocking: return .emerging
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
    SampleDataProvider.makePreviewContainer()
}
