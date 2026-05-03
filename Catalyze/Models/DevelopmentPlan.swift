//
//  DevelopmentPlan.swift
//  Catalyze
//
//  Individual Development Plans. `IDPAction` is a child entity (one-to-many)
//  rather than embedded JSON so each action's `done` flag can be flipped
//  without rewriting the whole plan — better for CloudKit sync.
//

import Foundation
import SwiftData

@Model
final class IDPAction {
    @Attribute(.unique) var id: String = UUID().uuidString
    var text: String = ""
    var done: Bool = false
    /// For deterministic ordering (CloudKit doesn't preserve array order
    /// across devices reliably).
    var sortIndex: Int = 0

    var plan: DevelopmentPlan? = nil

    init(
        id: String = UUID().uuidString,
        text: String,
        done: Bool = false,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.text = text
        self.done = done
        self.sortIndex = sortIndex
    }
}

@Model
final class DevelopmentPlan {
    @Attribute(.unique) var id: String = UUID().uuidString
    var memberId: String = ""
    var title: String = ""
    /// ID of a `StrengthWeakness` (only weaknesses / growth areas link here).
    var linkedGrowthAreaId: String? = nil
    var objective: String = ""
    var targetDate: Date? = nil
    var statusRaw: String = IDPStatus.active.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \IDPAction.plan)
    var actions: [IDPAction]? = []

    var member: TeamMember? = nil

    init(
        id: String = UUID().uuidString,
        memberId: String,
        title: String,
        linkedGrowthAreaId: String? = nil,
        objective: String,
        targetDate: Date? = nil,
        status: IDPStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.title = title
        self.linkedGrowthAreaId = linkedGrowthAreaId
        self.objective = objective
        self.targetDate = targetDate
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var status: IDPStatus {
        get { IDPStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    /// Sorted view of actions.
    var sortedActions: [IDPAction] {
        (actions ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }
}
