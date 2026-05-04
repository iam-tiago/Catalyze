//
//  IDPForm.swift
//  Catalyze
//
//  Form for adding or editing an Individual Development Plan. Includes
//  title, objective, target date, status, and a list of actions with
//  checkboxes and reordering.
//
//  Equivalent to `src/components/TeamMembers/IDPForm.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct IDPForm: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let member: TeamMember
    let idpToEdit: DevelopmentPlan?

    @State private var title = ""
    @State private var objective = ""
    @State private var targetDate: Date?
    @State private var status: IDPStatus = .active
    @State private var linkedGrowthAreaId: String? = nil
    @State private var hasTargetDate = false
    @State private var actions: [ActionFormData] = []

    var body: some View {
        NavigationStack {
            Form {
                // Basic info section
                Section("Basic Information") {
                    TextField("Title", text: $title)

                    TextField("Objective", text: $objective, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Optional link to growth area
                Section {
                    Picker("Linked Growth Area", selection: $linkedGrowthAreaId) {
                        Text("None").tag(nil as String?)

                        ForEach(member.weaknesses) { weakness in
                            Text(weakness.category).tag(weakness.id as String?)
                        }
                    }
                } header: {
                    Text("Link to Growth Area (Optional)")
                } footer: {
                    Text("Connect this plan to a specific area for improvement.")
                }

                // Target date
                Section {
                    Toggle("Set target date", isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker(
                            "Target Date",
                            selection: Binding(
                                get: { targetDate ?? Date() },
                                set: { targetDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                } header: {
                    Text("Target Date")
                }

                // Status (only when editing)
                if isEditing {
                    Section("Status") {
                        Picker("Status", selection: $status) {
                            ForEach(IDPStatus.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Actions
                Section {
                    ForEach($actions) { $action in
                        HStack {
                            Button {
                                action.done.toggle()
                            } label: {
                                Image(systemName: action.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(action.done ? .green : .secondary)
                            }
                            .buttonStyle(.plain)

                            TextField("Action", text: $action.text)
                                .strikethrough(action.done)
                                .foregroundStyle(action.done ? .secondary : .primary)

                            Button(role: .destructive) {
                                removeAction(action)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { from, to in
                        actions.move(fromOffsets: from, toOffset: to)
                    }

                    Button {
                        addAction()
                    } label: {
                        Label("Add Action", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Actions")
                } footer: {
                    Text("Drag to reorder. Tap the circle to mark as done.")
                }
            }
            .navigationTitle(isEditing ? "Edit Plan" : "New Development Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveIDP()
                    }
                    .disabled(!isValid)
                }

                // Delete button (only when editing)
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            deleteIDP()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }

    // MARK: - Helpers --------------------------------------------------------

    private var isEditing: Bool {
        idpToEdit != nil
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !objective.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadInitialData() {
        guard let idp = idpToEdit else {
            // New IDP — add one empty action by default
            actions = [ActionFormData(text: "", done: false)]
            return
        }

        title = idp.title
        objective = idp.objective
        targetDate = idp.targetDate
        hasTargetDate = idp.targetDate != nil
        status = idp.status
        linkedGrowthAreaId = idp.linkedGrowthAreaId

        // Load actions
        actions = idp.sortedActions.map {
            ActionFormData(text: $0.text, done: $0.done)
        }

        // If no actions, add one empty
        if actions.isEmpty {
            actions = [ActionFormData(text: "", done: false)]
        }
    }

    private func addAction() {
        actions.append(ActionFormData(text: "", done: false))
    }

    private func removeAction(_ action: ActionFormData) {
        actions.removeAll { $0.id == action.id }
    }

    private func saveIDP() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedObjective = objective.trimmingCharacters(in: .whitespaces)

        // Filter out empty actions
        let validActions = actions.filter {
            !$0.text.trimmingCharacters(in: .whitespaces).isEmpty
        }

        if let existing = idpToEdit {
            // Update existing
            existing.title = trimmedTitle
            existing.objective = trimmedObjective
            existing.targetDate = hasTargetDate ? targetDate : nil
            existing.status = status
            existing.linkedGrowthAreaId = linkedGrowthAreaId

            // Delete old actions
            if let oldActions = existing.actions {
                for action in oldActions {
                    context.delete(action)
                }
            }

            // Create new actions
            let newActions = validActions.enumerated().map { index, formData in
                IDPAction(
                    text: formData.text.trimmingCharacters(in: .whitespaces),
                    done: formData.done,
                    sortIndex: index
                )
            }

            for action in newActions {
                action.plan = existing
                context.insert(action)
            }

            existing.actions = newActions

            store.updateIDP(existing, in: context)
        } else {
            // Create new
            let newIDP = DevelopmentPlan(
                memberId: member.id,
                title: trimmedTitle,
                linkedGrowthAreaId: linkedGrowthAreaId,
                objective: trimmedObjective,
                targetDate: hasTargetDate ? targetDate : nil,
                status: .active
            )

            newIDP.member = member

            let newActions = validActions.enumerated().map { index, formData in
                IDPAction(
                    text: formData.text.trimmingCharacters(in: .whitespaces),
                    done: formData.done,
                    sortIndex: index
                )
            }

            for action in newActions {
                action.plan = newIDP
                context.insert(action)
            }

            newIDP.actions = newActions

            // Add to member
            if member.idps == nil {
                member.idps = []
            }
            member.idps?.append(newIDP)

            store.addIDP(newIDP, in: context)
        }

        dismiss()
    }

    private func deleteIDP() {
        guard let idp = idpToEdit else { return }
        store.deleteIDP(idp, in: context)
        dismiss()
    }
}

// MARK: - Action Form Data ---------------------------------------------------

private struct ActionFormData: Identifiable {
    let id = UUID()
    var text: String
    var done: Bool
}

// MARK: - Preview ------------------------------------------------------------

#Preview("New IDP") {
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
        intensity: .developing
    )
    weakness.member = member
    member.tags = [weakness]

    context.insert(member)
    try? context.save()

    return IDPForm(member: member, idpToEdit: nil)
        .environment(AppStore())
        .modelContainer(container)
}

#Preview("Edit IDP") {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)

    let member = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )

    let idp = DevelopmentPlan(
        memberId: member.id,
        title: "iOS Architecture Mastery",
        objective: "Become proficient in designing scalable iOS architectures.",
        targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
        status: .active
    )
    idp.member = member

    let action1 = IDPAction(text: "Read architecture book", done: true, sortIndex: 0)
    action1.plan = idp
    let action2 = IDPAction(text: "Implement in project", done: false, sortIndex: 1)
    action2.plan = idp

    idp.actions = [action1, action2]
    member.idps = [idp]

    context.insert(member)
    try? context.save()

    return IDPForm(member: member, idpToEdit: idp)
        .environment(AppStore())
        .modelContainer(container)
}
