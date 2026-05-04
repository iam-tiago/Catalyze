//
//  MemberView.swift
//  Catalyze
//
//  Individual member detail page. Shows header (photo, name, seniority,
//  edit/delete buttons) plus vertically-stacked sections for tags,
//  observations, IDPs, promotion tracking, and profile evolution.
//
//  Equivalent to `src/components/TeamMembers/MemberView.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct MemberView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    let memberId: String

    @Query private var allMembers: [TeamMember]

    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false

    var body: some View {
        Group {
            if let member = member {
                MemberDetailContent(
                    member: member,
                    onEdit: { showingEditForm = true },
                    onDelete: { showingDeleteAlert = true }
                )
            } else {
                MemberNotFoundView()
            }
        }
        .sheet(isPresented: $showingEditForm) {
            if let member = member {
                MemberForm(memberToEdit: member)
            }
        }
        .alert("Delete Member", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let member = member {
                    store.deleteMember(member, in: context)
                }
            }
        } message: {
            Text("Are you sure you want to delete this member? All associated data (observations, IDPs, promotion records) will also be deleted.")
        }
    }

    private var member: TeamMember? {
        allMembers.first { $0.id == memberId }
    }
}

// MARK: - Member Detail Content ----------------------------------------------

private struct MemberDetailContent: View {
    @Environment(AppStore.self) private var store
    
    let member: TeamMember
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                MemberHeader(member: member, onEdit: onEdit, onDelete: onDelete)
                    .padding(.horizontal)

                // Sections
                VStack(spacing: 16) {
                    TagSection(member: member)
                    
                    // Behavioral radar chart (right after strengths/weaknesses)
                    MemberRadar(member: member)
                    
                    TechnicalStackSection(member: member)
                    
                    // Technical radar chart (right after technical stack)
                    TechnicalRadar(member: member)
                    
                    ObservationSection(member: member)
                    IDPSection(member: member)
                    PromotionReadinessSection(member: member)
                    ProfileEvolutionSection(member: member)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    store.setActiveView(.team)
                } label: {
                    Label("Back to Team", systemImage: "chevron.left")
                }
            }
        }
    }
}

// MARK: - Member Header ------------------------------------------------------

private struct MemberHeader: View {
    let member: TeamMember
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Avatar + basic info
            HStack(spacing: 16) {
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
                .frame(width: 80, height: 80)
                .clipShape(Circle())

                // Name + role + seniority
                VStack(alignment: .leading, spacing: 6) {
                    Text(member.name)
                        .font(.title2.bold())

                    Text(member.role)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // Seniority chip
                    HStack(spacing: 8) {
                        Text(member.seniority.label)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.tint.opacity(0.15), in: Capsule())
                            .foregroundStyle(.tint)

                        // Stack count badge
                        if let stack = member.stack, !stack.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.caption2)
                                Text("\(stack.count)")
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.secondary.opacity(0.1), in: Capsule())
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            // Mentorship info
            if member.mentor != nil || member.mentorName != nil || !member.externalMentees.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    if let mentor = member.mentor {
                        HStack {
                            Image(systemName: "person.fill.checkmark")
                                .foregroundStyle(.secondary)
                            Text("Mentored by:")
                                .foregroundStyle(.secondary)
                            Text(mentor.name)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }

                    if let externalMentor = member.mentorName {
                        HStack {
                            Image(systemName: "person.fill.checkmark")
                                .foregroundStyle(.secondary)
                            Text("External mentor:")
                                .foregroundStyle(.secondary)
                            Text(externalMentor)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }

                    if !member.externalMentees.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.secondary)
                            Text("Mentoring:")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(member.externalMentees, id: \.self) { mentee in
                                    Text(mentee)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint.opacity(0.5))
    }
}

// MARK: - Member Not Found ---------------------------------------------------

private struct MemberNotFoundView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Member Not Found")
                .font(.title2.bold())

            Text("This member may have been deleted.")
                .foregroundStyle(.secondary)

            Button {
                store.setSelectedMember(nil)
            } label: {
                Text("Back to Team")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Reusable Section Card ----------------------------------------------

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Section content
            content()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("Member View") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let alice = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1,
        photoUrl: "https://i.pravatar.cc/150?img=1"
    )

    let mentor = TeamMember(
        name: "Bob Silva",
        role: "Staff Engineer",
        seniority: .t4
    )

    alice.mentor = mentor
    alice.externalMentees = ["Carol (Design Team)", "Dave (Backend Team)"]

    let stackSwift = StackEntry(tag: .swiftUI, level: .expert)
    stackSwift.member = alice
    let stackTS = StackEntry(tag: .typescript, level: .proficient)
    stackTS.member = alice

    alice.stack = [stackSwift, stackTS]

    let strength = StrengthWeakness(
        kind: .strength,
        category: "Code Quality",
        intensity: .strong
    )
    strength.member = alice
    alice.tags = [strength]

    context.insert(mentor)
    context.insert(alice)
    try? context.save()

    let store = AppStore()
    store.setSelectedMember(alice.id)

    return NavigationStack {
        MemberView(memberId: alice.id)
            .environment(store)
            .modelContainer(container)
    }
}
