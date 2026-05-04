//
//  TechnicalRadar.swift
//  Catalyze
//
//  Technical stack radar chart for a single team member. Shows proficiency
//  across technologies (Swift, TypeScript, Kubernetes, etc.) using Swift
//  Charts with polar coordinates.
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
                Text("Technical Stack")
                    .font(.headline)
                
                if let stack = member.stack, !stack.isEmpty {
                    Text("\(stack.count) technologies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No stack data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Chart
            if !radarData.isEmpty {
                Chart(radarData) { point in
                    // Area fill
                    AreaMark(
                        x: .value("Technology", point.technology),
                        y: .value("Proficiency", point.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.purple.opacity(0.3), .purple.opacity(0.1)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    
                    // Line outline
                    LineMark(
                        x: .value("Technology", point.technology),
                        y: .value("Proficiency", point.value)
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // Points
                    PointMark(
                        x: .value("Technology", point.technology),
                        y: .value("Proficiency", point.value)
                    )
                    .foregroundStyle(.purple)
                    .symbolSize(40)
                }
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(proficiencyLabel(intValue))
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
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No technical stack data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add stack proficiencies in the member profile")
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
        guard let stack = member.stack, !stack.isEmpty else { return [] }
        
        return stack.map { entry in
            TechRadarDataPoint(
                technology: entry.tag.rawValue,
                value: proficiencyToValue(entry.level)
            )
        }
        .sorted { $0.technology < $1.technology }
    }
    
    private func proficiencyToValue(_ level: StackProficiency) -> Double {
        switch level {
        case .learning:   return 0.5
        case .proficient: return 1.5
        case .advanced:   return 2.5
        case .expert:     return 3.0
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
    let technology: String
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
        
        let stack1 = StackEntry(tag: .swiftUI, level: .expert)
        stack1.member = member
        
        let stack2 = StackEntry(tag: .typescript, level: .proficient)
        stack2.member = member
        
        let stack3 = StackEntry(tag: .kubernetes, level: .learning)
        stack3.member = member
        
        let stack4 = StackEntry(tag: .graphql, level: .advanced)
        stack4.member = member
        
        member.stack = [stack1, stack2, stack3, stack4]
        
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
