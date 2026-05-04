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
    let member: TeamMember

    @State private var showingAddStrength = false
    @State private var showingAddWeakness = false
    @State private var tagToEdit: StrengthWeakness? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Label("Strengths & Growth Areas", systemImage: "star.fill")
                    .font(.headline)
                Spacer()
            }

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
                    FlowLayout(spacing: 8) {
                        ForEach(member.strengths) { strength in
                            TagChip(tag: strength)
                                .onTapGesture {
                                    tagToEdit = strength
                                }
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
                    FlowLayout(spacing: 8) {
                        ForEach(member.weaknesses) { weakness in
                            TagChip(tag: weakness)
                                .onTapGesture {
                                    tagToEdit = weakness
                                }
                        }
                    }
                }
            }
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
}

// MARK: - Tag Chip -----------------------------------------------------------

private struct TagChip: View {
    let tag: StrengthWeakness

    var body: some View {
        HStack(spacing: 6) {
            // Intensity indicator (dots)
            HStack(spacing: 2) {
                ForEach(0..<intensityDotCount, id: \.self) { _ in
                    Circle()
                        .fill(colorForKind)
                        .frame(width: 5, height: 5)
                }
            }

            // Category label
            Text(tag.category)
                .font(.subheadline)
                .lineLimit(1)

            // Note indicator
            if tag.note != nil && !tag.note!.isEmpty {
                Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(colorForKind.opacity(0.1), in: Capsule())
        .foregroundStyle(colorForKind)
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

// MARK: - Flow Layout --------------------------------------------------------

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        // Simple horizontal layout for now. A full flow layout would
        // calculate available width and wrap to multiple lines.
        // For most cases (3–5 tags per section), HStack is sufficient.
        LazyVStack(alignment: .leading, spacing: spacing) {
            content()
        }
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
