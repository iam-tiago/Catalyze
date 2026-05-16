// CatalyzeTokens.swift
// Design tokens do Catalyze Design System v1.0
//
// Como usar:
//   Text("Olá").foregroundStyle(CColor.neutral900)
//   .font(CFont.headline)
//   .padding(CSpace.lg)
//   .cornerRadius(CRadius.md)

import SwiftUI

// MARK: - Colors

/// Todos os tokens de cor do Catalyze.
/// Pense nesse enum como a paleta oficial do app —
/// nunca use cores hardcoded (#hex) diretamente nas views.
enum CColor {

    // MARK: Brand — Catalyze Indigo
    /// Cor principal da marca. Botões primários, ícone ativo na sidebar,
    /// seleção em segmented controls, links de ação.
    static let brandPrimary      = Color(hex: "#5B5BD6")
    /// Versão clara para fundos sutis: tier badges, cards de info.
    static let brandPrimaryLight = Color(hex: "#EEEEFF")
    /// Versão escura para estado pressionado de botões.
    static let brandPrimaryDark  = Color(hex: "#3D3DA7")

    // MARK: Semantic — Strength (green)
    /// Forças, habilidades consolidadas, "Strongest", Expert.
    static let strength      = Color(hex: "#16A34A")
    /// Fundo do card "Strongest" e linhas de força.
    static let strengthLight = Color(hex: "#DCFCE7")

    // MARK: Semantic — Growth (amber)
    /// Áreas de crescimento, "Needs Focus", Emerging.
    static let growth      = Color(hex: "#D97706")
    /// Fundo do card "Needs Focus" e linhas de crescimento.
    static let growthLight = Color(hex: "#FEF3C7")

    // MARK: Semantic — Info (blue)
    /// Informações neutras, estado Proficient.
    static let info      = Color(hex: "#2563EB")
    /// Fundo do stat card informativo (Team Size).
    static let infoLight = Color(hex: "#DBEAFE")

    // MARK: Semantic — Destructive
    /// Botão Delete, ações irreversíveis.
    static let destructive      = Color(hex: "#DC2626")
    static let destructiveLight = Color(hex: "#FEE2E2")

    // MARK: Proficiency Scale
    // Escala de proficiência em tecnologia: Learning → Expert
    static let proficiencyLearning      = Color(hex: "#D97706")
    static let proficiencyLearningLight = Color(hex: "#FEF3C7")
    static let proficiencyProficient      = Color(hex: "#2563EB")
    static let proficiencyProficientLight = Color(hex: "#DBEAFE")
    static let proficiencyAdvanced      = Color(hex: "#7C3AED")
    static let proficiencyAdvancedLight = Color(hex: "#EDE9FE")
    static let proficiencyExpert      = Color(hex: "#16A34A")
    static let proficiencyExpertLight = Color(hex: "#DCFCE7")

    // MARK: Neutrals
    /// Branco puro — fundo de cards e modais.
    static let neutral0   = Color(hex: "#FFFFFF")
    /// Fundo de página (quase branco).
    static let neutral50  = Color(hex: "#F9FAFB")
    /// Fundo de seções sutis e campos de formulário.
    static let neutral100 = Color(hex: "#F3F4F6")
    /// Bordas e separadores.
    static let neutral200 = Color(hex: "#E5E7EB")
    /// Texto terciário, placeholders, ícones desabilitados.
    static let neutral400 = Color(hex: "#9CA3AF")
    /// Texto secundário — subtítulos, labels, roles.
    static let neutral600 = Color(hex: "#4B5563")
    /// Texto de conteúdo padrão — corpo de texto, chips.
    static let neutral700 = Color(hex: "#374151")
    /// Texto primário — títulos, conteúdo principal.
    static let neutral900 = Color(hex: "#111827")
}

// MARK: - Typography

/// Tokens tipográficos do Catalyze.
/// Todos usam SF Pro (fonte do sistema) com tamanhos e pesos bem definidos.
///
/// Exemplo:
///   Text("Team Size").font(CFont.caption2)
enum CFont {
    static let largeTitle   = Font.system(size: 34, weight: .bold)
    static let title1       = Font.system(size: 28, weight: .bold)
    static let title2       = Font.system(size: 22, weight: .bold)
    static let title3       = Font.system(size: 20, weight: .semibold)
    static let headline     = Font.system(size: 17, weight: .semibold)
    static let body         = Font.system(size: 17, weight: .regular)
    static let callout      = Font.system(size: 16, weight: .regular)
    static let subheadline  = Font.system(size: 15, weight: .regular)
    static let footnote     = Font.system(size: 13, weight: .regular)
    static let caption1     = Font.system(size: 12, weight: .regular)
    static let caption2     = Font.system(size: 11, weight: .semibold)
}

// MARK: - Spacing

/// Escala de espaçamento baseada em múltiplos de 4pt.
/// Use sempre esses valores — nunca números mágicos como `.padding(10)`.
///
/// Exemplo:
///   .padding(.horizontal, CSpace.xl)
///   .padding(.vertical, CSpace.md)
enum CSpace {
    /// 4pt — espaço mínimo, entre ícone e texto em badges.
    static let xs:  CGFloat = 4
    /// 8pt — padding interno de chips e badges.
    static let sm:  CGFloat = 8
    /// 12pt — espaço entre elementos em rows.
    static let md:  CGFloat = 12
    /// 16pt — padding interno de cards, espaço entre rows.
    static let lg:  CGFloat = 16
    /// 20pt — espaço entre seções dentro de um card.
    static let xl:  CGFloat = 20
    /// 24pt — padding de cards maiores, margens laterais.
    static let x2l: CGFloat = 24
    /// 32pt — espaço entre cards/seções.
    static let x3l: CGFloat = 32
    /// 48pt — padding de telas, modais.
    static let x4l: CGFloat = 48
}

// MARK: - Corner Radius

/// Tokens de arredondamento de cantos.
///
/// Exemplo:
///   .clipShape(RoundedRectangle(cornerRadius: CRadius.md))
enum CRadius {
    /// 6pt — badges pequenos (tier, proficiency).
    static let xs:   CGFloat = 6
    /// 8pt — chips de habilidade, botões compactos.
    static let sm:   CGFloat = 8
    /// 12pt — stat cards, skill rows, member cards.
    static let md:   CGFloat = 12
    /// 16pt — cards principais, containers de seção.
    static let lg:   CGFloat = 16
    /// 20pt — modais, segmented control container.
    static let xl:   CGFloat = 20
    /// 999pt — avatares, botões pill.
    static let full: CGFloat = 999
}

// MARK: - Gradients

/// Gradientes para backgrounds e destaques visuais.
enum CGradient {
    /// Gradiente sutil de background para páginas
    static let pageBackground = LinearGradient(
        colors: [CColor.neutral50, CColor.neutral100.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradiente para cards hero/destaque
    static let heroCard = LinearGradient(
        colors: [CColor.brandPrimary, CColor.brandPrimary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradiente sutil para cards com hover
    static let cardHover = LinearGradient(
        colors: [CColor.neutral0, CColor.brandPrimaryLight.opacity(0.2)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Gradiente para stats/métricas positivas
    static let success = LinearGradient(
        colors: [CColor.strengthLight, CColor.strength.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradiente para growth/warning
    static let growth = LinearGradient(
        colors: [CColor.growthLight, CColor.growth.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shadows

/// Tokens de sombra para elevação de elementos.
///
/// Uso via ViewModifier:
///   .cardShadow()
///   .elevatedShadow()
extension View {
    /// Sombra padrão para cards.
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }

    /// Sombra mais pronunciada para modais e dropdowns.
    func elevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 4)
    }
    
    /// Sombra forte para elementos em destaque
    func strongShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Color Helper

extension Color {
    /// Inicializador que aceita string hexadecimal (ex: "#5B5BD6").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
