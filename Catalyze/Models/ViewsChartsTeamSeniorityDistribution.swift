//
//  TeamSeniorityDistribution.swift
//  Catalyze
//
//  Seniority distribution for the team with the same design pattern as
//  Tech Stack Distribution. Shows member count by seniority level.
//

import SwiftUI
import SwiftData

struct TeamSeniorityDistribution: View {
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Seniority distribution across \(members.count) members")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Chart
            if members.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No team members")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add team members to see distribution")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    // Show seniority levels (ordered from highest to lowest)
                    ForEach(Array(seniorityData.enumerated()), id: \.element.seniority) { index, data in
                        TeamSeniorityDistributionRow(data: data)
                        
                        if index < seniorityData.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Helpers --------------------------------------------------------
    
    private var seniorityData: [SeniorityData] {
        let groups = Dictionary(grouping: members) { $0.seniority }
        
        // Map to data and sort from highest (T4) to lowest (T1-3)
        return Seniority.allCases
            .compactMap { seniority in
                guard let members = groups[seniority], !members.isEmpty else { return nil }
                return SeniorityData(seniority: seniority, count: members.count)
            }
            .sorted { seniorityLevel($0.seniority) > seniorityLevel($1.seniority) }
    }
    
    private func seniorityLevel(_ seniority: Seniority) -> Int {
        // Convert to numeric level for sorting (higher number = more senior)
        switch seniority {
        case .t1_3: return 1
        case .t2_1: return 2
        case .t2_2: return 3
        case .t2_3: return 4
        case .t3_1: return 5
        case .t3_2: return 6
        case .t3_3: return 7
        case .t4:   return 8
        }
    }
    
    private func colorForSeniority(_ seniority: Seniority) -> Color {
        // Color scheme aligned with seniority categories
        switch seniority {
        case .t4:                return .green   // Expert
        case .t3_3, .t3_2, .t3_1: return .purple  // Senior
        case .t2_3, .t2_2, .t2_1: return .blue    // Specialist
        case .t1_3:              return .orange  // Associate
        }
    }
}

// MARK: - Seniority Data -----------------------------------------------------

private struct SeniorityData: Identifiable {
    var id: String { seniority.rawValue }
    let seniority: Seniority
    let count: Int
}

// MARK: - Team Seniority Distribution Row -----------------------------------

private struct TeamSeniorityDistributionRow: View {
    let data: SeniorityData
    
    private var color: Color {
        switch data.seniority {
        case .t4:                return .green   // Expert
        case .t3_3, .t3_2, .t3_1: return .purple  // Senior
        case .t2_3, .t2_2, .t2_1: return .blue    // Specialist
        case .t1_3:              return .orange  // Associate
        }
    }
    
    private var levelLabel: String {
        switch data.seniority {
        case .t4:                return "Expert"
        case .t3_3, .t3_2, .t3_1: return "Senior"
        case .t2_3, .t2_2, .t2_1: return "Specialist"
        case .t1_3:              return "Associate"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Seniority level and count
            HStack {
                Text(data.seniority.label)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text("\(data.count) member\(data.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Bar (full width, colored by level)
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(height: 16)
            
            // Level category label
            HStack(spacing: 3) {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                
                Text(levelLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    let alice = TeamMember(name: "Alice", role: "Staff Engineer", seniority: .t4)
    let bob = TeamMember(name: "Bob", role: "Senior Engineer", seniority: .t3_2)
    let carol = TeamMember(name: "Carol", role: "Engineer", seniority: .t2_2)
    let david = TeamMember(name: "David", role: "Senior Engineer", seniority: .t3_1)
    
    context.insert(alice)
    context.insert(bob)
    context.insert(carol)
    context.insert(david)
    try? context.save()
    
    return ScrollView {
        TeamSeniorityDistribution()
            .padding()
    }
    .modelContainer(container)
}
