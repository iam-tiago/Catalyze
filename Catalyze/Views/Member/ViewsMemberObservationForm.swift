//
//  ObservationForm.swift
//  Catalyze
//
//  Form for adding or editing an observation. Presented as a sheet from
//  the ObservationSection.
//
//  Equivalent to `src/components/TeamMembers/ObservationForm.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct ObservationForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let member: TeamMember
    let observationToEdit: TeamObservation?

    @State private var text = ""
    @State private var context_: ObservationContext = .oneOnOne
    @State private var createdAt = Date()

    var body: some View {
        NavigationStack {
            Form {
                // Text section
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                } header: {
                    Text("Observation")
                } footer: {
                    Text("What did you observe about this team member's behavior, performance, or growth?")
                }

                // Context section
                Section("Context") {
                    Picker("Context", selection: $context_) {
                        ForEach(ObservationContext.allCases) { ctx in
                            HStack {
                                contextIcon(ctx)
                                Text(ctx.rawValue)
                            }
                            .tag(ctx)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Date section (only show when editing)
                if isEditing {
                    Section("Date") {
                        DatePicker(
                            "Created",
                            selection: $createdAt,
                            displayedComponents: [.date]
                        )
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Observation" : "New Observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveObservation()
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
        observationToEdit != nil
    }

    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func contextIcon(_ ctx: ObservationContext) -> some View {
        let iconName: String
        switch ctx {
        case .oneOnOne:         iconName = "person.2.fill"
        case .incident:         iconName = "exclamationmark.triangle.fill"
        case .sprintReview:     iconName = "clock.arrow.circlepath"
        case .performanceCycle: iconName = "chart.bar.fill"
        case .other:            iconName = "ellipsis.circle.fill"
        }

        return Image(systemName: iconName)
            .foregroundStyle(.secondary)
    }

    private func loadInitialData() {
        guard let obs = observationToEdit else { return }

        text = obs.text
        context_ = obs.context
        createdAt = obs.createdAt
    }

    private func saveObservation() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = observationToEdit {
            // Update existing
            existing.text = trimmedText
            existing.context = context_
            existing.createdAt = createdAt
            try? context.save()
        } else {
            // Create new
            let newObs = TeamObservation(
                memberId: member.id,
                text: trimmedText,
                context: context_
            )

            newObs.member = member
            context.insert(newObs)

            // Add to member's observations array
            if member.observations == nil {
                member.observations = []
            }
            member.observations?.append(newObs)

            try? context.save()
        }

        dismiss()
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("New Observation") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    context.insert(member)
    try? context.save()

    return ObservationForm(member: member, observationToEdit: nil)
        .modelContainer(container)
}

#Preview("Edit Observation") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    let obs = TeamObservation(
        memberId: member.id,
        text: "Led the refactoring effort with great communication and documentation.",
        context: .sprintReview,
        createdAt: Date().addingTimeInterval(-86400 * 7)
    )
    obs.member = member
    member.observations = [obs]

    context.insert(member)
    try? context.save()

    return ObservationForm(member: member, observationToEdit: obs)
        .modelContainer(container)
}
