//
//  MemberForm.swift
//  Catalyze
//
//  Form for adding or editing a team member. Presented as a sheet from
//  the TeamView toolbar or from the member detail page.
//
//  Equivalent to `src/components/TeamMembers/MemberForm.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct MemberForm: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// If editing an existing member, pass it here. If nil, creates a new one.
    let memberToEdit: TeamMember?

    // Form state
    @State private var name = ""
    @State private var role = ""
    @State private var seniority: Seniority = .t2_1
    @State private var photoUrl = ""
    @State private var selectedMentorId: String? = nil
    @State private var externalMentorName = ""
    @State private var stackEntries: [StackEntryFormData] = []

    @Query(sort: \TeamMember.name) private var allMembers: [TeamMember]

    var body: some View {
        NavigationStack {
            Form {
                // Basic info section
                Section("Basic Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Role", text: $role)
                        .textContentType(.jobTitle)

                    Picker("Seniority", selection: $seniority) {
                        ForEach(Seniority.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                }

                // Photo section
                Section("Photo") {
                    TextField("Photo URL (optional)", text: $photoUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 80, height: 80)
                        }
                    }
                }

                // Mentorship section
                Section("Mentorship") {
                    Picker("Internal Mentor", selection: $selectedMentorId) {
                        Text("None").tag(nil as String?)

                        ForEach(availableMentors) { mentor in
                            Text(mentor.name).tag(mentor.id as String?)
                        }
                    }

                    TextField("External Mentor (optional)", text: $externalMentorName)
                        .textContentType(.name)
                }

                // Stack section
                Section {
                    ForEach($stackEntries) { $entry in
                        HStack {
                            Picker("Technology", selection: $entry.tag) {
                                ForEach(StackTag.allCases) { tag in
                                    Text(tag.rawValue).tag(tag)
                                }
                            }
                            .frame(maxWidth: .infinity)

                            Picker("Level", selection: $entry.level) {
                                ForEach(StackProficiency.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)

                            Button(role: .destructive) {
                                removeStackEntry(entry)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        addStackEntry()
                    } label: {
                        Label("Add Technology", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Technical Stack")
                } footer: {
                    Text("Select the technologies this person works with and their proficiency level.")
                }
            }
            .navigationTitle(isEditing ? "Edit Member" : "New Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveMember()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }

    // MARK: - Helpers --------------------------------------------------------

    private var isEditing: Bool {
        memberToEdit != nil
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !role.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var availableMentors: [TeamMember] {
        // Can't mentor yourself
        if let editing = memberToEdit {
            return allMembers.filter { $0.id != editing.id }
        }
        return allMembers
    }

    private func loadInitialData() {
        guard let member = memberToEdit else { return }

        name = member.name
        role = member.role
        seniority = member.seniority
        photoUrl = member.photoUrl ?? ""
        selectedMentorId = member.mentor?.id
        externalMentorName = member.mentorName ?? ""

        // Load stack entries
        stackEntries = (member.stack ?? []).map {
            StackEntryFormData(tag: $0.tag, level: $0.level)
        }
    }

    private func addStackEntry() {
        // Pick a tag that isn't already in the list
        let usedTags = Set(stackEntries.map { $0.tag })
        let availableTag = StackTag.allCases.first { !usedTags.contains($0) } ?? .typescript

        stackEntries.append(StackEntryFormData(tag: availableTag, level: .learning))
    }

    private func removeStackEntry(_ entry: StackEntryFormData) {
        stackEntries.removeAll { $0.id == entry.id }
    }

    private func saveMember() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedRole = role.trimmingCharacters(in: .whitespaces)

        if let existing = memberToEdit {
            // Update existing
            existing.name = trimmedName
            existing.role = trimmedRole
            existing.seniority = seniority
            existing.photoUrl = photoUrl.isEmpty ? nil : photoUrl
            existing.mentorName = externalMentorName.isEmpty ? nil : externalMentorName

            // Update mentor relationship
            if let mentorId = selectedMentorId {
                existing.mentor = allMembers.first { $0.id == mentorId }
            } else {
                existing.mentor = nil
            }

            // Update stack — remove old entries, insert new
            if let oldStack = existing.stack {
                for entry in oldStack {
                    context.delete(entry)
                }
            }

            let newStack = stackEntries.map {
                StackEntry(tag: $0.tag, level: $0.level)
            }
            for entry in newStack {
                entry.member = existing
                context.insert(entry)
            }
            existing.stack = newStack

            store.updateMember(existing, in: context)
        } else {
            // Create new
            let newMember = TeamMember(
                name: trimmedName,
                role: trimmedRole,
                seniority: seniority,
                photoUrl: photoUrl.isEmpty ? nil : photoUrl
            )

            newMember.mentorName = externalMentorName.isEmpty ? nil : externalMentorName

            if let mentorId = selectedMentorId {
                newMember.mentor = allMembers.first { $0.id == mentorId }
            }

            let newStack = stackEntries.map {
                StackEntry(tag: $0.tag, level: $0.level)
            }
            for entry in newStack {
                entry.member = newMember
                context.insert(entry)
            }
            newMember.stack = newStack

            store.addMember(newMember, in: context)
        }

        dismiss()
    }
}

// MARK: - Stack Entry Form Data ----------------------------------------------

private struct StackEntryFormData: Identifiable {
    let id = UUID()
    var tag: StackTag
    var level: StackProficiency
}

// MARK: - Preview ------------------------------------------------------------

#Preview("New Member") {
    MemberForm(memberToEdit: nil)
        .environment(AppStore())
        .modelContainer(try! PersistenceController.makePreviewContainer())
}

#Preview("Edit Member") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let alice = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1,
        photoUrl: "https://i.pravatar.cc/150?img=1"
    )

    let stackSwift = StackEntry(tag: .swiftUI, level: .expert)
    stackSwift.member = alice

    let stackTS = StackEntry(tag: .typescript, level: .proficient)
    stackTS.member = alice

    alice.stack = [stackSwift, stackTS]

    context.insert(alice)
    try? context.save()

    return MemberForm(memberToEdit: alice)
        .environment(AppStore())
        .modelContainer(container)
}
