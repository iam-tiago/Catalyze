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
            if members.isEmpty {
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
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                TeamRadarChartView(data: radarData)
                    .frame(height: 350)
                    .padding()
                    .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Stats
            if !members.isEmpty {
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
        // Fixed behavioral categories - always shown in this order
        let behavioralCategories = [
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
        
        // Calculate totals for each category
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
        
        // Build radar data with ALL categories (fixed order, 0 if no data)
        return behavioralCategories.map { category in
            let value: Double
            if let totals = categoryTotals[category] {
                value = totals.sum / Double(totals.count)
            } else {
                value = 0.0
            }
            
            return TeamRadarDataPoint(category: category, value: value)
        }
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

// MARK: - Team Radar Chart View ----------------------------------------------

private struct TeamRadarChartView: View {
    let data: [TeamRadarDataPoint]
    let maxValue: Double = 3.0
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 50
            
            ZStack {
                // Grid circles (background concentric circles)
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        .frame(width: radius * 2 * scale, height: radius * 2 * scale)
                }
                
                // Axes (spokes radiating from center)
                ForEach(0..<data.count, id: \.self) { index in
                    let angle = angleForIndex(index)
                    let endPoint = pointOnCircle(center: center, radius: radius, angle: angle)
                    
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: endPoint)
                    }
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                }
                
                // Data area (filled polygon)
                Path { path in
                    for (index, point) in data.enumerated() {
                        let angle = angleForIndex(index)
                        let distance = radius * (point.value / maxValue)
                        let coordinate = pointOnCircle(center: center, radius: distance, angle: angle)
                        
                        if index == 0 {
                            path.move(to: coordinate)
                        } else {
                            path.addLine(to: coordinate)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(Color.green.opacity(0.2))
                
                // Data line (outline)
                Path { path in
                    for (index, point) in data.enumerated() {
                        let angle = angleForIndex(index)
                        let distance = radius * (point.value / maxValue)
                        let coordinate = pointOnCircle(center: center, radius: distance, angle: angle)
                        
                        if index == 0 {
                            path.move(to: coordinate)
                        } else {
                            path.addLine(to: coordinate)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color.green, lineWidth: 2.5)
                
                // Data points (dots on each vertex)
                ForEach(0..<data.count, id: \.self) { index in
                    let point = data[index]
                    let angle = angleForIndex(index)
                    let distance = radius * (point.value / maxValue)
                    let coordinate = pointOnCircle(center: center, radius: distance, angle: angle)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        }
                        .position(coordinate)
                }
                
                // Category labels
                ForEach(0..<data.count, id: \.self) { index in
                    let point = data[index]
                    let angle = angleForIndex(index)
                    let labelDistance = radius + 30
                    let coordinate = pointOnCircle(center: center, radius: labelDistance, angle: angle)
                    
                    Text(point.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .position(coordinate)
                }
            }
        }
    }
    
    private func angleForIndex(_ index: Int) -> Double {
        let totalPoints = data.count
        let anglePerPoint = (2 * .pi) / Double(totalPoints)
        // Start from top (-.pi/2) and go clockwise
        return -.pi / 2 + anglePerPoint * Double(index)
    }
    
    private func pointOnCircle(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
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
