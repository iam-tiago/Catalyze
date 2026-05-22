# Guia de Migração: Sistema de Senioridade Customizável

## Visão Geral

O Catalyze agora suporta **níveis de senioridade customizáveis**, permitindo que cada organização defina sua própria escada de carreira. Este guia explica como migrar código existente e usar o novo sistema.

---

## 📋 O que mudou?

### Antes (Sistema Fixo)
```swift
// Enum fixo com valores hardcoded
enum Seniority: String {
    case t1_3 = "T1-3"
    case t2_1 = "T2-1"
    // ...
}

// Uso direto do enum
let member = TeamMember(seniority: .t2_1)
TierBadge(tier: member.seniority.rawValue)
```

### Agora (Sistema Customizável)
```swift
// Modelo SwiftData customizável
@Model
class SeniorityLevel {
    var code: String        // "T2-1", "Senior", "L5", etc.
    var displayName: String // "Senior Engineer II"
    var order: Int          // Para sorting
    var colorHex: String    // Cor customizada
    var category: String    // "IC", "Senior", "Staff", etc.
}

// Acesso via SeniorityService
@Environment(\.seniorityService) private var seniorityService

let level = seniorityService?.level(byCode: "T2-1")
TierBadge(level: level)
```

---

## 🎯 Presets Disponíveis

### 1. **T-Level** (Padrão)
Sistema de níveis técnicos com sub-divisões:
- T1-3: IC Engineer
- T2-1, T2-2, T2-3: Senior I, II, III
- T3-1, T3-2, T3-3: Staff I, II, Principal
- T4: Distinguished

### 2. **Traditional** (Junior/Pleno/Senior)
Nomenclatura tradicional brasileira:
- Júnior
- Pleno
- Sênior
- Especialista

### 3. **FAANG** (L3-L8)
Níveis usados em Big Tech:
- L3: SWE I (Entry)
- L4: SWE II (Mid)
- L5: Senior SWE
- L6: Staff SWE
- L7: Senior Staff SWE
- L8: Principal SWE

### 4. **Management** (IC + Management Track)
Bifurcação de carreira:
- **IC Track**: IC1, IC2, IC3, IC4
- **Management Track**: M1 (EM), M2 (Senior Manager), M3 (Director), M4 (VP)

### 5. **Startup** (4 níveis)
Sistema simplificado:
- Junior
- Mid
- Senior
- Lead

### 6. **Custom**
Crie seus próprios níveis!

---

## 🔧 Como Usar nos Componentes

### TierBadge

```swift
// Uso simples (cores padrão)
TierBadge(tier: "T3-1")

// Uso com SeniorityLevel (cores customizadas)
if let level = seniorityService?.level(byCode: "T3-1") {
    TierBadge(level: level)
}

// Uso com cores explícitas
TierBadge(
    tier: "Sênior",
    foreground: Color(hex: "#8B5CF6"),
    background: Color(hex: "#8B5CF6").opacity(0.15)
)
```

### MemberCard

```swift
// Se você tem acesso ao SeniorityService
@Environment(\.seniorityService) private var seniorityService

MemberCard(
    name: member.name,
    role: member.role,
    tier: member.seniority.rawValue, // Ainda funciona!
    topStrengths: topStrengths
)

// Para usar cores customizadas, modifique MemberCard internamente
// para aceitar um SeniorityLevel opcional
```

### PromotionReadiness

```swift
// Pegando níveis superiores para promoção
let higherLevels = seniorityService?.higherLevels(than: member.seniority.rawValue)

Picker("Target Tier", selection: $targetTier) {
    ForEach(higherLevels ?? [], id: \.id) { level in
        Text(level.displayName).tag(level.code)
    }
}
```

---

## 🚀 Setup Inicial

### 1. Adicionar ao ModelContainer

```swift
// No seu App ou Preview
.modelContainer(for: [
    TeamMember.self,
    OrganizationConfig.self,  // ✅ Adicionar
    SeniorityLevel.self,      // ✅ Adicionar
    // ... outros modelos
])
```

### 2. Injetar SeniorityService

```swift
// No App principal ou ContentView
@Environment(\.modelContext) private var modelContext

var body: some View {
    ContentView()
        .seniorityService(SeniorityService(modelContext: modelContext))
}
```

### 3. Usar em Views

```swift
struct MyView: View {
    @Environment(\.seniorityService) private var seniorityService
    
    var body: some View {
        VStack {
            // Listar todos os níveis
            ForEach(seniorityService?.levels ?? [], id: \.id) { level in
                TierBadge(level: level)
            }
        }
    }
}
```

---

## 🔄 Migração de Dados Existentes

### TeamMember ainda usa String

O modelo `TeamMember` continua armazenando senioridade como `String` (`seniorityRaw`), o que garante **compatibilidade total** com dados existentes:

```swift
@Model
final class TeamMember {
    var seniorityRaw: String = Seniority.t2_1.rawValue
    
    var seniority: Seniority {
        get { Seniority(rawValue: seniorityRaw) ?? .t2_1 }
        set { seniorityRaw = newValue.rawValue }
    }
}
```

### Migração automática

O `SeniorityService` automaticamente mapeia códigos antigos:

```swift
// Código antigo: "T2-1"
// Novo sistema: encontra o SeniorityLevel com code "T2-1"
let level = seniorityService?.level(byCode: member.seniority.rawValue)
```

Se o usuário trocar para preset "Traditional", os membros antigos com "T2-1" vão continuar funcionando - apenas não vão ter match visual até serem atualizados manualmente.

---

## ⚙️ Configuração pela UI

### Acessar Configuração

```swift
// Em SettingsView, adicionar navegação:
NavigationLink {
    SeniorityConfigView()
} label: {
    Label("Seniority Levels", systemImage: "chart.bar.fill")
}
```

### Funcionalidades

1. **Escolher Preset**: Selecione um sistema pré-configurado
2. **Visualizar Níveis**: Veja todos os níveis do preset escolhido
3. **Custom**: Crie/edite/delete níveis personalizados
4. **Cores**: Cada nível tem sua cor visual própria

---

## 📝 Exemplos Práticos

### Exemplo 1: Formulário de Membro

```swift
struct MemberForm: View {
    @Environment(\.seniorityService) private var seniorityService
    @State private var selectedLevel: String = ""
    
    var body: some View {
        Form {
            Picker("Seniority", selection: $selectedLevel) {
                ForEach(seniorityService?.levels ?? [], id: \.code) { level in
                    HStack {
                        Circle()
                            .fill(level.color)
                            .frame(width: 8, height: 8)
                        Text(level.displayName)
                    }
                    .tag(level.code)
                }
            }
        }
    }
}
```

### Exemplo 2: Dashboard com Métricas

```swift
struct TeamDashboard: View {
    @Environment(\.seniorityService) private var seniorityService
    @Query private var members: [TeamMember]
    
    var membersByLevel: [String: Int] {
        Dictionary(grouping: members, by: \.seniority.rawValue)
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack {
            ForEach(seniorityService?.levels ?? [], id: \.id) { level in
                HStack {
                    TierBadge(level: level)
                    Spacer()
                    Text("\(membersByLevel[level.code] ?? 0) members")
                }
            }
        }
    }
}
```

### Exemplo 3: Próximo Nível de Promoção

```swift
func suggestNextLevel(for member: TeamMember) -> SeniorityLevel? {
    seniorityService?.nextLevel(after: member.seniority.rawValue)
}

// Uso
if let next = suggestNextLevel(for: member) {
    Text("Next level: \(next.displayName)")
        .foregroundStyle(next.color)
}
```

---

## ✅ Checklist de Migração

- [x] Adicionar `OrganizationConfig` e `SeniorityLevel` ao ModelContainer
- [x] Criar `SeniorityService` e injetar via Environment
- [x] Atualizar `TierBadge` para aceitar `SeniorityLevel`
- [x] Adicionar `SeniorityConfigView` em Settings
- [ ] Atualizar formulários de criação/edição de membros para usar níveis customizados
- [ ] Atualizar `PromotionReadinessForm` para usar níveis customizados
- [ ] Adicionar migration script (se necessário) para dados legados
- [ ] Testar com diferentes presets
- [ ] Documentar escolha de preset recomendado para usuários

---

## 🐛 Troubleshooting

### Problema: Níveis não aparecem

**Solução**: Verifique se o `SeniorityService` está sendo injetado:
```swift
.seniorityService(SeniorityService(modelContext: modelContext))
```

### Problema: Cores não funcionam

**Solução**: Verifique se está usando o inicializador correto do `TierBadge`:
```swift
// ✅ Correto
TierBadge(level: seniorityLevel)

// ❌ Não vai usar cores customizadas
TierBadge(tier: seniorityLevel.code)
```

### Problema: Dados antigos não migram

**Solução**: O sistema mantém compatibilidade. Códigos antigos ("T2-1") continuam funcionando. Para atualizar visualmente, edite o membro e salve novamente.

---

## 🎨 Próximos Passos

1. **Visualizações avançadas**: Gráficos de distribuição de senioridade
2. **Progression tracking**: Histórico de mudanças de nível
3. **Export/Import**: Compartilhar configurações entre teams
4. **Templates**: Mais presets pré-configurados (Microsoft, Amazon, etc.)
5. **AI Suggestions**: Claude sugerindo próximo nível baseado em skills

---

**Dúvidas?** Consulte os arquivos:
- `SeniorityLevel.swift` - Modelos e presets
- `SeniorityService.swift` - API de acesso
- `SeniorityConfigView.swift` - UI de configuração
- `CatalyzeComponents.swift` - Componentes visuais
