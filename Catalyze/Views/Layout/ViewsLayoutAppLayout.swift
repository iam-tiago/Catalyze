//
//  AppLayout.swift
//  Catalyze
//

import SwiftUI
import SwiftData

struct AppLayout: View {
    @Environment(AppStore.self) private var store
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    @State private var showingSearch = false

    var body: some View {
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
    }
}

// MARK: - Sidebar

private struct Sidebar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            // Navigation items
            VStack(spacing: 2) {
                SidebarNavItem(
                    title: "Team",
                    icon: "person.3.fill",
                    isActive: store.activeView == .team || store.activeView == .member
                ) { store.setActiveView(.team) }

                SidebarNavItem(
                    title: "Insights",
                    icon: "brain.fill",
                    isActive: store.activeView == .insights
                ) { store.setActiveView(.insights) }

                SidebarNavItem(
                    title: "Settings",
                    icon: "gearshape.fill",
                    isActive: store.activeView == .settings
                ) { store.setActiveView(.settings) }
            }
            .padding(.horizontal, CSpace.sm)
            .padding(.top, CSpace.xs)

            Spacer()

            // EM Profile Card
            EMProfileCard()
                .padding(CSpace.md)
        }
        .background { sidebarBackground.ignoresSafeArea() }
        .navigationTitle("Catalyze")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var sidebarBackground: some View {
        ZStack {
            MeshGradient(width: 3, height: 3, points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ], colors: [
                Color(red: 0.063, green: 0.031, blue: 0.157),
                Color(red: 0.051, green: 0.051, blue: 0.122),
                Color(red: 0.039, green: 0.039, blue: 0.102),
                Color(red: 0.102, green: 0.063, blue: 0.227),
                Color(red: 0.102, green: 0.063, blue: 0.271),
                Color(red: 0.059, green: 0.039, blue: 0.157),
                Color(red: 0.039, green: 0.031, blue: 0.094),
                Color(red: 0.071, green: 0.031, blue: 0.165),
                Color(red: 0.031, green: 0.031, blue: 0.078)
            ])

            // Dot grid overlay
            Canvas { ctx, size in
                let spacing: CGFloat = 22
                let radius: CGFloat = 0.85
                var x = spacing / 2
                while x < size.width {
                    var y = spacing / 2
                    while y < size.height {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(.white)
                        )
                        y += spacing
                    }
                    x += spacing
                }
            }
            .opacity(0.06)
        }
    }
}

// MARK: - Sidebar Nav Item

private struct SidebarNavItem: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CSpace.md) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? CColor.brandPrimary : .white.opacity(0.5))
                    .frame(width: 22, alignment: .center)

                Text(title)
                    .font(CFont.subheadline)
                    .fontWeight(isActive ? .medium : .regular)
                    .foregroundStyle(isActive ? .white : .white.opacity(0.5))

                Spacer()
            }
            .padding(.horizontal, CSpace.md)
            .padding(.vertical, 10)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: CRadius.sm)
                        .fill(.white.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: CRadius.sm)
                                .stroke(.white.opacity(0.08), lineWidth: 0.5)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - EM Profile Card

private struct EMProfileCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Button { store.setActiveView(.settings) } label: {
            HStack(spacing: CSpace.md) {
                avatarView
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.emProfile.name.isEmpty ? "Your Name" : store.emProfile.name)
                        .font(CFont.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(store.emProfile.role.isEmpty ? "Set up your profile" : store.emProfile.role)
                        .font(CFont.caption1)
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(CSpace.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: CRadius.sm)
                    .fill(.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: CRadius.sm)
                            .stroke(.white.opacity(0.10), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = store.emProfile.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage).resizable().scaledToFill()
        } else if let urlString = store.emProfile.photoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholderAvatar
            }
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        ZStack {
            Circle().fill(CColor.brandPrimary.opacity(0.25))
            Image(systemName: "person.fill")
                .font(.system(size: 15))
                .foregroundStyle(CColor.brandPrimary)
        }
    }
}

// MARK: - Detail Pane

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

// MARK: - Placeholders

private struct MemberViewPlaceholder: View {
    var body: some View {
        VStack(spacing: CSpace.lg) {
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

// MARK: - Preview

#Preview("App Layout") {
    AppLayout()
        .environment(AppStore())
        .modelContainer(SampleDataProvider.makePreviewContainer())
}
