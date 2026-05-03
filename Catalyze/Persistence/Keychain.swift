//
//  Keychain.swift
//  Catalyze
//
//  Tiny wrapper around the Security framework's Keychain Services API
//  for storing the Claude API key. We use Keychain (not UserDefaults)
//  because the API key is sensitive credential material — UserDefaults
//  is plain plist storage that's readable from device backups.
//
//  We do NOT mark items as syncable to iCloud Keychain by default —
//  the user should enter their API key per device. (If you want to
//  change this later, set `kSecAttrSynchronizable: true`.)
//

import Foundation
import Security

enum KeychainError: Error {
    case unhandled(OSStatus)
}

enum Keychain {

    private static let service = "com.catalyze.app"

    /// Set a string value for a given key. Pass `nil` to delete.
    static func set(_ value: String?, for key: String) throws {
        if let value, !value.isEmpty {
            let data = Data(value.utf8)
            // Try to update first; if not found, add.
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            let attributes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String:
                    kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ]
            let updateStatus = SecItemUpdate(
                query as CFDictionary,
                attributes as CFDictionary
            )

            switch updateStatus {
            case errSecSuccess:
                return
            case errSecItemNotFound:
                var addQuery = query
                addQuery.merge(attributes) { _, new in new }
                let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
                guard addStatus == errSecSuccess else {
                    throw KeychainError.unhandled(addStatus)
                }
            default:
                throw KeychainError.unhandled(updateStatus)
            }
        } else {
            // Delete.
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.unhandled(status)
            }
        }
    }

    /// Read a string value for a given key. Returns nil if not set.
    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }
}

// MARK: - Well-known keys ----------------------------------------------------

extension Keychain {
    enum Key {
        static let claudeApiKey = "claude_api_key"
    }
}
