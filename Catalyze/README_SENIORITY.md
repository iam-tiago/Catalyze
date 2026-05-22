# 🎯 Sistema de Senioridade Customizável - Catalyze

## Visão Geral

O Catalyze agora possui um **sistema de senioridade totalmente customizável**, permitindo que cada organização defina sua própria escada de carreira. Você pode escolher entre **6 presets prontos** ou criar **níveis completamente personalizados**.

---

## ✨ Funcionalidades

### 📋 Presets Prontos

| Preset | Descrição | Níveis |
|--------|-----------|--------|
| **T-Level** | Sistema técnico com sub-divisões (padrão) | T1-3, T2-1, T2-2, T2-3, T3-1, T3-2, T3-3, T4 |
| **Traditional** | Nomenclatura brasileira clássica | Júnior, Pleno, Sênior, Especialista |
| **FAANG** | Níveis de Big Tech (Google, Meta, etc.) | L3, L4, L5, L6, L7, L8 |
| **Management** | Bifurcação IC + Management | IC1-IC4, M1-M4 (EM→VP) |
| **Startup** | Sistema simplificado para startups | Junior, Mid, Senior, Lead |
| **Custom** | Crie do zero! | Quantos níveis você quiser |

### 🎨 Personalização Total

Cada nível de senioridade pode ter:
- ✅ **Código customizado** (T2-1, Senior, L5, etc.)
- ✅ **Nome completo** (Senior Engineer II, Desenvolvedor Pleno)
- ✅ **Ordem numérica** (para sorting e promoções)
- ✅ **Cor personalizada** (badges coloridos!)
- ✅ **Categoria** (IC, Senior, Staff, Management, etc.)
- ✅ **Descrição** (critérios de cada nível)

---

## 📁 Arquivos Criados

### Modelos e Lógica
- **`SeniorityLevel.swift`** - Modelos SwiftData + Presets
  - `SeniorityLevel` (modelo persistente)
  - `OrganizationConfig` (configuração da empresa)
  - `SeniorityPreset` (enum com 6 presets)
  - `SeniorityLevelData` (value type para migração)

- **`SeniorityService.swift`** - Service centralizado
  - Acesso aos níveis da organização
  - Helpers para promoção (nextLevel, higherLevels)
  - Migration helpers (compatibilidade com enum antigo)
  - Environment key para injeção

### UI
- **`ViewsSettingsSeniorityConfigView.swift`** - Tela de configuração
  - Seleção de preset
  - Visualização dos níveis
  - Criação/edição de níveis customizados (modo Custom)
  - Form com color picker

- **`CatalyzeComponents.swift`** - Componentes atualizados
  - `TierBadge` (3 inicializadores: string, SeniorityLevel, cores explícitas)
  - `SeniorityLevelRow` (novo componente para lista de níveis)

### Documentação
- **`SENIORITY_MIGRATION_GUIDE.md`** - Guia completo de migração
- **`SETUP_EXAMPLE.swift`** - 9 exemplos práticos de uso
- **`README_SENIORITY.md`** - Este arquivo

---

## 🚀 Quick Start

### 1️⃣ Adicionar ao ModelContainer

```swift
// Em PersistenceController.swift ou CatalyzeApp.swift
let schema = Schema([
    // ... modelos existentes
    OrganizationConfig.self,  // ✅ Adicionar
    SeniorityLevel.self,      // ✅ Adicionar
])
```

### 2️⃣ Injetar SeniorityService

```swift
// Em CatalyzeApp.swift
@main
struct CatalyzeApp: App {
    private let container: ModelContainer
    @State private var seniorityService: SeniorityService?
    
    var body: some Scene {
        WindowGroup {
            AppLayout()
                .seniorityService(seniorityService ?? SeniorityService(modelContext: container.mainContext))
                .onAppear {
                    if seniorityService == nil {
                        seniorityService = SeniorityService(modelContext: container.mainContext)
                    }
                }
        }
        .modelContainer(container)
    }
}
```

### 3️⃣ Usar em Views

```swift
struct MemberFormView: View {
    @Environment(\.seniorityService) private var seniorityService
    
    var body: some View {
        Picker("Level", selection: $selectedLevel) {
            ForEach(seniorityService?.levels ?? [], id: \.code) { level in
                Text(level.displayName).tag(level.code)
            }
        }
    }
}
```

### 4️⃣ Adicionar em Settings

```swift
NavigationLink {
    SeniorityConfigView()
} label: {
    Label("Seniority Levels", systemImage: "chart.bar.fill")
}
```

---

## 🎨 Componentes Visuais

### TierBadge (Atualizado)

```swift
// Uso simples (cores padrão da marca)
TierBadge(tier: "T3-1")

// Com SeniorityLevel (cores customizadas!)
if let level = seniorityService?.level(byCode: "T3-1") {
    TierBadge(level: level)  // 🎨 Usa a cor do nível
}

// Com cores explícitas
TierBadge(
    tier: "Sênior",
    foreground: Color(hex: "#8B5CF6"),
    background: Color(hex: "#8B5CF6").opacity(0.15)
)
```

### SeniorityLevelRow (Novo)

```swift
SeniorityLevelRow(
    code: "T2-1",
    displayName: "Senior Engineer I",
    category: "Senior",
    color: Color(hex: "#3B82F6"),
    isEditable: true,
    onEdit: { /* editar */ },
    onDelete: { /* deletar */ }
)
```

---

## 🔄 Compatibilidade com Código Existente

### ✅ Totalmente Compatível

O sistema **NÃO quebra** código existente:

1. **TeamMember continua usando String**
   ```swift
   var seniorityRaw: String = "T2-1"
   ```

2. **Enum Seniority ainda funciona**
   ```swift
   let member = TeamMember(seniority: .t2_1)
   ```

3. **Migration automática**
   ```swift
   // Código antigo: member.seniority.rawValue → "T2-1"
   // Novo sistema: seniorityService.level(byCode: "T2-1") → SeniorityLevel
   ```

4. **Fallback visual**
   ```swift
   if let level = seniorityService?.level(byCode: code) {
       TierBadge(level: level)  // Cores customizadas
   } else {
       TierBadge(tier: code)    // Cores padrão
   }
   ```

---

## 📊 Casos de Uso

### 1. Dashboard com Distribuição

```swift
// Métricas por nível com cores
ForEach(seniorityService?.levels ?? [], id: \.id) { level in
    HStack {
        TierBadge(level: level)
        Text(level.displayName)
        Spacer()
        Text("\(countFor(level))")
            .foregroundStyle(level.color)
    }
}
```

### 2. Planejamento de Promoção

```swift
// Próximo nível sugerido
let next = seniorityService?.nextLevel(after: member.seniority.rawValue)

// Todos os níveis superiores
let targets = seniorityService?.higherLevels(than: member.seniority.rawValue)

Picker("Target", selection: $target) {
    ForEach(targets ?? [], id: \.code) { level in
        Text(level.displayName).tag(level.code)
    }
}
```

### 3. Formulário de Membro

```swift
Picker("Seniority", selection: $selectedLevel) {
    ForEach(seniorityService?.levels ?? [], id: \.code) { level in
        HStack {
            Circle().fill(level.color).frame(width: 8, height: 8)
            Text(level.displayName)
        }
        .tag(level.code)
    }
}
```

---

## 🎯 Roadmap Futuro

- [ ] **Gráficos de distribuição** por nível
- [ ] **Histórico de progressão** (tracking de mudanças)
- [ ] **Export/Import** de configurações
- [ ] **Mais presets** (Microsoft, Amazon, Spotify, etc.)
- [ ] **AI Suggestions** - Claude sugerindo próximo nível baseado em skills
- [ ] **Comparison view** - comparar diferentes presets antes de escolher
- [ ] **Salary bands** (opcional) - associar faixas salariais aos níveis

---

## 📚 Recursos

- **Guia de Migração**: `SENIORITY_MIGRATION_GUIDE.md`
- **Exemplos de Código**: `SETUP_EXAMPLE.swift`
- **Modelos**: `SeniorityLevel.swift`
- **Service**: `SeniorityService.swift`
- **UI**: `ViewsSettingsSeniorityConfigView.swift`
- **Componentes**: `CatalyzeComponents.swift`

---

## 🐛 Troubleshooting

### Níveis não aparecem?
✅ Verifique se `SeniorityService` está injetado via `.seniorityService(...)`

### Cores não funcionam?
✅ Use `TierBadge(level:)` em vez de `TierBadge(tier:)`

### Dados antigos?
✅ Sistema mantém compatibilidade - códigos antigos continuam funcionando

### Primeiro uso?
✅ O sistema cria automaticamente o preset T-Level na primeira vez

---

## 💡 Dica

Para testar os diferentes presets rapidamente:
1. Vá em **Settings → Seniority Levels**
2. Escolha um preset diferente
3. Veja como os badges mudam de cor!
4. Volte para Custom se quiser ajustar manualmente

---

**Made with 💜 by Catalyze Team**
