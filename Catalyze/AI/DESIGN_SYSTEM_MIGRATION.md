# 🎨 Catalyze Design System - Migração em Progresso

**Data**: Maio 2026  
**Status**: 🚧 Em Andamento  
**Objetivo**: Consolidar em um único Design System (Catalyze v1.0)

---

## 📊 Progresso Geral

| Componente | Status | Notas |
|-----------|--------|-------|
| **Design Tokens** | ✅ Completo | `CatalyzeTokens.swift` |
| **Componentes Base** | ✅ Completo | `CatalyzeComponents.swift` (12 componentes) |
| **TeamView** | ✅ Migrado | Usando `StatCard`, `TierBadge`, `SkillChip`, `EmptyState` |
| **TeamOverview** | ✅ Migrado | Preservando radares (ajustados manualmente) |
| **SettingsView** | ✅ Atualizado | Mensagens de confirmação com tokens |
| **MemberView** | 🚧 Próximo | Grande complexidade, muitos componentes |
| **InsightsView** | ⏳ Pendente | Já usa Catalyst antigo, precisa migrar |
| **Radares** | 🔒 **NÃO TOCAR** | Paddings/posições ajustados manualmente |

---

## ✅ O Que Foi Feito

### 1. **TeamView.swift** ✨

**Antes:**
```swift
// Código com valores hardcoded
.padding(20)
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
.font(.headline)
```

**Depois:**
```swift
// Usando Catalyze Design System
.padding(CSpace.x3l)
.background(CColor.neutral0)
.clipShape(RoundedRectangle(cornerRadius: CRadius.md))
.cardShadow()
.font(CFont.headline)
```

**Componentes Reutilizados:**
- ✅ `TierBadge` - Badge de seniority (T2-1, T3-1, etc.)
- ✅ `SkillChip` - Chips de strengths com intensity dots
- ✅ `EmptyState` - Estado vazio consistente

**Mudanças Visuais:**
- Background neutral50 na ScrollView
- Cards com shadow padronizado
- Spacing consistente (CSpace.x3l, CSpace.lg)
- Avatar placeholder com brandPrimary

---

### 2. **TeamOverview.swift** ✨

**Componentes Reutilizados:**
- ✅ `StatCard` - Cards de métricas (Team Size, Active IDPs, In Promotion)

**Melhorias:**
- Header com cores semânticas (CColor.neutral900, CColor.neutral400)
- Distribution cards com CColor.neutral100 background
- Bars com cores do design system (CColor.info, CColor.proficiencyAdvanced)
- Typography consistente (CFont.headline, CFont.caption1)

**⚠️ Preservado:**
- ✅ `TeamRadar` - **NÃO modificado** (paddings ajustados manualmente)
- ✅ `TeamTechnicalRadar` - **NÃO modificado** (posições ajustadas)

---

### 3. **SettingsView.swift** ✨

**Mudanças Leves:**
- Mensagens de confirmação com `CColor.strength` (verde)
- Typography com `CFont.caption1`
- Spacing com `CSpace.sm`

**Preservado:**
- Form nativo (mantém estilo do sistema)
- Toda funcionalidade intacta

---

## 🚧 Próximos Passos

### **Prioridade 1: MemberView**

Esta é a view mais complexa. Componentes que podem ser reutilizados:

- [ ] `MemberCard` (já existe em `CatalyzeComponents.swift`)
- [ ] `SectionHeader` - Headers colapsáveis
- [ ] `SkillRow` - Linhas de behavioral skills
- [ ] `TechStackRow` - Linhas de tech stack
- [ ] `IntensityDots` - Indicadores visuais
- [ ] `ProficiencyBadge` - Badges de proficiência
- [ ] `EmptyState` - Estados vazios

**⚠️ NÃO TOCAR:**
- `MemberRadar` (behavioral)
- `TechnicalRadar`
- Qualquer posicionamento/padding dos radares

---

### **Prioridade 2: InsightsView**

Atualmente usa **Catalyst Design System** (antigo). Precisa migrar para **Catalyze**.

**Componentes que podem substituir:**
- `CatalystCard` → Criar versão em Catalyze (ou adaptar)
- `CatalystEmptyState` → Já existe `EmptyState` em Catalyze
- `CatalystPrimaryButton` → Criar versão em Catalyze
- `CatalystInsightLayout` → Criar versão em Catalyze

**Alternativa:**
- Manter InsightsView como está (funciona bem)
- Remover arquivos `DesignSystemCatalyst*.swift` não usados

---

### **Prioridade 3: Limpeza**

Após migração completa:

- [ ] Remover `DesignSystemCatalyst*.swift` (antigos)
- [ ] Remover `DesignSystemREADME.md` e `DesignSystemSUMMARY.md`
- [ ] Atualizar documentação principal
- [ ] Criar guia de uso do Catalyze Design System

---

## 📐 Design Tokens Disponíveis

### Cores (`CColor`)

**Brand:**
- `brandPrimary` (#5B5BD6) - Indigo principal
- `brandPrimaryLight` (#EEEEFF) - Fundo sutil
- `brandPrimaryDark` (#3D3DA7) - Estado pressionado

**Semântica:**
- `strength` (#16A34A) - Verde para forças
- `strengthLight` (#DCFCE7)
- `growth` (#D97706) - Âmbar para crescimento
- `growthLight` (#FEF3C7)
- `info` (#2563EB) - Azul informativo
- `infoLight` (#DBEAFE)
- `destructive` (#DC2626) - Vermelho destrutivo

**Proficiência:**
- `proficiencyLearning` (amber)
- `proficiencyProficient` (blue)
- `proficiencyAdvanced` (purple)
- `proficiencyExpert` (green)

**Neutrals:**
- `neutral0` - Branco (#FFFFFF)
- `neutral50` - Background (#F9FAFB)
- `neutral100` - Campos (#F3F4F6)
- `neutral200` - Bordas (#E5E7EB)
- `neutral400` - Terciário (#9CA3AF)
- `neutral600` - Secundário (#4B5563)
- `neutral700` - Corpo (#374151)
- `neutral900` - Primário (#111827)

### Spacing (`CSpace`)

- `xs` - 4pt
- `sm` - 8pt
- `md` - 12pt
- `lg` - 16pt
- `xl` - 20pt
- `x2l` - 24pt
- `x3l` - 32pt
- `x4l` - 48pt

### Typography (`CFont`)

- `largeTitle` - 34pt bold
- `title1` - 28pt bold
- `title2` - 22pt bold
- `title3` - 20pt semibold
- `headline` - 17pt semibold
- `body` - 17pt regular
- `callout` - 16pt regular
- `subheadline` - 15pt regular
- `footnote` - 13pt regular
- `caption1` - 12pt regular
- `caption2` - 11pt semibold

### Corner Radius (`CRadius`)

- `xs` - 6pt (badges)
- `sm` - 8pt (chips)
- `md` - 12pt (cards)
- `lg` - 16pt (containers)
- `xl` - 20pt (modais)
- `full` - 999pt (circles)

### Shadows

- `.cardShadow()` - Sombra padrão para cards
- `.elevatedShadow()` - Sombra para modais

---

## 🎯 Componentes Disponíveis (CatalyzeComponents.swift)

1. ✅ `StatCard` - Métricas com ícone e cor
2. ✅ `TierBadge` - Badge de tier (T2-1, T3-1, etc.)
3. ✅ `ProficiencyBadge` - Badge de proficiência técnica
4. ✅ `IntensityDots` - Pontos de intensidade (1-3)
5. ✅ `SkillChip` - Chip com dots + nome
6. ✅ `SectionHeader` - Header colapsável com ícone
7. ✅ `InsightSummaryCard` - Strongest vs Needs Focus
8. ✅ `MemberCard` - Card completo de membro
9. ✅ `PrimaryButton` - Botão de ação primária
10. ✅ `EmptyState` - Estado vazio com ação opcional
11. ✅ `SkillRow` - Linha de behavioral skill
12. ✅ `TechStackRow` - Linha de tech stack

---

## 🔄 Estratégia de Migração

### Abordagem Gradual

1. ✅ **Fase 1: Views Simples**
   - TeamView ✅
   - TeamOverview ✅
   - SettingsView ✅

2. 🚧 **Fase 2: Views Complexas**
   - MemberView (em andamento)
   - InsightsView (planejado)

3. ⏳ **Fase 3: Limpeza**
   - Remover Catalyst antigo
   - Consolidar documentação
   - Testes visuais

### Regras

- ⚠️ **NUNCA tocar nos radares** (paddings/posições manuais)
- ✅ Sempre usar tokens (CColor, CFont, CSpace, CRadius)
- ✅ Reutilizar componentes quando possível
- ✅ Manter funcionalidade 100% intacta
- ✅ Testar cada view após migração

---

## 📝 Checklist de Migração (Por View)

Ao migrar uma view:

- [ ] Substituir valores hardcoded por tokens
- [ ] Usar componentes do `CatalyzeComponents.swift`
- [ ] Atualizar comentários no header
- [ ] Testar visualmente no Canvas
- [ ] Verificar states (empty, loading, error)
- [ ] Confirmar que funcionalidade está intacta
- [ ] Atualizar este documento

---

## 🎨 Antes vs Depois

### TeamView - MemberCard

**Antes:**
```swift
.padding()
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
Text(member.seniority.label)
    .font(.caption.weight(.medium))
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(.tint.opacity(0.15), in: Capsule())
```

**Depois:**
```swift
.padding(CSpace.lg)
.background(CColor.neutral0)
.clipShape(RoundedRectangle(cornerRadius: CRadius.md))
.cardShadow()
TierBadge(tier: member.seniority.label)
```

**Resultado:**
- ✅ Mais legível
- ✅ Cores semânticas
- ✅ Componente reutilizável
- ✅ Sombra consistente

---

## 🚀 Como Continuar

### Para Migrar uma Nova View:

1. Abra a view no Xcode
2. Identifique valores hardcoded (números, cores)
3. Identifique padrões repetidos (cards, badges, etc.)
4. Substitua por tokens e componentes
5. Teste no Canvas
6. Atualize este documento

### Para Criar um Novo Componente:

1. Adicione em `CatalyzeComponents.swift`
2. Use APENAS tokens (`CColor`, `CFont`, `CSpace`, `CRadius`)
3. Crie Preview no mesmo arquivo
4. Documente aqui

---

## 📚 Referências

- `CatalyzeTokens.swift` - Todos os design tokens
- `CatalyzeComponents.swift` - Todos os componentes reutilizáveis
- `README.md` - Documentação geral do projeto
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

---

**Última atualização**: Maio 2026  
**Próximo passo**: Migrar MemberView 🎯
