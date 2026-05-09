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
            "EQ",
            "Collaboration",
            "Growth Mindset",
            "Leadership",
            "Adaptability",
            "Mentoring"
        ]
        
        // Calculate totals for each category, tracking strengths and weaknesses separately
        var categoryData: [String: (strengthSum: Double, strengthCount: Int, weaknessSum: Double, weaknessCount: Int)] = [:]
        
        for member in members {
            for tag in member.strengths + member.weaknesses {
                guard behavioralCategories.contains(tag.category) else { continue }
                
                let value = intensityToValue(tag.intensity, isStrength: tag.kind == .strength)
                let isStrength = tag.kind == .strength
                
                if var existing = categoryData[tag.category] {
                    if isStrength {
                        existing.strengthSum += value
                        existing.strengthCount += 1
                    } else {
                        existing.weaknessSum += value
                        existing.weaknessCount += 1
                    }
                    categoryData[tag.category] = existing
                } else {
                    if isStrength {
                        categoryData[tag.category] = (value, 1, 0, 0)
                    } else {
                        categoryData[tag.category] = (0, 0, value, 1)
                    }
                }
            }
        }
        
        // Build radar data with ALL categories (fixed order, 0 if no data)
        return behavioralCategories.map { category in
            let data = categoryData[category]
            let strengthAvg = data.map { $0.strengthCount > 0 ? $0.strengthSum / Double($0.strengthCount) : 0.0 } ?? 0.0
            let weaknessAvg = data.map { $0.weaknessCount > 0 ? $0.weaknessSum / Double($0.weaknessCount) : 0.0 } ?? 0.0
            
            // Use the max value from either strengths or weaknesses, but track which type
            let hasStrength = (data?.strengthCount ?? 0) > 0
            let hasWeakness = (data?.weaknessCount ?? 0) > 0
            
            let value: Double
            let isStrengthDominant: Bool
            
            if hasStrength && hasWeakness {
                // Both exist, use average
                value = (strengthAvg + weaknessAvg) / 2
                isStrengthDominant = strengthAvg >= weaknessAvg
            } else if hasStrength {
                value = strengthAvg
                isStrengthDominant = true
            } else {
                value = weaknessAvg
                isStrengthDominant = false
            }
            
            return TeamRadarDataPoint(category: category, value: value, isStrength: isStrengthDominant, hasData: hasStrength || hasWeakness)
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
    let isStrength: Bool
    let hasData: Bool
    
    init(category: String, value: Double, isStrength: Bool = true, hasData: Bool = true) {
        self.category = category
        self.value = value
        self.isStrength = isStrength
        self.hasData = hasData
    }
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
                .fill(
                    LinearGradient(
                        colors: [.green.opacity(0.2), .orange.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Data line segments (colored by point type)
                ForEach(0..<data.count, id: \.self) { index in
                    let point = data[index]
                    let nextIndex = (index + 1) % data.count
                    let nextPoint = data[nextIndex]
                    
                    let angle1 = angleForIndex(index)
                    let distance1 = radius * (point.value / maxValue)
                    let coord1 = pointOnCircle(center: center, radius: distance1, angle: angle1)
                    
                    let angle2 = angleForIndex(nextIndex)
                    let distance2 = radius * (nextPoint.value / maxValue)
                    let coord2 = pointOnCircle(center: center, radius: distance2, angle: angle2)
                    
                    Path { path in
                        path.move(to: coord1)
                        path.addLine(to: coord2)
                    }
                    .stroke(
                        point.hasData ? (point.isStrength ? Color.green : Color.orange) : Color.gray,
                        lineWidth: 2.5
                    )
                }
                
                // Data points (colored by type)
                ForEach(0..<data.count, id: \.self) { index in
                    let point = data[index]
                    let angle = angleForIndex(index)
                    let distance = radius * (point.value / maxValue)
                    let coordinate = pointOnCircle(center: center, radius: distance, angle: angle)
                    
                    let pointColor = point.hasData ? (point.isStrength ? Color.green : Color.orange) : Color.gray
                    
                    Circle()
                        .fill(pointColor)
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
                    let labelDistance = radius + 24
                    let coordinate = pointOnCircle(center: center, radius: labelDistance, angle: angle)
                    
                    Text(point.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.center)
                        .frame(width: 100)
                        .position(coordinate)
                        .offset(labelOffset(for: angle))
                        .offset(labelOffset(for: angle))
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
    
    private func labelOffset(for angle: Double) -> CGSize {
        // Adjust label position based on angle to avoid overlap with radar
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 2 * .pi)
        let degrees = normalizedAngle * 180 / .pi
        
        // Push labels further out based on their position
        if degrees > -90 && degrees < -60 {
            // Top area
            return CGSize(width: 0, height: -12)
        } else if degrees >= -60 && degrees < -30 {
            // Top-right
            return CGSize(width: 12, height: -8)
        } else if degrees >= -30 && degrees < 30 {
            // Right side
            return CGSize(width: 15, height: 0)
        } else if degrees >= 30 && degrees < 60 {
            // Bottom-right
            return CGSize(width: 12, height: 8)
        } else if degrees >= 60 && degrees < 120 {
            // Bottom area
            return CGSize(width: 0, height: 6)
        } else if degrees >= 120 && degrees < 150 {
            // Bottom-left
            return CGSize(width: -12, height: 8)
        } else if degrees >= 150 || degrees < -150 {
            // Left side
            return CGSize(width: -15, height: 0)
        } else {
            // Top-left
            return CGSize(width: -1, height: -8)
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    // Create sample team
    let alice = TeamMember(name: "Paulo", role: "iOS Engineer", seniority: .t3_1)
    let s1 = StrengthWeakness(kind: .strength, category: "Communication", intensity: .strong)
    s1.member = alice
    let s2 = StrengthWeakness(kind: .strength, category: "Leadership", intensity: .solid)
    s2.member = alice
    alice.tags = [s1, s2]
    
    let bob = TeamMember(name: "Bob", role: "Backend Engineer", seniority: .t2_2)
    let s3 = StrengthWeakness(kind: .strength, category: "Ownership", intensity: .strong)
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
