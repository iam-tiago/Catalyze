//
//  Enums.swift
//  Catalyze
//
//  Direct port of the TypeScript enumerations in `src/types/index.ts`.
//  Each enum is `String`-backed and `Codable` so it can be persisted
//  by SwiftData and serialized for export / Claude API prompts.
//

import Foundation

// MARK: - Seniority ----------------------------------------------------------

enum Seniority: String, Codable, CaseIterable, Identifiable, Hashable {
    case t1_3 = "T1-3"
    case t2_1 = "T2-1"
    case t2_2 = "T2-2"
    case t2_3 = "T2-3"
    case t3_1 = "T3-1"
    case t3_2 = "T3-2"
    case t3_3 = "T3-3"
    case t4   = "T4"

    var id: String { rawValue }
    var label: String { rawValue }
}

// MARK: - Intensity ----------------------------------------------------------
//
// In the web app this was modeled as two narrowed string unions
// (StrengthIntensity / WeaknessIntensity) plus a discriminating union.
// Swift doesn't do narrowed string unions, so we use one enum with a
// `kind` (strength/weakness) parameter to validate which values are
// valid for which side. See `StrengthWeakness.intensityIsValid`.

enum Intensity: String, Codable, CaseIterable, Identifiable, Hashable {
    case emerging   = "Emerging"
    case solid      = "Solid"        // strengths only
    case strong     = "Strong"       // strengths only
    case developing = "Developing"   // weaknesses only
    case blocking   = "Blocking"     // weaknesses only

    var id: String { rawValue }

    static let strengthCases:  [Intensity] = [.emerging, .solid, .strong]
    static let weaknessCases:  [Intensity] = [.emerging, .developing, .blocking]
}

// MARK: - Strength / Weakness kind ------------------------------------------

enum SWKind: String, Codable, CaseIterable, Hashable {
    case strength
    case weakness
}

// MARK: - Observation context -----------------------------------------------

enum ObservationContext: String, Codable, CaseIterable, Identifiable, Hashable {
    case oneOnOne          = "1:1"
    case incident          = "Incident"
    case sprintReview      = "Sprint Review"
    case performanceCycle  = "Performance Cycle"
    case other             = "Other"

    var id: String { rawValue }
}

// MARK: - IDP status ---------------------------------------------------------

enum IDPStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case active    = "Active"
    case onHold    = "On Hold"
    case completed = "Completed"

    var id: String { rawValue }
}

// MARK: - Insight type -------------------------------------------------------

enum InsightType: String, Codable, CaseIterable, Identifiable, Hashable {
    case individual    = "individual"
    case situational   = "situational"
    case team          = "team"
    case oneOnOnePrep  = "1on1-prep"
    case perfReview    = "perf-review"

    var id: String { rawValue }
}

// MARK: - Promotion status ---------------------------------------------------

enum PromotionStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case notReady    = "Not Ready"
    case inProgress  = "In Progress"
    case ready       = "Ready"

    var id: String { rawValue }
}

// MARK: - Profile event type -------------------------------------------------

enum ProfileEventType: String, Codable, CaseIterable, Hashable {
    case strengthAdded   = "strength_added"
    case strengthUpdated = "strength_updated"
    case strengthRemoved = "strength_removed"
    case weaknessAdded   = "weakness_added"
    case weaknessUpdated = "weakness_updated"
    case weaknessRemoved = "weakness_removed"
}

// MARK: - Stack proficiency --------------------------------------------------

enum StackProficiency: String, Codable, CaseIterable, Identifiable, Hashable {
    case learning   = "Learning"
    case proficient = "Proficient"
    case advanced   = "Advanced"
    case expert     = "Expert"

    var id: String { rawValue }
}

// MARK: - Tag categories -----------------------------------------------------
//
// In TS this is `TagCategory | string` — predefined values plus free-form
// custom strings. We keep the predefined list as a typed namespace for
// pickers and validation, but `StrengthWeakness.category` is a plain
// `String` so user-defined categories are allowed too.

enum TagCategory {
    static let predefined: [String] = [
        "Communication", "Ownership", "Emotional Intelligence", "Collaboration",
        "Growth Mindset", "Problem Solving", "Leadership", "Adaptability",
        "Mentoring", "Language Mastery", "Code Quality", "Code Review",
        "Testing", "Architecture", "DevOps", "Debugging Logic",
        "Observability", "Security"
    ]
}

// MARK: - Stack tags ---------------------------------------------------------

enum StackTag: String, Codable, CaseIterable, Identifiable, Hashable {
    case golang        = "Golang"
    case java          = "Java"
    case kotlin        = "Kotlin"
    case swiftUI       = "Swift (UI)"
    case react         = "React"
    case typescript    = "TypeScript"
    case reduxRTK      = "Redux (RTK)"
    case aws           = "AWS"
    case kubernetes    = "Kubernetes"
    case docker        = "Docker"
    case helm          = "Helm"
    case graphql       = "GraphQL"
    case aiAssistedDev = "AI Assisted-Dev"
    case dynatrace     = "Dynatrace"
    case kibana        = "Kibana"

    var id: String { rawValue }
}

// MARK: - Active view (navigation routing) -----------------------------------

enum ActiveView: String, Codable, Hashable {
    case team
    case member
    case insights
    case settings
}
