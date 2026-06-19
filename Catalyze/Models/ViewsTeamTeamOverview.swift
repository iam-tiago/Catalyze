//
//  TeamOverview.swift
//  Catalyze
//
//  Collapsible team dashboard shown above the member grid.
//  Three preset layouts: Overview, Technical, Growth.
//

import SwiftUI
import SwiftData

// MARK: - Layout Preset

enum OverviewLayout: String, CaseIterable {
    case overview  = "overview"
    case technical = "technical"
    case growth    = "growth"

    var label: String {
        switch self {
        case .overview:  return "Behavioral"
        case .technical: return "Technical"
        case .growth:    return "Growth"
        }
    }

    var icon: String {
        switch self {
        case .overview:  return "person.3.fill"
        case .technical: return "chevron.left.forwardslash.chevron.right"
        case .growth:    return "arrow.up.circle.fill"
        }
    }
}

// MARK: - TeamOverview

struct TeamOverview: View {
    @Environment(AppStore.self) private var store
    @Query(sort: \TeamMember.name) private var members: [TeamMember]

    @State private var isExpanded = true
    @AppStorage("teamOverviewLayout") private var selectedLayout: OverviewLayout = .overview

    var body: some View {
        VStack(spacing: 0) {
            headerView

            if isExpanded {
                Divider()

                VStack(spacing: CSpace.xl) {
                    // Layout picker
                    Picker("Layout", selection: $selectedLayout) {
                        ForEach(OverviewLayout.allCases, id: \.self) { layout in
                            Label(layout.label, systemImage: layout.icon).tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Stats — always visible in all layouts
                    statsGrid

                    // Layout-specific content
                    Group {
                        switch selectedLayout {
                        case .overview:
                            TeamRadar()
                        case .technical:
                            technicalContent
                        case .growth:
                            growthContent
                        }
                    }
                    .transition(.opacity)
                    .animation(.smooth, value: selectedLayout)
                }
                .padding(CSpace.lg)
            }
        }
        .background(CColor.neutral0)
        .clipShape(RoundedRectangle(cornerRadius: CRadius.md))
        .cardShadow()
    }

    // MARK: - Header

    private var headerView: some View {
        Button {
            withAnimation(.smooth) { isExpanded.toggle() }
        } label: {
            HStack {
                Label("Team Overview", systemImage: "chart.bar.fill")
                    .font(CFont.headline)
                    .foregroundStyle(CColor.neutral900)

                Spacer()

                if !isExpanded {
                    Text("\(members.count) members")
                        .font(CFont.caption1)
                        .foregroundStyle(CColor.neutral600)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CColor.neutral400)
            }
            .padding(CSpace.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats (shared)

    private var statsGrid: some View {
        HStack(spacing: CSpace.md) {
            StatCard(
                icon: "person.3.fill",
                value: "\(members.count)",
                label: "Team Size",
                variant: .info
            )
            StatCard(
                icon: "checklist",
                value: "\(activeIDPsCount)",
                label: "Active IDPs",
                variant: .strength
            )
            StatCard(
                icon: "arrow.up.circle.fill",
                value: "\(membersInPromotionCount)",
                label: "In Promotion",
                variant: .growth
            )
        }
    }

    // MARK: - Technical layout

    private var technicalContent: some View {
        VStack(spacing: CSpace.xl) {
            TeamTechStackDistribution()
            TeamTechnicalRadar()
        }
    }

    // MARK: - Growth layout

    private var growthContent: some View {
        VStack(alignment: .leading, spacing: CSpace.lg) {
            idpBoard
            promotionPipeline
        }
    }

    private var idpBoard: some View {
        VStack(alignment: .leading, spacing: CSpace.md) {
            Text("DEVELOPMENT PLANS")
                .font(CFont.caption2)
                .foregroundStyle(CColor.neutral400)

            if membersWithActiveIDPs.isEmpty {
                Text("No active development plans")
                    .font(CFont.caption1)
                    .foregroundStyle(CColor.neutral400)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, CSpace.sm)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(membersWithActiveIDPs.enumerated()), id: \.element.id) { index, member in
                        let activeIDPs = (member.idps ?? []).filter { $0.status == .active }

                        Button {
                            store.navigateToMember(member.id, section: .idp)
                        } label: {
                            HStack(spacing: CSpace.md) {
                                initialsCircle(for: member.name, color: CColor.brandPrimary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name)
                                        .font(CFont.subheadline)
                                        .foregroundStyle(CColor.neutral900)
                                    if let firstIDP = activeIDPs.first {
                                        Text(firstIDP.title)
                                            .font(CFont.caption1)
                                            .foregroundStyle(CColor.neutral600)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                if activeIDPs.count > 1 {
                                    Text("\(activeIDPs.count) IDPs")
                                        .font(CFont.caption2)
                                        .foregroundStyle(CColor.info)
                                        .padding(.horizontal, CSpace.sm)
                                        .padding(.vertical, 3)
                                        .background(CColor.infoLight)
                                        .clipShape(Capsule())
                                } else if let idp = activeIDPs.first {
                                    let actions = idp.sortedActions
                                    let done = actions.filter { $0.done }.count
                                    if !actions.isEmpty {
                                        Text("\(done)/\(actions.count)")
                                            .font(CFont.caption2)
                                            .foregroundStyle(CColor.info)
                                            .monospacedDigit()
                                    }
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(CColor.neutral400)
                            }
                            .padding(.vertical, CSpace.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < membersWithActiveIDPs.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(CSpace.md)
                .background(CColor.neutral50)
                .clipShape(RoundedRectangle(cornerRadius: CRadius.sm))
            }
        }
    }

    private var promotionPipeline: some View {
        VStack(alignment: .leading, spacing: CSpace.md) {
            Text("PROMOTION PIPELINE")
                .font(CFont.caption2)
                .foregroundStyle(CColor.neutral400)

            if membersInPromotionList.isEmpty {
                Text("No members in promotion process")
                    .font(CFont.caption1)
                    .foregroundStyle(CColor.neutral400)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, CSpace.sm)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(membersInPromotionList.enumerated()), id: \.element.member.id) { index, item in
                        Button {
                            store.navigateToMember(item.member.id, section: .promotion)
                        } label: {
                            HStack(spacing: CSpace.md) {
                                initialsCircle(for: item.member.name, color: CColor.growth)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.member.name)
                                        .font(CFont.subheadline)
                                        .foregroundStyle(CColor.neutral900)
                                    Text(item.member.role)
                                        .font(CFont.caption1)
                                        .foregroundStyle(CColor.neutral600)
                                }

                                Spacer()

                                HStack(spacing: CSpace.sm) {
                                    TierBadge(tier: item.record.targetTier.rawValue)
                                    promotionStatusBadge(item.record.status)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(CColor.neutral400)
                            }
                            .padding(.vertical, CSpace.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < membersInPromotionList.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(CSpace.md)
                .background(CColor.neutral50)
                .clipShape(RoundedRectangle(cornerRadius: CRadius.sm))
            }
        }
    }

    // MARK: - Small helpers

    private func initialsCircle(for name: String, color: Color) -> some View {
        ZStack {
            Circle().fill(color.opacity(0.15))
            Text(name.prefix(1).uppercased())
                .font(CFont.caption1)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(width: 32, height: 32)
    }

    @ViewBuilder
    private func promotionStatusBadge(_ status: PromotionStatus) -> some View {
        let (label, color): (String, Color) = switch status {
        case .ready:      ("Ready", CColor.strength)
        case .inProgress: ("In Progress", CColor.growth)
        case .notReady:   ("Not Ready", CColor.neutral400)
        }
        Text(label)
            .font(CFont.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, CSpace.sm)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Computed properties

    private var activeIDPsCount: Int {
        members.reduce(0) { $0 + (($1.idps ?? []).filter { $0.status == .active }.count) }
    }

    private var membersInPromotionCount: Int {
        members.filter { member in
            (member.promotionRecords ?? []).contains { $0.status == .inProgress || $0.status == .ready }
        }.count
    }

    private var membersWithActiveIDPs: [TeamMember] {
        members.filter { (($0.idps ?? []).contains { $0.status == .active }) }
    }

    private var membersInPromotionList: [(member: TeamMember, record: PromotionReadiness)] {
        members.compactMap { member in
            guard let record = (member.promotionRecords ?? [])
                .first(where: { $0.status == .inProgress || $0.status == .ready })
            else { return nil }
            return (member, record)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        TeamOverview()
            .padding(CSpace.x2l)
    }
    .background(CColor.neutral50)
    .modelContainer(SampleDataProvider.makePreviewContainer())
}
