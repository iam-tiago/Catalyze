//
//  Insight.swift
//  Catalyze
//
//  Cached AI insight result. `memberId` is nil for team-level insights.
//

import Foundation
import SwiftData

@Model
final class Insight {
    @Attribute(.unique) var id: String = UUID().uuidString
    var typeRaw: String = InsightType.individual.rawValue
    var memberId: String? = nil
    var prompt: String = ""
    var response: String = ""
    var createdAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        type: InsightType,
        memberId: String? = nil,
        prompt: String,
        response: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.memberId = memberId
        self.prompt = prompt
        self.response = response
        self.createdAt = createdAt
    }

    var type: InsightType {
        get { InsightType(rawValue: typeRaw) ?? .individual }
        set { typeRaw = newValue.rawValue }
    }
}
