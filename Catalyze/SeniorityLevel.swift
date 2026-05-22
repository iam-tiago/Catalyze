//
//  SeniorityLevel.swift
//  Catalyze
//
//  Customizable seniority level system. Allows organizations to define
//  their own career ladders (T-Level, Junior/Pleno/Senior, FAANG L-levels, etc.).
//
//  SwiftData models for seniority configuration + presets.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - SeniorityLevel Model -----------------------------------------------

@Model
final class SeniorityLevel {
    // CloudKit doesn't support @Attribute(.unique)
    var id: String = UUID().uuidString
    
    /// Short code displayed in badges (e.g., "T2-1", "Senior", "L5")
    var code: String = ""
    
    /// Full display name (e.g., "Senior Engineer II", "Mid-Level Developer")
    var displayName: String = ""
    
    /// Numeric order for sorting (0 = entry level, 100 = highest)
    var order: Int = 0
    
    /// Hex color for visual representation (e.g., "#3B82F6")
    var colorHex: String = "#3B82F6"
    
    /// Category grouping (e.g., "IC", "Senior", "Staff", "Management")
    var category: String = ""
    
    /// Whether this level is currently active (allows soft-delete)
    var isActive: Bool = true
    
    /// Optional details about promotion criteria and expectations
    var levelDescription: String? = nil
    
    /// Inverse relationship to organization config
    var organization: OrganizationConfig? = nil
    
    init(
        id: String = UUID().uuidString,
        code: String,
        displayName: String,
        order: Int,
        colorHex: String,
        category: String,
        isActive: Bool = true,
        levelDescription: String? = nil
    ) {
        self.id = id
        self.code = code
        self.displayName = displayName
        self.order = order
        self.colorHex = colorHex
        self.category = category
        self.isActive = isActive
        self.levelDescription = levelDescription
    }
    
    /// Computed color from hex string
    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - OrganizationConfig Model -------------------------------------------

@Model
final class OrganizationConfig {
    var id: String = UUID().uuidString
    
    /// Organization name
    var name: String = "My Team"
    
    /// Active preset identifier
    var seniorityPresetRaw: String = SeniorityPreset.tLevel.rawValue
    
    /// Custom seniority levels for this organization
    @Relationship(deleteRule: .cascade, inverse: \SeniorityLevel.organization)
    var seniorityLevels: [SeniorityLevel]? = []
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        id: String = UUID().uuidString,
        name: String = "My Team",
        seniorityPreset: SeniorityPreset = .tLevel,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.seniorityPresetRaw = seniorityPreset.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var seniorityPreset: SeniorityPreset {
        get { SeniorityPreset(rawValue: seniorityPresetRaw) ?? .tLevel }
        set { seniorityPresetRaw = newValue.rawValue }
    }
    
    /// Active levels sorted by order
    var activeLevels: [SeniorityLevel] {
        (seniorityLevels ?? [])
            .filter { $0.isActive }
            .sorted { $0.order < $1.order }
    }
    
    /// Find a level by code
    func level(byCode code: String) -> SeniorityLevel? {
        seniorityLevels?.first { $0.code == code && $0.isActive }
    }
}

// MARK: - SeniorityLevelData (Value Type) ------------------------------------

/// Value type for preset data and migrations.
/// Used to create SwiftData models from presets.
struct SeniorityLevelData: Identifiable, Hashable {
    let id: String
    let code: String
    let displayName: String
    let order: Int
    let colorHex: String
    let category: String
    let levelDescription: String?
    
    init(
        id: String = UUID().uuidString,
        code: String,
        displayName: String,
        order: Int,
        colorHex: String,
        category: String,
        levelDescription: String? = nil
    ) {
        self.id = id
        self.code = code
        self.displayName = displayName
        self.order = order
        self.colorHex = colorHex
        self.category = category
        self.levelDescription = levelDescription
    }
    
    /// Convert to SwiftData model
    func toModel() -> SeniorityLevel {
        SeniorityLevel(
            id: id,
            code: code,
            displayName: displayName,
            order: order,
            colorHex: colorHex,
            category: category,
            levelDescription: levelDescription
        )
    }
}

// MARK: - SeniorityPreset Enum -----------------------------------------------

enum SeniorityPreset: String, Codable, CaseIterable, Identifiable {
    case tLevel = "t-level"
    case traditional = "traditional"
    case faang = "faang"
    case management = "management"
    case startup = "startup"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .tLevel:      return "T-Level (T1-T4)"
        case .traditional: return "Junior/Mid/Senior"
        case .faang:       return "FAANG (L3-L8)"
        case .management:  return "IC + Management Track"
        case .startup:     return "Startup (4 levels)"
        case .custom:      return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .tLevel:
            return "T-Level system: T1 (Associate), T2 (Specialist), T3 (Senior), T4 (Expert)"
        case .traditional:
            return "Traditional career ladder: Junior, Mid-Level, Senior, Lead"
        case .faang:
            return "Levels used in Big Tech: L3 (Entry), L4 (Mid), L5 (Senior), L6 (Staff), L7 (Senior Staff), L8 (Principal)"
        case .management:
            return "Career bifurcation: Individual Contributor and Management tracks"
        case .startup:
            return "Simplified system for startups: Junior, Mid, Senior, Lead"
        case .custom:
            return "Create your own custom levels"
        }
    }
    
    /// Preset levels data
    var levels: [SeniorityLevelData] {
        switch self {
        case .tLevel:
            return [
                SeniorityLevelData(
                    code: "T1-3",
                    displayName: "Associate Engineer",
                    order: 10,
                    colorHex: "#94A3B8",
                    category: "Associate",
                    levelDescription: "Entry level engineer building foundational skills"
                ),
                SeniorityLevelData(
                    code: "T2-1",
                    displayName: "Specialist I",
                    order: 20,
                    colorHex: "#3B82F6",
                    category: "Specialist",
                    levelDescription: "Specialist level with growing autonomy"
                ),
                SeniorityLevelData(
                    code: "T2-2",
                    displayName: "Specialist II",
                    order: 30,
                    colorHex: "#2563EB",
                    category: "Specialist",
                    levelDescription: "Solid specialist with team influence"
                ),
                SeniorityLevelData(
                    code: "T2-3",
                    displayName: "Specialist III",
                    order: 40,
                    colorHex: "#1D4ED8",
                    category: "Specialist",
                    levelDescription: "Strong specialist ready for Senior track"
                ),
                SeniorityLevelData(
                    code: "T3-1",
                    displayName: "Senior I",
                    order: 50,
                    colorHex: "#7C3AED",
                    category: "Senior",
                    levelDescription: "Senior level with cross-team impact"
                ),
                SeniorityLevelData(
                    code: "T3-2",
                    displayName: "Senior II",
                    order: 60,
                    colorHex: "#6D28D9",
                    category: "Senior",
                    levelDescription: "Advanced Senior with org-level influence"
                ),
                SeniorityLevelData(
                    code: "T3-3",
                    displayName: "Senior III (Principal)",
                    order: 70,
                    colorHex: "#5B21B6",
                    category: "Senior",
                    levelDescription: "Principal level with company-wide impact"
                ),
                SeniorityLevelData(
                    code: "T4",
                    displayName: "Expert (Distinguished)",
                    order: 80,
                    colorHex: "#4C1D95",
                    category: "Expert",
                    levelDescription: "Highest technical level - industry influence"
                )
            ]
            
        case .traditional:
            return [
                SeniorityLevelData(
                    code: "Junior",
                    displayName: "Junior Developer",
                    order: 10,
                    colorHex: "#10B981",
                    category: "IC",
                    levelDescription: "Entry-level professional starting their career"
                ),
                SeniorityLevelData(
                    code: "Mid",
                    displayName: "Mid-Level Developer",
                    order: 30,
                    colorHex: "#3B82F6",
                    category: "IC",
                    levelDescription: "Professional with autonomy in complex tasks"
                ),
                SeniorityLevelData(
                    code: "Senior",
                    displayName: "Senior Developer",
                    order: 50,
                    colorHex: "#8B5CF6",
                    category: "IC",
                    levelDescription: "Professional with technical leadership"
                ),
                SeniorityLevelData(
                    code: "Lead",
                    displayName: "Lead Engineer",
                    order: 70,
                    colorHex: "#EC4899",
                    category: "Leadership",
                    levelDescription: "Technical reference for the organization"
                )
            ]
            
        case .faang:
            return [
                SeniorityLevelData(
                    code: "L3",
                    displayName: "SWE I (Entry)",
                    order: 10,
                    colorHex: "#10B981",
                    category: "IC",
                    levelDescription: "Entry level software engineer"
                ),
                SeniorityLevelData(
                    code: "L4",
                    displayName: "SWE II (Mid)",
                    order: 25,
                    colorHex: "#3B82F6",
                    category: "IC",
                    levelDescription: "Mid-level software engineer"
                ),
                SeniorityLevelData(
                    code: "L5",
                    displayName: "Senior SWE",
                    order: 40,
                    colorHex: "#6366F1",
                    category: "Senior",
                    levelDescription: "Senior software engineer"
                ),
                SeniorityLevelData(
                    code: "L6",
                    displayName: "Staff SWE",
                    order: 55,
                    colorHex: "#8B5CF6",
                    category: "Staff",
                    levelDescription: "Staff software engineer"
                ),
                SeniorityLevelData(
                    code: "L7",
                    displayName: "Senior Staff SWE",
                    order: 70,
                    colorHex: "#A855F7",
                    category: "Staff",
                    levelDescription: "Senior Staff software engineer"
                ),
                SeniorityLevelData(
                    code: "L8",
                    displayName: "Principal SWE",
                    order: 85,
                    colorHex: "#C026D3",
                    category: "Leadership",
                    levelDescription: "Principal engineer"
                )
            ]
            
        case .management:
            return [
                // IC Track
                SeniorityLevelData(
                    code: "IC1",
                    displayName: "Junior IC",
                    order: 10,
                    colorHex: "#10B981",
                    category: "IC",
                    levelDescription: "Individual Contributor - Junior"
                ),
                SeniorityLevelData(
                    code: "IC2",
                    displayName: "Mid IC",
                    order: 20,
                    colorHex: "#3B82F6",
                    category: "IC",
                    levelDescription: "Individual Contributor - Mid"
                ),
                SeniorityLevelData(
                    code: "IC3",
                    displayName: "Senior IC",
                    order: 30,
                    colorHex: "#6366F1",
                    category: "IC",
                    levelDescription: "Individual Contributor - Senior"
                ),
                SeniorityLevelData(
                    code: "IC4",
                    displayName: "Staff IC",
                    order: 40,
                    colorHex: "#8B5CF6",
                    category: "IC",
                    levelDescription: "Individual Contributor - Staff"
                ),
                // Management Track
                SeniorityLevelData(
                    code: "M1",
                    displayName: "Engineering Manager",
                    order: 35,
                    colorHex: "#F59E0B",
                    category: "Management",
                    levelDescription: "Manages a team of engineers"
                ),
                SeniorityLevelData(
                    code: "M2",
                    displayName: "Senior Manager",
                    order: 50,
                    colorHex: "#D97706",
                    category: "Management",
                    levelDescription: "Manages multiple teams or senior ICs"
                ),
                SeniorityLevelData(
                    code: "M3",
                    displayName: "Director",
                    order: 65,
                    colorHex: "#B45309",
                    category: "Management",
                    levelDescription: "Leads engineering organization"
                ),
                SeniorityLevelData(
                    code: "M4",
                    displayName: "VP Engineering",
                    order: 80,
                    colorHex: "#92400E",
                    category: "Management",
                    levelDescription: "Leads engineering at company level"
                )
            ]
            
        case .startup:
            return [
                SeniorityLevelData(
                    code: "Junior",
                    displayName: "Junior Engineer",
                    order: 10,
                    colorHex: "#10B981",
                    category: "IC",
                    levelDescription: "Entry level"
                ),
                SeniorityLevelData(
                    code: "Mid",
                    displayName: "Mid-Level Engineer",
                    order: 30,
                    colorHex: "#3B82F6",
                    category: "IC",
                    levelDescription: "Autonomous engineer"
                ),
                SeniorityLevelData(
                    code: "Senior",
                    displayName: "Senior Engineer",
                    order: 50,
                    colorHex: "#8B5CF6",
                    category: "IC",
                    levelDescription: "Technical leader"
                ),
                SeniorityLevelData(
                    code: "Lead",
                    displayName: "Tech Lead",
                    order: 70,
                    colorHex: "#EC4899",
                    category: "Leadership",
                    levelDescription: "Team technical leader"
                )
            ]
            
        case .custom:
            return []
        }
    }
}

// MARK: - Migration from legacy Seniority enum -------------------------------

extension Seniority {
    /// Convert legacy enum to new SeniorityLevelData
    func toSeniorityLevelData() -> SeniorityLevelData {
        switch self {
        case .t1_3:
            return SeniorityLevelData(
                code: "T1-3",
                displayName: "Associate Engineer",
                order: 10,
                colorHex: "#94A3B8",
                category: "Associate"
            )
        case .t2_1:
            return SeniorityLevelData(
                code: "T2-1",
                displayName: "Specialist I",
                order: 20,
                colorHex: "#3B82F6",
                category: "Specialist"
            )
        case .t2_2:
            return SeniorityLevelData(
                code: "T2-2",
                displayName: "Specialist II",
                order: 30,
                colorHex: "#2563EB",
                category: "Specialist"
            )
        case .t2_3:
            return SeniorityLevelData(
                code: "T2-3",
                displayName: "Specialist III",
                order: 40,
                colorHex: "#1D4ED8",
                category: "Specialist"
            )
        case .t3_1:
            return SeniorityLevelData(
                code: "T3-1",
                displayName: "Senior I",
                order: 50,
                colorHex: "#7C3AED",
                category: "Senior"
            )
        case .t3_2:
            return SeniorityLevelData(
                code: "T3-2",
                displayName: "Senior II",
                order: 60,
                colorHex: "#6D28D9",
                category: "Senior"
            )
        case .t3_3:
            return SeniorityLevelData(
                code: "T3-3",
                displayName: "Senior III (Principal)",
                order: 70,
                colorHex: "#5B21B6",
                category: "Senior"
            )
        case .t4:
            return SeniorityLevelData(
                code: "T4",
                displayName: "Expert (Distinguished)",
                order: 80,
                colorHex: "#4C1D95",
                category: "Expert"
            )
        }
    }
}
