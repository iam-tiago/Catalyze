//
//  AppStore.swift
//  Catalyze
//
//  The single source of UI state for the app — the SwiftUI/Swift
//  equivalent of `useAppStore` from `src/store/index.ts`.
//
//  Differences from the web version:
//  - We DO NOT keep redundant arrays of members/observations/etc. here.
//    SwiftData's @Query property wrapper streams those directly into
//    the views, which is the idiomatic SwiftUI pattern. The store's
//    job is to hold *transient* state: which view is active, which
//    member is selected, the EM profile, the API credentials.
//  - All `addX/updateX/deleteX` mutations live on the store as
//    convenience methods that take a `ModelContext` — keeps the call
//    sites symmetrical with the web app while still letting SwiftUI's
//    @Query handle re-rendering.
//

import Foundation
import SwiftData
import Observation

@Observable
final class AppStore {

    // MARK: Navigation state -------------------------------------------------

    var activeView: ActiveView = .team
    var selectedMemberId: String? = nil

    // MARK: Settings (persisted via UserDefaults / Keychain) ----------------

    var apiKey: String = ""
    var baseURL: String = ClaudeClient.defaultBaseURL
    var emProfile: EMProfile = .empty

    // MARK: Init -------------------------------------------------------------

    init() {
        // Load settings from their respective stores on launch.
        self.apiKey = Keychain.get(Keychain.Key.claudeApiKey) ?? ""
        self.baseURL = UserDefaults.standard.string(forKey: Keys.baseURL)
            ?? ClaudeClient.defaultBaseURL
        self.emProfile = Self.loadEMProfile()
    }

    // MARK: Settings setters -------------------------------------------------

    func setApiKey(_ key: String) {
        apiKey = key
        try? Keychain.set(key.isEmpty ? nil : key, for: Keychain.Key.claudeApiKey)
    }

    func setBaseURL(_ url: String) {
        baseURL = url
        UserDefaults.standard.set(url, forKey: Keys.baseURL)
    }

    func setEMProfile(_ profile: EMProfile) {
        emProfile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Keys.emProfile)
        }
    }

    private static func loadEMProfile() -> EMProfile {
        guard let data = UserDefaults.standard.data(forKey: Keys.emProfile),
              let profile = try? JSONDecoder().decode(EMProfile.self, from: data)
        else { return .empty }
        return profile
    }

    // MARK: Navigation -------------------------------------------------------

    func setActiveView(_ view: ActiveView) {
        activeView = view
    }

    func setSelectedMember(_ id: String?) {
        selectedMemberId = id
        activeView = id == nil ? .team : .member
    }

    // MARK: Mutations --------------------------------------------------------
    //
    // SwiftUI views get their data via @Query, but they still need
    // somewhere to call into for inserts/updates/deletes. These methods
    // mirror the action names from the Zustand store so the mental
    // model carries over.

    func addMember(_ member: TeamMember, in context: ModelContext) {
        context.insert(member)
        try? context.save()
    }

    func updateMember(_ member: TeamMember, in context: ModelContext) {
        member.updatedAt = Date()
        try? context.save()
    }

    func deleteMember(_ member: TeamMember, in context: ModelContext) {
        // SwiftData cascades to all relationship-owned children
        // (observations, idps, promotionRecords, profileEvents, tags, stack).
        context.delete(member)
        if selectedMemberId == member.id {
            setSelectedMember(nil)
        }
        try? context.save()
    }

    func addObservation(_ obs: Observation, in context: ModelContext) {
        context.insert(obs)
        try? context.save()
    }

    func deleteObservation(_ obs: Observation, in context: ModelContext) {
        context.delete(obs)
        try? context.save()
    }

    func addInsight(_ insight: Insight, in context: ModelContext) {
        context.insert(insight)
        try? context.save()
    }

    func addIDP(_ idp: DevelopmentPlan, in context: ModelContext) {
        context.insert(idp)
        try? context.save()
    }

    func updateIDP(_ idp: DevelopmentPlan, in context: ModelContext) {
        idp.updatedAt = Date()
        try? context.save()
    }

    func deleteIDP(_ idp: DevelopmentPlan, in context: ModelContext) {
        context.delete(idp)
        try? context.save()
    }

    func addPromotionReadiness(
        _ record: PromotionReadiness,
        in context: ModelContext
    ) {
        context.insert(record)
        try? context.save()
    }

    func updatePromotionReadiness(
        _ record: PromotionReadiness,
        in context: ModelContext
    ) {
        record.updatedAt = Date()
        try? context.save()
    }

    func deletePromotionReadiness(
        _ record: PromotionReadiness,
        in context: ModelContext
    ) {
        context.delete(record)
        try? context.save()
    }

    func addProfileEvent(_ event: ProfileEvent, in context: ModelContext) {
        context.insert(event)
        try? context.save()
    }
}

// MARK: - UserDefaults keys --------------------------------------------------

private enum Keys {
    static let baseURL   = "catalyze_base_url"
    static let emProfile = "catalyze_em_profile"
}
