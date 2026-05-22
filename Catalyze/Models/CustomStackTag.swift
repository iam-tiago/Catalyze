//
//  CustomStackTag.swift
//  Catalyze
//
//  SwiftData model for custom tech stack tags. Allows teams to define
//  their own technology tags beyond the predefined StackTag enum.
//

import Foundation
import SwiftData

@Model
final class CustomStackTag {
    var id: String = UUID().uuidString
    var name: String = ""
    var isActive: Bool = true
    var createdAt: Date = Date()
    
    init(
        id: String = UUID().uuidString,
        name: String,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

// MARK: - StackEntry Extension -----------------------------------------------

extension StackEntry {
    /// Nome da tecnologia - vem do enum ou de um CustomStackTag
    var displayName: String {
        // Se tagRaw não é um valor válido do enum, assume que é um custom tag
        if let _ = StackTag(rawValue: tagRaw) {
            return tagRaw
        } else {
            return tagRaw // Custom tag name
        }
    }
    
    /// Verifica se é um tag predefinido ou customizado
    var isPredefined: Bool {
        StackTag(rawValue: tagRaw) != nil
    }
}

// MARK: - Available Tech Tags ------------------------------------------------

/// Combina tags predefinidos e customizados para uso em pickers
struct AvailableTechTags {
    let predefined: [StackTag]
    let custom: [CustomStackTag]
    
    /// Todos os nomes disponíveis (predefined + custom ativos)
    var allNames: [String] {
        let predefinedNames = predefined.map { $0.rawValue }
        let customNames = custom.filter { $0.isActive }.map { $0.name }
        return (predefinedNames + customNames).sorted()
    }
    
    /// Verifica se um nome já existe
    func contains(_ name: String) -> Bool {
        allNames.contains(name)
    }
}
