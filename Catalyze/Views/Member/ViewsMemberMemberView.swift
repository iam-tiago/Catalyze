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
                .id(memberId)
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    MemberHeader(member: member, onEdit: onEdit, onDelete: onDelete)
                        .padding(.horizontal)

                    // Sections
                    VStack(spacing: 16) {
                        // 1. Strengths & Growth Areas → Behavioral Profile radar
                        TagSection(member: member)
                        MemberRadar(member: member)

                        // 2. Tech Skills → Tech Skills radar
                        TechSkillsSection(member: member)
                        TechnicalRadar(member: member)

                        // 3. Tech Stack → distribution bars (for now, just list)
                        TechnicalStackSection(member: member)
                        TechStackDistribution(member: member)

                        // Other sections
                        ObservationSection(member: member)
                        IDPSection(member: member)
                            .id("section-idp")
                        PromotionReadinessSection(member: member)
                            .id("section-promotion")
                        ProfileEvolutionSection(member: member)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .onAppear { scrollToFocused(proxy) }
            .onChange(of: store.focusedMemberSection) { _, _ in scrollToFocused(proxy) }
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

    private func scrollToFocused(_ proxy: ScrollViewProxy) {
        guard let section = store.focusedMemberSection else { return }
        let anchor: String = switch section {
        case .idp:       "section-idp"
        case .promotion: "section-promotion"
        }
        store.focusedMemberSection = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.smooth) {
                proxy.scrollTo(anchor, anchor: .top)
            }
        }
    }
}

// MARK: - Member Header ------------------------------------------------------

private struct MemberHeader: View {
    let member: TeamMember
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var hasMentorship: Bool {
        member.mentor != nil || member.mentorName != nil || !member.externalMentees.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            heroSection

            VStack(spacing: CSpace.md) {
                HStack(spacing: CSpace.md) {
                    Button { onEdit() } label: {
                        Label("Edit", systemImage: "pencil").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive) { onDelete() } label: {
                        Label("Delete", systemImage: "trash").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if hasMentorship {
                    Divider()
                    mentorshipSection
                }
            }
            .padding(CSpace.lg)
            .background(CColor.neutral0)
        }
        .clipShape(RoundedRectangle(cornerRadius: CRadius.md))
        .cardShadow()
    }

    // MARK: Hero

    private var heroSection: some View {
        ZStack {
            heroBackground

            Canvas { ctx, size in
                let spacing: CGFloat = 22
                let radius: CGFloat = 0.85
                var x = spacing / 2
                while x < size.width {
                    var y = spacing / 2
                    while y < size.height {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(.white)
                        )
                        y += spacing
                    }
                    x += spacing
                }
            }
            .opacity(0.06)

            VStack(spacing: CSpace.md) {
                avatarView
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 3))
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)

                VStack(spacing: 4) {
                    Text(member.name)
                        .font(CFont.title2)
                        .foregroundStyle(.white)

                    Text(member.role)
                        .font(CFont.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                }

                HStack(spacing: CSpace.sm) {
                    Text(member.seniority.label)
                        .font(CFont.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, CSpace.md)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.15))
                        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                        .clipShape(Capsule())

                    if let stack = member.stack, !stack.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 10))
                            Text("\(stack.count)")
                                .font(CFont.caption2)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, CSpace.sm + 2)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.10))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, CSpace.x2l)
        }
    }

    private var heroBackground: some View {
        MeshGradient(width: 2, height: 2, points: [
            [0, 0], [1, 0],
            [0, 1], [1, 1]
        ], colors: gradientColors)
    }

    private var gradientColors: [Color] {
        switch member.seniority {
        case .t1_3:
            return [
                Color(red: 0.361, green: 0.157, blue: 0.035),
                Color(red: 0.573, green: 0.278, blue: 0.043),
                Color(red: 0.573, green: 0.278, blue: 0.043),
                Color(red: 0.851, green: 0.467, blue: 0.024)
            ]
        case .t2_1, .t2_2, .t2_3:
            return [
                Color(red: 0.075, green: 0.196, blue: 0.549),
                Color(red: 0.114, green: 0.314, blue: 0.745),
                Color(red: 0.114, green: 0.314, blue: 0.745),
                Color(red: 0.231, green: 0.510, blue: 0.965)
            ]
        case .t3_1, .t3_2, .t3_3:
            return [
                Color(red: 0.118, green: 0.106, blue: 0.294),
                Color(red: 0.216, green: 0.188, blue: 0.639),
                Color(red: 0.216, green: 0.188, blue: 0.639),
                Color(red: 0.357, green: 0.357, blue: 0.839)
            ]
        case .t4:
            return [
                Color(red: 0.024, green: 0.235, blue: 0.180),
                Color(red: 0.020, green: 0.369, blue: 0.275),
                Color(red: 0.020, green: 0.369, blue: 0.275),
                Color(red: 0.063, green: 0.624, blue: 0.506)
            ]
        }
    }

    // MARK: Avatar

    @ViewBuilder
    private var avatarView: some View {
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

    private var placeholderAvatar: some View {
        ZStack {
            Circle().fill(.white.opacity(0.15))
            Image(systemName: "person.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: Mentorship

    private var mentorshipSection: some View {
        VStack(alignment: .leading, spacing: CSpace.sm) {
            if let mentor = member.mentor {
                MentorRow(icon: "person.fill.checkmark", label: "Mentored by", value: mentor.name)
            }
            if let external = member.mentorName {
                MentorRow(icon: "person.fill.checkmark", label: "External mentor", value: external)
            }
            if !member.externalMentees.isEmpty {
                MentorRow(icon: "person.2.fill", label: "Mentoring", value: member.externalMentees.joined(separator: ", "))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MentorRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: CSpace.sm) {
            Image(systemName: icon)
                .foregroundStyle(CColor.neutral400)
                .frame(width: 16)
            Text(label + ":")
                .foregroundStyle(CColor.neutral600)
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(CColor.neutral900)
        }
        .font(CFont.subheadline)
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
