//
//  SettingsView.swift
//  Catalyze
//
//  Settings view for configuring the EM profile, API credentials, and
//  app preferences. Also includes import/export functionality.
//
//  Equivalent to `src/components/Settings/SettingsView.tsx` in the web app.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var role = ""
    @State private var teamName = ""
    @State private var photoUrl = ""
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var isTestingConnection = false
    
    // Save confirmation alerts
    @State private var showProfileSaved = false
    @State private var showCredentialsSaved = false
    
    // Appearance
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    // Sample data
    @State private var showingSampleDataAlert = false
    @State private var showingSampleDataSuccess = false
    
    // Team management
    @State private var showingTeamManagement = false

    var body: some View {
        Form {
            // EM Profile section
            Section("Your Profile") {
                TextField("Name", text: $name)
                    .textContentType(.name)

                TextField("Role", text: $role)
                    .textContentType(.jobTitle)

                TextField("Team Name (optional)", text: $teamName)

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
                if let data = photoData {
                    #if os(iOS)
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    #elseif os(macOS)
                    if let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    #endif
                } else if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .frame(width: 60, height: 60)
                    }
                }

                Button("Save Profile") {
                    saveProfile()
                }
                .buttonStyle(.borderedProminent)
                
                // Confirmation message
                if showProfileSaved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Profile saved successfully")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .transition(.opacity)
                }
            }

            // API Credentials section
            Section {
                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("Base URL", text: $baseURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button {
                    Task { await testConnection() }
                } label: {
                    if isTestingConnection {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Testing...")
                        }
                    } else {
                        Label("Test Connection", systemImage: "network")
                    }
                }
                .disabled(apiKey.isEmpty || isTestingConnection)

                if showingTestResult {
                    Text(testResultMessage)
                        .font(.caption)
                        .foregroundStyle(testResultMessage.contains("✓") ? .green : .red)
                }

                Button("Save Credentials") {
                    saveCredentials()
                }
                .buttonStyle(.borderedProminent)
                
                // Confirmation message
                if showCredentialsSaved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Credentials saved successfully")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .transition(.opacity)
                }
            } header: {
                Text("API Credentials")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your Anthropic API key or a LiteLLM-compatible proxy endpoint.")
                    Text("Default: \(ClaudeClient.defaultBaseURL)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Data Management section
            Section("Data Management") {
                // Sample Data
                Button {
                    showingSampleDataAlert = true
                } label: {
                    Label("Load Sample Data", systemImage: "person.3.fill")
                }
                
                if showingSampleDataSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Sample data loaded successfully")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .transition(.opacity)
                }
                
                // Team Management
                Button {
                    showingTeamManagement = true
                } label: {
                    Label("Manage Team", systemImage: "person.crop.circle.badge.minus")
                }
                
                Button {
                    // Export functionality (placeholder)
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }

                Button {
                    // Import functionality (placeholder)
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            }
            
            // Appearance section
            Section {
                Picker("Theme", selection: $appearanceMode) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Choose how Catalyze looks. System follows your device settings.")
                    .font(.caption)
            }

            // About section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSettings()
        }
        .alert("Load Sample Data?", isPresented: $showingSampleDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Load Sample Data") {
                loadSampleData()
            }
        } message: {
            Text("This will add 5 sample team members with observations, IDPs, and other mock data for demonstration purposes. Existing data will not be affected.")
        }
        .sheet(isPresented: $showingTeamManagement) {
            TeamManagementView()
        }
    }

    // MARK: - Helpers --------------------------------------------------------

    private func loadSettings() {
        // Load EM profile
        name = store.emProfile.name
        role = store.emProfile.role
        teamName = store.emProfile.teamName ?? ""
        photoUrl = store.emProfile.photoUrl ?? ""
        photoData = store.emProfile.photoData

        // Load API credentials
        apiKey = store.apiKey
        baseURL = store.baseURL
    }

    private func saveProfile() {
        let profile = EMProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            role: role.trimmingCharacters(in: .whitespaces),
            teamName: teamName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : teamName.trimmingCharacters(in: .whitespaces),
            photoUrl: photoUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : photoUrl.trimmingCharacters(in: .whitespaces),
            photoData: photoData
        )
        store.setEMProfile(profile)
        
        // Show confirmation
        withAnimation {
            showProfileSaved = true
        }
        
        // Hide after 3 seconds
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                showProfileSaved = false
            }
        }
    }

    private func saveCredentials() {
        store.setApiKey(apiKey.trimmingCharacters(in: .whitespaces))
        store.setBaseURL(baseURL.trimmingCharacters(in: .whitespaces).isEmpty
            ? ClaudeClient.defaultBaseURL
            : baseURL.trimmingCharacters(in: .whitespaces))
        
        // Show confirmation
        withAnimation {
            showCredentialsSaved = true
        }
        
        // Hide after 3 seconds
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                showCredentialsSaved = false
            }
        }
    }

    private func testConnection() async {
        isTestingConnection = true
        showingTestResult = false

        let client = ClaudeClient(
            apiKey: apiKey.trimmingCharacters(in: .whitespaces),
            baseURL: baseURL.trimmingCharacters(in: .whitespaces).isEmpty
                ? ClaudeClient.defaultBaseURL
                : baseURL.trimmingCharacters(in: .whitespaces)
        )

        do {
            _ = try await client.complete(
                messages: [ChatMessage(role: "user", content: "Hello")],
                maxTokens: 10
            ) { _ in }

            testResultMessage = "✓ Connection successful"
            showingTestResult = true
        } catch {
            testResultMessage = "✗ Connection failed: \(error.localizedDescription)"
            showingTestResult = true
        }

        isTestingConnection = false
    }
    
    private func loadSampleData() {
        // Create 5 sample team members with realistic data
        let sampleMembers: [(String, String, Seniority)] = [
            ("Alice Chen", "Senior iOS Engineer", .t3_1),
            ("Bob Silva", "Staff Engineer", .t4),
            ("Carol Martinez", "iOS Engineer", .t2_2),
            ("David Kumar", "Senior Backend Engineer", .t3_2),
            ("Emma Thompson", "iOS Engineer", .t2_1)
        ]
        
        var createdMembers: [TeamMember] = []
        
        for (name, role, seniority) in sampleMembers {
            let member = TeamMember(
                name: name,
                role: role,
                seniority: seniority
            )
            
            // Add stack entries
            let stackData: [(StackTag, StackProficiency)] = {
                switch name {
                case "Alice Chen":
                    return [(.swiftUI, .expert), (.typescript, .proficient), (.react, .learning)]
                case "Bob Silva":
                    return [(.swiftUI, .expert), (.golang, .expert), (.docker, .proficient)]
                case "Carol Martinez":
                    return [(.swiftUI, .proficient), (.typescript, .learning)]
                case "David Kumar":
                    return [(.golang, .expert), (.docker, .expert), (.kubernetes, .proficient)]
                case "Emma Thompson":
                    return [(.swiftUI, .learning), (.typescript, .proficient)]
                default:
                    return []
                }
            }()
            
            let stackEntries = stackData.map { tag, level in
                let entry = StackEntry(tag: tag, level: level)
                entry.member = member
                context.insert(entry)
                return entry
            }
            member.stack = stackEntries
            
            // Add strengths
            let strengths: [(String, Intensity)] = {
                switch name {
                case "Alice Chen":
                    return [("Code Quality", .strong), ("SwiftUI", .strong), ("Mentoring", .solid)]
                case "Bob Silva":
                    return [("System Design", .strong), ("Code Quality", .strong), ("Leadership", .strong)]
                case "Carol Martinez":
                    return [("Learning Agility", .solid), ("UI/UX", .emerging)]
                case "David Kumar":
                    return [("Backend Architecture", .strong), ("Code Quality", .strong)]
                case "Emma Thompson":
                    return [("Problem Solving", .solid), ("Communication", .emerging)]
                default:
                    return []
                }
            }()
            
            for (category, intensity) in strengths {
                let strength = StrengthWeakness(
                    kind: .strength,
                    category: category,
                    intensity: intensity
                )
                strength.member = member
                context.insert(strength)
            }
            
            // Add weaknesses/opportunities
            let weaknesses: [(String, Intensity)] = {
                switch name {
                case "Alice Chen":
                    return [("Public Speaking", .emerging)]
                case "Bob Silva":
                    return [("Delegation", .emerging)]
                case "Carol Martinez":
                    return [("System Design", .developing), ("Testing", .emerging)]
                case "David Kumar":
                    return [("Frontend Skills", .emerging)]
                case "Emma Thompson":
                    return [("Code Review Skills", .emerging), ("Performance Optimization", .developing)]
                default:
                    return []
                }
            }()
            
            for (category, intensity) in weaknesses {
                let weakness = StrengthWeakness(
                    kind: .weakness,
                    category: category,
                    intensity: intensity
                )
                weakness.member = member
                context.insert(weakness)
            }
            
            // Add observations
            let observations: [(Date, String, ObservationContext)] = {
                let now = Date()
                switch name {
                case "Alice Chen":
                    return [
                        (now.addingTimeInterval(-7*24*3600), "Led the migration to SwiftUI with excellent technical decisions and clear documentation.", .sprintReview),
                        (now.addingTimeInterval(-14*24*3600), "Mentored Carol on iOS best practices, showing great patience and teaching skills.", .oneOnOne)
                    ]
                case "Bob Silva":
                    return [
                        (now.addingTimeInterval(-3*24*3600), "Designed the new microservices architecture that improved system scalability by 3x.", .performanceCycle),
                        (now.addingTimeInterval(-21*24*3600), "Could improve on delegating tasks to allow team members to grow.", .oneOnOne)
                    ]
                case "Carol Martinez":
                    return [
                        (now.addingTimeInterval(-5*24*3600), "Shipped her first major feature independently with minimal guidance.", .sprintReview),
                        (now.addingTimeInterval(-12*24*3600), "Needs more practice with system design and architectural thinking.", .oneOnOne)
                    ]
                default:
                    return []
                }
            }()
            
            for (date, text, context) in observations {
                let obs = TeamObservation(
                    memberId: member.id,
                    text: text,
                    context: context,
                    createdAt: date
                )
                self.context.insert(obs)
            }
            
            // Add IDP
            if name == "Carol Martinez" || name == "Emma Thompson" {
                let idp = DevelopmentPlan(
                    memberId: member.id,
                    title: "System Design & Architecture",
                    objective: "Develop strong system design skills to independently architect medium-sized features",
                    targetDate: Date().addingTimeInterval(90*24*3600),
                    status: .active
                )
                context.insert(idp)
            }
            
            context.insert(member)
            createdMembers.append(member)
        }
        
        // Set up mentorship relationships
        if createdMembers.count >= 3 {
            createdMembers[2].mentor = createdMembers[0] // Carol mentored by Alice
            createdMembers[4].mentor = createdMembers[0] // Emma mentored by Alice
        }
        
        // Save
        try? context.save()
        
        // Show success message
        withAnimation {
            showingSampleDataSuccess = true
        }
        
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                showingSampleDataSuccess = false
            }
        }
    }
}

// MARK: - Appearance Mode ----------------------------------------------------

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Team Management View -----------------------------------------------

private struct TeamManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppStore.self) private var store
    
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    @State private var memberToDelete: TeamMember?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                if members.isEmpty {
                    ContentUnavailableView {
                        Label("No Team Members", systemImage: "person.3.slash")
                    } description: {
                        Text("Add team members to manage them here.")
                    }
                } else {
                    ForEach(members) { member in
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
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            // Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.headline)
                                Text(member.role)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(member.seniority.label)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.tint.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.tint)
                            }
                            
                            Spacer()
                            
                            // Delete button
                            Button(role: .destructive) {
                                memberToDelete = member
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Manage Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Member?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    memberToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let member = memberToDelete {
                        store.deleteMember(member, in: context)
                        memberToDelete = nil
                    }
                }
            } message: {
                if let member = memberToDelete {
                    Text("Are you sure you want to delete \(member.name)? All associated data (observations, IDPs, promotion records) will also be deleted.")
                }
            }
        }
    }
    
    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint.opacity(0.5))
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppStore())
            .modelContainer(try! PersistenceController.makePreviewContainer())
    }
}
