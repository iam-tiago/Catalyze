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
}
