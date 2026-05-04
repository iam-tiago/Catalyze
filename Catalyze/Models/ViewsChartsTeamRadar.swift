//
//  TeamRadar.swift
//  Catalyze
//
//  Aggregated behavioral radar chart for the entire team. Shows average
//  intensity across behavioral categories, giving a team-level view of
//  strengths and growth areas.
//
//  Equivalent to `src/components/Charts/TeamRadar.tsx` in the web app.
//

import SwiftUI
import SwiftData
import Charts

struct TeamRadar: View {
    @Query(sort: \TeamMember.name) private var members: [TeamMember]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Team Behavioral Profile")
                    .font(.headline)
                
                Text("Aggregated across \(members.count) members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Chart
            if !radarData.isEmpty {
                Chart(radarData) { point in
                    // Area fill
                    AreaMark(
                        x: .value("Category", point.category),
                        y: .value("Average", point.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.green.opacity(0.3), .green.opacity(0.1)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    
                    // Line outline
                    LineMark(
                        x: .value("Category", point.category),
                        y: .value("Average", point.value)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // Points
                    PointMark(
                        x: .value("Category", point.category),
                        y: .value("Average", point.value)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(40)
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", point.value))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(intensityLabel(intValue))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(orientation: .vertical)
                            .font(.caption2)
                    }
                }
                .frame(height: 350)
                .padding()
                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No team data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add team members with strengths and growth areas")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Stats
            if !radarData.isEmpty {
                HStack(spacing: 24) {
                    StatBox(
                        label: "Strongest",
                        value: strongestCategory,
                        color: .green
                    )
                    
                    StatBox(
                        label: "Needs Focus",
                        value: weakestCategory,
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Helpers --------------------------------------------------------
    
    private var radarData: [TeamRadarDataPoint] {
        guard !members.isEmpty else { return [] }
        
        let behavioralCategories = [
            "Communication", "Ownership", "Emotional Intelligence", "Collaboration",
            "Growth Mindset", "Problem Solving", "Leadership", "Adaptability", "Mentoring"
        ]
        
        var categoryTotals: [String: (sum: Double, count: Int)] = [:]
        
        for member in members {
            for tag in member.strengths + member.weaknesses {
                guard behavioralCategories.contains(tag.category) else { continue }
                
                let value = intensityToValue(tag.intensity, isStrength: tag.kind == .strength)
                
                if var existing = categoryTotals[tag.category] {
                    existing.sum += value
                    existing.count += 1
                    categoryTotals[tag.category] = existing
                } else {
                    categoryTotals[tag.category] = (value, 1)
                }
            }
        }
        
        // Calculate averages
        return categoryTotals.map { category, totals in
            TeamRadarDataPoint(
                category: category,
                value: totals.sum / Double(totals.count)
            )
        }
        .sorted { $0.category < $1.category }
    }
    
    private var strongestCategory: String {
        radarData.max(by: { $0.value < $1.value })?.category ?? "—"
    }
    
    private var weakestCategory: String {
        radarData.min(by: { $0.value < $1.value })?.category ?? "—"
    }
    
    private func intensityToValue(_ intensity: Intensity, isStrength: Bool) -> Double {
        if isStrength {
            switch intensity {
            case .emerging: return 1.0
            case .solid:    return 2.0
            case .strong:   return 3.0
            default:        return 1.0
            }
        } else {
            switch intensity {
            case .emerging:   return 1.0
            case .developing: return 0.5
            case .blocking:   return 0.25
            default:          return 1.0
            }
        }
    }
    
    private func intensityLabel(_ level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Emerging"
        case 2: return "Solid"
        case 3: return "Strong"
        default: return ""
        }
    }
}

// MARK: - Team Radar Data Point ----------------------------------------------

private struct TeamRadarDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
}

// MARK: - Stat Box -----------------------------------------------------------

private struct StatBox: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    // Create sample team
    let alice = TeamMember(name: "Alice", role: "iOS Engineer", seniority: .t3_1)
    let s1 = StrengthWeakness(kind: .strength, category: "Communication", intensity: .strong)
    s1.member = alice
    let s2 = StrengthWeakness(kind: .strength, category: "Leadership", intensity: .solid)
    s2.member = alice
    alice.tags = [s1, s2]
    
    let bob = TeamMember(name: "Bob", role: "Backend Engineer", seniority: .t2_2)
    let s3 = StrengthWeakness(kind: .strength, category: "Problem Solving", intensity: .strong)
    s3.member = bob
    let w1 = StrengthWeakness(kind: .weakness, category: "Communication", intensity: .developing)
    w1.member = bob
    bob.tags = [s3, w1]
    
    let carol = TeamMember(name: "Carol", role: "Full Stack", seniority: .t2_1)
    let s4 = StrengthWeakness(kind: .strength, category: "Collaboration", intensity: .solid)
    s4.member = carol
    carol.tags = [s4]
    
    context.insert(alice)
    context.insert(bob)
    context.insert(carol)
    try? context.save()
    
    return ScrollView {
        TeamRadar()
            .padding()
    }
    .modelContainer(container)
}
