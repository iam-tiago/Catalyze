//
//  ErrorHandling.swift
//  Catalyze
//
//  Centralized error handling utilities for consistent error management
//  across the app.
//

import Foundation
import SwiftUI

// MARK: - App Errors ---------------------------------------------------------

enum AppError: LocalizedError {
    case persistenceFailure(underlying: Error)
    case validationFailure(String)
    case networkError(underlying: Error)
    case apiKeyMissing
    case cloudKitSyncFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .persistenceFailure(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .validationFailure(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiKeyMissing:
            return "No API key configured. Please set one in Settings."
        case .cloudKitSyncFailed(let error):
            return "iCloud sync failed: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .persistenceFailure:
            return "Please try again. If the problem persists, restart the app."
        case .validationFailure:
            return "Please check your input and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .apiKeyMissing:
            return "Go to Settings and add your Claude API key."
        case .cloudKitSyncFailed:
            return "Check that you're signed into iCloud in Settings."
        }
    }
}

// MARK: - Error Alert Modifier -----------------------------------------------

struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: .constant(error != nil),
                presenting: error
            ) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    if let description = error.errorDescription {
                        Text(description)
                    }
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

// MARK: - Logging Helper -----------------------------------------------------

enum Logger {
    static func log(
        _ message: String,
        level: Level = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let prefix = level.emoji
        print("\(prefix) [\(fileName):\(line)] \(message)")
        #endif
    }
    
    static func error(
        _ error: Error,
        context: String = "",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let contextInfo = context.isEmpty ? "" : " (\(context))"
        print("❌ [\(fileName):\(line)] Error\(contextInfo): \(error.localizedDescription)")
        #endif
    }
    
    enum Level {
        case debug, info, warning, error, success
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .success: return "✅"
            }
        }
    }
}

// MARK: - Validation Helpers -------------------------------------------------

enum Validator {
    static func validateName(_ name: String) -> Result<String, AppError> {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else {
            return .failure(.validationFailure("Name cannot be empty"))
        }
        
        guard trimmed.count >= 2 else {
            return .failure(.validationFailure("Name must be at least 2 characters"))
        }
        
        guard trimmed.count <= 100 else {
            return .failure(.validationFailure("Name is too long (max 100 characters)"))
        }
        
        return .success(trimmed)
    }
    
    static func validateRole(_ role: String) -> Result<String, AppError> {
        let trimmed = role.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else {
            return .failure(.validationFailure("Role cannot be empty"))
        }
        
        guard trimmed.count >= 2 else {
            return .failure(.validationFailure("Role must be at least 2 characters"))
        }
        
        guard trimmed.count <= 100 else {
            return .failure(.validationFailure("Role is too long (max 100 characters)"))
        }
        
        return .success(trimmed)
    }
    
    static func validateURL(_ urlString: String) -> Result<URL?, AppError> {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else {
            return .success(nil)
        }
        
        guard let url = URL(string: trimmed) else {
            return .failure(.validationFailure("Invalid URL format"))
        }
        
        guard ["http", "https"].contains(url.scheme?.lowercased()) else {
            return .failure(.validationFailure("URL must start with http:// or https://"))
        }
        
        return .success(url)
    }
}
