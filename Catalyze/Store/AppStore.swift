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
        Logger.log("Attempting to add member: \(member.name)", level: .info)
        
        context.insert(member)
        
        do {
            try context.save()
            Logger.log("Member saved successfully: \(member.name)", level: .success)
        } catch {
            Logger.error(error, context: "Adding member \(member.name)")
            // TODO: Propagate error to UI layer for user notification
        }
    }

    func updateMember(_ member: TeamMember, in context: ModelContext) {
        Logger.log("Updating member: \(member.name)", level: .info)
        
        member.updatedAt = Date()
        
        do {
            try context.save()
            Logger.log("Member updated successfully", level: .success)
        } catch {
            Logger.error(error, context: "Updating member \(member.name)")
        }
    }

    func deleteMember(_ member: TeamMember, in context: ModelContext) {
        // SwiftData cascades to all relationship-owned children
        // (observations, idps, promotionRecords, profileEvents, tags, stack).
        let memberName = member.name
        context.delete(member)
        if selectedMemberId == member.id {
            setSelectedMember(nil)
        }
        do {
            try context.save()
            print("✓ Member deleted: \(memberName)")
        } catch {
            print("✗ Failed to delete member: \(error)")
        }
    }

    func addObservation(_ obs: TeamObservation, in context: ModelContext) {
        context.insert(obs)
        do {
            try context.save()
            print("✓ Observation saved")
        } catch {
            print("✗ Failed to save observation: \(error)")
        }
    }

    func deleteObservation(_ obs: TeamObservation, in context: ModelContext) {
        context.delete(obs)
        do {
            try context.save()
            print("✓ Observation deleted")
        } catch {
            print("✗ Failed to delete observation: \(error)")
        }
    }

    func addInsight(_ insight: Insight, in context: ModelContext) {
        context.insert(insight)
        do {
            try context.save()
            print("✓ Insight saved")
        } catch {
            print("✗ Failed to save insight: \(error)")
        }
    }

    func addIDP(_ idp: DevelopmentPlan, in context: ModelContext) {
        context.insert(idp)
        do {
            try context.save()
            print("✓ IDP saved")
        } catch {
            print("✗ Failed to save IDP: \(error)")
        }
    }

    func updateIDP(_ idp: DevelopmentPlan, in context: ModelContext) {
        idp.updatedAt = Date()
        do {
            try context.save()
            print("✓ IDP updated")
        } catch {
            print("✗ Failed to update IDP: \(error)")
        }
    }

    func deleteIDP(_ idp: DevelopmentPlan, in context: ModelContext) {
        context.delete(idp)
        do {
            try context.save()
            print("✓ IDP deleted")
        } catch {
            print("✗ Failed to delete IDP: \(error)")
        }
    }

    func addPromotionReadiness(
        _ record: PromotionReadiness,
        in context: ModelContext
    ) {
        context.insert(record)
        do {
            try context.save()
            print("✓ Promotion readiness saved")
        } catch {
            print("✗ Failed to save promotion readiness: \(error)")
        }
    }

    func updatePromotionReadiness(
        _ record: PromotionReadiness,
        in context: ModelContext
    ) {
        record.updatedAt = Date()
        do {
            try context.save()
            print("✓ Promotion readiness updated")
        } catch {
            print("✗ Failed to update promotion readiness: \(error)")
        }
    }

    func deletePromotionReadiness(
        _ record: PromotionReadiness,
        in context: ModelContext
    ) {
        context.delete(record)
        do {
            try context.save()
            print("✓ Promotion readiness deleted")
        } catch {
            print("✗ Failed to delete promotion readiness: \(error)")
        }
    }

    func addProfileEvent(_ event: ProfileEvent, in context: ModelContext) {
        context.insert(event)
        do {
            try context.save()
            print("✓ Profile event saved")
        } catch {
            print("✗ Failed to save profile event: \(error)")
        }
    }
}

// MARK: - UserDefaults keys --------------------------------------------------

private enum Keys {
    static let baseURL   = "catalyze_base_url"
    static let emProfile = "catalyze_em_profile"
}
