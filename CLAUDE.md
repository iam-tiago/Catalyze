# Catalyze — Contexto do Projeto

## O que é o app
Catalyze é um app para iPad (SwiftUI, componentes nativos) para Engineering Managers gerenciarem performance e desenvolvimento da equipe. O usuário principal é Tiago Canabarro (Engineering Manager). O app tem três seções: **Team** (visão geral + perfil de cada membro), **Insights** (geração de insights com IA) e **Settings**.

## Design System — Catalyze v1.0

Os arquivos do design system estão em `CatalyzeTokens.swift` e `CatalyzeComponents.swift`. **Nunca usar cores ou espaçamentos hardcoded** — sempre usar os tokens abaixo.

### Filosofia
- **Clarity first** — hierarquia visual clara, nada disputando atenção
- **Meaningful color** — cores carregam significado semântico
- **Native at heart** — amplifica componentes nativos do iPadOS, não os substitui

### Cores principais (`CColor`)
| Token | Hex | Uso |
|---|---|---|
| `brandPrimary` | `#5B5BD6` | Botões, ícone ativo na sidebar, links de ação |
| `brandPrimaryLight` | `#EEEEFF` | Fundos sutis, tier badges |
| `strength` | `#16A34A` | Forças, "Strongest", Expert |
| `strengthLight` | `#DCFCE7` | Fundo de cards de força |
| `growth` | `#D97706` | Crescimento, "Needs Focus", Emerging |
| `growthLight` | `#FEF3C7` | Fundo de cards de crescimento |
| `info` | `#2563EB` | Informações neutras, Proficient |
| `infoLight` | `#DBEAFE` | Fundo do stat card Team Size |
| `destructive` | `#DC2626` | Botão Delete |
| `neutral50` | `#F9FAFB` | Fundo de página |
| `neutral0` | `#FFFFFF` | Fundo de cards e modais |
| `neutral200` | `#E5E7EB` | Bordas e separadores |
| `neutral400` | `#9CA3AF` | Texto terciário, placeholders |
| `neutral600` | `#4B5563` | Texto secundário (roles, subtítulos) |
| `neutral700` | `#374151` | Corpo de texto, chips |
| `neutral900` | `#111827` | Texto primário (títulos) |

### Proficiência técnica (`ProficiencyLevel`)
- `.learning` → âmbar `#D97706`
- `.proficient` → azul `#2563EB`
- `.advanced` → roxo `#7C3AED`
- `.expert` → verde `#16A34A`

### Intensidade comportamental (`SkillIntensity`)
- `.emerging` → 1 ponto âmbar
- `.solid` → 2 pontos índigo
- `.strong` → 3 pontos verde

### Espaçamento (`CSpace`)
`xs`=4, `sm`=8, `md`=12, `lg`=16, `xl`=20, `x2l`=24, `x3l`=32, `x4l`=48

### Corner Radius (`CRadius`)
`xs`=6, `sm`=8, `md`=12, `lg`=16, `xl`=20, `full`=999

### Tipografia (`CFont`)
`largeTitle`=34/Bold, `title1`=28/Bold, `title2`=22/Bold, `title3`=20/Semibold, `headline`=17/Semibold, `body`=17/Regular, `callout`=16, `subheadline`=15, `footnote`=13, `caption1`=12, `caption2`=11/Semibold

### Sombras (via ViewModifier)
- `.cardShadow()` — cards padrão
- `.elevatedShadow()` — modais e dropdowns

### Componentes disponíveis (`CatalyzeComponents.swift`)
- `StatCard(icon:value:label:variant:)` — cards de métrica (Team Size, Active IDPs, In Promotion)
- `TierBadge(tier:)` — badge de nível hierárquico (T2-1, T3-1, T4...)
- `ProficiencyBadge(level:)` — badge de proficiência técnica
- `IntensityDots(intensity:)` — pontos de intensidade de habilidade comportamental
- `SkillChip(name:intensity:)` — chip compacto com dots + nome
- `SectionHeader(icon:title:isExpanded:)` — header colapsável com animação spring
- `InsightSummaryCard(strongest:needsFocus:)` — dois cards Strongest/Needs Focus
- `MemberCard(name:role:tier:topStrengths:)` — card de membro da equipe
- `PrimaryButton(title:icon:action:)` — botão pill com cor de marca
- `EmptyState(icon:message:actionTitle:actionIcon:onAction:)` — estado vazio
- `SkillRow(name:intensity:level:background:onDelete:)` — linha de habilidade comportamental
- `TechStackRow(name:level:onDelete:)` — linha de tecnologia

### Ícones (SF Symbols)
Team=`person.3.fill`, Insights=`brain.head.profile`, Settings=`gearshape.fill`, Strengths=`star.fill`, Tech Skills=`wrench.and.screwdriver.fill`, Tech Stack=`chevron.left.forwardslash.chevron.right`, Observations=`note.text`, Dev Plans=`checklist`, Promotion=`arrow.up.circle.fill`, AI=`sparkles`, Add=`plus.circle.fill`

## Stack técnica
- SwiftUI (iPadOS nativo)
- Componentes nativos: NavigationSplitView, List, Sheet, SegmentedControl
- Sem dependências externas (sem SPM por enquanto)

## Convenções de código
- Arquivos de componente usam apenas tokens do design system — nunca valores hardcoded
- Animações: `.spring(response: 0.3, dampingFraction: 0.8)` para interações de UI
- Confirmação antes de deletar: sempre usar `.confirmationDialog` ou swipe-to-delete
- Estados de loading: `.redacted(reason: .placeholder)`
