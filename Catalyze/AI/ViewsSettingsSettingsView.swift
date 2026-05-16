//
//  SettingsView.swift
//  Catalyze
//
//  Settings view for configuring the EM profile, API credentials, and
//  app preferences. Also includes import/export functionality.
//
//  ✨ Lightly adapted to Catalyze Design System v1.0
//  (Form keeps native styling, only confirmations and colors updated)
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
    
    // Export/Import
    @State private var showingExportActivity = false
    @State private var exportFileURL: URL?
    @State private var showingImportPicker = false
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingExportSuccess = false

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
                    HStack(spacing: CSpace.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(CColor.strength)
                        Text("Profile saved successfully")
                            .font(CFont.caption1)
                            .foregroundStyle(CColor.strength)
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
                    HStack(spacing: CSpace.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(CColor.strength)
                        Text("Credentials saved successfully")
                            .font(CFont.caption1)
                            .foregroundStyle(CColor.strength)
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
                    HStack(spacing: CSpace.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(CColor.strength)
                        Text("Sample data loaded successfully")
                            .font(CFont.caption1)
                            .foregroundStyle(CColor.strength)
                    }
                    .transition(.opacity)
                }
                
                // Team Management
                Button {
                    showingTeamManagement = true
                } label: {
                    Label("Manage Team", systemImage: "person.crop.circle.badge.minus")
                }
                
                // Cleanup Problem Solving tags (temporary migration button)
                Button(role: .destructive) {
                    cleanupProblemSolvingTags()
                } label: {
                    Label("Cleanup Problem Solving Tags", systemImage: "trash")
                }
                
                // Cleanup technical categories (temporary migration button)
                Button(role: .destructive) {
                    cleanupTechnicalCategoriesMigration()
                } label: {
                    Label("Cleanup Technical Categories", systemImage: "wrench.and.screwdriver")
                }
                
                Button {
                    exportData()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                if showingExportSuccess {
                    HStack(spacing: CSpace.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(CColor.strength)
                        Text("Data exported successfully")
                            .font(CFont.caption1)
                            .foregroundStyle(CColor.strength)
                    }
                    .transition(.opacity)
                }

                Button {
                    showingImportPicker = true
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
        .fileExporter(
            isPresented: $showingExportActivity,
            document: exportFileURL != nil ? CatalyzeDocument(fileURL: exportFileURL!) : nil,
            contentType: .json,
            defaultFilename: generateExportFilename()
        ) { result in
            switch result {
            case .success(let url):
                print("Export successful: \(url)")
                withAnimation {
                    showingExportSuccess = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation {
                        showingExportSuccess = false
                    }
                }
            case .failure(let error):
                Logger.error(error, context: "Export file dialog")
                importErrorMessage = "Failed to export: \(error.localizedDescription)"
                showingImportError = true
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert("Import Successful", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been imported successfully.")
        }
        .alert("Import Failed", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
        }
    }

    // MARK: - Helpers --------------------------------------------------------
    
    private func generateExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateString = formatter.string(from: Date())
        return "Catalyze-Export-\(dateString).json"
    }

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
    
    // MARK: - Export/Import --------------------------------------------------
    
    private func cleanupProblemSolvingTags() {
        Logger.log("Starting cleanup of 'Problem Solving' tags", level: .info)
        
        let descriptor = FetchDescriptor<StrengthWeakness>(
            predicate: #Predicate { $0.category == "Problem Solving" }
        )
        
        do {
            let tags = try context.fetch(descriptor)
            Logger.log("Found \(tags.count) 'Problem Solving' tags to delete", level: .info)
            
            for tag in tags {
                context.delete(tag)
            }
            
            try context.save()
            Logger.log("Successfully deleted \(tags.count) 'Problem Solving' tags", level: .success)
            
            // Show success feedback
            withAnimation {
                showingSampleDataSuccess = true
            }
            
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation {
                    showingSampleDataSuccess = false
                }
            }
        } catch {
            Logger.error(error, context: "Cleanup Problem Solving tags")
            importErrorMessage = "Failed to cleanup tags: \(error.localizedDescription)"
            showingImportError = true
        }
    }
    
    private func cleanupTechnicalCategoriesMigration() {
        Logger.log("Starting technical categories cleanup", level: .info)
        
        var deletedCount = 0
        var renamedCount = 0
        
        do {
            // Delete "Language Mastery"
            let languageMasteryDescriptor = FetchDescriptor<StrengthWeakness>(
                predicate: #Predicate { $0.category == "Language Mastery" }
            )
            let languageMasteryTags = try context.fetch(languageMasteryDescriptor)
            for tag in languageMasteryTags {
                context.delete(tag)
                deletedCount += 1
            }
            
            // Delete "Security"
            let securityDescriptor = FetchDescriptor<StrengthWeakness>(
                predicate: #Predicate { $0.category == "Security" }
            )
            let securityTags = try context.fetch(securityDescriptor)
            for tag in securityTags {
                context.delete(tag)
                deletedCount += 1
            }
            
            // Rename "Debugging Logic" → "Debugging"
            let debuggingLogicDescriptor = FetchDescriptor<StrengthWeakness>(
                predicate: #Predicate { $0.category == "Debugging Logic" }
            )
            let debuggingLogicTags = try context.fetch(debuggingLogicDescriptor)
            for tag in debuggingLogicTags {
                tag.category = "Debugging"
                renamedCount += 1
            }
            
            try context.save()
            Logger.log("Technical cleanup complete: \(deletedCount) deleted, \(renamedCount) renamed", level: .success)
            
            // Show success feedback
            withAnimation {
                showingSampleDataSuccess = true
            }
            
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation {
                    showingSampleDataSuccess = false
                }
            }
        } catch {
            Logger.error(error, context: "Technical categories cleanup")
            importErrorMessage = "Failed to cleanup: \(error.localizedDescription)"
            showingImportError = true
        }
    }
    
    private func exportData() {
        Logger.log("Export data initiated", level: .info)
        do {
            // Fetch all team members
            let descriptor = FetchDescriptor<TeamMember>(sortBy: [SortDescriptor(\.name)])
            let members = try context.fetch(descriptor)
            Logger.log("Fetched \(members.count) members for export", level: .info)
            
            // Create exportable data structure
            let exportData = ExportData(
                version: "1.0.0",
                exportDate: Date(),
                emProfile: store.emProfile,
                members: members.map { member in
                    ExportMember(
                        id: member.id,
                        name: member.name,
                        role: member.role,
                        seniority: member.seniorityRaw,
                        photoUrl: member.photoUrl,
                        photoData: member.photoData,
                        mentorId: member.mentor?.id,
                        mentorName: member.mentorName,
                        externalMentees: member.externalMentees,
                        stack: (member.stack ?? []).map { entry in
                            ExportStackEntry(tag: entry.tagRaw, level: entry.levelRaw)
                        },
                        tags: (member.tags ?? []).map { tag in
                            ExportTag(
                                kind: tag.kindRaw,
                                category: tag.category,
                                intensity: tag.intensityRaw,
                                note: tag.note,
                                createdAt: tag.createdAt
                            )
                        },
                        observations: (member.observations ?? []).map { obs in
                            ExportObservation(
                                text: obs.text,
                                context: obs.contextRaw,
                                createdAt: obs.createdAt
                            )
                        },
                        createdAt: member.createdAt,
                        updatedAt: member.updatedAt
                    )
                }
            )
            
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)
            Logger.log("JSON encoded: \(jsonData.count) bytes", level: .success)
            
            // Write to temporary file with safe filename
            let tempDir = FileManager.default.temporaryDirectory
            let filename = generateExportFilename()
            let tempURL = tempDir.appendingPathComponent(filename)
            
            // Remove old file if exists
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            
            try jsonData.write(to: tempURL)
            Logger.log("File written to: \(tempURL.path)", level: .success)
            
            exportFileURL = tempURL
            showingExportActivity = true
            
        } catch {
            Logger.error(error, context: "Export data")
            importErrorMessage = "Failed to export: \(error.localizedDescription)"
            showingImportError = true
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else {
                throw NSError(
                    domain: "Catalyze",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No file selected"]
                )
            }
            
            Logger.log("Starting import from: \(selectedFile.lastPathComponent)", level: .info)
            
            // Start accessing security-scoped resource
            guard selectedFile.startAccessingSecurityScopedResource() else {
                throw NSError(
                    domain: "Catalyze",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to access file. Please try selecting the file again."]
                )
            }
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            
            // Read and decode JSON
            let jsonData = try Data(contentsOf: selectedFile)
            Logger.log("Read \(jsonData.count) bytes from file", level: .info)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importData = try decoder.decode(ExportData.self, from: jsonData)
            
            Logger.log("Decoded \(importData.members.count) members from export version \(importData.version)", level: .info)
            
            // Validate version compatibility
            if importData.version != "1.0.0" {
                Logger.log("Warning: Import version \(importData.version) may not be fully compatible", level: .warning)
            }
            
            // Import members
            var memberIdMap: [String: TeamMember] = [:]
            var importedCount = 0
            
            for exportMember in importData.members {
                // Check if member already exists
                let checkDescriptor = FetchDescriptor<TeamMember>(
                    predicate: #Predicate { $0.id == exportMember.id }
                )
                let existing = try context.fetch(checkDescriptor)
                
                if !existing.isEmpty {
                    Logger.log("Skipping duplicate member: \(exportMember.name)", level: .warning)
                    continue
                }
                
                let member = TeamMember(
                    id: exportMember.id,
                    name: exportMember.name,
                    role: exportMember.role,
                    seniority: Seniority(rawValue: exportMember.seniority) ?? .t2_1,
                    photoUrl: exportMember.photoUrl,
                    createdAt: exportMember.createdAt,
                    updatedAt: exportMember.updatedAt
                )
                member.photoData = exportMember.photoData
                member.mentorName = exportMember.mentorName
                member.externalMentees = exportMember.externalMentees
                
                // Import stack
                member.stack = exportMember.stack.map { entry in
                    let stackEntry = StackEntry(
                        tag: StackTag(rawValue: entry.tag) ?? .typescript,
                        level: StackProficiency(rawValue: entry.level) ?? .learning
                    )
                    stackEntry.member = member
                    context.insert(stackEntry)
                    return stackEntry
                }
                
                // Import tags
                member.tags = exportMember.tags.map { tag in
                    let strengthWeakness = StrengthWeakness(
                        kind: SWKind(rawValue: tag.kind) ?? .strength,
                        category: tag.category,
                        intensity: Intensity(rawValue: tag.intensity) ?? .emerging,
                        note: tag.note,
                        createdAt: tag.createdAt
                    )
                    strengthWeakness.member = member
                    context.insert(strengthWeakness)
                    return strengthWeakness
                }
                
                // Import observations
                member.observations = exportMember.observations.map { obs in
                    let observation = TeamObservation(
                        memberId: member.id,
                        text: obs.text,
                        context: ObservationContext(rawValue: obs.context) ?? .oneOnOne,
                        createdAt: obs.createdAt
                    )
                    observation.member = member
                    context.insert(observation)
                    return observation
                }
                
                context.insert(member)
                memberIdMap[member.id] = member
                importedCount += 1
            }
            
            // Set up mentor relationships (after all members are created)
            for exportMember in importData.members {
                if let mentorId = exportMember.mentorId,
                   let member = memberIdMap[exportMember.id],
                   let mentor = memberIdMap[mentorId] {
                    member.mentor = mentor
                }
            }
            
            // Import EM profile if included
            if let emProfile = importData.emProfile {
                store.setEMProfile(emProfile)
                Logger.log("EM Profile imported", level: .info)
            }
            
            // Save all changes
            try context.save()
            Logger.log("Import successful: \(importedCount) members imported", level: .success)
            
            showingImportSuccess = true
            
        } catch let decodingError as DecodingError {
            Logger.error(decodingError, context: "Import - JSON decoding")
            importErrorMessage = "Invalid file format. Please ensure you're importing a valid Catalyze export file."
            showingImportError = true
        } catch {
            Logger.error(error, context: "Import")
            importErrorMessage = "Failed to import data: \(error.localizedDescription)"
            showingImportError = true
        }
    }
}

// MARK: - Export/Import Data Structures -------------------------------------

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let emProfile: EMProfile?
    let members: [ExportMember]
}

struct ExportMember: Codable {
    let id: String
    let name: String
    let role: String
    let seniority: String
    let photoUrl: String?
    let photoData: Data?
    let mentorId: String?
    let mentorName: String?
    let externalMentees: [String]
    let stack: [ExportStackEntry]
    let tags: [ExportTag]
    let observations: [ExportObservation]
    let createdAt: Date
    let updatedAt: Date
}

struct ExportStackEntry: Codable {
    let tag: String
    let level: String
}

struct ExportTag: Codable {
    let kind: String
    let category: String
    let intensity: String
    let note: String?
    let createdAt: Date
}

struct ExportObservation: Codable {
    let text: String
    let context: String
    let createdAt: Date
}

// MARK: - File Document Wrapper ---------------------------------------------

struct CatalyzeDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let url = configuration.file.regularFileContents.flatMap({ data in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("temp-import.json")
            try? data.write(to: tempURL)
            return tempURL
        }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.fileURL = url
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try Data(contentsOf: fileURL)
        return FileWrapper(regularFileWithContents: data)
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
