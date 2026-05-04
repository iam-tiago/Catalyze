# Catalyst Design System

Um sistema de design elegante e consistente para o app Catalyze.

## 📐 Princípios

1. **Consistência** - Mesmos espaçamentos, cores e tipografia em todo o app
2. **Reutilização** - Componentes modulares e composíveis
3. **Clareza** - Interface limpa com hierarquia visual clara
4. **Responsividade** - Adaptável a diferentes tamanhos de tela

---

## 🎨 Design Tokens

### Espaçamentos (`CatalystSpacing`)

```swift
CatalystSpacing.xs    // 4pt  - Spacing mínimo
CatalystSpacing.sm    // 8pt  - Entre elementos relacionados
CatalystSpacing.md    // 12pt - Campos de formulário
CatalystSpacing.lg    // 16pt - Entre elementos
CatalystSpacing.xl    // 24pt - Entre seções
CatalystSpacing.xxl   // 32pt - Entre seções principais
CatalystSpacing.xxxl  // 48pt - Seções hero
```

### Corner Radius (`CatalystRadius`)

```swift
CatalystRadius.sm  // 8pt  - Elementos compactos
CatalystRadius.md  // 12pt - Cards e botões
CatalystRadius.lg  // 16pt - Cards proeminentes
CatalystRadius.xl  // 20pt - Elementos hero
```

### Tipografia (`CatalystTypography`)

```swift
CatalystTypography.sectionTitle  // .title2.bold() - Títulos de seção
CatalystTypography.cardTitle     // .headline - Títulos de cards
CatalystTypography.body          // .body - Texto padrão
CatalystTypography.label         // .subheadline.weight(.medium) - Labels de campos
CatalystTypography.caption       // .caption - Texto pequeno
CatalystTypography.subheadline   // .subheadline - Informação secundária
```

### Opacidade (`CatalystOpacity`)

```swift
CatalystOpacity.subtle  // 0.05 - Overlay muito sutil
CatalystOpacity.light   // 0.1  - Overlay leve
CatalystOpacity.medium  // 0.15 - Overlay médio
CatalystOpacity.strong  // 0.3  - Overlay forte
```

### Tamanhos de Ícones (`CatalystIconSize`)

```swift
CatalystIconSize.sm   // 16pt
CatalystIconSize.md   // 24pt
CatalystIconSize.lg   // 32pt
CatalystIconSize.xl   // 48pt
CatalystIconSize.hero // 64pt
```

---

## 🧩 Componentes

### 1. `CatalystCard`

Card básico com Material design e padding consistente.

**Uso:**
```swift
CatalystCard {
    VStack(spacing: CatalystSpacing.lg) {
        Text("Content here")
    }
}

// Com padding customizado
CatalystCard(padding: CatalystSpacing.md) {
    // Content
}
```

**Parâmetros:**
- `padding: CGFloat` - Padding interno (default: `CatalystSpacing.xl`)
- `radius: CGFloat` - Corner radius (default: `CatalystRadius.lg`)
- `content: () -> Content` - Conteúdo do card

---

### 2. `CatalystCardHeader`

Header padronizado para cards com título, ícone e trailing content opcional.

**Uso:**
```swift
CatalystCardHeader("Card Title", icon: "star.fill")

// Com trailing content
CatalystCardHeader("Loading", icon: "brain.fill") {
    ProgressView().controlSize(.small)
}
```

**Parâmetros:**
- `title: String` - Título do header
- `icon: String` - SF Symbol
- `trailing: () -> some View` - Content opcional no trailing

---

### 3. `CatalystEmptyState`

Estado vazio consistente com ícone, título e mensagem.

**Uso:**
```swift
CatalystEmptyState(
    icon: "person.3.slash",
    title: "No team members",
    message: "Add members to get started."
)

// Com ação
CatalystEmptyState(
    icon: "doc.text.slash",
    title: "No documents",
    message: "Create your first document.",
    actionLabel: "Add Document",
    action: { addDocument() }
)
```

**Parâmetros:**
- `icon: String` - SF Symbol
- `title: String` - Título principal
- `message: String` - Descrição
- `actionLabel: String?` - Label do botão (opcional)
- `action: (() -> Void)?` - Ação do botão (opcional)

---

### 4. `CatalystPrimaryButton`

Botão de ação primária com loading state automático.

**Uso:**
```swift
CatalystPrimaryButton(
    "Generate Insight",
    icon: "sparkles",
    isLoading: isGenerating,
    isEnabled: canGenerate
) {
    Task { await generate() }
}
```

**Parâmetros:**
- `title: String` - Texto do botão
- `icon: String` - SF Symbol
- `isLoading: Bool` - Estado de loading (default: `false`)
- `isEnabled: Bool` - Se está habilitado (default: `true`)
- `action: () -> Void` - Ação ao clicar

**Recursos:**
- Loading text inteligente baseado no título ("Generating...", "Analyzing...", etc.)
- Desabilita automaticamente quando em loading
- Estilo `.borderedProminent` e `.controlSize(.large)`

---

### 5. `CatalystFieldLabel`

Label consistente para campos de formulário.

**Uso:**
```swift
VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
    CatalystFieldLabel("Team Member")
    
    Picker("Select", selection: $selected) {
        // Options
    }
}
```

---

### 6. `CatalystErrorBanner`

Banner de erro consistente.

**Uso:**
```swift
if let error = errorMessage {
    CatalystErrorBanner(message: error)
}
```

---

### 7. `CatalystLoadingIndicator`

Indicador de loading para headers.

**Uso:**
```swift
HStack {
    Text("AI Response")
    Spacer()
    if isGenerating {
        CatalystLoadingIndicator("Streaming...")
    }
}
```

---

### 8. `CatalystInsightLayout`

Layout especializado para tabs de Insights (com GeometryReader).

**Uso:**
```swift
CatalystInsightLayout(
    inputTitle: "Generate Insight",
    streamingText: streamingText,
    isGenerating: isGenerating,
    errorMessage: errorMessage
) {
    // Input controls aqui (pickers, buttons, etc.)
}
```

**Parâmetros:**
- `inputTitle: String` - Título da seção de input
- `inputIcon: String` - SF Symbol (default: `"brain.fill"`)
- `streamingText: String` - Texto de resposta da IA
- `isGenerating: Bool` - Se está gerando
- `errorMessage: String?` - Mensagem de erro (opcional)
- `inputContent: () -> InputContent` - Controles de input

**Recursos:**
- Card de input com header
- Card de output (aparece apenas quando `streamingText` não está vazio)
- Loading indicator automático
- Error banner automático
- GeometryReader para scroll horizontal correto

---

### 9. `CatalystSimpleInsightLayout`

Versão simplificada sem GeometryReader (para a maioria dos casos).

**Uso:** Idêntico ao `CatalystInsightLayout`, mas sem `GeometryReader`.

---

## 📋 Padrões de Uso

### Formulário Padrão

```swift
VStack(spacing: CatalystSpacing.lg) {
    VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
        CatalystFieldLabel("Label")
        Picker("Select", selection: $value) {
            // Options
        }
    }
    
    CatalystPrimaryButton("Submit", icon: "checkmark") {
        submit()
    }
}
```

### Card com Header

```swift
CatalystCard {
    VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
        CatalystCardHeader("Title", icon: "star.fill")
        
        Text("Body content")
            .font(CatalystTypography.body)
    }
}
```

### Tab de Insight

```swift
CatalystSimpleInsightLayout(
    inputTitle: "Tab Title",
    inputIcon: "custom.icon",
    streamingText: streamingText,
    isGenerating: isGenerating,
    errorMessage: errorMessage
) {
    VStack(spacing: CatalystSpacing.lg) {
        // Input controls
    }
}
```

---

## 🎯 Próximos Passos

### Fase 2 - Componentes Adicionais
- [ ] `CatalystTextField` - Campo de texto customizado
- [ ] `CatalystTextEditor` - Editor de texto multi-linha
- [ ] `CatalystPicker` - Picker com estilo consistente
- [ ] `CatalystSecondaryButton` - Botão secundário
- [ ] `CatalystDestructiveButton` - Botão destrutivo

### Fase 3 - Expansão
- [ ] Aplicar design system em `TeamView`
- [ ] Aplicar design system em `MemberView`
- [ ] Aplicar design system em `SettingsView`
- [ ] Criar variantes de tema (light/dark otimizados)

### Fase 4 - Refinamentos
- [ ] Animações consistentes
- [ ] Estados de hover/pressed
- [ ] Acessibilidade melhorada
- [ ] Testes visuais

---

## 📚 Referências

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- Material Design na SwiftUI (`.regularMaterial`, `.ultraThinMaterial`, etc.)
