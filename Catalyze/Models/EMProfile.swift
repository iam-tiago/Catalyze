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
import SwiftUI

struct EMProfile: Codable, Equatable {
    var name: String
    var role: String
    /// Custom team name shown on the Team page header.
    var teamName: String?
    /// Path or URL string of the EM's avatar image.
    var photoUrl: String?
    
    /// Photo data for locally-picked images (from Photos library)
    /// Takes precedence over photoUrl when both exist
    var photoData: Data?

    static let empty = EMProfile(name: "", role: "", teamName: nil, photoUrl: nil, photoData: nil)
    
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
