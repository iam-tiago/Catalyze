//
//  TeamOverview.swift
//  Catalyze
//
//  Collapsible team dashboard shown above the member grid. Displays
//  team stats (size, seniority distribution, active IDPs) and the
//  aggregated team radar chart.
//
//  Equivalent to `src/components/TeamMembers/TeamOverview.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct TeamOverview: View {
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.smooth) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Team Overview", systemImage: "chart.bar.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Stats preview when collapsed
                    if !isExpanded {
                        Text("\(members.count) members")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Content (collapsible)
            if isExpanded {
                Divider()
                
                VStack(spacing: 20) {
                    // Stats grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 12
                    ) {
                        StatCard(
                            title: "Team Size",
                            value: "\(members.count)",
                            icon: "person.3.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Active IDPs",
                            value: "\(activeIDPsCount)",
                            icon: "list.bullet.clipboard.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "In Promotion",
                            value: "\(membersInPromotionCount)",
                            icon: "arrow.up.circle.fill",
                            color: .orange
                        )
                    }
                    
                    // Distribution charts (side by side)
                    if !members.isEmpty {
                        HStack(alignment: .top, spacing: 16) {
                            // Seniority distribution
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Seniority Distribution")
                                    .font(.subheadline.weight(.semibold))
                                
                                ForEach(seniorityBreakdown, id: \.seniority) { item in
                                    HStack {
                                        Text(item.seniority.label)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("\(item.count)")
                                            .font(.caption.weight(.medium))
                                        
                                        // Bar
                                        GeometryReader { geo in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(.blue)
                                                .frame(width: geo.size.width * (Double(item.count) / Double(members.count)))
                                        }
                                        .frame(width: 60, height: 6)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                            
                            // Stack distribution
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Stack Distribution")
                                    .font(.subheadline.weight(.semibold))
                                
                                ForEach(stackBreakdown.prefix(8), id: \.tag) { item in
                                    HStack {
                                        Text(item.tag.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("\(item.count)")
                                            .font(.caption.weight(.medium))
                                        
                                        // Bar
                                        GeometryReader { geo in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(.purple)
                                                .frame(width: geo.size.width * (Double(item.count) / Double(totalStackEntries)))
                                        }
                                        .frame(width: 60, height: 6)
                                    }
                                }
                                
                                if stackBreakdown.isEmpty {
                                    Text("No stack data")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // Team radar
                    TeamRadar()
                }
                .padding()
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helpers --------------------------------------------------------
    
    private var activeIDPsCount: Int {
        members.reduce(0) { count, member in
            count + (member.idps ?? []).filter { $0.status == .active }.count
        }
    }
    
    private var membersInPromotionCount: Int {
        members.filter { member in
            let records = member.promotionRecords ?? []
            return !records.filter { $0.status == .inProgress || $0.status == .ready }.isEmpty
        }.count
    }
    
    private var seniorityBreakdown: [(seniority: Seniority, count: Int)] {
        let groups = Dictionary(grouping: members) { $0.seniority }
        return Seniority.allCases.compactMap { seniority in
            guard let count = groups[seniority]?.count, count > 0 else { return nil }
            return (seniority, count)
        }
    }
    
    private var stackBreakdown: [(tag: StackTag, count: Int)] {
        var tagCounts: [StackTag: Int] = [:]
        
        for member in members {
            guard let stack = member.stack else { continue }
            for entry in stack {
                tagCounts[entry.tag, default: 0] += 1
            }
        }
        
        return tagCounts
            .map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var totalStackEntries: Int {
        members.reduce(0) { total, member in
            total + (member.stack?.count ?? 0)
        }
    }
}

// MARK: - Stat Card ----------------------------------------------------------

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
                .contentTransition(.numericText())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    let alice = TeamMember(name: "Alice", role: "iOS Engineer", seniority: .t3_1)
    let bob = TeamMember(name: "Bob", role: "Backend Engineer", seniority: .t2_2)
    let carol = TeamMember(name: "Carol", role: "Full Stack", seniority: .t2_1)
    
    let idp = DevelopmentPlan(memberId: alice.id, title: "iOS Architecture", objective: "Learn", status: .active)
    idp.member = alice
    alice.idps = [idp]
    
    context.insert(alice)
    context.insert(bob)
    context.insert(carol)
    try? context.save()
    
    return ScrollView {
        TeamOverview()
            .padding()
    }
    .modelContainer(container)
}
