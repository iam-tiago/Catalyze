//
//  Observation.swift
//  Catalyze
//
//  Equivalent to the TS `Observation` interface.
//  Note: Renamed from `Observation` to `TeamObservation` to avoid conflict
//  with Swift's Observation framework.
//

import Foundation
import SwiftData

@Model
final class TeamObservation {
    // CloudKit doesn't support @Attribute(.unique)
    var id: String = UUID().uuidString
    var memberId: String = ""
    var text: String = ""
    var contextRaw: String = ObservationContext.oneOnOne.rawValue
    var createdAt: Date = Date()

    /// CloudKit requires inverse relationship
    var member: TeamMember? = nil

    init(
        id: String = UUID().uuidString,
        memberId: String,
        text: String,
        context: ObservationContext,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.text = text
        self.contextRaw = context.rawValue
        self.createdAt = createdAt
    }

    var context: ObservationContext {
        get { ObservationContext(rawValue: contextRaw) ?? .other }
        set { contextRaw = newValue.rawValue }
    }
}
// Type alias for backward compatibility with existing code
// Note: Use `TeamObservation` directly in new code to avoid ambiguity
typealias CatalyzeObservation = TeamObservation

