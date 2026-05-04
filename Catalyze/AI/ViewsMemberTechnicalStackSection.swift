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
    
    let member: TeamMember
    let entryToEdit: StackEntry?
    
    @State private var selectedTag: StackTag
    @State private var selectedLevel: StackProficiency
    
    init(member: TeamMember, entryToEdit: StackEntry?) {
        self.member = member
        self.entryToEdit = entryToEdit
        
        _selectedTag = State(initialValue: entryToEdit?.tag ?? .swiftUI)
        _selectedLevel = State(initialValue: entryToEdit?.level ?? .learning)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Technology") {
                    Picker("Select Technology", selection: $selectedTag) {
                        ForEach(StackTag.allCases) { tag in
                            Text(tag.rawValue).tag(tag)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Proficiency Level") {
                    Picker("Select Level", selection: $selectedLevel) {
                        ForEach(StackProficiency.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(StackProficiency.allCases) { level in
                            HStack {
                                Text(level.rawValue)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(levelDescription(level))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Level Descriptions")
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
                }
            }
        }
    }
    
    private var isEditing: Bool {
        entryToEdit != nil
    }
    
    private func levelDescription(_ level: StackProficiency) -> String {
        switch level {
        case .learning: return "Actively learning and practicing"
        case .proficient: return "Comfortable working independently"
        case .advanced: return "Deep knowledge and experience"
        case .expert: return "Authority, can mentor others"
        }
    }
    
    private func save() {
        if let existing = entryToEdit {
            // Update existing
            existing.tag = selectedTag
            existing.level = selectedLevel
        } else {
            // Create new
            let newEntry = StackEntry(tag: selectedTag, level: selectedLevel)
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
