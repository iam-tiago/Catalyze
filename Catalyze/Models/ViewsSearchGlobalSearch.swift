//
//  GlobalSearch.swift
//  Catalyze
//
//  Global search functionality accessible via ⌘K. Searches across members,
//  observations, and IDPs, presenting results in a searchable list.
//
//  Equivalent to `src/components/Search/GlobalSearch.tsx` in the web app.
//

import SwiftUI
import SwiftData

struct GlobalSearch: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @Query private var members: [TeamMember]
    @Query private var observations: [TeamObservation]
    @Query private var idps: [DevelopmentPlan]
    
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        
                        Text("Search")
                            .font(.title2.bold())
                        
                        Text("Find members, observations, or development plans")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 40)
                } else {
                    // Results sections
                    if !filteredMembers.isEmpty {
                        Section("Members (\(filteredMembers.count))") {
                            ForEach(filteredMembers) { member in
                                MemberRow(member: member)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        store.setSelectedMember(member.id)
                                        dismiss()
                                    }
                            }
                        }
                    }
                    
                    if !filteredObservations.isEmpty {
                        Section("Observations (\(filteredObservations.count))") {
                            ForEach(filteredObservations) { obs in
                                ObservationRow(observation: obs, members: members)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let memberId = obs.member?.id {
                                            store.setSelectedMember(memberId)
                                            dismiss()
                                        }
                                    }
                            }
                        }
                    }
                    
                    if !filteredIDPs.isEmpty {
                        Section("Development Plans (\(filteredIDPs.count))") {
                            ForEach(filteredIDPs) { idp in
                                IDPRow(idp: idp, members: members)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let memberId = idp.member?.id {
                                            store.setSelectedMember(memberId)
                                            dismiss()
                                        }
                                    }
                            }
                        }
                    }
                    
                    // No results
                    if filteredMembers.isEmpty && filteredObservations.isEmpty && filteredIDPs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                            
                            Text("No results")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 40)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search members, observations, IDPs...")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                }
            }
            .onAppear {
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - Filtered Results -----------------------------------------------
    
    private var filteredMembers: [TeamMember] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        
        return members.filter { member in
            member.name.lowercased().contains(query) ||
            member.role.lowercased().contains(query) ||
            member.seniority.rawValue.lowercased().contains(query)
        }
    }
    
    private var filteredObservations: [TeamObservation] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        
        return observations.filter { obs in
            obs.text.lowercased().contains(query) ||
            obs.context.rawValue.lowercased().contains(query)
        }
    }
    
    private var filteredIDPs: [DevelopmentPlan] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        
        return idps.filter { idp in
            idp.title.lowercased().contains(query) ||
            idp.objective.lowercased().contains(query)
        }
    }
}

// MARK: - Member Row ---------------------------------------------------------

private struct MemberRow: View {
    let member: TeamMember
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline.weight(.medium))
                
                Text("\(member.role) • \(member.seniority.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Observation Row ----------------------------------------------------

private struct ObservationRow: View {
    let observation: TeamObservation
    let members: [TeamMember]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                if let memberName = memberName {
                    Text(memberName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(observation.text)
                    .font(.subheadline)
                    .lineLimit(2)
                
                HStack {
                    Text(observation.context.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.1), in: Capsule())
                    
                    Text(observation.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
        }
    }
    
    private var memberName: String? {
        members.first { $0.id == observation.memberId }?.name
    }
}

// MARK: - IDP Row ------------------------------------------------------------

private struct IDPRow: View {
    let idp: DevelopmentPlan
    let members: [TeamMember]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                if let memberName = memberName {
                    Text(memberName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(idp.title)
                    .font(.subheadline.weight(.medium))
                
                Text(idp.objective)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(idp.status.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1), in: Capsule())
                        .foregroundStyle(statusColor)
                    
                    if let targetDate = idp.targetDate {
                        Text(targetDate, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var memberName: String? {
        members.first { $0.id == idp.memberId }?.name
    }
    
    private var statusColor: Color {
        switch idp.status {
        case .active:    return .blue
        case .onHold:    return .orange
        case .completed: return .green
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    GlobalSearch()
        .environment(AppStore())
        .modelContainer(try! PersistenceController.makePreviewContainer())
}
