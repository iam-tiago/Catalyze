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
import PhotosUI

struct MemberForm: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.seniorityService) private var seniorityService

    /// If editing an existing member, pass it here. If nil, creates a new one.
    let memberToEdit: TeamMember?

    // Form state
    @State private var name = ""
    @State private var role = ""
    @State private var seniority: Seniority = .t2_1
    @State private var selectedSeniorityCode: String = "T2-1"
    @State private var photoUrl = ""
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var selectedMentorId: String? = nil
    @State private var externalMentorName = ""
    @State private var showingError = false
    @State private var errorMessage = ""

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

                    // ✅ UPDATED: Seniority picker with custom levels and colors
                    if let service = seniorityService, !service.levels.isEmpty {
                        Picker("Seniority", selection: $selectedSeniorityCode) {
                            ForEach(service.levels, id: \.code) { level in
                                HStack {
                                    Circle()
                                        .fill(level.color)
                                        .frame(width: 8, height: 8)
                                    Text(level.displayName)
                                }
                                .tag(level.code)
                            }
                        }
                    } else {
                        // Fallback to legacy enum if service not available
                        Picker("Seniority", selection: $seniority) {
                            ForEach(Seniority.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }
                    }
                    
                    // Preview badge
                    if let service = seniorityService,
                       let level = service.level(byCode: selectedSeniorityCode) {
                        HStack {
                            Text("Badge Preview")
                                .font(CFont.caption1)
                                .foregroundStyle(CColor.neutral600)
                            Spacer()
                            TierBadge(level: level)
                        }
                    }
                }

                // Photo section
                Section("Photo") {
                    // PhotosPicker for local photos
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                photoData = data
                                photoUrl = "" // Clear URL when photo is picked
                            }
                        }
                    }
                    
                    // OR URL field
                    TextField("Or paste photo URL", text: $photoUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: photoUrl) { _, newUrl in
                            if !newUrl.isEmpty {
                                photoData = nil // Clear photo data when URL is entered
                                photoItem = nil
                            }
                        }

                    // Preview
                    if let data = photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Helpers --------------------------------------------------------

    private var isEditing: Bool {
        memberToEdit != nil
    }

    private var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedRole = role.trimmingCharacters(in: .whitespaces)
        
        return !trimmedName.isEmpty && 
               trimmedName.count >= 2 &&
               !trimmedRole.isEmpty &&
               trimmedRole.count >= 2
    }

    private var availableMentors: [TeamMember] {
        // Can't mentor yourself
        if let editing = memberToEdit {
            return allMembers.filter { $0.id != editing.id }
        }
        return allMembers
    }

    private func loadInitialData() {
        guard let member = memberToEdit else {
            // New member - initialize with first level from service or default
            if let service = seniorityService, let firstLevel = service.levels.first {
                selectedSeniorityCode = firstLevel.code
            } else {
                selectedSeniorityCode = seniority.rawValue
            }
            return
        }

        name = member.name
        role = member.role
        seniority = member.seniority
        selectedSeniorityCode = member.seniority.rawValue
        photoUrl = member.photoUrl ?? ""
        photoData = member.photoData
        selectedMentorId = member.mentor?.id
        externalMentorName = member.mentorName ?? ""
    }

    private func saveMember() {
        // Validate name
        guard case .success(let validName) = Validator.validateName(name) else {
            if case .failure(let error) = Validator.validateName(name) {
                errorMessage = error.localizedDescription ?? "Invalid name"
                showingError = true
            }
            return
        }
        
        // Validate role
        guard case .success(let validRole) = Validator.validateRole(role) else {
            if case .failure(let error) = Validator.validateRole(role) {
                errorMessage = error.localizedDescription ?? "Invalid role"
                showingError = true
            }
            return
        }
        
        // Validate photo URL if provided
        if !photoUrl.isEmpty {
            guard case .success = Validator.validateURL(photoUrl) else {
                if case .failure(let error) = Validator.validateURL(photoUrl) {
                    errorMessage = error.localizedDescription ?? "Invalid photo URL"
                    showingError = true
                }
                return
            }
        }

        if let existing = memberToEdit {
            // Update existing
            existing.name = validName
            existing.role = validRole
            // ✅ UPDATED: Use selectedSeniorityCode for custom levels
            existing.seniorityRaw = selectedSeniorityCode
            existing.photoUrl = photoUrl.isEmpty ? nil : photoUrl
            existing.photoData = photoData
            existing.mentorName = externalMentorName.isEmpty ? nil : externalMentorName

            // Update mentor relationship
            if let mentorId = selectedMentorId {
                existing.mentor = allMembers.first { $0.id == mentorId }
            } else {
                existing.mentor = nil
            }

            store.updateMember(existing, in: context)
        } else {
            // Create new
            // ✅ UPDATED: Map selectedSeniorityCode to Seniority enum or use default
            let seniorityEnum = Seniority(rawValue: selectedSeniorityCode) ?? .t2_1
            
            let newMember = TeamMember(
                name: validName,
                role: validRole,
                seniority: seniorityEnum,
                photoUrl: photoUrl.isEmpty ? nil : photoUrl
            )
            
            // Override with custom code if different
            if selectedSeniorityCode != seniorityEnum.rawValue {
                newMember.seniorityRaw = selectedSeniorityCode
            }
            
            newMember.photoData = photoData
            newMember.mentorName = externalMentorName.isEmpty ? nil : externalMentorName

            if let mentorId = selectedMentorId {
                newMember.mentor = allMembers.first { $0.id == mentorId }
            }

            store.addMember(newMember, in: context)
        }

        dismiss()
    }
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
