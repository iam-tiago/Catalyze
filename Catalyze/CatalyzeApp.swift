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
        } catch {
            // Last-resort fallback. Logged for diagnostics.
            print("[Catalyze] Failed to open persistent store: \(error)")
            // swiftlint:disable:next force_try
            self.container = try! PersistenceController.makePreviewContainer()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .modelContainer(container)
    }
}

// MARK: - ContentView (placeholder) ------------------------------------------
//
// The real layout (NavigationSplitView with a sidebar + detail) lives in
// Views/Layout/AppLayout.swift, which will be built in the next step.
// This placeholder keeps the project compiling end-to-end.

struct ContentView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        // Will be replaced by AppLayout() — see Views/Layout/AppLayout.swift
        // (next step). For now we render a placeholder so the project
        // builds and runs.
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Catalyze")
                .font(.largeTitle.bold())
            Text("Layout coming in the next step.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
