//
//  TagForm.swift
//  Catalyze
//
//  Form for adding or editing a strength/weakness tag. Presented as a
//  sheet from the TagSection.
//
//  Equivalent to `src/components/TeamMembers/TagForm.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct TagForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let member: TeamMember
    let kind: SWKind
    let tagToEdit: StrengthWeakness?

    @State private var category = ""
    @State private var customCategory = ""
    @State private var intensity: Intensity = .emerging
    @State private var note = ""
    @State private var isCustomCategory = false

    var body: some View {
        NavigationStack {
            Form {
                // Category section
                Section("Category") {
                    Picker("Select category", selection: $category) {
                        ForEach(BehavioralCategory.all, id: \.self) { cat in
                            HStack {
                                Image(systemName: iconForBehavioralCategory(cat))
                                Text(cat)
                            }
                            .tag(cat)
                        }

                        Text("Custom…").tag("__custom__")
                    }
                    .pickerStyle(.menu)

                    if category == "__custom__" {
                        TextField("Custom category", text: $customCategory)
                            .textInputAutocapitalization(.words)
                    }
                    
                    // Category preview with icon (only for predefined categories)
                    if category != "__custom__" && !category.isEmpty {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(colorForIntensity(intensity, kind: kind).opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: iconForBehavioralCategory(category))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(colorForIntensity(intensity, kind: kind))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category)
                                    .font(.body.weight(.medium))
                                
                                Text(kind == .strength ? "Strength" : "Growth Area")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Intensity section
                Section("Intensity Level") {
                    ForEach(validIntensities, id: \.self) { level in
                        Button {
                            intensity = level
                        } label: {
                            HStack {
                                Text(level.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    // Dots indicator
                                    HStack(spacing: 3) {
                                        ForEach(0..<3, id: \.self) { index in
                                            Circle()
                                                .fill(index < dotCount(for: level) ? colorForIntensity(level, kind: kind) : Color.secondary.opacity(0.2))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    
                                    if intensity == level {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(colorForIntensity(level, kind: kind))
                                            .font(.body.weight(.semibold))
                                    }
                                }
                            }
                        }
                    }
                }
                
                // About This Level section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: iconForIntensity(intensity))
                                .foregroundStyle(colorForIntensity(intensity, kind: kind))
                                .font(.title3)
                            
                            Text(intensity.rawValue)
                                .font(.headline)
                                .foregroundStyle(colorForIntensity(intensity, kind: kind))
                        }
                        
                        Text(descriptionForIntensity(intensity, kind: kind))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("About This Level")
                }

                // Note section
                Section {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Note")
                } footer: {
                    Text("Add context or examples for this \(kind == .strength ? "strength" : "growth area").")
                }
            }
            .navigationTitle(isEditing ? "Edit \(titleSuffix)" : "New \(titleSuffix)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTag()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }

    // MARK: - Helpers --------------------------------------------------------

    private var isEditing: Bool {
        tagToEdit != nil
    }

    private var isValid: Bool {
        let finalCategory = category == "__custom__" ? customCategory : category
        return !finalCategory.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var titleSuffix: String {
        kind == .strength ? "Strength" : "Growth Area"
    }

    private var validIntensities: [Intensity] {
        kind == .strength ? Intensity.strengthCases : Intensity.weaknessCases
    }

    private func dotCount(for intensity: Intensity) -> Int {
        intensity.dotCount
    }
    
    private func iconForBehavioralCategory(_ category: String) -> String {
        BehavioralCategory.icon(for: category)
    }
    
    private func colorForIntensity(_ intensity: Intensity, kind: SWKind) -> Color {
        intensity.color(for: kind)
    }
    
    private func iconForIntensity(_ intensity: Intensity) -> String {
        intensity.icon
    }
    
    private func descriptionForIntensity(_ intensity: Intensity, kind: SWKind) -> String {
        if kind == .strength {
            switch intensity {
            case .emerging:
                return "Shows promise; occasional good examples"
            case .solid:
                return "Consistent; reliable in this area"
            case .strong:
                return "Outstanding; models excellence for others"
            default:
                return ""
            }
        } else {
            switch intensity {
            case .emerging:
                return "Early stage; needs active development"
            case .developing:
                return "Progressing but still affecting work quality"
            case .blocking:
                return "Critical gap; prevents higher-level responsibilities"
            default:
                return ""
            }
        }
    }

    private func loadInitialData() {
        guard let tag = tagToEdit else {
            // New tag — set default intensity for the kind
            intensity = kind == .strength ? .emerging : .emerging
            return
        }

        // Editing existing tag
        if BehavioralCategory.all.contains(tag.category) {
            category = tag.category
            isCustomCategory = false
        } else {
            category = "__custom__"
            customCategory = tag.category
            isCustomCategory = true
        }

        intensity = tag.intensity
        note = tag.note ?? ""
    }

    private func saveTag() {
        let finalCategory = (category == "__custom__" ? customCategory : category)
            .trimmingCharacters(in: .whitespaces)

        let finalNote = note.trimmingCharacters(in: .whitespaces)

        if let existing = tagToEdit {
            // Update existing
            existing.category = finalCategory
            existing.intensity = intensity
            existing.note = finalNote.isEmpty ? nil : finalNote
            try? context.save()
        } else {
            // Create new
            let newTag = StrengthWeakness(
                kind: kind,
                category: finalCategory,
                intensity: intensity,
                note: finalNote.isEmpty ? nil : finalNote
            )

            newTag.member = member
            context.insert(newTag)

            // Add to member's tags array
            if member.tags == nil {
                member.tags = []
            }
            member.tags?.append(newTag)

            try? context.save()
        }

        dismiss()
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("New Strength") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    context.insert(member)
    try? context.save()

    return TagForm(member: member, kind: .strength, tagToEdit: nil)
        .modelContainer(container)
}

#Preview("Edit Weakness") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    let weakness = StrengthWeakness(
        kind: .weakness,
        category: "Testing",
        intensity: .developing,
        note: "Needs to write more unit tests"
    )
    weakness.member = member
    member.tags = [weakness]

    context.insert(member)
    try? context.save()

    return TagForm(member: member, kind: .weakness, tagToEdit: weakness)
        .modelContainer(container)
}
