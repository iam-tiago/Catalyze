//
//  TechnicalStackSection.swift
//  Catalyze
//
//  Technical stack section for the member detail page. Shows technology
//  proficiencies with the ability to add, edit, and remove entries.
//

import SwiftUI
import SwiftData

struct TechnicalStackSection: View {
    @Environment(\.modelContext) private var context
    
    let member: TeamMember

    @State private var showingAddStack = false
    @State private var stackToEdit: StackEntry? = nil
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with collapse button
            HStack {
                Button {
                    withAnimation(.smooth) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Label("Tech Stack", systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.headline)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    Button {
                        showingAddStack = true
                    } label: {
                        Label("Add Technology", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isExpanded {
                Divider()

            if (member.stack ?? []).isEmpty {
                Text("No technologies added yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(member.stack ?? []) { entry in
                        StackEntryRow(entry: entry, onTap: {
                            stackToEdit = entry
                        }, onDelete: {
                            deleteEntry(entry)
                        })
                    }
                }
            }
            }  // End if isExpanded
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingAddStack) {
            StackEntryForm(member: member, entryToEdit: nil)
        }
        .sheet(item: $stackToEdit) { entry in
            StackEntryForm(member: member, entryToEdit: entry)
        }
    }
    
    private func deleteEntry(_ entry: StackEntry) {
        context.delete(entry)
        try? context.save()
    }
}

// MARK: - Stack Entry Row ----------------------------------------------------

private struct StackEntryRow: View {
    let entry: StackEntry
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Technology name
            Text(entry.tag.rawValue)
                .font(.body.weight(.medium))
            
            Spacer()
            
            // Proficiency badge
            Text(entry.level.rawValue)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(proficiencyColor.opacity(0.15), in: Capsule())
                .foregroundStyle(proficiencyColor)
            
            // Delete button
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var proficiencyColor: Color {
        switch entry.level {
        case .learning: return .orange
        case .proficient: return .blue
        case .advanced: return .purple
        case .expert: return .green
        }
    }
}

// MARK: - Stack Entry Form ---------------------------------------------------

private struct StackEntryForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomStackTag.name) private var customTags: [CustomStackTag]
    
    let member: TeamMember
    let entryToEdit: StackEntry?
    
    @State private var selectedTagName: String
    @State private var selectedLevel: StackProficiency
    
    init(member: TeamMember, entryToEdit: StackEntry?) {
        self.member = member
        self.entryToEdit = entryToEdit
        
        _selectedTagName = State(initialValue: entryToEdit?.tagRaw ?? "")
        _selectedLevel = State(initialValue: entryToEdit?.level ?? .learning)
    }
    
    private var availableTagNames: [String] {
        let predefined = StackTag.allCases.map { $0.rawValue }
        let custom = customTags.filter { $0.isActive }.map { $0.name }
        let all = (predefined + custom).sorted()
        
        // When editing, allow current tag
        if isEditing {
            return all
        }
        
        // When adding, exclude already added tags
        let addedTags = Set((member.stack ?? []).map { $0.tagRaw })
        return all.filter { !addedTags.contains($0) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Technology") {
                    if isEditing {
                        HStack {
                            Text(selectedTagName)
                                .font(.body)
                            Spacer()
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Technology", selection: $selectedTagName) {
                            if selectedTagName.isEmpty {
                                Text("Select Technology")
                                    .tag("")
                            }
                            
                            ForEach(availableTagNames, id: \.self) { tagName in
                                Text(tagName)
                                    .tag(tagName)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Proficiency Level") {
                    ForEach(StackProficiency.allCases) { level in
                        Button {
                            selectedLevel = level
                        } label: {
                            HStack {
                                Text(level.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 3) {
                                    LevelIndicator(level: level)
                                    
                                    if selectedLevel == level {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(colorForLevel(level))
                                            .font(.body.weight(.semibold))
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    LevelDescription(level: selectedLevel)
                } header: {
                    Text("About This Level")
                }
            }
            .navigationTitle(isEditing ? "Edit Technology" : "Add Technology")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .disabled(!isEditing && selectedTagName.isEmpty)
                }
            }
        }
    }
    
    private var isEditing: Bool {
        entryToEdit != nil
    }
    
    private func colorForLevel(_ level: StackProficiency) -> Color {
        switch level {
        case .learning:   return .orange
        case .proficient: return .blue
        case .advanced:   return .purple
        case .expert:     return .green
        }
    }
    
    private func save() {
        if let existing = entryToEdit {
            // Update existing
            existing.level = selectedLevel
        } else {
            // Create new
            let newEntry = StackEntry(
                id: UUID().uuidString,
                tag: StackTag.swiftUI, // Dummy, will be overwritten
                level: selectedLevel
            )
            newEntry.tagRaw = selectedTagName
            newEntry.member = member
            context.insert(newEntry)
            
            // Add to member's stack array
            if member.stack == nil {
                member.stack = [newEntry]
            } else {
                member.stack?.append(newEntry)
            }
        }
        
        try? context.save()
        dismiss()
    }
}

// MARK: - Level Indicator ----------------------------------------------------

private struct LevelIndicator: View {
    let level: StackProficiency
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < levelDots ? colorForLevel : Color.secondary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var levelDots: Int {
        switch level {
        case .learning:   return 1
        case .proficient: return 2
        case .advanced:   return 3
        case .expert:     return 4
        }
    }
    
    private var colorForLevel: Color {
        switch level {
        case .learning:   return .orange
        case .proficient: return .blue
        case .advanced:   return .purple
        case .expert:     return .green
        }
    }
}

// MARK: - Level Description --------------------------------------------------

private struct LevelDescription: View {
    let level: StackProficiency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(colorForLevel)
                    .font(.title3)
                
                Text(level.rawValue)
                    .font(.headline)
                    .foregroundStyle(colorForLevel)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var iconName: String {
        switch level {
        case .learning:   return "leaf"
        case .proficient: return "checkmark.circle"
        case .advanced:   return "star.circle"
        case .expert:     return "crown"
        }
    }
    
    private var description: String {
        switch level {
        case .learning:
            return "Currently learning this technology. Can work on simple tasks with guidance."
        case .proficient:
            return "Comfortable with this technology. Can work independently on most tasks."
        case .advanced:
            return "Strong expertise. Can handle complex tasks and mentor others."
        case .expert:
            return "Deep mastery. Can architect solutions and is a go-to resource for the team."
        }
    }
    
    private var colorForLevel: Color {
        switch level {
        case .learning:   return .orange
        case .proficient: return .blue
        case .advanced:   return .purple
        case .expert:     return .green
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    let alice = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )
    
    let stackSwift = StackEntry(tag: .swiftUI, level: .expert)
    stackSwift.member = alice
    let stackTS = StackEntry(tag: .typescript, level: .proficient)
    stackTS.member = alice
    
    alice.stack = [stackSwift, stackTS]
    
    context.insert(alice)
    try? context.save()
    
    return ScrollView {
        TechnicalStackSection(member: alice)
            .padding()
    }
    .modelContainer(container)
}
