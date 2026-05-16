//
//  CatalyzeApp.swift
//  Catalyze
//
//  App entry point. Sets up the SwiftData ModelContainer (with CloudKit
//  sync), injects the AppStore into the environment, and shows the
//  root view.
//
//  This file is the equivalent of `src/main.tsx` + `src/App.tsx` in the
//  web app — it's where the React root would live.
//

import SwiftUI
import SwiftData

@main
struct CatalyzeApp: App {

    // The SwiftData container is created once for the app's lifetime.
    // If creation fails (corrupted store, schema mismatch we can't
    // migrate), we fall back to an in-memory store so the app still
    // launches and the user can re-import their data from a backup.
    private let container: ModelContainer

    @State private var store = AppStore()

    init() {
        do {
            self.container = try PersistenceController.makeContainer()
            Logger.log("ModelContainer initialized successfully", level: .success)
            
            // Verify persistence is working
            #if DEBUG
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<TeamMember>()
            if let members = try? context.fetch(descriptor) {
                Logger.log("Found \(members.count) existing members in database", level: .info)
                if !members.isEmpty {
                    Logger.log("Sample members:", level: .debug)
                    for member in members.prefix(3) {
                        Logger.log("  - \(member.name) (\(member.role))", level: .debug)
                    }
                }
            }
            #endif
        } catch {
            // If all else fails, crash with a helpful error message
            // In production, this should rarely happen as makeContainer()
            // already has fallback to local-only storage
            Logger.error(error, context: "Failed to initialize any persistent store")
            fatalError("""
                Failed to initialize persistent storage.
                
                This usually means:
                1. Your iCloud entitlements are not configured
                2. The app doesn't have proper CloudKit permissions
                3. There's a schema migration issue
                
                Error: \(error.localizedDescription)
                
                Please check:
                - Xcode > Signing & Capabilities > iCloud
                - Container identifier matches your entitlements
                - You're signed into iCloud on the simulator/device
                """)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppLayout()
                .environment(store)
        }
        .modelContainer(container)
    }
}

