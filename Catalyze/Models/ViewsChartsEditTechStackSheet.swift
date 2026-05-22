//
//  EditTechStackSheet.swift
//  Catalyze
//
//  Sheet para editar o tech stack de um membro: adicionar, editar e deletar
//  tecnologias e seus níveis de proficiência.
//

import SwiftUI
import SwiftData

struct EditTechStackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let member: TeamMember
    
    @State private var showingAddSheet = false
    @State private var editingEntry: StackEntry?
    
    // Tecnologias já adicionadas (para não permitir duplicatas)
    private var addedTags: Set<StackTag> {
        Set((member.stack ?? []).map { $0.tag })
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let stack = member.stack, !stack.isEmpty {
                    List {
                        ForEach(stack.sorted(by: { $0.tag.rawValue < $1.tag.rawValue })) { entry in
                            TechStackEntryRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingEntry = entry
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Technologies", systemImage: "chevron.left.forwardslash.chevron.right")
                    } description: {
                        Text("Add technologies to track proficiency levels")
                    }
                }
            }
            .navigationTitle("Tech Stack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(addedTags.count >= StackTag.allCases.count)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTechStackEntrySheet(member: member, excludedTags: addedTags)
            }
            .sheet(item: $editingEntry) { entry in
                EditTechStackEntrySheet(entry: entry)
            }
        }
    }
    
    private func deleteEntry(_ entry: StackEntry) {
        withAnimation {
            modelContext.delete(entry)
            member.stack?.removeAll { $0.id == entry.id }
            try? modelContext.save()
        }
    }
}

// MARK: - Tech Stack Entry Row ----------------------------------------------

private struct TechStackEntryRow: View {
    let entry: StackEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Tech icon/badge
            ZStack {
                Circle()
                    .fill(colorForLevel.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(colorForLevel)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.tag.rawValue)
                    .font(.body.weight(.medium))
                
                Text(entry.level.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Visual indicator
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < levelDots ? colorForLevel : Color.secondary.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var levelDots: Int {
        switch entry.level {
        case .learning:   return 1
        case .proficient: return 2
        case .advanced:   return 3
        case .expert:     return 4
        }
    }
    
    private var colorForLevel: Color {
        switch entry.level {
        case .learning:   return .orange
        case .proficient: return .blue
        case .advanced:   return .purple
        case .expert:     return .green
        }
    }
}

// MARK: - Add Tech Stack Entry Sheet -----------------------------------------

private struct AddTechStackEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let member: TeamMember
    let excludedTags: Set<StackTag>
    
    @State private var selectedTag: StackTag?
    @State private var selectedLevel: StackProficiency = .learning
    
    private var availableTags: [StackTag] {
        StackTag.allCases.filter { !excludedTags.contains($0) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Technology") {
                    Picker("Technology", selection: $selectedTag) {
                        Text("Select a technology")
                            .tag(nil as StackTag?)
                        
                        ForEach(availableTags) { tag in
                            Text(tag.rawValue)
                                .tag(tag as StackTag?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Proficiency Level") {
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(StackProficiency.allCases) { level in
                            HStack {
                                Text(level.rawValue)
                                Spacer()
                                LevelIndicator(level: level)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section {
                    LevelDescription(level: selectedLevel)
                } header: {
                    Text("About This Level")
                }
            }
            .navigationTitle("Add Technology")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addEntry()
                    }
                    .disabled(selectedTag == nil)
                }
            }
        }
    }
    
    private func addEntry() {
        guard let tag = selectedTag else { return }
        
        let entry = StackEntry(tag: tag, level: selectedLevel)
        entry.member = member
        
        modelContext.insert(entry)
        
        if member.stack == nil {
            member.stack = []
        }
        member.stack?.append(entry)
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Edit Tech Stack Entry Sheet ----------------------------------------

private struct EditTechStackEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entry: StackEntry
    
    @State private var selectedLevel: StackProficiency
    
    init(entry: StackEntry) {
        self.entry = entry
        _selectedLevel = State(initialValue: entry.level)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Technology") {
                    HStack {
                        Text(entry.tag.rawValue)
                            .font(.body)
                        Spacer()
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Proficiency Level") {
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(StackProficiency.allCases) { level in
                            HStack {
                                Text(level.rawValue)
                                Spacer()
                                LevelIndicator(level: level)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section {
                    LevelDescription(level: selectedLevel)
                } header: {
                    Text("About This Level")
                }
            }
            .navigationTitle("Edit Technology")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(selectedLevel == entry.level)
                }
            }
        }
    }
    
    private func saveChanges() {
        entry.level = selectedLevel
        try? modelContext.save()
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

#Preview("Edit Tech Stack") {
    @Previewable @State var container: ModelContainer = {
        let container = try! PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        
        let alice = TeamMember(
            name: "Alice Chen",
            role: "Senior iOS Engineer",
            seniority: .t3_1
        )
        
        let stack1 = StackEntry(tag: .swiftUI, level: .expert)
        stack1.member = alice
        
        let stack2 = StackEntry(tag: .typescript, level: .proficient)
        stack2.member = alice
        
        alice.stack = [stack1, stack2]
        
        context.insert(alice)
        try? context.save()
        
        return container
    }()
    
    let context = ModelContext(container)
    let alice = try! context.fetch(FetchDescriptor<TeamMember>()).first!
    
    return EditTechStackSheet(member: alice)
        .modelContainer(container)
}

#Preview("Add Entry") {
    @Previewable @State var container: ModelContainer = {
        let container = try! PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        
        let alice = TeamMember(
            name: "Alice Chen",
            role: "Senior iOS Engineer",
            seniority: .t3_1
        )
        
        context.insert(alice)
        try? context.save()
        
        return container
    }()
    
    let context = ModelContext(container)
    let alice = try! context.fetch(FetchDescriptor<TeamMember>()).first!
    
    return AddTechStackEntrySheet(member: alice, excludedTags: [])
        .modelContainer(container)
}
