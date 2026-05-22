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
    
    /// Full display name (e.g., "Senior Engineer II", "Sênior Pleno")
    var displayName: String = ""
    
    /// Numeric order for sorting (0 = entry level, 100 = highest)
    var order: Int = 0
    
    /// Hex color for visual representation (e.g., "#3B82F6")
    var colorHex: String = "#3B82F6"
    
    /// Category grouping (e.g., "IC", "Senior", "Staff", "Management")
    var category: String = ""
    
    /// Whether this level is currently active (allows soft-delete)
    var isActive: Bool = true
    
    /// Optional description for promotion criteria
    var description: String? = nil
    
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
        description: String? = nil
    ) {
        self.id = id
        self.code = code
        self.displayName = displayName
        self.order = order
        self.colorHex = colorHex
        self.category = category
        self.isActive = isActive
        self.description = description
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
    let description: String?
    
    init(
        id: String = UUID().uuidString,
        code: String,
        displayName: String,
        order: Int,
        colorHex: String,
        category: String,
        description: String? = nil
    ) {
        self.id = id
        self.code = code
        self.displayName = displayName
        self.order = order
        self.colorHex = colorHex
        self.category = category
        self.description = description
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
            description: description
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
        case .traditional: return "Junior/Pleno/Senior"
        case .faang:       return "FAANG (L3-L8)"
        case .management:  return "IC + Management Track"
        case .startup:     return "Startup (4 níveis)"
        case .custom:      return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .tLevel:
            return "Sistema de níveis técnicos com sub-divisões (T1-3, T2-1, T2-2, T2-3, T3-1, T3-2, T3-3, T4)"
        case .traditional:
            return "Nomenclatura tradicional brasileira: Júnior, Pleno, Sênior, Especialista"
        case .faang:
            return "Níveis usados em Big Tech: L3 (Entry), L4 (Mid), L5 (Senior), L6 (Staff), L7 (Senior Staff), L8 (Principal)"
        case .management:
            return "Bifurcação de carreira: Individual Contributor e Management tracks"
        case .startup:
            return "Sistema simplificado para startups: Junior, Mid, Senior, Lead"
        case .custom:
            return "Crie seus próprios níveis customizados"
        }
    }
    
    /// Preset levels data
    var levels: [SeniorityLevelData] {
        switch self {
        case .tLevel:
            return [
                SeniorityLevelData(
                    code: "T1-3",
                    displayName: "IC Engineer",
                    order: 10,
                    colorHex: "#94A3B8",
                    category: "IC",
                    description: "Individual Contributor - Entry level engineer"
                ),
                SeniorityLevelData(
                    code: "T2-1",
                    displayName: "Senior Engineer I",
                    order: 20,
                    colorHex: "#3B82F6",
                    category: "Senior",
                    description: "Senior level with growing autonomy"
                ),
                SeniorityLevelData(
                    code: "T2-2",
                    displayName: "Senior Engineer II",
                    order: 30,
                    colorHex: "#2563EB",
                    category: "Senior",
                    description: "Solid senior with team influence"
                ),
                SeniorityLevelData(
                    code: "T2-3",
                    displayName: "Senior Engineer III",
                    order: 40,
                    colorHex: "#1D4ED8",
                    category: "Senior",
                    description: "Strong senior ready for Staff track"
                ),
                SeniorityLevelData(
                    code: "T3-1",
                    displayName: "Staff Engineer I",
                    order: 50,
                    colorHex: "#7C3AED",
                    category: "Staff",
                    description: "Staff level with cross-team impact"
                ),
                SeniorityLevelData(
                    code: "T3-2",
                    displayName: "Staff Engineer II",
                    order: 60,
                    colorHex: "#6D28D9",
                    category: "Staff",
                    description: "Senior Staff with org-level influence"
                ),
                SeniorityLevelData(
                    code: "T3-3",
                    displayName: "Principal Engineer",
                    order: 70,
                    colorHex: "#5B21B6",
                    category: "Staff",
                    description: "Principal with company-wide impact"
                ),
                SeniorityLevelData(
                    code: "T4",
                    displayName: "Distinguished Engineer",
                    order: 80,
                    colorHex: "#4C1D95",
                    category: "Leadership",
                    description: "Highest technical level - industry influence"
                )
            ]
            
        case .traditional:
            return [
                SeniorityLevelData(
                    code: "Júnior",
                    displayName: "Desenvolvedor Júnior",
                    order: 10,
                    colorHex: "#10B981",
                    category: "IC",
                    description: "Profissional em início de carreira"
                ),
                SeniorityLevelData(
                    code: "Pleno",
                    displayName: "Desenvolvedor Pleno",
                    order: 30,
                    colorHex: "#3B82F6",
                    category: "IC",
                    description: "Profissional com autonomia em tarefas complexas"
                ),
                SeniorityLevelData(
                    code: "Sênior",
                    displayName: "Desenvolvedor Sênior",
                    order: 50,
                    colorHex: "#8B5CF6",
                    category: "IC",
                    description: "Profissional com liderança técnica"
                ),
                SeniorityLevelData(
                    code: "Especialista",
                    displayName: "Especialista",
                    order: 70,
                    colorHex: "#EC4899",
                    category: "Leadership",
                    description: "Referência técnica da organização"
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
                    description: "Entry level software engineer"
                ),
                SeniorityLevelData(
                    code: "L4",
                    displayName: "SWE II (Mid)",
                    order: 25,
                    colorHex: "#3B82F6",
                    category: "IC",
                    description: "Mid-level software engineer"
                ),
                SeniorityLevelData(
                    code: "L5",
                    displayName: "Senior SWE",
                    order: 40,
                    colorHex: "#6366F1",
                    category: "Senior",
                    description: "Senior software engineer"
                ),
                SeniorityLevelData(
                    code: "L6",
                    displayName: "Staff SWE",
                    order: 55,
                    colorHex: "#8B5CF6",
                    category: "Staff",
                    description: "Staff software engineer"
                ),
                SeniorityLevelData(
                    code: "L7",
                    displayName: "Senior Staff SWE",
                    order: 70,
                    colorHex: "#A855F7",
                    category: "Staff",
                    description: "Senior Staff software engineer"
                ),
                SeniorityLevelData(
                    code: "L8",
                    displayName: "Principal SWE",
                    order: 85,
                    colorHex: "#C026D3",
                    category: "Leadership",
                    description: "Principal engineer"
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
                    description: "Individual Contributor - Junior"
                ),
                SeniorityLevelData(
                    code: "IC2",
                    displayName: "Mid IC",
                    order: 20,
                    colorHex: "#3B82F6",
                    category: "IC",
                    description: "Individual Contributor - Mid"
                ),
                SeniorityLevelData(
                    code: "IC3",
                    displayName: "Senior IC",
                    order: 30,
                    colorHex: "#6366F1",
                    category: "IC",
                    description: "Individual Contributor - Senior"
                ),
                SeniorityLevelData(
                    code: "IC4",
                    displayName: "Staff IC",
                    order: 40,
                    colorHex: "#8B5CF6",
                    category: "IC",
                    description: "Individual Contributor - Staff"
                ),
                // Management Track
                SeniorityLevelData(
                    code: "M1",
                    displayName: "Engineering Manager",
                    order: 35,
                    colorHex: "#F59E0B",
                    category: "Management",
                    description: "Manages a team of engineers"
                ),
                SeniorityLevelData(
                    code: "M2",
                    displayName: "Senior Manager",
                    order: 50,
                    colorHex: "#D97706",
                    category: "Management",
                    description: "Manages multiple teams or senior ICs"
                ),
                SeniorityLevelData(
                    code: "M3",
                    displayName: "Director",
                    order: 65,
                    colorHex: "#B45309",
                    category: "Management",
                    description: "Leads engineering organization"
                ),
                SeniorityLevelData(
                    code: "M4",
                    displayName: "VP Engineering",
                    order: 80,
                    colorHex: "#92400E",
                    category: "Management",
                    description: "Leads engineering at company level"
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
                    description: "Entry level"
                ),
                SeniorityLevelData(
                    code: "Mid",
                    displayName: "Mid-Level Engineer",
                    order: 30,
                    colorHex: "#3B82F6",
                    category: "IC",
                    description: "Autonomous engineer"
                ),
                SeniorityLevelData(
                    code: "Senior",
                    displayName: "Senior Engineer",
                    order: 50,
                    colorHex: "#8B5CF6",
                    category: "IC",
                    description: "Technical leader"
                ),
                SeniorityLevelData(
                    code: "Lead",
                    displayName: "Tech Lead",
                    order: 70,
                    colorHex: "#EC4899",
                    category: "Leadership",
                    description: "Team technical leader"
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
                displayName: "IC Engineer",
                order: 10,
                colorHex: "#94A3B8",
                category: "IC"
            )
        case .t2_1:
            return SeniorityLevelData(
                code: "T2-1",
                displayName: "Senior Engineer I",
                order: 20,
                colorHex: "#3B82F6",
                category: "Senior"
            )
        case .t2_2:
            return SeniorityLevelData(
                code: "T2-2",
                displayName: "Senior Engineer II",
                order: 30,
                colorHex: "#2563EB",
                category: "Senior"
            )
        case .t2_3:
            return SeniorityLevelData(
                code: "T2-3",
                displayName: "Senior Engineer III",
                order: 40,
                colorHex: "#1D4ED8",
                category: "Senior"
            )
        case .t3_1:
            return SeniorityLevelData(
                code: "T3-1",
                displayName: "Staff Engineer I",
                order: 50,
                colorHex: "#7C3AED",
                category: "Staff"
            )
        case .t3_2:
            return SeniorityLevelData(
                code: "T3-2",
                displayName: "Staff Engineer II",
                order: 60,
                colorHex: "#6D28D9",
                category: "Staff"
            )
        case .t3_3:
            return SeniorityLevelData(
                code: "T3-3",
                displayName: "Principal Engineer",
                order: 70,
                colorHex: "#5B21B6",
                category: "Staff"
            )
        case .t4:
            return SeniorityLevelData(
                code: "T4",
                displayName: "Distinguished Engineer",
                order: 80,
                colorHex: "#4C1D95",
                category: "Leadership"
            )
        }
    }
}
