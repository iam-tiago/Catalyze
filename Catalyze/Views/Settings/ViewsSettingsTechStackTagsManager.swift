//
//  TechStackTagsManager.swift
//  Catalyze
//
//  View para gerenciar tecnologias. Permite adicionar tecnologias customizadas
//  e desativar/ativar tanto predefinidas quanto customizadas.
//

import SwiftUI
import SwiftData

struct TechStackTagsManager: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomStackTag.name) private var customTags: [CustomStackTag]
    
    @AppStorage("disabledPredefinedTags") private var disabledPredefinedTagsRaw: String = ""
    
    @State private var showingAddSheet = false
    @State private var editingTag: CustomStackTag?
    
    private var disabledPredefinedTags: Set<String> {
        Set(disabledPredefinedTagsRaw.split(separator: ",").map { String($0) })
    }
    
    var body: some View {
        List {
            // Predefined tags (can be disabled)
            Section {
                ForEach(StackTag.allCases) { tag in
                    let isActive = !disabledPredefinedTags.contains(tag.rawValue)
                    
                    HStack {
                        Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isActive ? .green : .secondary)
                            .font(.body)
                        
                        Text(tag.rawValue)
                            .font(.body)
                            .foregroundStyle(isActive ? .primary : .secondary)
                        
                        Spacer()
                        
                        if !isActive {
                            Text("Disabled")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2), in: Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                    .swipeActions(edge: .leading) {
                        Button {
                            togglePredefinedTag(tag.rawValue)
                        } label: {
                            Label(
                                isActive ? "Disable" : "Enable",
                                systemImage: isActive ? "eye.slash" : "eye"
                            )
                        }
                        .tint(isActive ? .orange : .green)
                    }
                }
            } header: {
                Text("Predefined Technologies")
            } footer: {
                Text("Built-in technologies. Swipe left to disable/enable.")
            }
            
            // Custom tags (editable)
            Section {
                if customTags.isEmpty {
                    ContentUnavailableView {
                        Label("No Custom Technologies", systemImage: "tag")
                    } description: {
                        Text("Add technologies specific to your team")
                    }
                } else {
                    ForEach(customTags) { tag in
                        CustomTagRow(tag: tag)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingTag = tag
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTag(tag)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleActive(tag)
                                } label: {
                                    Label(
                                        tag.isActive ? "Disable" : "Enable",
                                        systemImage: tag.isActive ? "eye.slash" : "eye"
                                    )
                                }
                                .tint(tag.isActive ? .orange : .green)
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Custom Technologies")
                    Spacer()
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                }
            } footer: {
                Text("Custom technologies specific to your team. Swipe left to disable/enable or delete.")
            }
        }
        .navigationTitle("Tech Stack Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCustomTagSheet()
        }
        .sheet(item: $editingTag) { tag in
            EditCustomTagSheet(tag: tag)
        }
    }
    
    private func togglePredefinedTag(_ tagName: String) {
        var disabled = disabledPredefinedTags
        if disabled.contains(tagName) {
            disabled.remove(tagName)
        } else {
            disabled.insert(tagName)
        }
        disabledPredefinedTagsRaw = disabled.sorted().joined(separator: ",")
    }
    
    private func deleteTag(_ tag: CustomStackTag) {
        withAnimation {
            modelContext.delete(tag)
            try? modelContext.save()
        }
    }
    
    private func toggleActive(_ tag: CustomStackTag) {
        withAnimation {
            tag.isActive.toggle()
            try? modelContext.save()
        }
    }
}

// MARK: - Custom Tag Row -----------------------------------------------------

private struct CustomTagRow: View {
    let tag: CustomStackTag
    
    var body: some View {
        HStack {
            Image(systemName: tag.isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(tag.isActive ? .blue : .secondary)
                .font(.body)
            
            Text(tag.name)
                .font(.body)
                .foregroundStyle(tag.isActive ? .primary : .secondary)
            
            Spacer()
            
            if !tag.isActive {
                Text("Inactive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2), in: Capsule())
            }
        }
    }
}

// MARK: - Add Custom Tag Sheet -----------------------------------------------

private struct AddCustomTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomStackTag.name) private var existingCustomTags: [CustomStackTag]
    
    @State private var tagName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var allExistingNames: Set<String> {
        let predefined = Set(StackTag.allCases.map { $0.rawValue.lowercased() })
        let custom = Set(existingCustomTags.map { $0.name.lowercased() })
        return predefined.union(custom)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Technology name", text: $tagName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                } footer: {
                    Text("Enter a unique name for this technology (e.g., \"Python\", \"PostgreSQL\", \"Rust\")")
                }
                
                if showingError {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
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
                        addTag()
                    }
                    .disabled(tagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addTag() {
        let trimmed = tagName.trimmingCharacters(in: .whitespaces)
        
        // Validação
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a technology name"
            showingError = true
            return
        }
        
        guard !allExistingNames.contains(trimmed.lowercased()) else {
            errorMessage = "This technology already exists"
            showingError = true
            return
        }
        
        // Criar tag
        let newTag = CustomStackTag(name: trimmed)
        modelContext.insert(newTag)
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Edit Custom Tag Sheet ----------------------------------------------

private struct EditCustomTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomStackTag.name) private var allCustomTags: [CustomStackTag]
    
    let tag: CustomStackTag
    
    @State private var tagName: String
    @State private var isActive: Bool
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(tag: CustomStackTag) {
        self.tag = tag
        _tagName = State(initialValue: tag.name)
        _isActive = State(initialValue: tag.isActive)
    }
    
    private var allExistingNames: Set<String> {
        let predefined = Set(StackTag.allCases.map { $0.rawValue.lowercased() })
        let custom = Set(allCustomTags.filter { $0.id != tag.id }.map { $0.name.lowercased() })
        return predefined.union(custom)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Technology name", text: $tagName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                }
                
                Section {
                    Toggle("Active", isOn: $isActive)
                } footer: {
                    Text("Inactive technologies won't appear in pickers but existing data is preserved")
                }
                
                if showingError {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
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
                    .disabled(tagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        let trimmed = tagName.trimmingCharacters(in: .whitespaces)
        
        // Validação
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a technology name"
            showingError = true
            return
        }
        
        guard !allExistingNames.contains(trimmed.lowercased()) else {
            errorMessage = "This technology already exists"
            showingError = true
            return
        }
        
        // Atualizar
        tag.name = trimmed
        tag.isActive = isActive
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    let tag1 = CustomStackTag(name: "Python")
    let tag2 = CustomStackTag(name: "PostgreSQL")
    let tag3 = CustomStackTag(name: "Rust", isActive: false)
    
    context.insert(tag1)
    context.insert(tag2)
    context.insert(tag3)
    try? context.save()
    
    return NavigationStack {
        TechStackTagsManager()
    }
    .modelContainer(container)
}
