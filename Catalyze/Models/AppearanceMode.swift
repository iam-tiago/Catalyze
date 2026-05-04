//
//  AppearanceMode.swift
//  Catalyze
//
//  Enum for app theme preference (System, Light, Dark).
//  Used by AppStorage in AppLayout and SettingsView.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
