//
//  EMProfile.swift
//  Catalyze
//
//  The Engineering Manager's own profile. It's a singleton (not a list),
//  changes rarely, and doesn't relate to other entities — so we keep it
//  in UserDefaults rather than introducing a one-row SwiftData table.
//  Sync across devices happens automatically via NSUbiquitousKeyValueStore
//  (the iCloud key-value store), which is the standard approach for
//  small, app-wide user settings.
//

import Foundation

struct EMProfile: Codable, Equatable {
    var name: String
    var role: String
    /// Custom team name shown on the Team page header.
    var teamName: String?
    /// Path or URL string of the EM's avatar image.
    var photoUrl: String?

    static let empty = EMProfile(name: "", role: "", teamName: nil, photoUrl: nil)
}
