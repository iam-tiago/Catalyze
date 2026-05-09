# 🚀 Catalyze - People Management for Engineering Managers

**Versão**: 1.0.0  
**Plataforma**: iPadOS 17.0+  
**Linguagem**: Swift 6.0  
**Frameworks**: SwiftUI, SwiftData, CloudKit

---

## 📖 Sobre

Catalyze é uma ferramenta **local-first** para Engineering Managers acompanharem o desenvolvimento de seus times. Todos os dados ficam no dispositivo, com sincronização opcional via iCloud.

### Funcionalidades Principais

✨ **Gestão de Time**
- Perfis completos de membros com fotos, skills e seniority
- Acompanhamento de forças e áreas de melhoria
- Radar visual de competências técnicas e comportamentais

🎯 **Desenvolvimento Individual**
- Individual Development Plans (IDPs) com ações rastreáveis
- Observações contextualizadas (1:1s, incidents, reviews)
- Timeline de evolução do perfil

📊 **Insights com IA**
- Análise individual de padrões de comportamento
- Preparação para 1:1s
- Recomendações para performance reviews
- Insights de saúde do time

☁️ **Privacidade e Sync**
- Todos os dados armazenados localmente
- Sincronização automática via CloudKit (iCloud)
- API key segura no Keychain
- Zero autenticação, zero backend

---

## 🎨 Design

- **Native iPad UI** com NavigationSplitView
- **Adaptive layouts** para portrait/landscape/Split View
- **SF Symbols** para ícones consistentes
- **Dark mode** completo
- **Accessibility** com VoiceOver

---

## 🏗️ Arquitetura

### Tech Stack

| Camada | Tecnologia |
|--------|-----------|
| UI | SwiftUI |
| State | @Observable (AppStore) |
| Database | SwiftData |
| Sync | CloudKit (private database) |
| Charts | Swift Charts |
| AI | Anthropic Claude API (SSE streaming) |
| Security | Keychain (API key) |
| Settings | UserDefaults (EM profile) |

### Estrutura do Projeto

```
Catalyze/
├── CatalyzeApp.swift          # App entry point
├── Models/
│   ├── Enums.swift            # Seniority, Intensity, etc.
│   ├── TeamMember.swift       # Member + StrengthWeakness + StackEntry
│   ├── MemberObservation.swift
│   ├── DevelopmentPlan.swift  # IDP + actions
│   ├── PromotionReadiness.swift
│   ├── Insight.swift
│   ├── ProfileEvent.swift
│   └── EMProfile.swift        # Engineering Manager profile
├── Persistence/
│   ├── Persistence.swift      # SwiftData container + CloudKit
│   └── Keychain.swift         # API key storage
├── Store/
│   └── AppStore.swift         # @Observable state management
├── AI/
│   ├── ClaudeClient.swift     # Streaming SSE client
│   └── ClaudePrompts.swift    # Prompt templates
├── Views/
│   ├── Layout/
│   │   └── AppLayout.swift    # NavigationSplitView root
│   ├── Team/
│   │   ├── TeamView.swift     # Member grid
│   │   ├── TeamOverview.swift # Dashboard stats
│   │   └── MemberForm.swift   # Add/edit member
│   ├── Member/
│   │   ├── MemberView.swift   # Member detail
│   │   ├── TagSection.swift
│   │   ├── ObservationSection.swift
│   │   └── ... (outros sections)
│   ├── Charts/
│   │   ├── MemberRadar.swift
│   │   ├── TechnicalRadar.swift
│   │   └── TeamRadar.swift
│   ├── Insights/
│   │   └── InsightsView.swift # AI insights tabs
│   └── Settings/
│       └── SettingsView.swift
└── Utilities/
    └── ErrorHandling.swift    # Logging, validation, errors
```

---

## 🆕 Melhorias Recentes

### ✅ Sistema de Logging
- Logger centralizado com níveis (debug, info, warning, error, success)
- Logs estruturados apenas em modo DEBUG
- Performance otimizada em Release builds

### ✅ Tratamento de Erros
- `AppError` enum com erros tipados
- Sugestões de recuperação para o usuário
- Modifier `.errorAlert()` para exibir erros consistentemente

### ✅ Validação Robusta
- `Validator` utility com validações reutilizáveis
- Validação de nome, role e URLs
- Feedback imediato ao usuário

### ✅ CloudKit Ativo
- Sincronização automática entre dispositivos
- Backup transparente no iCloud
- Containers separados para dev/prod

📄 **Documentação completa**: Ver `IMPROVEMENTS.md`

---

## 🚀 Como Usar

### Requisitos

- Xcode 16.3+
- iPadOS 17.0+ (simulador ou device)
- Conta iCloud (para sync)
- API key do Claude (opcional, para AI insights)

### Instalação

1. Clone o repositório
2. Abra `Catalyze.xcodeproj` no Xcode
3. Selecione seu time de desenvolvimento
4. Atualize o Bundle ID e entitlements se necessário
5. Build e Run (`⌘R`)

### Primeira Configuração

1. Abra **Settings** no app
2. Configure seu perfil (nome, role, team name)
3. (Opcional) Adicione sua API key do Claude
4. Volte para **Team** e adicione seu primeiro membro

---

## 🧪 Testes

### Checklist Completo
Ver `TEST_CHECKLIST.md` para lista detalhada de testes.

### Smoke Tests Rápidos

```bash
# 1. Clean build
⇧⌘K → ⌘B

# 2. Add → Edit → Delete member
# Verificar persistência após relaunch

# 3. Testar cascade delete
# Adicionar observation → deletar member → verificar cascade

# 4. Testar AI insights
# Configurar API key → gerar insight → verificar streaming

# 5. (Opcional) Testar CloudKit sync
# Dois simuladores com mesma conta iCloud
```

---

## 📊 Data Models

### Principais Entidades

**TeamMember**
- Nome, role, seniority, foto
- Strengths & weaknesses (behavioral tags)
- Stack proficiencies (technical tags)
- Mentorship (internal & external)

**TeamObservation**
- Texto da observação
- Contexto (1:1, Incident, Sprint Review, etc.)
- Data e membro relacionado

**DevelopmentPlan** (IDP)
- Título, objetivo, target date
- Status (Active, On Hold, Completed)
- Lista de ações (checkboxes)
- Link opcional para growth area

**PromotionReadiness**
- Target tier
- Status (Not Ready, In Progress, Ready)
- Critérios customizáveis
- AI assessment

**Insight**
- Tipo (individual, team, 1:1 prep, etc.)
- Prompt e resposta do Claude
- Cached para referência futura

---

## 🔐 Segurança

- **API key**: Armazenada no Keychain, não sincroniza
- **Data at rest**: SQLite local (protegido por criptografia do device)
- **Data in transit**: HTTPS para Claude API
- **CloudKit**: Private database (apenas iCloud do usuário)
- **Privacy**: Anthropic não treina com dados da API

---

## 🎯 Roadmap

### ✅ Versão 1.0 (Atual)
- Gestão completa de membros
- IDPs e observations
- AI insights (Claude)
- CloudKit sync
- Sistema de logging e validação

### 🚧 Versão 1.1 (Planejado)
- [ ] Export/Import (JSON + Markdown)
- [ ] Insights history view
- [ ] Local notifications (IDP deadlines)
- [ ] PhotosPicker improvements

### 🔮 Versão 2.0 (Futuro)
- [ ] iPhone companion app
- [ ] Mac Catalyst version
- [ ] Widgets para quick view
- [ ] Collaboration features
- [ ] Custom fields

---

## 🐛 Troubleshooting

## 🐛 Troubleshooting

### ⚠️ IMPORTANTE: CloudKit Schema Fix (v1.1.0)

**Se você usou versões anteriores do app**, o schema foi corrigido para ser compatível com CloudKit.

**VOCÊ DEVE deletar o app e reinstalar:**

```bash
# 1. Delete o app do simulador (toque e segure → Remove App)
# 2. Clean Build no Xcode
⇧⌘K
# 3. Build and Run
⌘R
```

**O que mudou:**
- ✅ Removido `@Attribute(.unique)` (CloudKit incompatível)
- ✅ Adicionado relacionamentos inversos bidirecionais
- ✅ App agora totalmente compatível com CloudKit

📄 **Detalhes**: `CLOUDKIT_SCHEMA_FIX.md`

---

### Build Failures
```bash
# Clean build folder
⇧⌘K

# Delete DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reabrir Xcode
```

### CloudKit Não Sincroniza
1. **Delete o app e reinstale** (schema pode estar antigo)
2. Verificar iCloud ativado (Settings app)
3. Verificar entitlements corretos (`CAPABILITIES_SETUP.md`)
4. Esperar 30-60s para primeira sync
5. Checar console para mensagens "SwiftData container created with CloudKit"

### Persistência Não Funciona
1. **Delete o app completamente**
2. Clean Build Folder (`⇧⌘K`)
3. Build and Run novamente
4. Verificar logs no console (deve ver "ModelContainer initialized successfully")

---

## 📚 Recursos

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Best Practices](https://developer.apple.com/documentation/cloudkit)
- [Claude API Reference](https://docs.anthropic.com/claude/reference)
- [Swift Charts](https://developer.apple.com/documentation/Charts)

---

## 📄 Documentação Adicional

- `TECHNICAL_SPEC.md` - Especificação técnica completa
- `IMPROVEMENTS.md` - Histórico de melhorias
- `TEST_CHECKLIST.md` - Checklist de testes detalhado
- `CAPABILITIES_SETUP.md` - Guia de configuração de entitlements
- `TROUBLESHOOTING_SWIFTDATA.md` - Troubleshooting de erros de persistência
- `CLOUDKIT_SCHEMA_FIX.md` - ⚠️ **IMPORTANTE!** Correção do schema para CloudKit
- `QUICK_CLOUDKIT_SETUP.md` - Guia de 5 minutos para ativar CloudKit

---

## 🤝 Contribuindo

Este é um projeto interno. Para sugestões:

1. Abra uma issue descrevendo o problema/feature
2. Discuta a abordagem antes de implementar
3. Siga os padrões de código estabelecidos
4. Adicione testes para novas funcionalidades
5. Atualize a documentação

### Padrões de Código

- **Logging**: Use `Logger.log()` em vez de `print()`
- **Erros**: Use `AppError` e `.errorAlert()`
- **Validação**: Use `Validator` utilities
- **SwiftUI**: Prefira composition over inheritance
- **Naming**: Swift API Design Guidelines

---

## 📝 License

Proprietary - Internal use only

---

## 👥 Autores

**Prontto Team**

---

## 🙏 Agradecimentos

- Apple por SwiftUI e SwiftData
- Anthropic pelo Claude API
- Comunidade Swift

---

**Feito com ❤️ para Engineering Managers**

---

## 📞 Suporte

Para questões ou suporte:
- Email: [seu-email]
- Slack: #catalyze-support

---

**Última atualização**: Maio 2026
