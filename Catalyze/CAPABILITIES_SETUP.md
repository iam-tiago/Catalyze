# ⚙️ Configuração de Capabilities e Entitlements

## 📋 Capabilities Necessárias

Para o Catalyze funcionar corretamente, você precisa configurar as seguintes capabilities no Xcode:

---

## 1. iCloud

### Como Adicionar:
1. Selecione o **projeto Catalyze** no navigator
2. Selecione o **target "Catalyze"**
3. Vá em **Signing & Capabilities**
4. Clique **+ Capability**
5. Adicione **iCloud**

### Configurações Necessárias:

#### ✅ Services (marque ambos):
- ☑️ **CloudKit**
- ☑️ **CloudKit (Background)**

#### ✅ Containers:
Adicione o container CloudKit:
```
iCloud.com.prontto.Catalyze
```

**⚠️ IMPORTANTE**: Se você mudou o Bundle ID, o container deve seguir o padrão:
```
iCloud.<SEU-BUNDLE-ID>
```

Exemplo:
- Bundle ID: `com.seutime.Catalyze`
- Container: `iCloud.com.seutime.Catalyze`

---

## 2. Keychain Sharing

### Como Adicionar:
1. Na mesma tela de **Signing & Capabilities**
2. Clique **+ Capability**
3. Adicione **Keychain Sharing**

### Configurações Necessárias:

#### ✅ Keychain Groups:
```
$(AppIdentifierPrefix)com.prontto.Catalyze
```

**⚠️ IMPORTANTE**: Se mudou o Bundle ID, ajuste para:
```
$(AppIdentifierPrefix)<SEU-BUNDLE-ID>
```

---

## 3. Background Modes (Opcional, mas recomendado)

Para CloudKit funcionar em background:

### Como Adicionar:
1. **+ Capability** → **Background Modes**

### Marque:
- ☑️ **Remote notifications**

Isso permite que CloudKit sincronize quando o app está em background.

---

## 📄 Arquivo de Entitlements

O Xcode deve criar automaticamente um arquivo `Catalyze.entitlements` com este conteúdo:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- iCloud CloudKit -->
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.prontto.Catalyze</string>
    </array>
    
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    
    <!-- Key-Value Storage para CloudKit -->
    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)com.prontto.Catalyze</string>
    
    <!-- Keychain Sharing -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.prontto.Catalyze</string>
    </array>
</dict>
</plist>
```

**⚠️ Se você mudou o Bundle ID**, atualize TODOS os lugares:
- `com.prontto.Catalyze` → `<SEU-BUNDLE-ID>`
- Container: `iCloud.com.prontto.Catalyze` → `iCloud.<SEU-BUNDLE-ID>`

---

## 🔧 Atualizando o Bundle ID

Se precisar mudar o Bundle ID:

### 1. No Xcode:
1. **General** → **Bundle Identifier** → mude para seu ID
2. **Signing & Capabilities** → **Team** → selecione seu time

### 2. No Código:
**NÃO** precisa mudar nada! O código usa configuração automática.

### 3. Nos Entitlements:
O Xcode atualiza automaticamente quando você muda nas Capabilities.

---

## 🧪 Testando a Configuração

### Teste 1: Verificar Capabilities
```bash
# No Terminal, no diretório do projeto:
plutil -p Catalyze.entitlements
```

Deve mostrar os entitlements configurados.

### Teste 2: Build sem Erros
1. Clean Build (`⇧⌘K`)
2. Build (`⌘B`)
3. Não deve haver erros de signing ou entitlements

### Teste 3: iCloud no Simulador
1. **Settings** → **Apple ID** → faça login
2. **Settings** → **Apple ID** → **iCloud** → ative **iCloud Drive**
3. Rode o app
4. Adicione um membro
5. No console, veja: `✅ SwiftData container created with CloudKit`

### Teste 4: Sync Entre Dispositivos
1. Use **dois simuladores** ou **dois devices físicos**
2. Ambos logados na **mesma conta iCloud**
3. Ambos com **iCloud Drive ativado**
4. Adicione membro no Device 1
5. Espere ~30 segundos
6. Abra app no Device 2
7. Membro deve aparecer automaticamente

---

## ⚠️ Problemas Comuns

### Erro: "No valid 'aps-environment' entitlement"
**Solução**: Adicione **Background Modes** → **Remote notifications**

### Erro: "CloudKit container not found"
**Solução**: 
1. Verifique container identifier
2. Certifique-se que Team está selecionado
3. O container é criado automaticamente quando você roda o app pela primeira vez

### Erro: "iCloud entitlements don't match"
**Solução**:
1. Delete o app do simulador/device
2. Clean Build Folder (`⇧⌘K`)
3. Build and Run novamente

### App não sincroniza
**Solução**:
1. Verifique se iCloud Drive está ON em Settings
2. Verifique internet connection
3. Espere até 60 segundos para primeira sync
4. Force quit e reabra o app

---

## 🔒 Segurança e Privacy

### API Key (Claude):
- ✅ Armazenada no **Keychain** (criptografado)
- ❌ **NÃO sincroniza** via iCloud (por segurança)
- 📱 Precisa ser configurada em **cada dispositivo**

### Dados do App:
- ✅ **Sincronizam** via CloudKit
- 🔒 Armazenados no **iCloud privado** do usuário
- 🚫 **Ninguém mais** tem acesso (nem você como desenvolvedor)

### Privacy Info.plist:
Não precisa adicionar nada! CloudKit não requer permissões especiais de runtime.

---

## 📱 Configuração por Plataforma

### iPadOS (Principal):
- ✅ Todas as capabilities acima
- ✅ CloudKit sync completo
- ✅ Keychain sharing

### iPhone (Futuro):
Mesmas capabilities, mas adicione:
- Size Classes para layout adaptativo

### macOS via Catalyst (Futuro):
Mesmas capabilities, mas:
- Keychain pode ter grupo diferente
- iCloud container é o mesmo

---

## 🚀 Deploy para App Store

### Antes de Submeter:

1. **Verifique Capabilities**:
   - iCloud configurado ✓
   - Keychain Sharing configurado ✓
   - Background Modes configurado ✓

2. **Teste em Device Físico**:
   - Não apenas simulador
   - Com conta iCloud real
   - Teste sync entre dois devices

3. **Privacy Manifest** (iOS 17+):
   - App não coleta dados (todos ficam no iCloud do usuário)
   - No privacy label do App Store: "Data Not Collected"

4. **CloudKit Dashboard**:
   - Acesse [iCloud Dashboard](https://icloud.developer.apple.com)
   - Verifique que seu container existe
   - Production environment deve estar ativo

---

## 📊 CloudKit Dashboard

### Acessando:
1. Vá em https://icloud.developer.apple.com/dashboard
2. Faça login com Apple Developer account
3. Selecione `iCloud.com.prontto.Catalyze` (ou seu container)

### O Que Verificar:
- ✅ Container existe
- ✅ Schema está correto (automático via SwiftData)
- ✅ Environment: Development E Production
- ℹ️ Você NÃO precisa criar schema manualmente (SwiftData faz isso)

### Debugging:
- **Telemetry**: Veja estatísticas de sync
- **Logs**: Veja erros de sync (se houver)
- **Data**: Veja registros (apenas em Development!)

---

## 🎯 Checklist Final

Antes de considerar configuração completa:

- [ ] iCloud capability adicionada
- [ ] CloudKit marcado nas capabilities
- [ ] Container identifier correto
- [ ] Keychain Sharing adicionado
- [ ] Background Modes (remote notifications) adicionado
- [ ] Team selecionado em Signing
- [ ] Bundle ID único e correto
- [ ] Build compila sem erros
- [ ] Testado em simulador com iCloud
- [ ] Testado sync entre dois devices
- [ ] App persiste dados após relaunch
- [ ] CloudKit Dashboard mostra container

---

## 📞 Recursos Adicionais

- [CloudKit Quick Start](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [App Store Review Guidelines - Data Storage](https://developer.apple.com/app-store/review/guidelines/#data-storage-and-sharing)

---

**Configuração Verificada**: Maio 2026  
**Compatible com**: iOS 17.0+, iPadOS 17.0+
