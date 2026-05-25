//
//  TechSkillsSection.swift
//  Catalyze
//
//  Tech skills section for the member detail page. Shows technical
//  strengths & growth areas (Language Mastery, Code Quality, Testing, etc.)
//  with the ability to add, edit, and remove entries.
//
//  This is separate from Tech Stack (frameworks/tools) and feeds into
//  the Tech Skills radar chart.
//

import SwiftUI
import SwiftData

struct TechSkillsSection: View {
    @Environment(\.modelContext) private var context
    
    let member: TeamMember

    @State private var showingAddStrength = false
    @State private var showingAddWeakness = false
    @State private var tagToEdit: StrengthWeakness? = nil
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with collapse button
            Button {
                withAnimation(.smooth) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Tech Skills", systemImage: "wrench.and.screwdriver.fill")
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
                Divider()

            // Technical strengths subsection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Technical Strengths")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    Button {
                        showingAddStrength = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }

                if techStrengths.isEmpty {
                    Text("No technical strengths added yet")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(techStrengths) { strength in
                            TechSkillRow(
                                tag: strength,
                                onTap: { tagToEdit = strength },
                                onDelete: { deleteTag(strength) }
                            )
                        }
                    }
                }
            }

            Divider()

            // Technical growth areas subsection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Technical Growth Areas")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    Button {
                        showingAddWeakness = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }

                if techWeaknesses.isEmpty {
                    Text("No technical growth areas added yet")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(techWeaknesses) { weakness in
                            TechSkillRow(
                                tag: weakness,
                                onTap: { tagToEdit = weakness },
                                onDelete: { deleteTag(weakness) }
                            )
                        }
                    }
                }
            }
            }  // End if isExpanded
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingAddStrength) {
            TechSkillForm(member: member, kind: .strength, tagToEdit: nil)
        }
        .sheet(isPresented: $showingAddWeakness) {
            TechSkillForm(member: member, kind: .weakness, tagToEdit: nil)
        }
        .sheet(item: $tagToEdit) { tag in
            TechSkillForm(member: member, kind: tag.kind, tagToEdit: tag)
        }
    }
    
    // Filter tags to only show technical categories
    private var techStrengths: [StrengthWeakness] {
        let technicalCategories = ["Language Mastery", "Code Quality", "Code Review", "Testing", "Architecture", "DevOps", "Debugging Logic", "Observability", "Security"]
        return member.strengths.filter { technicalCategories.contains($0.category) }
    }
    
    private var techWeaknesses: [StrengthWeakness] {
        let technicalCategories = ["Language Mastery", "Code Quality", "Code Review", "Testing", "Architecture", "DevOps", "Debugging Logic", "Observability", "Security"]
        return member.weaknesses.filter { technicalCategories.contains($0.category) }
    }
    
    private func deleteTag(_ tag: StrengthWeakness) {
        context.delete(tag)
        try? context.save()
    }
}

// MARK: - Tech Skill Row -----------------------------------------------------

private struct TechSkillRow: View {
    let tag: StrengthWeakness
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Intensity indicator (dots)
            HStack(spacing: 2) {
                ForEach(0..<intensityDotCount, id: \.self) { _ in
                    Circle()
                        .fill(colorForKind)
                        .frame(width: 6, height: 6)
                }
            }

            // Category label
            Text(tag.category)
                .font(.body.weight(.medium))

            Spacer()
            
            // Intensity badge
            Text(tag.intensity.rawValue)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(colorForKind.opacity(0.15), in: Capsule())
                .foregroundStyle(colorForKind)

            // Note indicator
            if tag.note != nil && !tag.note!.isEmpty {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
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
        .background(colorForKind.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var intensityDotCount: Int {
        switch tag.intensity {
        case .emerging:   return 1
        case .solid, .developing:      return 2
        case .strong, .blocking:     return 3
        }
    }

    private var colorForKind: Color {
        tag.kind == .strength ? .green : .orange
    }
}

// MARK: - Tech Skill Form ----------------------------------------------------

private struct TechSkillForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let member: TeamMember
    let kind: SWKind
    let tagToEdit: StrengthWeakness?
    
    @State private var selectedCategory: String
    @State private var selectedIntensity: Intensity
    @State private var note: String
    
    init(member: TeamMember, kind: SWKind, tagToEdit: StrengthWeakness?) {
        self.member = member
        self.kind = kind
        self.tagToEdit = tagToEdit
        
        let technicalCategories = ["Language Mastery", "Code Quality", "Code Review", "Testing", "Architecture", "DevOps", "Debugging Logic", "Observability", "Security"]
        _selectedCategory = State(initialValue: tagToEdit?.category ?? technicalCategories[0])
        _selectedIntensity = State(initialValue: tagToEdit?.intensity ?? .emerging)
        _note = State(initialValue: tagToEdit?.note ?? "")
    }
    
    private var technicalCategories: [String] {
        ["Language Mastery", "Code Quality", "Code Review", "Testing", "Architecture", "DevOps", "Debugging Logic", "Observability", "Security"]
    }
    
    private var validIntensities: [Intensity] {
        kind == .strength ? Intensity.strengthCases : Intensity.weaknessCases
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(technicalCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Intensity") {
                    Picker("Select Intensity", selection: $selectedIntensity) {
                        ForEach(validIntensities, id: \.self) { intensity in
                            Text(intensity.rawValue).tag(intensity)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit \(kind == .strength ? "Tech Strength" : "Tech Growth Area")" : "Add \(kind == .strength ? "Tech Strength" : "Tech Growth Area")")
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
        tagToEdit != nil
    }
    
    private func save() {
        if let existing = tagToEdit {
            // Update existing
            existing.category = selectedCategory
            existing.intensity = selectedIntensity
            existing.note = note.isEmpty ? nil : note
        } else {
            // Create new
            let newTag = StrengthWeakness(
                kind: kind,
                category: selectedCategory,
                intensity: selectedIntensity,
                note: note.isEmpty ? nil : note
            )
            newTag.member = member
            context.insert(newTag)
            
            // Add to member's tags array
            if member.tags == nil {
                member.tags = [newTag]
            } else {
                member.tags?.append(newTag)
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

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    let strength1 = StrengthWeakness(
        kind: .strength,
        category: "Code Quality",
        intensity: .strong,
        note: "Writes highly maintainable code"
    )
    strength1.member = member

    let strength2 = StrengthWeakness(
        kind: .strength,
        category: "Testing",
        intensity: .solid
    )
    strength2.member = member

    let weakness1 = StrengthWeakness(
        kind: .weakness,
        category: "DevOps",
        intensity: .developing
    )
    weakness1.member = member

    member.tags = [strength1, strength2, weakness1]

    context.insert(member)
    try? context.save()

    return ScrollView {
        TechSkillsSection(member: member)
            .padding()
    }
    .modelContainer(container)
}
