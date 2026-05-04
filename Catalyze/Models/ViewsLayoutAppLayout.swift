//
//  AppLayout.swift
//  Catalyze
//
//  Root layout shell for the iPad app. Uses NavigationSplitView with
//  a fixed sidebar (Team / Insights / Settings + EM profile at bottom)
//  and a detail pane that switches based on AppStore.activeView.
//
//  Equivalent to `src/components/Layout/AppLayout.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct AppLayout: View {
    @Environment(AppStore.self) private var store
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    @State private var showingSearch = false

    var body: some View {
        @Bindable var bindableStore = store

        NavigationSplitView {
            Sidebar()
        } detail: {
            DetailPane()
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(appearanceMode.colorScheme)
        .sheet(isPresented: $showingSearch) {
            GlobalSearch()
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        // ⌘K shortcut is handled via the commands modifier below
    }
}

// MARK: - Commands -----------------------------------------------------------

extension AppLayout {
    @ToolbarContentBuilder
    var appCommands: some ToolbarContent {
        ToolbarItem {
            Button {
                showingSearch = true
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }
            .keyboardShortcut("k", modifiers: .command)
        }
    }
}

// MARK: - Sidebar ------------------------------------------------------------

private struct Sidebar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            // Main navigation list
            List {
                Button {
                    store.setActiveView(.team)
                } label: {
                    Label("Team", systemImage: "person.3.fill")
                }
                .listRowBackground(store.activeView == .team ? Color.accentColor.opacity(0.15) : Color.clear)

                Button {
                    store.setActiveView(.insights)
                } label: {
                    Label("Insights", systemImage: "brain.fill")
                }
                .listRowBackground(store.activeView == .insights ? Color.accentColor.opacity(0.15) : Color.clear)

                Button {
                    store.setActiveView(.settings)
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .listRowBackground(store.activeView == .settings ? Color.accentColor.opacity(0.15) : Color.clear)
            }
            .listStyle(.sidebar)

            Divider()

            // EM Profile card at the bottom
            EMProfileCard()
                .padding()
        }
        .navigationTitle("Catalyze")
    }
}

// MARK: - EM Profile Card ----------------------------------------------------

private struct EMProfileCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Group {
                if let urlString = store.emProfile.photoUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        placeholderAvatar
                    }
                } else {
                    placeholderAvatar
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            // Name + role
            VStack(alignment: .leading, spacing: 2) {
                if !store.emProfile.name.isEmpty {
                    Text(store.emProfile.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }

                if !store.emProfile.role.isEmpty {
                    Text(store.emProfile.role)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // If both are empty, show a CTA
                if store.emProfile.name.isEmpty && store.emProfile.role.isEmpty {
                    Text("Set up your profile")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            // Chevron to indicate it's tappable (goes to Settings)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture {
            store.setActiveView(.settings)
        }
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint)
    }
}

// MARK: - Detail Pane --------------------------------------------------------

private struct DetailPane: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            switch store.activeView {
            case .team:
                TeamView()

            case .member:
                if let memberId = store.selectedMemberId {
                    MemberView(memberId: memberId)
                } else {
                    MemberViewPlaceholder()
                }

            case .insights:
                InsightsView()

            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Placeholders ------------------------------------------------------

private struct MemberViewPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Member Detail")
                .font(.title.bold())
            Text("Select a member from the team to view details")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Member")
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("App Layout") {
    AppLayout()
        .environment(AppStore())
        .modelContainer(try! PersistenceController.makePreviewContainer())
}
