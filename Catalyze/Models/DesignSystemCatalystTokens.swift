//
//  CatalystTokens.swift
//  Catalyze
//
//  Design tokens for the Catalyst Design System.
//  Defines spacing, typography, corner radius, and other design primitives
//  to ensure consistency across the app.
//

import SwiftUI

// MARK: - Spacing ------------------------------------------------------------

enum CatalystSpacing {
    /// 4pt - Minimal spacing for tight layouts
    static let xs: CGFloat = 4
    
    /// 8pt - Small spacing between related elements
    static let sm: CGFloat = 8
    
    /// 12pt - Medium spacing for form fields
    static let md: CGFloat = 12
    
    /// 16pt - Standard spacing between elements
    static let lg: CGFloat = 16
    
    /// 24pt - Large spacing between sections
    static let xl: CGFloat = 24
    
    /// 32pt - Extra large spacing for major sections
    static let xxl: CGFloat = 32
    
    /// 48pt - Maximum spacing for hero sections
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius ------------------------------------------------------

enum CatalystRadius {
    /// 8pt - Small radius for compact elements
    static let sm: CGFloat = 8
    
    /// 12pt - Medium radius for cards and buttons
    static let md: CGFloat = 12
    
    /// 16pt - Large radius for prominent cards
    static let lg: CGFloat = 16
    
    /// 20pt - Extra large radius for hero elements
    static let xl: CGFloat = 20
}

// MARK: - Typography ---------------------------------------------------------

enum CatalystTypography {
    /// Large section titles (e.g., "Generate Insight")
    static let sectionTitle = Font.title2.bold()
    
    /// Card and subsection titles
    static let cardTitle = Font.headline
    
    /// Standard body text
    static let body = Font.body
    
    /// Labels and field names
    static let label = Font.subheadline.weight(.medium)
    
    /// Small descriptive text
    static let caption = Font.caption
    
    /// Subheadline for secondary information
    static let subheadline = Font.subheadline
}

// MARK: - Opacity ------------------------------------------------------------

enum CatalystOpacity {
    /// Very subtle background overlay
    static let subtle: CGFloat = 0.05
    
    /// Light background overlay
    static let light: CGFloat = 0.1
    
    /// Medium background overlay
    static let medium: CGFloat = 0.15
    
    /// Strong background overlay
    static let strong: CGFloat = 0.3
}

// MARK: - Animation ----------------------------------------------------------

enum CatalystAnimation {
    /// Quick animation for immediate feedback
    static let quick = Animation.easeOut(duration: 0.2)
    
    /// Standard animation for most transitions
    static let standard = Animation.easeInOut(duration: 0.3)
    
    /// Smooth animation for complex transitions
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Icon Sizes ---------------------------------------------------------

enum CatalystIconSize {
    /// Small icon (16pt)
    static let sm: CGFloat = 16
    
    /// Medium icon (24pt)
    static let md: CGFloat = 24
    
    /// Large icon (32pt)
    static let lg: CGFloat = 32
    
    /// Extra large icon (48pt)
    static let xl: CGFloat = 48
    
    /// Hero icon (64pt)
    static let hero: CGFloat = 64
}
