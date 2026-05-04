//
//  CatalyzeApp.swift
//  Catalyze
//
//  Main app entry point. Sets up the SwiftData ModelContainer and injects
//  the AppStore into the environment.
//
//  Equivalent to `src/main.tsx` + `src/App.tsx` in the web version.
//

import SwiftUI
import SwiftData

@main
struct CatalyzeApp: App {
    private let container: ModelContainer
    @State private var store = AppStore()
    
    init() {
        // Initialize ModelContainer
        // For debugging persistence issues, you can temporarily disable CloudKit
        // by using makePreviewContainer() instead of makeContainer()
        do {
            container = try PersistenceController.makeContainer()
            print("✓ ModelContainer initialized successfully")
        } catch {
            // In production, you might want more graceful error handling
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppLayout()
                .modelContainer(container)  // CRITICAL: Injects SwiftData context
                .environment(store)          // Injects AppStore
                .preferredColorScheme(store.appearanceColorScheme)
        }
    }
}

// MARK: - AppStore Extension for Appearance ---------------------------------

extension AppStore {
    /// Returns the ColorScheme based on saved appearance preference
    var appearanceColorScheme: ColorScheme? {
        // Read from UserDefaults directly since @AppStorage can't be used here
        guard let rawValue = UserDefaults.standard.string(forKey: "appearanceMode"),
              let mode = AppearanceMode(rawValue: rawValue)
        else {
            return nil // System default
        }
        
        return mode.colorScheme
    }
}

// MARK: - AppearanceMode (moved from SettingsView for shared access) --------

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
