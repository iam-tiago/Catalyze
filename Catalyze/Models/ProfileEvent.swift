//
//  ProfileEvent.swift
//  Catalyze
//
//  Append-only history log: who changed which strength/weakness when.
//

import Foundation
import SwiftData

@Model
final class ProfileEvent {
    // CloudKit doesn't support @Attribute(.unique)
    var id: String = UUID().uuidString
    var memberId: String = ""
    var typeRaw: String = ProfileEventType.strengthAdded.rawValue
    var category: String = ""
    var intensityBeforeRaw: String? = nil
    var intensityAfterRaw: String? = nil
    var createdAt: Date = Date()

    // CloudKit requires inverse relationship
    var member: TeamMember? = nil

    init(
        id: String = UUID().uuidString,
        memberId: String,
        type: ProfileEventType,
        category: String,
        intensityBefore: Intensity? = nil,
        intensityAfter: Intensity? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.typeRaw = type.rawValue
        self.category = category
        self.intensityBeforeRaw = intensityBefore?.rawValue
        self.intensityAfterRaw = intensityAfter?.rawValue
        self.createdAt = createdAt
    }

    var type: ProfileEventType {
        get { ProfileEventType(rawValue: typeRaw) ?? .strengthAdded }
        set { typeRaw = newValue.rawValue }
    }

    var intensityBefore: Intensity? {
        get { intensityBeforeRaw.flatMap(Intensity.init(rawValue:)) }
        set { intensityBeforeRaw = newValue?.rawValue }
    }

    var intensityAfter: Intensity? {
        get { intensityAfterRaw.flatMap(Intensity.init(rawValue:)) }
        set { intensityAfterRaw = newValue?.rawValue }
    }
}
