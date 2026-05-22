//
//  TeamTechStackDistribution.swift
//  Catalyze
//
//  Aggregated tech stack distribution for the entire team. Shows which
//  technologies are used and the proficiency levels across team members.
//

import SwiftUI
import SwiftData
import Charts

struct TeamTechStackDistribution: View {
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Proficiency distribution across \(members.count) members")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Chart
            if stackData.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No tech stack data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add technologies to team members")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    // Technologies list with proficiency breakdown
                    ForEach(stackData.prefix(10)) { data in
                        TechStackTeamRow(data: data)
                        
                        if data.technology != stackData.prefix(10).last?.technology {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
                
                if stackData.count > 10 {
                    Text("Showing top 10 of \(stackData.count) technologies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                // Legend
                HStack(spacing: 16) {
                    ForEach(StackProficiency.allCases) { level in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForLevel(level))
                                .frame(width: 8, height: 8)
                            
                            Text(level.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helpers --------------------------------------------------------
    
    private var stackData: [TeamTechData] {
        // Aggregate all stack entries across team members
        var techCounts: [String: [StackProficiency: Int]] = [:]
        
        for member in members {
            guard let stack = member.stack else { continue }
            for entry in stack {
                let tech = entry.tagRaw
                if techCounts[tech] == nil {
                    techCounts[tech] = [:]
                }
                techCounts[tech]?[entry.level, default: 0] += 1
            }
        }
        
        // Convert to array and calculate totals
        return techCounts.map { (tech, levels) in
            let total = levels.values.reduce(0, +)
            let avgLevel = calculateAverageLevel(from: levels)
            
            return TeamTechData(
                technology: tech,
                totalCount: total,
                learningCount: levels[.learning] ?? 0,
                proficientCount: levels[.proficient] ?? 0,
                advancedCount: levels[.advanced] ?? 0,
                expertCount: levels[.expert] ?? 0,
                averageLevel: avgLevel
            )
        }
        .sorted { $0.totalCount > $1.totalCount } // Sort by most used
    }
    
    private func calculateAverageLevel(from levels: [StackProficiency: Int]) -> Double {
        let weights: [StackProficiency: Double] = [
            .learning: 1.0,
            .proficient: 2.0,
            .advanced: 3.0,
            .expert: 4.0
        ]
        
        let totalWeight = levels.reduce(0.0) { sum, entry in
            sum + (weights[entry.key] ?? 0) * Double(entry.value)
        }
        
        let totalCount = levels.values.reduce(0, +)
        return totalCount > 0 ? totalWeight / Double(totalCount) : 0
    }
    
    private func colorForLevel(_ level: StackProficiency) -> Color {
        switch level {
        case .learning:   return .orange
        case .proficient: return .blue
        case .advanced:   return .purple
        case .expert:     return .green
        }
    }
}

// MARK: - Team Tech Data -----------------------------------------------------

private struct TeamTechData: Identifiable {
    let id = UUID()
    let technology: String
    let totalCount: Int
    let learningCount: Int
    let proficientCount: Int
    let advancedCount: Int
    let expertCount: Int
    let averageLevel: Double
}

// MARK: - Tech Stack Team Row ------------------------------------------------

private struct TechStackTeamRow: View {
    let data: TeamTechData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Technology name and total count
            HStack {
                Text(data.technology)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text("\(data.totalCount) member\(data.totalCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Proficiency distribution bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // Learning
                    if data.learningCount > 0 {
                        proficiencySegment(
                            count: data.learningCount,
                            total: data.totalCount,
                            color: .orange,
                            width: geometry.size.width
                        )
                    }
                    
                    // Proficient
                    if data.proficientCount > 0 {
                        proficiencySegment(
                            count: data.proficientCount,
                            total: data.totalCount,
                            color: .blue,
                            width: geometry.size.width
                        )
                    }
                    
                    // Advanced
                    if data.advancedCount > 0 {
                        proficiencySegment(
                            count: data.advancedCount,
                            total: data.totalCount,
                            color: .purple,
                            width: geometry.size.width
                        )
                    }
                    
                    // Expert
                    if data.expertCount > 0 {
                        proficiencySegment(
                            count: data.expertCount,
                            total: data.totalCount,
                            color: .green,
                            width: geometry.size.width
                        )
                    }
                }
            }
            .frame(height: 24)
            
            // Breakdown numbers
            HStack(spacing: 12) {
                if data.learningCount > 0 {
                    proficiencyLabel(count: data.learningCount, level: "Learning", color: .orange)
                }
                if data.proficientCount > 0 {
                    proficiencyLabel(count: data.proficientCount, level: "Proficient", color: .blue)
                }
                if data.advancedCount > 0 {
                    proficiencyLabel(count: data.advancedCount, level: "Advanced", color: .purple)
                }
                if data.expertCount > 0 {
                    proficiencyLabel(count: data.expertCount, level: "Expert", color: .green)
                }
            }
        }
        .padding()
    }
    
    private func proficiencySegment(count: Int, total: Int, color: Color, width: CGFloat) -> some View {
        let percentage = Double(count) / Double(total)
        
        return RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: width * percentage)
            .overlay {
                if percentage > 0.15 {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
    }
    
    private func proficiencyLabel(count: Int, level: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text("\(count)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
            
            Text(level)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        
        let alice = TeamMember(name: "Alice", role: "iOS Engineer", seniority: .t3_1)
        let s1 = StackEntry(tag: .swiftUI, level: .expert)
        s1.member = alice
        let s2 = StackEntry(tag: .typescript, level: .proficient)
        s2.member = alice
        alice.stack = [s1, s2]
        
        let bob = TeamMember(name: "Bob", role: "Backend", seniority: .t2_2)
        let s3 = StackEntry(tag: .typescript, level: .expert)
        s3.member = bob
        let s4 = StackEntry(tag: .golang, level: .advanced)
        s4.member = bob
        bob.stack = [s3, s4]
        
        let carol = TeamMember(name: "Carol", role: "Full Stack", seniority: .t2_1)
        let s5 = StackEntry(tag: .typescript, level: .proficient)
        s5.member = carol
        let s6 = StackEntry(tag: .react, level: .learning)
        s6.member = carol
        carol.stack = [s5, s6]
        
        context.insert(alice)
        context.insert(bob)
        context.insert(carol)
        try? context.save()
        
        return container
    }()
    
    ScrollView {
        TeamTechStackDistribution()
            .padding()
    }
    .modelContainer(container)
}
