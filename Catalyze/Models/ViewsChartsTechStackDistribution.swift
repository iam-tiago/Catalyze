//
//  TechStackDistribution.swift
//  Catalyze
//
//  Tech stack distribution chart for a single team member. Shows proficiency
//  levels across different technologies using horizontal bar charts.
//

import SwiftUI
import Charts

struct TechStackDistribution: View {
    let member: TeamMember
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Tech Stack Distribution")
                    .font(.headline)
                
                if let stack = member.stack, !stack.isEmpty {
                    Text("\(stack.count) technologies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No technologies added yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Chart
            if let stack = member.stack, !stack.isEmpty {
                VStack(spacing: 12) {
                    ForEach(stack.sorted(by: { $0.tag.rawValue < $1.tag.rawValue })) { entry in
                        TechStackBar(entry: entry)
                    }
                }
                .padding()
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
                
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
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    
                    Text("No tech stack data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add technologies to see distribution")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(Color(white: 0.5, opacity: 0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
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

// MARK: - Tech Stack Bar -----------------------------------------------------

private struct TechStackBar: View {
    let entry: StackEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Technology name
            Text(entry.tag.rawValue)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            
            // Bar with segments
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 24)
                    
                    // Filled portion
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorForLevel)
                        .frame(width: geometry.size.width * fillPercentage, height: 24)
                    
                    // Level label inside bar
                    HStack {
                        Text(entry.level.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width * fillPercentage, height: 24)
                }
            }
            .frame(height: 24)
        }
    }
    
    private var fillPercentage: Double {
        switch entry.level {
        case .learning:   return 0.25
        case .proficient: return 0.50
        case .advanced:   return 0.75
        case .expert:     return 1.0
        }
    }
    
    private var colorForLevel: Color {
        switch entry.level {
        case .learning:   return .orange
        case .proficient: return .blue
        case .advanced:   return .purple
        case .expert:     return .green
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    let container = try! PersistenceController.makePreviewContainer()
    let context = ModelContext(container)
    
    let alice = TeamMember(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        seniority: .t3_1
    )
    
    let stack1 = StackEntry(tag: .swiftUI, level: .expert)
    stack1.member = alice
    
    let stack2 = StackEntry(tag: .typescript, level: .proficient)
    stack2.member = alice
    
    let stack3 = StackEntry(tag: .graphql, level: .advanced)
    stack3.member = alice
    
    let stack4 = StackEntry(tag: .aws, level: .learning)
    stack4.member = alice
    
    alice.stack = [stack1, stack2, stack3, stack4]
    
    context.insert(alice)
    try? context.save()
    
    return ScrollView {
        TechStackDistribution(member: alice)
            .padding()
    }
    .modelContainer(container)
}
