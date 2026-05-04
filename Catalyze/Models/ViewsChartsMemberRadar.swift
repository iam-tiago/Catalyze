//
//  MemberRadar.swift
//  Catalyze
//
//  Behavioral radar chart for a single team member. Shows intensity across
//  behavioral categories (Communication, Leadership, Problem Solving, etc.)
//  using Swift Charts with polar coordinates.
//
//  Equivalent to `src/components/Charts/MemberRadar.tsx` in the web app.
//

import SwiftUI
import SwiftData
import Charts

struct MemberRadar: View {
    let member: TeamMember
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Behavioral Profile")
                    .font(.headline)
                
                Text("Based on \(member.strengths.count) strengths and \(member.weaknesses.count) growth areas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Chart
            if !radarData.isEmpty {
                Chart(radarData) { point in
                    // Area fill
                    AreaMark(
                        x: .value("Category", point.category),
                        y: .value("Intensity", point.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    
                    // Line outline
                    LineMark(
                        x: .value("Category", point.category),
                        y: .value("Intensity", point.value)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // Points
                    PointMark(
                        x: .value("Category", point.category),
                        y: .value("Intensity", point.value)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(40)
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
                .frame(height: 300)
                .padding()
                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No behavioral data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add strengths and growth areas to see the radar")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Legend
            if !radarData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scale")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(0..<4) { level in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                
                                Text(intensityLabel(level))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helpers --------------------------------------------------------
    
    private var radarData: [RadarDataPoint] {
        // Get behavioral categories (exclude technical ones)
        let behavioralCategories = [
            "Communication", "Ownership", "Emotional Intelligence", "Collaboration",
            "Growth Mindset", "Problem Solving", "Leadership", "Adaptability", "Mentoring"
        ]
        
        // Calculate average intensity per category
        var categoryValues: [String: Double] = [:]
        
        for tag in member.strengths + member.weaknesses {
            guard behavioralCategories.contains(tag.category) else { continue }
            
            let value = intensityToValue(tag.intensity, isStrength: tag.kind == .strength)
            
            if let existing = categoryValues[tag.category] {
                // Average if multiple tags in same category
                categoryValues[tag.category] = (existing + value) / 2
            } else {
                categoryValues[tag.category] = value
            }
        }
        
        // Build radar points (include only categories with data)
        return categoryValues.map { category, value in
            RadarDataPoint(category: category, value: value)
        }
        .sorted { $0.category < $1.category }
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
            // For weaknesses, invert the scale (blocking = needs most work = lower on chart)
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

// MARK: - Radar Data Point ---------------------------------------------------

private struct RadarDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        
        let member = TeamMember(
            name: "Alice Chen",
            role: "Senior iOS Engineer",
            seniority: .t3_1
        )
        
        let s1 = StrengthWeakness(kind: .strength, category: "Communication", intensity: .strong)
        s1.member = member
        
        let s2 = StrengthWeakness(kind: .strength, category: "Leadership", intensity: .solid)
        s2.member = member
        
        let s3 = StrengthWeakness(kind: .strength, category: "Problem Solving", intensity: .solid)
        s3.member = member
        
        let w1 = StrengthWeakness(kind: .weakness, category: "Mentoring", intensity: .emerging)
        w1.member = member
        
        member.tags = [s1, s2, s3, w1]
        
        context.insert(member)
        try? context.save()
        
        return container
    }()
    
    let context = ModelContext(container)
    let member = try! context.fetch(FetchDescriptor<TeamMember>()).first!
    
    ScrollView {
        MemberRadar(member: member)
            .padding()
    }
    .modelContainer(container)
}
