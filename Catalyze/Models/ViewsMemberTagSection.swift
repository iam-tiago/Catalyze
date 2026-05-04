//
//  TagSection.swift
//  Catalyze
//
//  Strengths & growth areas section for the member detail page. Shows
//  two subsections (strengths / weaknesses) with chips for each tag.
//  Tapping a chip opens the edit form; "+" adds a new tag.
//
//  Equivalent to `src/components/TeamMembers/TagSection.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct TagSection: View {
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
                    Label("Strengths & Growth Areas", systemImage: "star.fill")
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

            // Strengths subsection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Strengths")
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

                if member.strengths.isEmpty {
                    Text("No strengths added yet")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(behavioralStrengths) { strength in
                            TagRow(
                                tag: strength,
                                onTap: { tagToEdit = strength },
                                onDelete: { deleteTag(strength) }
                            )
                        }
                    }
                }
            }

            Divider()

            // Weaknesses / Growth Areas subsection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Growth Areas")
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

                if member.weaknesses.isEmpty {
                    Text("No growth areas added yet")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(behavioralWeaknesses) { weakness in
                            TagRow(
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
            TagForm(member: member, kind: .strength, tagToEdit: nil)
        }
        .sheet(isPresented: $showingAddWeakness) {
            TagForm(member: member, kind: .weakness, tagToEdit: nil)
        }
        .sheet(item: $tagToEdit) { tag in
            TagForm(member: member, kind: tag.kind, tagToEdit: tag)
        }
    }
    
    // Filter tags to only show behavioral categories (excluding technical)
    private var behavioralStrengths: [StrengthWeakness] {
        member.strengths.filter { !BehavioralCategory.technicalCategories.contains($0.category) }
    }
    
    private var behavioralWeaknesses: [StrengthWeakness] {
        member.weaknesses.filter { !BehavioralCategory.technicalCategories.contains($0.category) }
    }
    
    private func deleteTag(_ tag: StrengthWeakness) {
        context.delete(tag)
        try? context.save()
    }
}

// MARK: - Tag Row -----------------------------------------------------------

private struct TagRow: View {
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

// MARK: - Behavioral Categories ----------------------------------------------

enum BehavioralCategory {
    // Technical categories that should NOT appear in behavioral section
    static let technicalCategories: [String] = [
        "Language Mastery",
        "Code Quality",
        "Code Review",
        "Testing",
        "Architecture",
        "DevOps",
        "Debugging Logic",
        "Observability",
        "Security"
    ]
    
    // Behavioral categories (for reference/validation)
    static let behavioralCategories: [String] = [
        "Communication",
        "Ownership",
        "Emotional Intelligence",
        "Collaboration",
        "Growth Mindset",
        "Problem Solving",
        "Leadership",
        "Adaptability",
        "Mentoring"
    ]
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
        category: "Leadership",
        intensity: .solid
    )
    strength2.member = member

    let weakness1 = StrengthWeakness(
        kind: .weakness,
        category: "Testing",
        intensity: .developing
    )
    weakness1.member = member

    member.tags = [strength1, strength2, weakness1]

    context.insert(member)
    try? context.save()

    return ScrollView {
        TagSection(member: member)
            .padding()
    }
    .modelContainer(container)
}
