//
//  TeamMember.swift
//  Catalyze
//
//  SwiftData model for a team member.
//  Equivalent to the TS `TeamMember` interface plus the nested
//  `StrengthWeakness` and `StackEntry` types.
//
//  CloudKit compatibility notes:
//  - Every persisted property has a default value (CloudKit requirement).
//  - Relationships are optional with `nullify` delete rules where the
//    other side is independent (mentor link), and `cascade` where the
//    children only exist as part of the parent (strengths, weaknesses,
//    stack entries, observations, IDPs, promotion records, profile events).
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - StrengthWeakness ---------------------------------------------------

@Model
final class StrengthWeakness {
    @Attribute(.unique) var id: String = UUID().uuidString

    /// Strength or weakness — stored as the raw string of `SWKind`.
    var kindRaw: String = SWKind.strength.rawValue

    /// Free-form category string. Predefined values live in
    /// `TagCategory.predefined`, but custom values are allowed.
    var category: String = ""

    /// Stored as the raw string of `Intensity` so we can persist any
    /// of the 5 cases regardless of kind. Validation happens at write time.
    var intensityRaw: String = Intensity.emerging.rawValue

    var note: String? = nil
    var createdAt: Date = Date()

    /// Inverse relationship — the member that owns this tag.
    /// Set on either the `member.strengths` or `member.weaknesses` array.
    var member: TeamMember? = nil

    init(
        id: String = UUID().uuidString,
        kind: SWKind,
        category: String,
        intensity: Intensity,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.category = category
        self.intensityRaw = intensity.rawValue
        self.note = note
        self.createdAt = createdAt
    }

    // Typed accessors --------------------------------------------------------

    var kind: SWKind {
        get { SWKind(rawValue: kindRaw) ?? .strength }
        set { kindRaw = newValue.rawValue }
    }

    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .emerging }
        set { intensityRaw = newValue.rawValue }
    }

    /// Is the current `intensity` valid for the current `kind`?
    /// Useful for form validation.
    var intensityIsValid: Bool {
        switch kind {
        case .strength: return Intensity.strengthCases.contains(intensity)
        case .weakness: return Intensity.weaknessCases.contains(intensity)
        }
    }
}

// MARK: - StackEntry ---------------------------------------------------------

@Model
final class StackEntry {
    @Attribute(.unique) var id: String = UUID().uuidString

    /// Stored as the raw string of `StackTag`.
    var tagRaw: String = StackTag.typescript.rawValue
    var levelRaw: String = StackProficiency.learning.rawValue

    var member: TeamMember? = nil

    init(
        id: String = UUID().uuidString,
        tag: StackTag,
        level: StackProficiency
    ) {
        self.id = id
        self.tagRaw = tag.rawValue
        self.levelRaw = level.rawValue
    }

    var tag: StackTag {
        get { StackTag(rawValue: tagRaw) ?? .typescript }
        set { tagRaw = newValue.rawValue }
    }

    var level: StackProficiency {
        get { StackProficiency(rawValue: levelRaw) ?? .learning }
        set { levelRaw = newValue.rawValue }
    }
}

// MARK: - TeamMember ---------------------------------------------------------

@Model
final class TeamMember {
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String = ""
    var role: String = ""
    var seniorityRaw: String = Seniority.t2_1.rawValue
    var photoUrl: String? = nil
    
    /// Photo data for locally-picked images (from Photos library)
    /// Takes precedence over photoUrl when both exist
    @Attribute(.externalStorage) var photoData: Data? = nil

    /// Stack proficiencies. `cascade` because they only exist as part
    /// of the member.
    @Relationship(deleteRule: .cascade, inverse: \StackEntry.member)
    var stack: [StackEntry]? = []

    /// Internal mentor (another team member). `nullify` so deleting the
    /// mentor doesn't cascade-delete this member.
    @Relationship(deleteRule: .nullify)
    var mentor: TeamMember? = nil

    /// Free-text name of an external mentor (someone not in the team).
    var mentorName: String? = nil

    /// Free-text names of people outside the team this member mentors.
    /// Stored as a single newline-separated string for simplicity (avoids
    /// CloudKit array-of-string headaches).
    var externalMenteesRaw: String? = nil

    @Relationship(deleteRule: .cascade, inverse: \StrengthWeakness.member)
    var tags: [StrengthWeakness]? = []

    @Relationship(deleteRule: .cascade)
    var observations: [TeamObservation]? = []

    @Relationship(deleteRule: .cascade)
    var idps: [DevelopmentPlan]? = []

    @Relationship(deleteRule: .cascade)
    var promotionRecords: [PromotionReadiness]? = []

    @Relationship(deleteRule: .cascade)
    var profileEvents: [ProfileEvent]? = []

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        name: String,
        role: String,
        seniority: Seniority,
        photoUrl: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.seniorityRaw = seniority.rawValue
        self.photoUrl = photoUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Typed accessors --------------------------------------------------------

    var seniority: Seniority {
        get { Seniority(rawValue: seniorityRaw) ?? .t2_1 }
        set { seniorityRaw = newValue.rawValue }
    }

    /// All tags filtered by kind. Keeps the call sites that used to read
    /// `member.strengths` / `member.weaknesses` ergonomic.
    var strengths: [StrengthWeakness] {
        (tags ?? []).filter { $0.kind == .strength }
    }

    var weaknesses: [StrengthWeakness] {
        (tags ?? []).filter { $0.kind == .weakness }
    }

    var externalMentees: [String] {
        get {
            (externalMenteesRaw ?? "")
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map { String($0) }
        }
        set {
            externalMenteesRaw = newValue
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        }
    }
    
    /// Helper to get avatar image (prioritizes photoData over photoUrl)
    var avatarImage: Image? {
        #if os(iOS) || os(macOS)
        if let data = photoData {
            #if os(iOS)
            if let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(data: data) {
                return Image(nsImage: nsImage)
            }
            #endif
        }
        #endif
        return nil
    }
}
