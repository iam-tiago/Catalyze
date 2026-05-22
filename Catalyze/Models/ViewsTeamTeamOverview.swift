//
//  TeamOverview.swift
//  Catalyze
//
//  Collapsible team dashboard shown above the member grid. Displays
//  team stats (size, seniority distribution, active IDPs) and the
//  aggregated team radar chart.
//
//  ✨ Migrated to Catalyze Design System v1.0
//  ⚠️ Radar charts preserved (manually adjusted)
//

import SwiftUI
import SwiftData

struct TeamOverview: View {
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    @State private var isExpanded = true
    @State private var selectedRadarType: RadarType = .behavioral
    
    enum RadarType: String, CaseIterable {
        case behavioral = "Behavioral"
        case technical = "Technical"
        
        var icon: String {
            switch self {
            case .behavioral: return "person.3.fill"
            case .technical: return "chevron.left.forwardslash.chevron.right"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            headerView
            
            // Content (collapsible)
            if isExpanded {
                Divider()
                
                VStack(spacing: CSpace.xl) {
                    // Stats grid
                    statsGrid
                    
                    // Distribution charts (side by side)
                    if !members.isEmpty {
                        distributionCharts
                    }
                    
                    // Team radar with toggle
                    radarSection
                }
                .padding(CSpace.lg)
            }
        }
        .background(CColor.neutral0)
        .clipShape(RoundedRectangle(cornerRadius: CRadius.md))
        .cardShadow()
    }
    
    // MARK: - Subviews -------------------------------------------------------
    
    private var headerView: some View {
        Button {
            withAnimation(.smooth) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Label("Team Overview", systemImage: "chart.bar.fill")
                    .font(CFont.headline)
                    .foregroundStyle(CColor.neutral900)
                
                Spacer()
                
                // Stats preview when collapsed
                if !isExpanded {
                    Text("\(members.count) members")
                        .font(CFont.caption1)
                        .foregroundStyle(CColor.neutral600)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CColor.neutral400)
            }
            .padding(CSpace.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var statsGrid: some View {
        HStack(spacing: CSpace.md) {
            StatCard(
                icon: "person.3.fill",
                value: "\(members.count)",
                label: "Team Size",
                variant: .info
            )
            
            StatCard(
                icon: "checklist",
                value: "\(activeIDPsCount)",
                label: "Active IDPs",
                variant: .strength
            )
            
            StatCard(
                icon: "arrow.up.circle.fill",
                value: "\(membersInPromotionCount)",
                label: "In Promotion",
                variant: .growth
            )
        }
    }
    
    private var distributionCharts: some View {
        HStack(alignment: .top, spacing: CSpace.lg) {
            // Seniority distribution (new standardized version)
            VStack(alignment: .leading, spacing: CSpace.sm) {
                TeamSeniorityDistribution()
            }
            .frame(maxWidth: .infinity)
            
            // Tech Stack distribution with proficiency levels
            VStack(alignment: .leading, spacing: CSpace.sm) {
                TeamTechStackDistribution()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func distributionCard(
        title: String,
        items: [(label: String, count: Int)],
        total: Int,
        color: Color,
        emptyMessage: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: CSpace.sm) {
            Text(title)
                .font(CFont.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(CColor.neutral900)
            
            if let emptyMessage = emptyMessage {
                Text(emptyMessage)
                    .font(CFont.caption1)
                    .foregroundStyle(CColor.neutral400)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, CSpace.sm)
            } else {
                ForEach(items, id: \.label) { item in
                    HStack {
                        Text(item.label)
                            .font(CFont.caption1)
                            .foregroundStyle(CColor.neutral600)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(CFont.caption1)
                            .fontWeight(.medium)
                            .foregroundStyle(CColor.neutral900)
                        
                        // Bar
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: geo.size.width * (Double(item.count) / Double(max(total, 1))))
                        }
                        .frame(width: 60, height: 6)
                    }
                }
            }
        }
        .padding(CSpace.lg)
        .frame(maxWidth: .infinity)
        .background(CColor.neutral100)
        .clipShape(RoundedRectangle(cornerRadius: CRadius.sm))
    }
    
    private var radarSection: some View {
        VStack(alignment: .leading, spacing: CSpace.md) {
            // Radar type picker
            Picker("Radar Type", selection: $selectedRadarType) {
                ForEach(RadarType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Show appropriate radar based on selection
            // ⚠️ DO NOT MODIFY RADARS - manually adjusted paddings/positions
            switch selectedRadarType {
            case .behavioral:
                TeamRadar()
                    .transition(.opacity.combined(with: .scale))
            case .technical:
                TeamTechnicalRadar()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.smooth, value: selectedRadarType)
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
            .padding(CSpace.x2l)
    }
    .background(CColor.neutral50)
    .modelContainer(container)
}
