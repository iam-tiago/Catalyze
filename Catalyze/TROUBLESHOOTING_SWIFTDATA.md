# 🔧 Guia de Troubleshooting - Erro de Persistência SwiftData

## ❌ Erro: SwiftDataError error 1

### Sintomas
```
❌ [CatalyzeApp.swift:XX] Error (Failed to open persistent store): 
   The operation couldn't be completed. (SwiftData.SwiftDataError error 1.)
```

Este erro indica que o SwiftData não conseguiu inicializar o container persistente.

---

## 🔍 Causas Comuns

### 1. **Entitlements do CloudKit Não Configurados**
   - O app precisa das capabilities corretas no Xcode
   - Container identifier deve existir no Apple Developer Portal

### 2. **Conta iCloud Não Configurada**
   - Simulador ou device não está conectado ao iCloud
   - iCloud Drive pode estar desativado

### 3. **Schema Migration Pendente**
   - Mudanças no modelo que precisam de migração
   - SwiftData não consegue migrar automaticamente

### 4. **Dados Corrompidos**
   - Store local pode estar corrompido
   - Precisa ser deletado e recriado

---

## ✅ Soluções (Em Ordem)

### Solução 1: Verificar iCloud no Simulador/Device

**Simulador:**
1. Abra **Settings** no simulador
2. Vá em **Apple ID** (topo da tela)
3. Faça login com Apple ID de teste
4. Vá em **iCloud**
5. Ative **iCloud Drive**
6. Delete o app e rode novamente

**Device Físico:**
1. **Settings** > **[Seu Nome]** > **iCloud**
2. Certifique-se que **iCloud Drive** está ON
3. Verifique se há espaço disponível no iCloud

---

### Solução 2: Configurar CloudKit Entitlements no Xcode

1. **Selecione o projeto** no Xcode
2. **Selecione o target "Catalyze"**
3. Vá em **Signing & Capabilities**
4. Verifique se **iCloud** está presente:
   - Se NÃO: clique **+ Capability** → adicione **iCloud**
5. Em **iCloud**, certifique-se que está marcado:
   - ☑️ **CloudKit**
   - ☑️ **CloudKit (Background)**
6. Em **Containers**, deve haver:
   - `iCloud.com.prontto.Catalyze` (ou seu bundle ID)
   - Se não existir, clique **+** e adicione

**Importante**: O container identifier deve seguir o padrão:
```
iCloud.<seu-bundle-id>
```

Se seu Bundle ID é `com.seutime.Catalyze`, o container deve ser:
```
iCloud.com.seutime.Catalyze
```

---

### Solução 3: Atualizar o Código para Usar Local-Only Temporariamente

Se CloudKit está causando problemas e você quer testar sem ele:

**Em `Persistence.swift`, altere `makeContainer()` para:**

```swift
static func makeContainer() throws -> ModelContainer {
    Logger.log("Using LOCAL-ONLY container (CloudKit disabled)", level: .warning)
    return try makeLocalOnlyContainer()
}
```

Isso vai:
- ✅ Persistir dados localmente (sobrevive a relaunches)
- ❌ NÃO sincronizar via iCloud
- ✅ Permitir testar o resto do app

**Depois que resolver o CloudKit, volte ao código original.**

---

### Solução 4: Deletar Dados Corrompidos

**Opção A - Deletar o App:**
1. No simulador/device, **delete o app** (toque e segure, "Remove App")
2. No Xcode, **Clean Build Folder** (`⇧⌘K`)
3. **Build and Run** novamente (`⌘R`)

**Opção B - Deletar DerivedData:**
```bash
# No Terminal:
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**Opção C - Reset Simulador:**
1. **Device** menu → **Erase All Content and Settings...**
2. Configure iCloud novamente
3. Rode o app

---

### Solução 5: Verificar Bundle ID e Team

1. No Xcode, **Signing & Capabilities**
2. Certifique-se que:
   - **Team** está selecionado (não "None")
   - **Bundle Identifier** é único (ex: `com.SEUTIME.Catalyze`)
   - **Signing Certificate** está válido

3. Se mudar o Bundle ID, TAMBÉM mude:
   - Container identifier em **iCloud Capabilities**
   - Código em `Persistence.swift` se estiver hardcoded

---

### Solução 6: Criar Container no CloudKit Dashboard (Avançado)

Se o container não existe no Apple Developer Portal:

1. Vá em [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Faça login com seu Apple Developer account
3. Verifique se `iCloud.com.prontto.Catalyze` existe
4. Se NÃO existir:
   - No Xcode, rode o app uma vez com as capabilities corretas
   - O Xcode criará automaticamente
   - OU crie manualmente no dashboard

---

### Solução 7: Verificar Schema do SwiftData

Se você fez mudanças nos models recentemente:

**Verifique `Persistence.swift`:**
```swift
enum CatalyzeSchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            TeamMember.self,
            StrengthWeakness.self,
            StackEntry.self,
            TeamObservation.self,
            Insight.self,
            DevelopmentPlan.self,
            IDPAction.self,
            PromotionReadiness.self,
            PromotionCriterion.self,
            ProfileEvent.self,
        ]
    }
}
```

**Certifique-se que:**
- ✅ Todos os seus `@Model` classes estão listados
- ✅ Nenhum model foi removido (precisa migração)
- ✅ Todos os models têm valores default em propriedades não-opcionais

---

## 🚀 Solução Rápida (Desenvolvimento)

**Para voltar a trabalhar AGORA:**

1. **Abra `CatalyzeApp.swift`**
2. **Comente o `try` e force local-only:**

```swift
init() {
    // Força local-only temporariamente para debug
    do {
        self.container = try PersistenceController.makeLocalOnlyContainer()
        Logger.log("Using LOCAL-ONLY container for debugging", level: .warning)
    } catch {
        fatalError("Nem local storage funcionou: \(error)")
    }
}
```

3. **Build and Run**
4. **Teste o app** sem CloudKit
5. **Depois resolva o CloudKit** seguindo as soluções acima

---

## 📋 Checklist de Verificação

Antes de pedir ajuda, verifique:

- [ ] iCloud está ativado no Settings do simulador/device
- [ ] iCloud Drive está ON
- [ ] Capability "iCloud" está adicionada no Xcode
- [ ] CloudKit está marcado nas capabilities
- [ ] Container identifier segue padrão `iCloud.<bundle-id>`
- [ ] Team está selecionado em Signing
- [ ] Bundle ID é único e válido
- [ ] App foi deletado e reinstalado
- [ ] DerivedData foi limpo (`⇧⌘K`)
- [ ] Simulador tem espaço disponível

---

## 🔬 Debug Avançado

**Para ver exatamente onde falha:**

1. **Adicione breakpoint** em `Persistence.swift` linha do `try ModelContainer(...)`
2. **Rode em debug mode**
3. **Quando parar**, no console digite:
   ```
   po error
   ```
4. **Veja o erro completo** com mais detalhes

**Ative logging do Core Data:**

No **Scheme** > **Run** > **Arguments**:

Adicione em **Arguments Passed On Launch**:
```
-com.apple.CoreData.SQLDebug 1
-com.apple.CoreData.CloudKitDebug 1
```

Isso vai mostrar MUITO mais informação no console.

---

## 💡 Entendendo o Erro

`SwiftDataError error 1` geralmente significa:

- **Error 1**: Falha ao inicializar o persistent store
  - CloudKit não está disponível
  - Entitlements incorretos
  - Schema incompatível
  - Permissões de arquivo

É um erro **genérico**, então precisamos investigar o contexto.

---

## 🎯 Recomendação para Produção

Para apps em produção, sempre tenha fallback:

```swift
static func makeContainer() throws -> ModelContainer {
    do {
        // Tenta com CloudKit
        return try makeContainerWithCloudKit()
    } catch {
        Logger.log("CloudKit failed, using local-only", level: .warning)
        // Fallback para local-only
        return try makeLocalOnlyContainer()
    }
}
```

Isso garante que o app **sempre funciona**, mesmo sem CloudKit.

---

## 📞 Ainda Com Problemas?

Se nada funcionou:

1. **Copie o erro COMPLETO** do console
2. **Capture screenshot** das Capabilities no Xcode
3. **Verifique** o Bundle ID atual
4. **Abra uma issue** com essas informações

---

## ✅ Solução Aplicada Agora

O código foi atualizado para:

1. **Tentar CloudKit primeiro**
2. **Se falhar, usar local-only automaticamente**
3. **Se ambos falharem, crash com mensagem detalhada**

Isso significa que o app deve funcionar **sem modificação** agora, mesmo que CloudKit não esteja configurado. Os dados vão persistir localmente.

**Para habilitar CloudKit depois:**
1. Configure os entitlements corretamente
2. O app vai detectar automaticamente e começar a sincronizar

---

**Data**: Maio 2026  
**Versão**: 1.0.1
