//
//  SeniorityConfigView.swift
//  Catalyze
//
//  Configuration screen for customizable seniority levels.
//  Allows users to select presets or create custom career ladders.
//

import SwiftUI
import SwiftData

struct SeniorityConfigView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query private var configs: [OrganizationConfig]
    
    @State private var selectedPreset: SeniorityPreset = .tLevel
    @State private var customLevels: [SeniorityLevelData] = []
    @State private var showingAddLevel = false
    @State private var showingEditLevel: SeniorityLevelData? = nil
    @State private var hasUnsavedChanges = false
    
    var currentConfig: OrganizationConfig? {
        configs.first
    }
    
    var displayedLevels: [SeniorityLevelData] {
        if selectedPreset == .custom {
            return customLevels.sorted { $0.order < $1.order }
        } else {
            return selectedPreset.levels
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                presetSection
                levelsSection
                descriptionSection
            }
            .navigationTitle("Seniority Levels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .disabled(!hasUnsavedChanges)
                }
            }
            .sheet(isPresented: $showingAddLevel) {
                SeniorityLevelFormView(
                    levelData: nil,
                    onSave: { newLevel in
                        customLevels.append(newLevel)
                        hasUnsavedChanges = true
                    }
                )
            }
            .sheet(item: $showingEditLevel) { level in
                SeniorityLevelFormView(
                    levelData: level,
                    onSave: { updatedLevel in
                        if let index = customLevels.firstIndex(where: { $0.id == updatedLevel.id }) {
                            customLevels[index] = updatedLevel
                            hasUnsavedChanges = true
                        }
                    }
                )
            }
        }
        .onAppear {
            loadCurrentConfiguration()
        }
    }
    
    // MARK: - Sections
    
    private var presetSection: some View {
        Section {
            Picker("Seniority System", selection: $selectedPreset) {
                ForEach(SeniorityPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedPreset) { _, newValue in
                presetChanged(to: newValue)
            }
        } header: {
            Text("System Type")
        }
    }
    
    private var levelsSection: some View {
        Section {
            ForEach(displayedLevels) { level in
                SeniorityLevelRow(
                    code: level.code,
                    displayName: level.displayName,
                    category: level.category,
                    color: Color(hex: level.colorHex),
                    isEditable: selectedPreset == .custom,
                    onEdit: selectedPreset == .custom ? {
                        showingEditLevel = level
                    } : nil,
                    onDelete: selectedPreset == .custom ? {
                        deleteLevel(level)
                    } : nil
                )
            }
            
            if selectedPreset == .custom {
                Button {
                    showingAddLevel = true
                } label: {
                    Label("Add Level", systemImage: "plus.circle.fill")
                        .foregroundStyle(CColor.brandPrimary)
                }
            }
        } header: {
            HStack {
                Text("Levels")
                Spacer()
                Text("\(displayedLevels.count) levels")
                    .font(CFont.caption1)
                    .foregroundStyle(CColor.neutral600)
            }
        } footer: {
            if selectedPreset == .custom {
                Text("Create your own career ladder by adding custom levels.")
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            Text(selectedPreset.description)
                .font(CFont.callout)
                .foregroundStyle(CColor.neutral700)
        } header: {
            Text("About This System")
        }
    }
    
    // MARK: - Actions
    
    private func loadCurrentConfiguration() {
        if let config = currentConfig {
            selectedPreset = config.seniorityPreset
            
            if selectedPreset == .custom {
                customLevels = config.activeLevels.map { level in
                    SeniorityLevelData(
                        id: level.id,
                        code: level.code,
                        displayName: level.displayName,
                        order: level.order,
                        colorHex: level.colorHex,
                        category: level.category,
                        levelDescription: level.levelDescription
                    )
                }
            }
        } else {
            // First time setup - use T-Level as default
            selectedPreset = .tLevel
        }
    }
    
    private func presetChanged(to preset: SeniorityPreset) {
        if preset == .custom {
            // Initialize custom levels from current preset if empty
            if customLevels.isEmpty {
                customLevels = SeniorityPreset.tLevel.levels
            }
        }
        hasUnsavedChanges = true
    }
    
    private func deleteLevel(_ level: SeniorityLevelData) {
        customLevels.removeAll { $0.id == level.id }
        hasUnsavedChanges = true
    }
    
    private func saveConfiguration() {
        let config: OrganizationConfig
        
        if let existingConfig = currentConfig {
            config = existingConfig
        } else {
            config = OrganizationConfig()
            context.insert(config)
        }
        
        // Update preset
        config.seniorityPreset = selectedPreset
        
        // Clear existing levels
        config.seniorityLevels?.forEach { context.delete($0) }
        config.seniorityLevels = []
        
        // Insert new levels
        let levelsToSave = selectedPreset == .custom ? customLevels : selectedPreset.levels
        
        for levelData in levelsToSave {
            let level = levelData.toModel()
            level.organization = config
            context.insert(level)
        }
        
        config.updatedAt = Date()
        
        // Save context
        do {
            try context.save()
            hasUnsavedChanges = false
            dismiss()
        } catch {
            print("❌ Error saving seniority configuration: \(error)")
        }
    }
}

// MARK: - Level Form View

struct SeniorityLevelFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    let levelData: SeniorityLevelData?
    let onSave: (SeniorityLevelData) -> Void
    
    @State private var code: String = ""
    @State private var displayName: String = ""
    @State private var category: String = "IC"
    @State private var order: Int = 10
    @State private var colorHex: String = "#3B82F6"
    @State private var levelDescription: String = ""
    
    private let categories = ["IC", "Senior", "Staff", "Leadership", "Management"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Code", text: $code, prompt: Text("e.g., T2-1, Senior, L5"))
                    TextField("Display Name", text: $displayName, prompt: Text("e.g., Senior Engineer II"))
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Order & Color") {
                    Stepper("Order: \(order)", value: $order, in: 0...100, step: 5)
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 24, height: 24)
                    }
                    
                    // Color presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: CSpace.sm) {
                            ForEach(colorPresets, id: \.self) { color in
                                Button {
                                    colorHex = color
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            if colorHex == color {
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: 2)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, CSpace.xs)
                    }
                }
                
                Section("Description (Optional)") {
                    TextEditor(text: $levelDescription)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(levelData == nil ? "Add Level" : "Edit Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLevel()
                    }
                    .disabled(code.isEmpty || displayName.isEmpty)
                }
            }
        }
        .onAppear {
            if let levelData {
                code = levelData.code
                displayName = levelData.displayName
                category = levelData.category
                order = levelData.order
                colorHex = levelData.colorHex
                levelDescription = levelData.levelDescription ?? ""
            }
        }
    }
    
    private let colorPresets = [
        "#10B981", "#14B8A6", "#06B6D4", "#3B82F6", "#6366F1",
        "#8B5CF6", "#A855F7", "#D946EF", "#EC4899", "#F43F5E",
        "#EF4444", "#F97316", "#F59E0B", "#EAB308", "#84CC16",
        "#94A3B8", "#64748B", "#475569", "#334155", "#1E293B"
    ]
    
    private func saveLevel() {
        let newLevel = SeniorityLevelData(
            id: levelData?.id ?? UUID().uuidString,
            code: code,
            displayName: displayName,
            order: order,
            colorHex: colorHex,
            category: category,
            levelDescription: levelDescription.isEmpty ? nil : levelDescription
        )
        
        onSave(newLevel)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Seniority Config") {
    SeniorityConfigView()
        .modelContainer(for: [OrganizationConfig.self, SeniorityLevel.self])
}

#Preview("Level Form - New") {
    SeniorityLevelFormView(levelData: nil) { _ in }
}

#Preview("Level Form - Edit") {
    SeniorityLevelFormView(
        levelData: SeniorityLevelData(
            code: "T3-1",
            displayName: "Staff Engineer I",
            order: 50,
            colorHex: "#7C3AED",
            category: "Staff"
        )
    ) { _ in }
}
