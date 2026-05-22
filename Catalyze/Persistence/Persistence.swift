//
//  Persistence.swift
//  Catalyze
//
//  SwiftData container setup. This is the equivalent of `src/db/index.ts`
//  in the web app, plus CloudKit sync configuration.
//
//  Schema versioning: SwiftData uses VersionedSchema + SchemaMigrationPlan
//  rather than Dexie's `.version(N).stores(...)`. Right now we have only
//  v1 — when a future change requires migration, add a new
//  VersionedSchema struct and an entry in `migrationPlan.stages`.
//
//  CloudKit notes:
//  - Container identifier matches the one declared in entitlements:
//    `iCloud.com.prontto.Catalyze` (change to your actual bundle/team).
//  - Schema must satisfy CloudKit's constraints: every property has a
//    default, no @Attribute(.unique) constraints rely on the cloud
//    enforcing uniqueness (CloudKit ignores them; we use string UUIDs
//    so collisions are vanishingly unlikely anyway).
//  - The `cloudKitDatabase: .private` database keeps data scoped to
//    the user's iCloud account.
//

import Foundation
import SwiftData

// MARK: - Schema versioning --------------------------------------------------

enum CatalyzeSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            TeamMember.self,
            StrengthWeakness.self,
            StackEntry.self,
            TeamObservation.self,
            Insight.self,
            DevelopmentPlan.self,
            IDPAction.self,
            PromotionReadiness.self,
            PromotionCriterion.self,
            ProfileEvent.self,
            // ✅ ADDED: Seniority customization models
            OrganizationConfig.self,
            SeniorityLevel.self,
        ]
    }
}

enum CatalyzeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CatalyzeSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // Add migration stages here when introducing v2, v3, etc.
        []
    }
}

// MARK: - Container factory --------------------------------------------------

enum PersistenceController {

    /// Production container — persists to the app's Application Support
    /// directory and syncs via CloudKit.
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CatalyzeSchemaV1.self)
        
        // Try with CloudKit first, fall back to local-only if it fails
        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            let container = try ModelContainer(
                for: schema,
                migrationPlan: CatalyzeMigrationPlan.self,
                configurations: [config]
            )
            
            #if DEBUG
            Logger.log("SwiftData container created with CloudKit", level: .success)
            Logger.log("Store URL: \(config.url)", level: .info)
            #endif
            
            return container
        } catch {
            // CloudKit failed, try local-only
            Logger.log("CloudKit initialization failed, using local-only storage", level: .warning)
            Logger.error(error, context: "CloudKit initialization")
            
            return try makeLocalOnlyContainer()
        }
    }

    /// In-memory container for previews and unit tests. No CloudKit.
    static func makePreviewContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CatalyzeSchemaV1.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: CatalyzeMigrationPlan.self,
            configurations: [config]
        )
    }
    
    /// Debug container - persists locally but WITHOUT CloudKit sync
    /// Use this if CloudKit is causing issues during development
    static func makeLocalOnlyContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CatalyzeSchemaV1.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // Disabled CloudKit
        )
        
        let container = try ModelContainer(
            for: schema,
            migrationPlan: CatalyzeMigrationPlan.self,
            configurations: [config]
        )
        
        Logger.log("Local-only container created (CloudKit disabled)", level: .info)
        Logger.log("Store URL: \(config.url)", level: .info)
        
        return container
    }
}
