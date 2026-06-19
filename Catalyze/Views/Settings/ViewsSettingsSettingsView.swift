//
//  SettingsView.swift
//  Catalyze
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI

// MARK: - SettingsSection

enum SettingsSection: String, CaseIterable, Identifiable {
    case profile      = "profile"
    case ai           = "ai"
    case organization = "organization"
    case data         = "data"
    case appearance   = "appearance"
    case about        = "about"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile:      return "Your Profile"
        case .ai:           return "AI & API"
        case .organization: return "Organization"
        case .data:         return "Data"
        case .appearance:   return "Appearance"
        case .about:        return "About"
        }
    }

    var icon: String {
        switch self {
        case .profile:      return "person.crop.circle.fill"
        case .ai:           return "key.fill"
        case .organization: return "chart.bar.fill"
        case .data:         return "externaldrive.fill"
        case .appearance:   return "paintbrush.fill"
        case .about:        return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .profile:      return .blue
        case .ai:           return .purple
        case .organization: return .orange
        case .data:         return .green
        case .appearance:   return .pink
        case .about:        return .gray
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @State private var selectedSection: SettingsSection = .profile

    // File I/O state (top-level — needed by fileExporter/fileImporter modifiers)
    @State private var showingExportActivity = false
    @State private var exportFileURL: URL?
    @State private var showingImportPicker = false
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingExportSuccess = false

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selectedSection: $selectedSection)
            Divider()
            settingsContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle(selectedSection.title)
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showingExportActivity,
            document: exportFileURL != nil ? CatalyzeDocument(fileURL: exportFileURL!) : nil,
            contentType: .json,
            defaultFilename: generateExportFilename()
        ) { result in
            switch result {
            case .success:
                withAnimation { showingExportSuccess = true }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { showingExportSuccess = false }
                }
            case .failure(let error):
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

    @ViewBuilder
    private var settingsContent: some View {
        switch selectedSection {
        case .profile:
            ProfileSettingsSection()
        case .ai:
            AISettingsSection()
        case .organization:
            OrganizationSettingsSection()
        case .data:
            DataSettingsSection(
                onExport: exportData,
                onImport: { showingImportPicker = true },
                exportSuccess: showingExportSuccess
            )
        case .appearance:
            AppearanceSettingsSection()
        case .about:
            AboutSettingsSection()
        }
    }

    // MARK: - Export

    private func generateExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "Catalyze-Export-\(formatter.string(from: Date())).json"
    }

    private func exportData() {
        do {
            let descriptor = FetchDescriptor<TeamMember>(sortBy: [SortDescriptor(\.name)])
            let members = try context.fetch(descriptor)

            let exportData = ExportData(
                version: "1.1.0",
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
                        stack: (member.stack ?? []).map {
                            ExportStackEntry(tag: $0.tagRaw, level: $0.levelRaw)
                        },
                        tags: (member.tags ?? []).map {
                            ExportTag(kind: $0.kindRaw, category: $0.category, intensity: $0.intensityRaw, note: $0.note, createdAt: $0.createdAt)
                        },
                        observations: (member.observations ?? []).sorted(by: { $0.createdAt < $1.createdAt }).map {
                            ExportObservation(text: $0.text, context: $0.contextRaw, createdAt: $0.createdAt)
                        },
                        idps: (member.idps ?? []).map { idp in
                            ExportIDP(
                                id: idp.id,
                                title: idp.title,
                                objective: idp.objective,
                                linkedGrowthAreaId: idp.linkedGrowthAreaId,
                                targetDate: idp.targetDate,
                                status: idp.statusRaw,
                                actions: idp.sortedActions.map {
                                    ExportIDPAction(id: $0.id, text: $0.text, done: $0.done, sortIndex: $0.sortIndex)
                                },
                                createdAt: idp.createdAt,
                                updatedAt: idp.updatedAt
                            )
                        },
                        promotionRecords: (member.promotionRecords ?? []).map { record in
                            ExportPromotionRecord(
                                id: record.id,
                                targetTier: record.targetTierRaw,
                                status: record.statusRaw,
                                aiAssessment: record.aiAssessment,
                                notes: record.notes,
                                criteria: record.sortedCriteria.map {
                                    ExportPromotionCriterion(id: $0.id, category: $0.category, label: $0.label, met: $0.met, note: $0.note, isCustom: $0.isCustom, sortIndex: $0.sortIndex)
                                },
                                createdAt: record.createdAt,
                                updatedAt: record.updatedAt
                            )
                        },
                        profileEvents: (member.profileEvents ?? []).sorted(by: { $0.createdAt < $1.createdAt }).map {
                            ExportProfileEvent(type: $0.typeRaw, category: $0.category, intensityBefore: $0.intensityBeforeRaw, intensityAfter: $0.intensityAfterRaw, createdAt: $0.createdAt)
                        },
                        createdAt: member.createdAt,
                        updatedAt: member.updatedAt
                    )
                }
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(generateExportFilename())
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try jsonData.write(to: tempURL)

            exportFileURL = tempURL
            showingExportActivity = true
        } catch {
            importErrorMessage = "Failed to export: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    // MARK: - Import

    private func handleImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }
            guard selectedFile.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "Catalyze", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to access file."])
            }
            defer { selectedFile.stopAccessingSecurityScopedResource() }

            let jsonData = try Data(contentsOf: selectedFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importData = try decoder.decode(ExportData.self, from: jsonData)

            var memberIdMap: [String: TeamMember] = [:]

            for exportMember in importData.members {
                let checkDescriptor = FetchDescriptor<TeamMember>(predicate: #Predicate { $0.id == exportMember.id })
                if !(try context.fetch(checkDescriptor)).isEmpty { continue }

                let member = TeamMember(
                    id: exportMember.id,
                    name: exportMember.name,
                    role: exportMember.role,
                    seniority: Seniority(rawValue: exportMember.seniority) ?? .t2_1,
                    photoUrl: exportMember.photoUrl,
                    createdAt: exportMember.createdAt,
                    updatedAt: exportMember.updatedAt
                )
                member.seniorityRaw = exportMember.seniority  // preserve raw string for custom presets
                member.photoData = exportMember.photoData
                member.mentorName = exportMember.mentorName
                member.externalMentees = exportMember.externalMentees

                member.stack = exportMember.stack.map {
                    let e = StackEntry(tag: StackTag(rawValue: $0.tag) ?? .typescript, level: StackProficiency(rawValue: $0.level) ?? .learning)
                    e.member = member
                    context.insert(e)
                    return e
                }
                member.tags = exportMember.tags.map {
                    let t = StrengthWeakness(kind: SWKind(rawValue: $0.kind) ?? .strength, category: $0.category, intensity: Intensity(rawValue: $0.intensity) ?? .emerging, note: $0.note, createdAt: $0.createdAt)
                    t.member = member
                    context.insert(t)
                    return t
                }
                member.observations = exportMember.observations.map {
                    let o = TeamObservation(memberId: member.id, text: $0.text, context: ObservationContext(rawValue: $0.context) ?? .oneOnOne, createdAt: $0.createdAt)
                    o.member = member
                    context.insert(o)
                    return o
                }
                member.idps = exportMember.idps.map { exportIDP in
                    let idp = DevelopmentPlan(
                        id: exportIDP.id,
                        memberId: member.id,
                        title: exportIDP.title,
                        linkedGrowthAreaId: exportIDP.linkedGrowthAreaId,
                        objective: exportIDP.objective,
                        targetDate: exportIDP.targetDate,
                        status: IDPStatus(rawValue: exportIDP.status) ?? .active,
                        createdAt: exportIDP.createdAt,
                        updatedAt: exportIDP.updatedAt
                    )
                    idp.member = member
                    idp.actions = exportIDP.actions.map {
                        let action = IDPAction(id: $0.id, text: $0.text, done: $0.done, sortIndex: $0.sortIndex)
                        action.plan = idp
                        context.insert(action)
                        return action
                    }
                    context.insert(idp)
                    return idp
                }
                member.promotionRecords = exportMember.promotionRecords.map { exportRecord in
                    let record = PromotionReadiness(
                        id: exportRecord.id,
                        memberId: member.id,
                        targetTier: Seniority(rawValue: exportRecord.targetTier) ?? .t2_1,
                        status: PromotionStatus(rawValue: exportRecord.status) ?? .notReady,
                        aiAssessment: exportRecord.aiAssessment,
                        notes: exportRecord.notes,
                        createdAt: exportRecord.createdAt,
                        updatedAt: exportRecord.updatedAt
                    )
                    record.targetTierRaw = exportRecord.targetTier  // preserve raw string for custom presets
                    record.member = member
                    record.criteria = exportRecord.criteria.map {
                        let c = PromotionCriterion(id: $0.id, category: $0.category, label: $0.label, met: $0.met, note: $0.note, isCustom: $0.isCustom, sortIndex: $0.sortIndex)
                        c.record = record
                        context.insert(c)
                        return c
                    }
                    context.insert(record)
                    return record
                }
                member.profileEvents = exportMember.profileEvents.map {
                    let e = ProfileEvent(
                        memberId: member.id,
                        type: ProfileEventType(rawValue: $0.type) ?? .strengthAdded,
                        category: $0.category,
                        intensityBefore: $0.intensityBefore.flatMap { Intensity(rawValue: $0) },
                        intensityAfter: $0.intensityAfter.flatMap { Intensity(rawValue: $0) },
                        createdAt: $0.createdAt
                    )
                    e.member = member
                    context.insert(e)
                    return e
                }

                context.insert(member)
                memberIdMap[member.id] = member
            }

            for exportMember in importData.members {
                if let mentorId = exportMember.mentorId,
                   let member = memberIdMap[exportMember.id],
                   let mentor = memberIdMap[mentorId] {
                    member.mentor = mentor
                }
            }

            if let emProfile = importData.emProfile {
                store.setEMProfile(emProfile)
            }

            try context.save()
            showingImportSuccess = true
        } catch is DecodingError {
            importErrorMessage = "Invalid file format. Please ensure you're importing a valid Catalyze export file."
            showingImportError = true
        } catch {
            importErrorMessage = "Failed to import data: \(error.localizedDescription)"
            showingImportError = true
        }
    }
}

// MARK: - Sidebar

private struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(CFont.headline)
                    .foregroundStyle(CColor.neutral900)
                Spacer()
            }
            .padding(.horizontal, CSpace.lg)
            .padding(.vertical, CSpace.md)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(SettingsSection.allCases) { section in
                        SidebarRow(section: section, isSelected: selectedSection == section) {
                            selectedSection = section
                        }
                    }
                }
                .padding(CSpace.sm)
            }
        }
        .frame(width: 220)
        .background(CColor.neutral50)
    }
}

private struct SidebarRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CSpace.md) {
                Image(systemName: section.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(section.color)
                    .clipShape(RoundedRectangle(cornerRadius: CRadius.xs))

                Text(section.title)
                    .font(CFont.subheadline)
                    .foregroundStyle(CColor.neutral900)

                Spacer()
            }
            .padding(.horizontal, CSpace.sm)
            .padding(.vertical, CSpace.sm)
            .background(isSelected ? CColor.brandPrimaryLight : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: CRadius.sm))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Section

private enum PhotoSource { case library, url }

private struct ProfileSettingsSection: View {
    @Environment(AppStore.self) private var store

    @State private var name = ""
    @State private var role = ""
    @State private var teamName = ""
    @State private var photoUrl = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoSource: PhotoSource = .library
    @State private var showProfileSaved = false

    var body: some View {
        Form {
            // Avatar header — live preview
            Section {
                VStack(spacing: CSpace.sm) {
                    avatarView
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        Text(name.isEmpty ? "Your Name" : name)
                            .font(CFont.headline)
                            .foregroundStyle(CColor.neutral900)
                        if !role.isEmpty {
                            Text(role)
                                .font(CFont.subheadline)
                                .foregroundStyle(CColor.neutral600)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, CSpace.md)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }

            Section("Identity") {
                TextField("Name", text: $name)
                    .textContentType(.name)
                TextField("Role", text: $role)
                    .textContentType(.jobTitle)
                TextField("Team Name (optional)", text: $teamName)
            }

            Section("Photo") {
                Picker("Source", selection: $photoSource) {
                    Label("Library", systemImage: "photo.on.rectangle").tag(PhotoSource.library)
                    Label("URL", systemImage: "link").tag(PhotoSource.url)
                }
                .pickerStyle(.segmented)
                .onChange(of: photoSource) { _, new in
                    if new == .library { photoUrl = "" }
                    else { photoData = nil; photoItem = nil }
                }

                if photoSource == .library {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                } else {
                    TextField("Photo URL", text: $photoUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }

            Section {
                Button("Save Profile") { save() }
                    .buttonStyle(.borderedProminent)

                if showProfileSaved {
                    Label("Profile saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(CColor.strength)
                        .font(CFont.caption1)
                        .transition(.opacity)
                }
            }
        }
        .onAppear { load() }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .clipShape(Circle())
        } else {
            ZStack {
                Circle().fill(CColor.brandPrimaryLight)
                Text(name.prefix(1).uppercased().isEmpty ? "?" : name.prefix(1).uppercased())
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(CColor.brandPrimary)
            }
        }
    }

    private func load() {
        name     = store.emProfile.name
        role     = store.emProfile.role
        teamName = store.emProfile.teamName ?? ""
        photoUrl = store.emProfile.photoUrl ?? ""
        photoData = store.emProfile.photoData
        photoSource = (store.emProfile.photoData != nil) ? .library
                    : (store.emProfile.photoUrl != nil)  ? .url
                    : .library
    }

    private func save() {
        let profile = EMProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            role: role.trimmingCharacters(in: .whitespaces),
            teamName: teamName.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            photoUrl: photoUrl.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            photoData: photoData
        )
        store.setEMProfile(profile)
        withAnimation { showProfileSaved = true }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { showProfileSaved = false }
        }
    }
}

// MARK: - AI Section

private struct AISettingsSection: View {
    @Environment(AppStore.self) private var store

    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var testResultMessage = ""
    @State private var showingTestResult = false
    @State private var isTestingConnection = false
    @State private var showCredentialsSaved = false

    var body: some View {
        Form {
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
            } header: {
                Text("Claude API")
            } footer: {
                VStack(alignment: .leading, spacing: CSpace.xs) {
                    Text("Enter your Anthropic API key or a LiteLLM-compatible proxy endpoint.")
                    Text("Default: \(ClaudeClient.defaultBaseURL)")
                        .foregroundStyle(CColor.neutral400)
                }
                .font(CFont.caption2)
            }

            Section {
                Button {
                    Task { await testConnection() }
                } label: {
                    if isTestingConnection {
                        HStack(spacing: CSpace.sm) {
                            ProgressView().controlSize(.small)
                            Text("Testing...")
                        }
                    } else {
                        Label("Test Connection", systemImage: "network")
                    }
                }
                .disabled(apiKey.isEmpty || isTestingConnection)

                if showingTestResult {
                    Label(
                        testResultMessage,
                        systemImage: testResultMessage.contains("✓") ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .foregroundStyle(testResultMessage.contains("✓") ? CColor.strength : CColor.destructive)
                    .font(CFont.caption1)
                }

                Button("Save Credentials") { save() }
                    .buttonStyle(.borderedProminent)

                if showCredentialsSaved {
                    Label("Credentials saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(CColor.strength)
                        .font(CFont.caption1)
                        .transition(.opacity)
                }
            }
        }
        .onAppear { load() }
    }

    private func load() {
        apiKey  = store.apiKey
        baseURL = store.baseURL
    }

    private func save() {
        store.setApiKey(apiKey.trimmingCharacters(in: .whitespaces))
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespaces)
        store.setBaseURL(trimmedURL.isEmpty ? ClaudeClient.defaultBaseURL : trimmedURL)
        withAnimation { showCredentialsSaved = true }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { showCredentialsSaved = false }
        }
    }

    private func testConnection() async {
        isTestingConnection = true
        showingTestResult   = false
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespaces)
        let client = ClaudeClient(
            apiKey: apiKey.trimmingCharacters(in: .whitespaces),
            baseURL: trimmedURL.isEmpty ? ClaudeClient.defaultBaseURL : trimmedURL
        )
        do {
            _ = try await client.complete(
                messages: [ChatMessage(role: "user", content: "Hello")],
                maxTokens: 10
            ) { _ in }
            testResultMessage = "✓ Connection successful"
        } catch {
            testResultMessage = "✗ \(error.localizedDescription)"
        }
        showingTestResult   = true
        isTestingConnection = false
    }
}

// MARK: - Organization Section

private struct OrganizationSettingsSection: View {
    @Environment(\.seniorityService) private var seniorityService

    @State private var showingSeniorityConfig = false
    @State private var showingTagsManager     = false

    var body: some View {
        Form {
            Section {
                Button { showingSeniorityConfig = true } label: {
                    HStack {
                        Label("Seniority Levels", systemImage: "chart.bar.fill")
                        Spacer()
                        if let service = seniorityService {
                            Text(service.currentPreset.displayName)
                                .font(CFont.caption1)
                                .foregroundStyle(CColor.neutral600)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CColor.neutral400)
                    }
                }
                .buttonStyle(.plain)

                Button { showingTagsManager = true } label: {
                    HStack {
                        Label("Tech Stack Tags", systemImage: "tag.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CColor.neutral400)
                    }
                }
                .buttonStyle(.plain)
            } footer: {
                Text("Customize your team's career ladder and technology tags.")
            }
        }
        .sheet(isPresented: $showingSeniorityConfig) {
            NavigationStack { SeniorityConfigView() }
        }
        .sheet(isPresented: $showingTagsManager) {
            NavigationStack { TechStackTagsManager() }
        }
    }
}

// MARK: - Data Section

private struct DataSettingsSection: View {
    @Environment(\.modelContext) private var context
    @Environment(AppStore.self) private var store

    let onExport: () -> Void
    let onImport: () -> Void
    let exportSuccess: Bool

    @State private var showingSampleDataAlert   = false
    @State private var showingSampleDataSuccess = false
    @State private var showingTeamManagement    = false

    var body: some View {
        Form {
            Section("Transfer") {
                Button { onExport() } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }

                if exportSuccess {
                    Label("Data exported successfully", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(CColor.strength)
                        .font(CFont.caption1)
                }

                Button { onImport() } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            }

            Section("Team") {
                Button { showingTeamManagement = true } label: {
                    Label("Manage Team", systemImage: "person.crop.circle.badge.minus")
                }
            }

            Section {
                Button(role: .destructive) {
                    showingSampleDataAlert = true
                } label: {
                    Label("Reset to Demo Data", systemImage: "arrow.counterclockwise")
                }

                if showingSampleDataSuccess {
                    Label("10 demo members loaded successfully", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(CColor.strength)
                        .font(CFont.caption1)
                        .transition(.opacity)
                }
            } header: {
                Text("Reset")
            } footer: {
                Text("Replaces all existing team data with 10 demo members.")
            }
        }
        .alert("Reset to Demo Data?", isPresented: $showingSampleDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { resetData() }
        } message: {
            Text("This will delete all existing team data and replace it with 10 demo members across iOS, Android, Frontend, and Backend. This cannot be undone.")
        }
        .sheet(isPresented: $showingTeamManagement) {
            TeamManagementView()
        }
    }

    private func resetData() {
        let descriptor = FetchDescriptor<TeamMember>()
        if let existing = try? context.fetch(descriptor) {
            existing.forEach { context.delete($0) }
        }
        try? context.save()
        SampleDataProvider.populate(in: context)
        withAnimation { showingSampleDataSuccess = true }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { showingSampleDataSuccess = false }
        }
    }
}

// MARK: - Appearance Section

private struct AppearanceSettingsSection: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $appearanceMode) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Theme")
            } footer: {
                Text("System follows your device settings.")
            }
        }
    }
}

// MARK: - About Section

private struct AboutSettingsSection: View {
    var body: some View {
        Form {
            Section("About Catalyze") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
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
    }
}

// MARK: - String helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Export/Import Data Structures

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
    let idps: [ExportIDP]
    let promotionRecords: [ExportPromotionRecord]
    let profileEvents: [ExportProfileEvent]
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

struct ExportIDP: Codable {
    let id: String
    let title: String
    let objective: String
    let linkedGrowthAreaId: String?
    let targetDate: Date?
    let status: String
    let actions: [ExportIDPAction]
    let createdAt: Date
    let updatedAt: Date
}

struct ExportIDPAction: Codable {
    let id: String
    let text: String
    let done: Bool
    let sortIndex: Int
}

struct ExportPromotionRecord: Codable {
    let id: String
    let targetTier: String
    let status: String
    let aiAssessment: String?
    let notes: String?
    let criteria: [ExportPromotionCriterion]
    let createdAt: Date
    let updatedAt: Date
}

struct ExportPromotionCriterion: Codable {
    let id: String
    let category: String
    let label: String
    let met: Bool
    let note: String?
    let isCustom: Bool
    let sortIndex: Int
}

struct ExportProfileEvent: Codable {
    let type: String
    let category: String
    let intensityBefore: String?
    let intensityAfter: String?
    let createdAt: Date
}

// MARK: - File Document Wrapper

struct CatalyzeDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    init(configuration: ReadConfiguration) throws {
        guard let url = configuration.file.regularFileContents.flatMap({ data -> URL? in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp-import.json")
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

// MARK: - Team Management View

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
                        HStack(spacing: CSpace.lg) {
                            avatarView(for: member)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name).font(.headline)
                                Text(member.role).font(.subheadline).foregroundStyle(.secondary)
                                Text(member.seniority.label)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.tint.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.tint)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                memberToDelete = member
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash").foregroundStyle(.red)
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
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Member?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { memberToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let member = memberToDelete {
                        store.deleteMember(member, in: context)
                        memberToDelete = nil
                    }
                }
            } message: {
                if let member = memberToDelete {
                    Text("Are you sure you want to delete \(member.name)? All associated data will also be deleted.")
                }
            }
        }
    }

    @ViewBuilder
    private func avatarView(for member: TeamMember) -> some View {
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
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint.opacity(0.5))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppStore())
            .modelContainer(try! PersistenceController.makePreviewContainer())
    }
}
