//
//  TechnicalRadar.swift
//  Catalyze
//
//  Technical skills radar chart for a single team member. Shows proficiency
//  across technical skill categories (Language Mastery, Code Quality, Testing, etc.)
//  using custom radar chart with polar coordinates.
//
//  Equivalent to `src/components/Charts/TechnicalRadar.tsx` in the web app.
//

import SwiftUI
import SwiftData
import Charts

struct TechnicalRadar: View {
    let member: TeamMember
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Tech Skills")
                    .font(.headline)
                
                Text("Based on technical strengths and growth areas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Chart
            if hasTechnicalData {
                TechnicalRadarChartView(data: radarData)
                    .frame(height: 300)
                    .padding()
                    .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No tech skills data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add tech strengths and growth areas")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Legend
            if hasTechnicalData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scale")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(0..<4) { level in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.purple)
                                    .frame(width: 8, height: 8)
                                
                                Text(proficiencyLabel(level))
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
    
    private var radarData: [TechRadarDataPoint] {
        // Fixed technical skill categories - always shown in this order
        let technicalCategories = [
            "Language Mastery",
            "Code Quality",
            "Code Review",
            "Testing",
            "Architecture",
            "DevOps",
            "Debugging Logic",
            "Observability",
            "Security"
        ]
        
        // Calculate totals for each category
        var categoryTotals: [String: (sum: Double, count: Int)] = [:]
        
        for tag in member.strengths + member.weaknesses {
            guard technicalCategories.contains(tag.category) else { continue }
            
            let value = intensityToValue(tag.intensity, isStrength: tag.kind == .strength)
            
            if var existing = categoryTotals[tag.category] {
                existing.sum += value
                existing.count += 1
                categoryTotals[tag.category] = existing
            } else {
                categoryTotals[tag.category] = (value, 1)
            }
        }
        
        // Build radar data with ALL categories (fixed order, 0 if no data)
        return technicalCategories.map { category in
            let value: Double
            if let totals = categoryTotals[category] {
                value = totals.sum / Double(totals.count)
            } else {
                value = 0.0
            }
            
            return TechRadarDataPoint(category: category, value: value)
        }
    }
    
    private var hasTechnicalData: Bool {
        radarData.contains { $0.value > 0 }
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
    
    private func proficiencyLabel(_ level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Learning"
        case 2: return "Proficient"
        case 3: return "Expert"
        default: return ""
        }
    }
}

// MARK: - Tech Radar Data Point ----------------------------------------------

private struct TechRadarDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
}

// MARK: - Technical Radar Chart View -----------------------------------------

private struct TechnicalRadarChartView: View {
    let data: [TechRadarDataPoint]
    let maxValue: Double = 3.0
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 50
            
            ZStack {
                // Grid circles
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        .frame(width: radius * 2 * scale, height: radius * 2 * scale)
                }
                
                // Grid value labels
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    let value = maxValue * scale
                    let labelRadius = radius * scale
                    Text(String(format: "%.1f", value))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: center.x + 5, y: center.y - labelRadius - 5)
                }
                
                // Axes
                ForEach(0..<data.count, id: \.self) { index in
                    let angle = angleForIndex(index)
                    let endPoint = pointOnCircle(center: center, radius: radius, angle: angle)
                    
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: endPoint)
                    }
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                }
                
                // Data area
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
                .fill(Color.purple.opacity(0.2))
                
                // Data line
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
                .stroke(Color.purple, lineWidth: 2.5)
                
                // Data points
                ForEach(0..<data.count, id: \.self) { index in
                    let point = data[index]
                    let angle = angleForIndex(index)
                    let distance = radius * (point.value / maxValue)
                    let coordinate = pointOnCircle(center: center, radius: distance, angle: angle)
                    
                    Circle()
                        .fill(Color.purple)
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
    @Previewable @State var container: ModelContainer = {
        let container = try! PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        
        let member = TeamMember(
            name: "Alice Chen",
            role: "Senior iOS Engineer",
            seniority: .t3_1
        )
        
        let s1 = StrengthWeakness(kind: .strength, category: "Language Mastery", intensity: .strong)
        s1.member = member
        
        let s2 = StrengthWeakness(kind: .strength, category: "Code Quality", intensity: .solid)
        s2.member = member
        
        let s3 = StrengthWeakness(kind: .strength, category: "Testing", intensity: .solid)
        s3.member = member
        
        let w1 = StrengthWeakness(kind: .weakness, category: "DevOps", intensity: .emerging)
        w1.member = member
        
        let w2 = StrengthWeakness(kind: .weakness, category: "Security", intensity: .developing)
        w2.member = member
        
        member.tags = [s1, s2, s3, w1, w2]
        
        context.insert(member)
        try? context.save()
        
        return container
    }()
    
    let context = ModelContext(container)
    let member = try! context.fetch(FetchDescriptor<TeamMember>()).first!
    
    ScrollView {
        TechnicalRadar(member: member)
            .padding()
    }
    .modelContainer(container)
}
