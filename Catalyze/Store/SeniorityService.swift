//
//  SeniorityService.swift
//  Catalyze
//
//  Centralized service for managing seniority levels.
//  Provides convenient access to the current organization's seniority configuration.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
class SeniorityService {
    private var modelContext: ModelContext
    private var config: OrganizationConfig?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.config = fetchOrCreateConfig()
    }
    
    // MARK: - Public API
    
    /// Get all active seniority levels sorted by order
    var levels: [SeniorityLevel] {
        config?.activeLevels ?? []
    }
    
    /// Get current preset type
    var currentPreset: SeniorityPreset {
        config?.seniorityPreset ?? .tLevel
    }
    
    /// Find a level by code
    func level(byCode code: String) -> SeniorityLevel? {
        config?.level(byCode: code)
    }
    
    /// Get the next level for promotion planning
    func nextLevel(after currentCode: String) -> SeniorityLevel? {
        guard let current = level(byCode: currentCode) else { return nil }
        return levels.first { $0.order > current.order }
    }
    
    /// Get all levels higher than the given code (for promotion targets)
    func higherLevels(than code: String) -> [SeniorityLevel] {
        guard let current = level(byCode: code) else { return levels }
        return levels.filter { $0.order > current.order }
    }
    
    /// Initialize default configuration if needed
    func ensureDefaultConfig() {
        if config == nil {
            config = createDefaultConfig()
        }
    }
    
    /// Reload configuration from database
    func reload() {
        config = fetchOrCreateConfig()
    }
    
    // MARK: - Migration Helpers
    
    /// Migrate a legacy Seniority enum value to the new system
    func migrateLegacySeniority(_ legacy: Seniority) -> SeniorityLevel? {
        let data = legacy.toSeniorityLevelData()
        return level(byCode: data.code)
    }
    
    /// Get seniority code for display (handles both old and new systems)
    func displayCode(for code: String) -> String {
        // If we have a matching level with custom display, use it
        if let level = level(byCode: code) {
            return level.code
        }
        // Otherwise return the raw code (backward compatibility)
        return code
    }
    
    /// Get color for a seniority code
    func color(for code: String) -> Color {
        level(byCode: code)?.color ?? CColor.brandPrimary
    }
    
    /// Get background color for a seniority code
    func backgroundColor(for code: String) -> Color {
        color(for: code).opacity(0.15)
    }
    
    // MARK: - Private Helpers
    
    private func fetchOrCreateConfig() -> OrganizationConfig? {
        let descriptor = FetchDescriptor<OrganizationConfig>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        do {
            let configs = try modelContext.fetch(descriptor)
            if let existing = configs.first {
                return existing
            } else {
                return createDefaultConfig()
            }
        } catch {
            print("❌ Error fetching OrganizationConfig: \(error)")
            return createDefaultConfig()
        }
    }
    
    private func createDefaultConfig() -> OrganizationConfig {
        let config = OrganizationConfig(
            name: "My Team",
            seniorityPreset: .tLevel
        )
        
        modelContext.insert(config)
        
        // Insert default T-Level preset
        for levelData in SeniorityPreset.tLevel.levels {
            let level = levelData.toModel()
            level.organization = config
            modelContext.insert(level)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error creating default config: \(error)")
        }
        
        return config
    }
}

// MARK: - Environment Key

struct SeniorityServiceKey: EnvironmentKey {
    static let defaultValue: SeniorityService? = nil
}

extension EnvironmentValues {
    var seniorityService: SeniorityService? {
        get { self[SeniorityServiceKey.self] }
        set { self[SeniorityServiceKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func seniorityService(_ service: SeniorityService) -> some View {
        environment(\.seniorityService, service)
    }
}
