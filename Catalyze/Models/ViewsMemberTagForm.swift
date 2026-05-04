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
                        ForEach(TagCategory.predefined, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }

                        Text("Custom…").tag("__custom__")
                    }
                    .pickerStyle(.menu)

                    if category == "__custom__" {
                        TextField("Custom category", text: $customCategory)
                            .textInputAutocapitalization(.words)
                    }
                }

                // Intensity section
                Section("Intensity") {
                    Picker("Intensity", selection: $intensity) {
                        ForEach(validIntensities, id: \.self) { level in
                            HStack {
                                // Visual indicator
                                HStack(spacing: 2) {
                                    ForEach(0..<dotCount(for: level), id: \.self) { _ in
                                        Circle()
                                            .fill(kind == .strength ? Color.green : Color.orange)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .frame(width: 30, alignment: .leading)

                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
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
        switch intensity {
        case .emerging:   return 1
        case .solid, .developing:      return 2
        case .strong, .blocking:     return 3
        }
    }

    private func loadInitialData() {
        guard let tag = tagToEdit else {
            // New tag — set default intensity for the kind
            intensity = kind == .strength ? .emerging : .emerging
            return
        }

        // Editing existing tag
        if TagCategory.predefined.contains(tag.category) {
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
