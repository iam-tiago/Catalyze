//
//  InsightHistoryView.swift
//  Catalyze
//
//  Historical view of all generated AI insights. Allows filtering by type,
//  member, and date range. Users can view, copy, and delete past insights.
//

import SwiftUI
import SwiftData

struct InsightHistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Insight.createdAt, order: .reverse) private var allInsights: [Insight]
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    @State private var selectedType: InsightType?
    @State private var selectedMemberId: String?
    @State private var searchText = ""
    @State private var selectedInsight: Insight?
    @State private var showingDeleteConfirmation = false
    @State private var insightToDelete: Insight?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                filtersSection
                    .padding()
                    .background(.quaternary.opacity(0.3))
                
                // Insights list
                if filteredInsights.isEmpty {
                    emptyState
                } else {
                    insightsList
                }
            }
            .navigationTitle("Insight History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailView(insight: insight)
            }
            .alert("Delete Insight?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let insight = insightToDelete {
                        deleteInsight(insight)
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Filters Section ------------------------------------------------
    
    private var filtersSection: some View {
        VStack(spacing: CatalystSpacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search insights...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(CatalystSpacing.sm)
            .background(.background, in: RoundedRectangle(cornerRadius: CatalystRadius.sm))
            
            // Type and Member filters
            HStack(spacing: CatalystSpacing.md) {
                // Type filter
                Menu {
                    Button("All Types") {
                        selectedType = nil
                    }
                    
                    Divider()
                    
                    ForEach(InsightType.allCases) { type in
                        Button(type.displayName) {
                            selectedType = type
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedType?.displayName ?? "All Types")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, CatalystSpacing.md)
                    .padding(.vertical, CatalystSpacing.sm)
                    .background(.background, in: RoundedRectangle(cornerRadius: CatalystRadius.sm))
                    .foregroundStyle(.primary)
                }
                
                // Member filter
                Menu {
                    Button("All Members") {
                        selectedMemberId = nil
                    }
                    
                    Divider()
                    
                    ForEach(members) { member in
                        Button(member.name) {
                            selectedMemberId = member.id
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.circle")
                        Text(memberName(for: selectedMemberId) ?? "All Members")
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, CatalystSpacing.md)
                    .padding(.vertical, CatalystSpacing.sm)
                    .background(.background, in: RoundedRectangle(cornerRadius: CatalystRadius.sm))
                    .foregroundStyle(.primary)
                }
            }
            
            // Results count
            Text("\(filteredInsights.count) insight\(filteredInsights.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Insights List --------------------------------------------------
    
    private var insightsList: some View {
        List {
            ForEach(filteredInsights) { insight in
                InsightHistoryRow(
                    insight: insight,
                    memberName: memberName(for: insight.memberId)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedInsight = insight
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        insightToDelete = insight
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowInsets(EdgeInsets(
                    top: CatalystSpacing.sm,
                    leading: CatalystSpacing.md,
                    bottom: CatalystSpacing.sm,
                    trailing: CatalystSpacing.md
                ))
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Empty State ----------------------------------------------------
    
    private var emptyState: some View {
        VStack(spacing: CatalystSpacing.lg) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("No Insights Yet")
                .font(CatalystTypography.title3)
                .fontWeight(.semibold)
            
            Text("Generate insights to see them here")
                .font(CatalystTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helpers --------------------------------------------------------
    
    private var filteredInsights: [Insight] {
        allInsights.filter { insight in
            // Type filter
            if let selectedType, insight.type != selectedType {
                return false
            }
            
            // Member filter
            if let selectedMemberId, insight.memberId != selectedMemberId {
                return false
            }
            
            // Search filter
            if !searchText.isEmpty {
                let lowercasedSearch = searchText.lowercased()
                let matchesPrompt = insight.prompt.lowercased().contains(lowercasedSearch)
                let matchesResponse = insight.response.lowercased().contains(lowercasedSearch)
                let matchesMember = memberName(for: insight.memberId)?.lowercased().contains(lowercasedSearch) ?? false
                
                if !matchesPrompt && !matchesResponse && !matchesMember {
                    return false
                }
            }
            
            return true
        }
    }
    
    private func memberName(for memberId: String?) -> String? {
        guard let memberId else { return nil }
        return members.first { $0.id == memberId }?.name
    }
    
    private func deleteInsight(_ insight: Insight) {
        context.delete(insight)
        try? context.save()
    }
}

// MARK: - Insight History Row ------------------------------------------------

private struct InsightHistoryRow: View {
    let insight: Insight
    let memberName: String?

    var body: some View {
        HStack(spacing: CatalystSpacing.md) {
            // Left accent strip
            RoundedRectangle(cornerRadius: 2)
                .fill(insight.type.color)
                .frame(width: 3)
                .padding(.vertical, CatalystSpacing.xs)

            VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                HStack {
                    Text(insight.type.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, CatalystSpacing.sm)
                        .padding(.vertical, 4)
                        .background(insight.type.color.opacity(0.12), in: Capsule())
                        .foregroundStyle(insight.type.color)

                    Spacer()

                    Text(insight.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let memberName {
                    Text(memberName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(insight.prompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(insight.response)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, CatalystSpacing.xs)
    }
}

// MARK: - Insight Detail View ------------------------------------------------

private struct InsightDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    let insight: Insight
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CatalystSpacing.xl) {
                    // Metadata card
                    CatalystCard {
                        VStack(alignment: .leading, spacing: CatalystSpacing.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: CatalystSpacing.xs) {
                                    Text("Type")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(insight.type.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: CatalystSpacing.xs) {
                                    Text("Created")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(insight.createdAt, style: .date)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if let memberName = memberName(for: insight.memberId) {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: CatalystSpacing.xs) {
                                    Text("Team Member")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(memberName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if !insight.prompt.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: CatalystSpacing.xs) {
                                    Text("Prompt")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(insight.prompt)
                                        .font(.subheadline)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    
                    // Response card
                    AIOutputCard(text: insight.response, isGenerating: false)
                }
                .padding(CatalystSpacing.xl)
            }
            .navigationTitle("Insight Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            copyToClipboard()
                        } label: {
                            Label("Copy Response", systemImage: "doc.on.doc")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Insight?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteInsight()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private func memberName(for memberId: String?) -> String? {
        guard let memberId else { return nil }
        return members.first { $0.id == memberId }?.name
    }
    
    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = insight.response
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(insight.response, forType: .string)
        #endif
    }
    
    private func deleteInsight() {
        context.delete(insight)
        try? context.save()
        dismiss()
    }
}

// MARK: - InsightType Extensions ---------------------------------------------

extension InsightType {
    var displayName: String {
        switch self {
        case .individual:   return "Individual"
        case .situational:  return "Situational"
        case .team:         return "Team"
        case .oneOnOnePrep: return "1:1 Prep"
        case .perfReview:   return "Performance Review"
        }
    }
    
    var color: Color {
        switch self {
        case .individual:   return .blue
        case .situational:  return .purple
        case .team:         return .green
        case .oneOnOnePrep: return .orange
        case .perfReview:   return .pink
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    // Create sample team member
    let alice = TeamMember(name: "Alice Chen", role: "iOS Engineer", seniority: .t3_1)
    context.insert(alice)
    
    // Create sample insights
    let insight1 = Insight(
        type: .individual,
        memberId: alice.id,
        prompt: "Individual insight for Alice Chen",
        response: """
## Individual Analysis for Alice Chen

### Strengths
- **Code Quality**: Demonstrates strong attention to detail
- **SwiftUI Expertise**: Leading the migration effort

### Growth Areas
1. Public speaking
2. Presenting to stakeholders

**Recommendation**: Consider a mentorship program focused on communication skills.
"""
    )
    
    let insight2 = Insight(
        type: .team,
        memberId: nil,
        prompt: "Team analysis for 5 members",
        response: """
## Team Analysis

The team shows strong technical capabilities but needs improvement in cross-functional communication.

### Key Patterns
- High code quality across all engineers
- Limited documentation practices
- Strong pair programming culture

### Recommendations
1. Implement documentation standards
2. Schedule regular knowledge sharing sessions
3. Create a tech blog or wiki
""",
        createdAt: Date().addingTimeInterval(-86400) // 1 day ago
    )
    
    let insight3 = Insight(
        type: .oneOnOnePrep,
        memberId: alice.id,
        prompt: "1:1 prep for Alice Chen",
        response: """
## 1:1 Preparation - Alice Chen

### Topics to Cover
1. Recent SwiftUI migration progress
2. Career growth aspirations
3. Team collaboration feedback

### Questions to Ask
- How are you feeling about the current workload?
- What challenges are you facing?
- What support do you need from me?
""",
        createdAt: Date().addingTimeInterval(-172800) // 2 days ago
    )
    
    context.insert(insight1)
    context.insert(insight2)
    context.insert(insight3)
    try? context.save()
    
    return InsightHistoryView()
        .modelContainer(container)
}
