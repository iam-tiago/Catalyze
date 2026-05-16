// CatalyzeComponents.swift
// Componentes reutilizáveis do Catalyze Design System v1.0
//
// Importe este arquivo (junto com CatalyzeTokens.swift) em qualquer View.
// Todos os componentes usam exclusivamente tokens de CColor, CFont, CSpace e CRadius.

import SwiftUI

// MARK: - Models de suporte

/// Nível de intensidade de uma habilidade comportamental.
enum SkillIntensity: String, CaseIterable {
    case emerging = "Emerging"
    case solid    = "Solid"
    case strong   = "Strong"

    var dotCount: Int {
        switch self {
        case .emerging: return 1
        case .solid:    return 2
        case .strong:   return 3
        }
    }

    var color: Color {
        switch self {
        case .emerging: return CColor.growth
        case .solid:    return CColor.brandPrimary
        case .strong:   return CColor.strength
        }
    }
}

/// Nível de proficiência técnica.
enum ProficiencyLevel: String, CaseIterable {
    case learning  = "Learning"
    case proficient = "Proficient"
    case advanced  = "Advanced"
    case expert    = "Expert"

    var foreground: Color {
        switch self {
        case .learning:   return CColor.proficiencyLearning
        case .proficient: return CColor.proficiencyProficient
        case .advanced:   return CColor.proficiencyAdvanced
        case .expert:     return CColor.proficiencyExpert
        }
    }

    var background: Color {
        switch self {
        case .learning:   return CColor.proficiencyLearningLight
        case .proficient: return CColor.proficiencyProficientLight
        case .advanced:   return CColor.proficiencyAdvancedLight
        case .expert:     return CColor.proficiencyExpertLight
        }
    }
}

/// Variante visual do StatCard.
enum StatCardVariant {
    case info      // Team Size
    case strength  // Active IDPs
    case growth    // In Promotion

    var iconColor: Color {
        switch self {
        case .info:     return CColor.info
        case .strength: return CColor.strength
        case .growth:   return CColor.growth
        }
    }

    var backgroundColor: Color {
        switch self {
        case .info:     return CColor.infoLight
        case .strength: return CColor.strengthLight
        case .growth:   return CColor.growthLight
        }
    }
}


// MARK: - 1. StatCard

/// Card de métrica com fundo colorido, ícone, número e label.
///
/// ```swift
/// StatCard(
///     icon: "person.3.fill",
///     value: "6",
///     label: "Team Size",
///     variant: .info
/// )
/// ```
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let variant: StatCardVariant

    var body: some View {
        VStack(spacing: CSpace.sm) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(variant.iconColor)

            Text(value)
                .font(CFont.title1)
                .foregroundStyle(CColor.neutral900)

            Text(label)
                .font(CFont.footnote)
                .foregroundStyle(CColor.neutral600)
        }
        .frame(maxWidth: .infinity)
        .padding(CSpace.lg)
        .background(variant.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CRadius.md))
    }
}


// MARK: - 2. TierBadge

/// Badge que exibe o nível hierárquico de um membro (T2-1, T3-1, T4...).
///
/// ```swift
/// TierBadge(tier: "T3-1")
/// ```
struct TierBadge: View {
    let tier: String

    var body: some View {
        Text(tier)
            .font(CFont.caption2)
            .foregroundStyle(CColor.brandPrimary)
            .padding(.horizontal, CSpace.sm)
            .padding(.vertical, CSpace.xs)
            .background(CColor.brandPrimaryLight)
            .clipShape(RoundedRectangle(cornerRadius: CRadius.xs))
    }
}


// MARK: - 3. ProficiencyBadge

/// Badge colorido que indica o nível de proficiência técnica.
///
/// ```swift
/// ProficiencyBadge(level: .expert)
/// ProficiencyBadge(level: .learning)
/// ```
struct ProficiencyBadge: View {
    let level: ProficiencyLevel

    var body: some View {
        Text(level.rawValue)
            .font(CFont.caption2)
            .foregroundStyle(level.foreground)
            .padding(.horizontal, CSpace.sm)
            .padding(.vertical, CSpace.xs)
            .background(level.background)
            .clipShape(RoundedRectangle(cornerRadius: CRadius.xs))
    }
}


// MARK: - 4. IntensityDots

/// Pontos visuais que indicam a intensidade de uma habilidade comportamental.
/// 1 ponto = Emerging, 2 = Solid, 3 = Strong.
///
/// ```swift
/// IntensityDots(intensity: .strong)
/// ```
struct IntensityDots: View {
    let intensity: SkillIntensity
    private let totalDots = 3
    private let dotSize: CGFloat = 7

    var body: some View {
        HStack(spacing: CSpace.xs) {
            ForEach(0..<totalDots, id: \.self) { index in
                Circle()
                    .fill(index < intensity.dotCount ? intensity.color : CColor.neutral200)
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}


// MARK: - 5. SkillChip

/// Chip compacto com dots de intensidade e nome da habilidade.
/// Usado em MemberCard para mostrar top strengths.
///
/// ```swift
/// SkillChip(name: "Mentoring", intensity: .solid)
/// ```
struct SkillChip: View {
    let name: String
    let intensity: SkillIntensity

    var body: some View {
        HStack(spacing: CSpace.xs) {
            IntensityDots(intensity: intensity)
            Text(name)
                .font(CFont.footnote)
                .foregroundStyle(CColor.neutral700)
        }
    }
}


// MARK: - 6. SectionHeader

/// Cabeçalho de seção colapsável com ícone, título e chevron animado.
///
/// ```swift
/// @State private var isExpanded = true
///
/// SectionHeader(
///     icon: "star.fill",
///     title: "Strengths & Growth Areas",
///     isExpanded: $isExpanded
/// )
/// ```
struct SectionHeader: View {
    let icon: String
    let title: String
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CColor.neutral900)

                Text(title)
                    .font(CFont.headline)
                    .foregroundStyle(CColor.neutral900)

                Spacer()

                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CColor.neutral400)
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
            }
        }
        .buttonStyle(.plain)
    }
}


// MARK: - 7. InsightSummaryCard

/// Dois cards lado a lado — "Strongest" (verde) e "Needs Focus" (âmbar).
///
/// ```swift
/// InsightSummaryCard(
///     strongest: "Ownership",
///     needsFocus: "EQ"
/// )
/// ```
struct InsightSummaryCard: View {
    let strongest: String
    let needsFocus: String

    var body: some View {
        HStack(spacing: CSpace.md) {
            summaryPanel(
                label: "STRONGEST",
                value: strongest,
                labelColor: CColor.neutral600,
                valueColor: CColor.strength,
                background: CColor.strengthLight
            )
            summaryPanel(
                label: "NEEDS FOCUS",
                value: needsFocus,
                labelColor: CColor.neutral600,
                valueColor: CColor.growth,
                background: CColor.growthLight
            )
        }
    }

    private func summaryPanel(
        label: String,
        value: String,
        labelColor: Color,
        valueColor: Color,
        background: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: CSpace.xs) {
            Text(label)
                .font(CFont.caption2)
                .foregroundStyle(labelColor)
            Text(value)
                .font(CFont.headline)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CSpace.lg)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: CRadius.md))
    }
}


// MARK: - 8. MemberCard

/// Card de membro da equipe com avatar, identificação, tier badge e top strengths.
///
/// ```swift
/// MemberCard(
///     name: "Alice Chen",
///     role: "Senior iOS Engineer",
///     tier: "T3-1",
///     topStrengths: [
///         ("Mentoring", .solid),
///         ("SwiftUI", .strong)
///     ]
/// )
/// ```
struct MemberCard: View {
    let name: String
    let role: String
    let tier: String
    let topStrengths: [(name: String, intensity: SkillIntensity)]

    var body: some View {
        VStack(alignment: .leading, spacing: CSpace.md) {
            // Header: Avatar + Info + Tier
            HStack(spacing: CSpace.md) {
                avatarView

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(CFont.headline)
                        .foregroundStyle(CColor.neutral900)
                    Text(role)
                        .font(CFont.subheadline)
                        .foregroundStyle(CColor.neutral600)
                }

                Spacer()

                TierBadge(tier: tier)
            }

            if !topStrengths.isEmpty {
                Divider()

                // Top Strengths
                VStack(alignment: .leading, spacing: CSpace.sm) {
                    Text("TOP STRENGTHS")
                        .font(CFont.caption2)
                        .foregroundStyle(CColor.neutral400)

                    HStack(spacing: CSpace.lg) {
                        ForEach(topStrengths, id: \.name) { skill in
                            SkillChip(name: skill.name, intensity: skill.intensity)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(CSpace.lg)
        .background(CColor.neutral0)
        .clipShape(RoundedRectangle(cornerRadius: CRadius.md))
        .cardShadow()
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(CColor.brandPrimaryLight)
                .frame(width: 44, height: 44)
            Image(systemName: "person.fill")
                .font(.system(size: 22))
                .foregroundStyle(CColor.brandPrimary)
        }
    }
}


// MARK: - 9. PrimaryButton

/// Botão pill com fundo na cor de marca. Ação principal da tela.
///
/// ```swift
/// PrimaryButton(title: "Start Tracking", icon: "plus") {
///     // ação
/// }
/// ```
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: CSpace.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(CFont.headline)
                }
                Text(title)
                    .font(CFont.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, CSpace.xl)
            .padding(.vertical, CSpace.md)
            .background(CColor.brandPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(CatalyzeButtonStyle())
    }
}

/// Estilo de botão com feedback visual de pressão.
private struct CatalyzeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}


// MARK: - 10. EmptyState

/// Estado vazio padrão para seções sem conteúdo.
///
/// ```swift
/// EmptyState(
///     icon: "note.text",
///     message: "No observations yet"
/// )
///
/// // Com botão de ação:
/// EmptyState(
///     icon: "arrow.up.circle",
///     message: "Not tracking promotion yet",
///     actionTitle: "Start Tracking",
///     actionIcon: "plus"
/// ) {
///     // ação
/// }
/// ```
struct EmptyState: View {
    let icon: String
    let message: String
    var actionTitle: String? = nil
    var actionIcon: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: CSpace.lg) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(CColor.neutral400)

            Text(message)
                .font(CFont.callout)
                .foregroundStyle(CColor.neutral600)
                .multilineTextAlignment(.center)

            if let actionTitle, let onAction {
                PrimaryButton(title: actionTitle, icon: actionIcon, action: onAction)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CSpace.x3l)
    }
}


// MARK: - 11. SkillRow

/// Linha de habilidade com dots de intensidade, nome e badge de nível.
/// Usado dentro de seções expansíveis no perfil do membro.
///
/// ```swift
/// SkillRow(
///     name: "Mentoring",
///     intensity: .solid,
///     level: "Solid",
///     background: CColor.strengthLight,
///     onDelete: { /* ação */ }
/// )
/// ```
struct SkillRow: View {
    let name: String
    let intensity: SkillIntensity
    let level: String
    var background: Color = CColor.neutral100
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: CSpace.md) {
            IntensityDots(intensity: intensity)

            Text(name)
                .font(CFont.body)
                .foregroundStyle(CColor.neutral900)

            Spacer()

            Text(level)
                .font(CFont.caption2)
                .foregroundStyle(intensity.color)
                .padding(.horizontal, CSpace.sm)
                .padding(.vertical, CSpace.xs)
                .background(intensity.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CRadius.xs))

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(CColor.destructive)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, CSpace.lg)
        .padding(.vertical, CSpace.md)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: CRadius.sm))
    }
}


// MARK: - 12. TechStackRow

/// Linha de tecnologia com nome e badge de proficiência.
///
/// ```swift
/// TechStackRow(
///     name: "Swift (UI)",
///     level: .expert,
///     onDelete: { /* ação */ }
/// )
/// ```
struct TechStackRow: View {
    let name: String
    let level: ProficiencyLevel
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: CSpace.md) {
            Text(name)
                .font(CFont.body)
                .foregroundStyle(CColor.neutral900)

            Spacer()

            ProficiencyBadge(level: level)

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(CColor.destructive)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, CSpace.lg)
        .padding(.vertical, CSpace.md)
    }
}


// MARK: - Previews

#Preview("StatCard") {
    HStack(spacing: CSpace.md) {
        StatCard(icon: "person.3.fill", value: "6", label: "Team Size", variant: .info)
        StatCard(icon: "checklist", value: "0", label: "Active IDPs", variant: .strength)
        StatCard(icon: "arrow.up.circle.fill", value: "0", label: "In Promotion", variant: .growth)
    }
    .padding()
    .background(CColor.neutral50)
}

#Preview("Badges") {
    VStack(spacing: CSpace.lg) {
        HStack(spacing: CSpace.sm) {
            TierBadge(tier: "T2-1")
            TierBadge(tier: "T3-1")
            TierBadge(tier: "T4")
        }

        HStack(spacing: CSpace.sm) {
            ProficiencyBadge(level: .learning)
            ProficiencyBadge(level: .proficient)
            ProficiencyBadge(level: .advanced)
            ProficiencyBadge(level: .expert)
        }

        HStack(spacing: CSpace.lg) {
            IntensityDots(intensity: .emerging)
            IntensityDots(intensity: .solid)
            IntensityDots(intensity: .strong)
        }
    }
    .padding()
    .background(CColor.neutral50)
}

#Preview("MemberCard") {
    MemberCard(
        name: "Alice Chen",
        role: "Senior iOS Engineer",
        tier: "T3-1",
        topStrengths: [
            ("Mentoring", .solid),
            ("SwiftUI", .strong)
        ]
    )
    .padding()
    .background(CColor.neutral50)
}

#Preview("InsightSummaryCard") {
    InsightSummaryCard(strongest: "Ownership", needsFocus: "EQ")
        .padding()
        .background(CColor.neutral50)
}

#Preview("EmptyState") {
    EmptyState(
        icon: "arrow.up.circle",
        message: "Not tracking promotion yet",
        actionTitle: "Start Tracking",
        actionIcon: "plus"
    ) {
        print("Tapped")
    }
    .background(CColor.neutral50)
}

#Preview("SectionHeader") {
    VStack {
        SectionHeader(
            icon: "star.fill",
            title: "Strengths & Growth Areas",
            isExpanded: .constant(true)
        )
        SectionHeader(
            icon: "wrench.and.screwdriver.fill",
            title: "Tech Skills",
            isExpanded: .constant(false)
        )
    }
    .padding()
    .background(CColor.neutral0)
}

