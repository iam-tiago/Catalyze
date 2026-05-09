//
//  PromotionReadiness.swift
//  Catalyze
//
//  Promotion readiness tracker for a target tier. Criteria are child
//  entities for the same CloudKit-friendliness reasons as IDP actions.
//

import Foundation
import SwiftData

@Model
final class PromotionCriterion {
    // CloudKit doesn't support @Attribute(.unique)
    var id: String = UUID().uuidString
    var category: String = ""
    var label: String = ""
    var met: Bool = false
    var note: String? = nil
    var isCustom: Bool = false
    var sortIndex: Int = 0

    var record: PromotionReadiness? = nil

    init(
        id: String = UUID().uuidString,
        category: String,
        label: String,
        met: Bool = false,
        note: String? = nil,
        isCustom: Bool = false,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.category = category
        self.label = label
        self.met = met
        self.note = note
        self.isCustom = isCustom
        self.sortIndex = sortIndex
    }
}

@Model
final class PromotionReadiness {
    // CloudKit doesn't support @Attribute(.unique)
    var id: String = UUID().uuidString
    var memberId: String = ""
    var targetTierRaw: String = Seniority.t2_2.rawValue
    var statusRaw: String = PromotionStatus.notReady.rawValue
    var aiAssessment: String? = nil
    var notes: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \PromotionCriterion.record)
    var criteria: [PromotionCriterion]? = []

    // CloudKit requires inverse relationship
    var member: TeamMember? = nil

    init(
        id: String = UUID().uuidString,
        memberId: String,
        targetTier: Seniority,
        status: PromotionStatus = .notReady,
        aiAssessment: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.targetTierRaw = targetTier.rawValue
        self.statusRaw = status.rawValue
        self.aiAssessment = aiAssessment
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var targetTier: Seniority {
        get { Seniority(rawValue: targetTierRaw) ?? .t2_2 }
        set { targetTierRaw = newValue.rawValue }
    }

    var status: PromotionStatus {
        get { PromotionStatus(rawValue: statusRaw) ?? .notReady }
        set { statusRaw = newValue.rawValue }
    }

    var sortedCriteria: [PromotionCriterion] {
        (criteria ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }
}
