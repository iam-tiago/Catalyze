//
//  TechStackDistribution.swift
//  Catalyze
//
//  Tech stack distribution chart for a single team member. Shows proficiency
//  levels across different technologies using horizontal bar charts.
//

import SwiftUI
import SwiftData
import Charts

struct TechStackDistribution: View {
    let member: TeamMember
    
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
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
                
                Spacer()
                
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingEditSheet) {
                EditTechStackSheet(member: member)
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
                    
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Add Technologies", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
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
    @Previewable @State var container: ModelContainer = {
        let container = try! PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        
        let alice = TeamMember(
            name: "Alice Chen",
            role: "Senior iOS Engineer",
            seniority: .t3_1
        )
        
        // Behavioral strengths
        let behavioralS1 = StrengthWeakness(
            kind: .strength,
            category: "Communication",
            intensity: .strong,
            note: "Excellent at explaining complex technical concepts"
        )
        behavioralS1.member = alice
        
        let behavioralS2 = StrengthWeakness(
            kind: .strength,
            category: "Leadership",
            intensity: .solid
        )
        behavioralS2.member = alice
        
        // Behavioral growth areas
        let behavioralW1 = StrengthWeakness(
            kind: .weakness,
            category: "Mentoring",
            intensity: .emerging,
            note: "Starting to mentor junior developers"
        )
        behavioralW1.member = alice
        
        // Technical strengths
        let techS1 = StrengthWeakness(
            kind: .strength,
            category: "Code Quality",
            intensity: .strong,
            note: "Writes highly maintainable and testable code"
        )
        techS1.member = alice
        
        let techS2 = StrengthWeakness(
            kind: .strength,
            category: "Testing",
            intensity: .solid
        )
        techS2.member = alice
        
        let techS3 = StrengthWeakness(
            kind: .strength,
            category: "Architecture",
            intensity: .solid
        )
        techS3.member = alice
        
        // Technical growth areas
        let techW1 = StrengthWeakness(
            kind: .weakness,
            category: "DevOps",
            intensity: .developing,
            note: "Working on improving CI/CD knowledge"
        )
        techW1.member = alice
        
        let techW2 = StrengthWeakness(
            kind: .weakness,
            category: "Security",
            intensity: .emerging
        )
        techW2.member = alice
        
        // Tech Stack
        let stack1 = StackEntry(tag: .swiftUI, level: .expert)
        stack1.member = alice
        
        let stack2 = StackEntry(tag: .typescript, level: .proficient)
        stack2.member = alice
        
        let stack3 = StackEntry(tag: .graphql, level: .advanced)
        stack3.member = alice
        
        let stack4 = StackEntry(tag: .aws, level: .learning)
        stack4.member = alice
        
        let stack5 = StackEntry(tag: .docker, level: .proficient)
        stack5.member = alice
        
        let stack6 = StackEntry(tag: .kotlin, level: .learning)
        stack6.member = alice
        
        // Assign all relationships
        alice.tags = [
            behavioralS1, behavioralS2, behavioralW1,
            techS1, techS2, techS3, techW1, techW2
        ]
        alice.stack = [stack1, stack2, stack3, stack4, stack5, stack6]
        
        context.insert(alice)
        try? context.save()
        
        return container
    }()
    
    let context = ModelContext(container)
    let alice = try! context.fetch(FetchDescriptor<TeamMember>()).first!
    
    ScrollView {
        TechStackDistribution(member: alice)
            .padding()
    }
    .modelContainer(container)
}
