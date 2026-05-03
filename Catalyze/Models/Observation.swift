//
//  Observation.swift
//  Catalyze
//
//  Equivalent to the TS `Observation` interface.
//

import Foundation
import SwiftData

@Model
final class Observation {
    @Attribute(.unique) var id: String = UUID().uuidString
    var memberId: String = ""
    var text: String = ""
    var contextRaw: String = ObservationContext.oneOnOne.rawValue
    var createdAt: Date = Date()

    /// Inverse — back-reference to the owning member.
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
