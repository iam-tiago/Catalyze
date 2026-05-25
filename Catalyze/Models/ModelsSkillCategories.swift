//
//  SkillCategories.swift
//  Catalyze
//
//  Centralized definition of all skill categories (behavioral and technical).
//  This ensures consistency across forms, views, and radar charts.
//

import Foundation

// MARK: - Behavioral Categories ----------------------------------------------

/// Behavioral skill categories for soft skills (communication, leadership, etc.)
/// Used in TagForm and TagSection.
enum BehavioralCategory {
    /// All behavioral categories available in the app
    static let all: [String] = [
        "Communication",
        "Ownership",
        "EQ",
        "Collaboration",
        "Growth Mindset",
        "Leadership",
        "Adaptability",
        "Mentoring"
    ]
    
    /// Returns SF Symbol icon for a given behavioral category
    static func icon(for category: String) -> String {
        switch category {
        case "Communication":   return "bubble.left.and.bubble.right"
        case "Ownership":       return "person.badge.shield.checkmark"
        case "EQ":              return "heart.text.square"
        case "Collaboration":   return "person.2"
        case "Growth Mindset":  return "brain.head.profile"
        case "Leadership":      return "flag"
        case "Adaptability":    return "arrow.triangle.2.circlepath"
        case "Mentoring":       return "person.2.wave.2"
        default:                return "star"
        }
    }
}

// MARK: - Technical Categories -----------------------------------------------

/// Technical skill categories for hard skills (code quality, testing, etc.)
/// Used in TechSkillsSection and TechSkillForm.
enum TechnicalCategory {
    /// All technical categories available in the app
    static let all: [String] = [
        "Code Quality",
        "Code Review",
        "Testing",
        "Architecture",
        "DevOps",
        "Infrastructure",
        "Debugging",
        "Observability"
    ]
    
    /// Returns SF Symbol icon for a given technical category
    static func icon(for category: String) -> String {
        switch category {
        case "Code Quality":    return "checkmark.seal"
        case "Code Review":     return "text.magnifyingglass"
        case "Testing":         return "testtube.2"
        case "Architecture":    return "building.columns"
        case "DevOps":          return "gearshape.2"
        case "Infrastructure":  return "server.rack"
        case "Debugging":       return "ladybug"
        case "Observability":   return "chart.xyaxis.line"
        default:                return "wrench.and.screwdriver"
        }
    }
}
// MARK: - Intensity Extensions -----------------------------------------------

import SwiftUI

extension Intensity {
    /// Returns the appropriate color based on the type (strength/weakness)
    func color(for kind: SWKind) -> Color {
        switch (kind, self) {
        case (.strength, .emerging):   return .orange
        case (.strength, .solid):      return .blue
        case (.strength, .strong):     return .green
        case (.weakness, .emerging):   return .orange
        case (.weakness, .developing): return .yellow
        case (.weakness, .blocking):   return .red
        default:                       return .gray
        }
    }
    
    /// Returns the appropriate icon for the intensity level
    var icon: String {
        switch self {
        case .emerging:   return "leaf"
        case .solid:      return "checkmark.circle"
        case .strong:     return "star.circle"
        case .developing: return "arrow.triangle.2.circlepath"
        case .blocking:   return "exclamationmark.triangle"
        }
    }
    
    /// Number of dots for visual indicator
    var dotCount: Int {
        switch self {
        case .emerging:   return 1
        case .solid, .developing: return 2
        case .strong, .blocking:  return 3
        }
    }
}

