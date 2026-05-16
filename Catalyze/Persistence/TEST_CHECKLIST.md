# ✅ Checklist de Testes - Catalyze

Use este checklist para verificar se todas as melhorias estão funcionando corretamente.

---

## 🏗️ Build e Compilação

- [ ] O projeto compila sem erros (`⌘B`)
- [ ] O projeto compila sem warnings críticos
- [ ] Build limpo funciona (`⇧⌘K` → `⌘B`)
- [ ] Preview funciona no Xcode Canvas

---

## 📱 Funcionalidade Básica

### Adicionar Membro
- [ ] Adicionar membro com dados válidos → Sucesso
- [ ] Nome vazio → Mostra erro "Name cannot be empty"
- [ ] Nome com 1 caractere → Mostra erro "Name must be at least 2 characters"
- [ ] Role vazio → Mostra erro "Role cannot be empty"
- [ ] Role com 1 caractere → Mostra erro "Role must be at least 2 characters"
- [ ] Nome ou role com mais de 100 caracteres → Mostra erro
- [ ] Membro aparece na grid após adicionar
- [ ] Seniority picker funciona corretamente

### Editar Membro
- [ ] Editar nome de membro existente → Salva corretamente
- [ ] Editar role → Salva corretamente
- [ ] Alterar seniority → Salva corretamente
- [ ] `updatedAt` é atualizado automaticamente

### Deletar Membro
- [ ] Deletar membro → Remove da lista
- [ ] Observações do membro são deletadas (cascade)
- [ ] IDPs do membro são deletados (cascade)
- [ ] Tags do membro são deletadas (cascade)

---

## 🖼️ Fotos

### PhotosPicker
- [ ] Selecionar foto da biblioteca → Preview aparece
- [ ] Foto selecionada salva com o membro
- [ ] PhotoData é priorizado sobre photoUrl

### URL de Foto
- [ ] URL válida (https://example.com/photo.jpg) → Aceita
- [ ] URL inválida (não-é-url) → Mostra erro
- [ ] URL sem http/https → Mostra erro
- [ ] AsyncImage carrega foto da URL
- [ ] Limpar URL quando foto é selecionada

---

## 🔄 Persistência

### Local Storage
- [ ] Adicionar membro → Fechar app → Reabrir → Membro ainda existe
- [ ] Editar membro → Fechar app → Reabrir → Edição persistiu
- [ ] Deletar membro → Fechar app → Reabrir → Membro sumiu

### CloudKit Sync (Requer 2 dispositivos ou simuladores)
- [ ] Configurar iCloud no simulador/device
- [ ] Adicionar membro no Device 1
- [ ] Esperar ~30 segundos
- [ ] Abrir app no Device 2
- [ ] Membro aparece no Device 2
- [ ] Editar no Device 2 → Sincroniza para Device 1
- [ ] Deletar no Device 1 → Remove do Device 2

---

## 🔍 Validação

### Nome
- [ ] "" (vazio) → Erro
- [ ] "A" (1 char) → Erro
- [ ] "AB" (2 chars) → Válido
- [ ] Nome com 100 caracteres → Válido
- [ ] Nome com 101 caracteres → Erro
- [ ] Espaços no início/fim são removidos

### Role
- [ ] "" (vazio) → Erro
- [ ] "A" (1 char) → Erro
- [ ] "AB" (2 chars) → Válido
- [ ] Role com 100 caracteres → Válido
- [ ] Role com 101 caracteres → Erro
- [ ] Espaços no início/fim são removidos

### Photo URL
- [ ] "" (vazio) → Válido (opcional)
- [ ] "https://example.com/photo.jpg" → Válido
- [ ] "http://example.com/photo.jpg" → Válido
- [ ] "ftp://example.com/photo.jpg" → Erro
- [ ] "não-é-url" → Erro
- [ ] "example.com" (sem protocolo) → Erro

---

## 🎨 UI/UX

### Team View
- [ ] Grid adapta ao tamanho da tela
- [ ] Hover effect funciona nos cards (iPad com mouse/trackpad)
- [ ] Empty state aparece quando não há membros
- [ ] Empty state desaparece quando primeiro membro é adicionado
- [ ] TeamOverview só aparece quando há membros
- [ ] Botão "+" abre MemberForm

### Member Card
- [ ] Avatar placeholder aparece quando não há foto
- [ ] Avatar da URL carrega corretamente
- [ ] Avatar do PhotoData aparece
- [ ] Nome e role aparecem truncados se muito longos
- [ ] Seniority chip mostra nível correto
- [ ] Top 2 strengths aparecem (se existirem)
- [ ] Intensidade das strengths mostrada com dots (1-3)

### Member Form
- [ ] Navigation title: "New Member" ao criar
- [ ] Navigation title: "Edit Member" ao editar
- [ ] Botão "Cancel" fecha o form
- [ ] Botão "Add"/"Save" desabilitado quando inválido
- [ ] Picker de mentor lista todos membros exceto o atual
- [ ] Mentor interno e externo são mutuamente exclusivos
- [ ] Form fecha após salvar com sucesso

---

## 📊 Logs (Console)

### Em DEBUG Mode
- [ ] Logs aparecem no console
- [ ] Formato: `[emoji] [arquivo:linha] mensagem`
- [ ] Níveis corretos: info (ℹ️), success (✅), error (❌), warning (⚠️), debug (🔍)
- [ ] Ao adicionar membro: "Attempting to add member" → "Member saved successfully"
- [ ] Ao editar membro: "Updating member" → "Member updated successfully"
- [ ] Ao falhar: "Error (contexto): descrição"

### Em Release Mode (Build for Release)
- [ ] Nenhum log aparece no console
- [ ] Performance não é impactada por logs

---

## 🔔 Alertas de Erro

- [ ] Erro de validação mostra alert com mensagem clara
- [ ] Alert tem botão "OK" para dispensar
- [ ] Erro de persistência mostra alert (se propagado)
- [ ] Alert desaparece ao tocar "OK"
- [ ] Form não fecha quando há erro

---

## 🧩 Mentoria

### Mentor Interno
- [ ] Selecionar mentor da lista → Salva relação
- [ ] Mentor aparece no member detail
- [ ] Deletar mentor → Relação vira nil (nullify, não cascade)
- [ ] Não pode selecionar a si mesmo como mentor

### Mentor Externo
- [ ] Digitar nome de mentor externo → Salva
- [ ] Nome vazio → Salva como nil
- [ ] Nome aparece no member detail

---

## 🎯 Seniority

- [ ] Todos os níveis aparecem no picker: T1-3, T2-1, T2-2, T2-3, T3-1, T3-2, T3-3, T4
- [ ] Seniority padrão é T2-1
- [ ] Seniority selecionado salva corretamente
- [ ] Label exibido corretamente no card

---

## 🔒 Keychain

- [ ] API key salva no Keychain (Settings)
- [ ] API key persiste entre launches
- [ ] API key NÃO sincroniza via iCloud (segurança)
- [ ] API key pode ser editada

---

## 💾 UserDefaults

- [ ] Base URL salva corretamente
- [ ] EM Profile salva como JSON
- [ ] Dados persistem entre launches
- [ ] Team name aparece no título (se configurado)

---

## 🚀 Performance

- [ ] App inicia em menos de 2 segundos (simulador)
- [ ] Grid com 50 membros renderiza suavemente
- [ ] Scroll é fluido sem travamentos
- [ ] Adicionar membro é instantâneo
- [ ] CloudKit sync não trava UI

---

## ♿ Acessibilidade (Básico)

- [ ] VoiceOver lê nomes dos membros
- [ ] VoiceOver lê botões ("Add Member", "Cancel", "Save")
- [ ] Dynamic Type aumenta texto (Settings > Display & Brightness > Text Size)
- [ ] Contraste suficiente em light/dark mode

---

## 🌓 Dark Mode

- [ ] App funciona em light mode
- [ ] App funciona em dark mode
- [ ] Transição suave entre modes
- [ ] Cards legíveis em ambos os modes
- [ ] Chips de seniority/strengths legíveis

---

## 📐 Layout Responsivo

### Portrait (Vertical)
- [ ] Grid mostra 1-2 colunas dependendo do tamanho
- [ ] Sidebar visível
- [ ] Conteúdo não corta

### Landscape (Horizontal)
- [ ] Grid mostra 2-3+ colunas
- [ ] Sidebar e detail lado a lado
- [ ] Aproveita espaço disponível

### Split View (Slide Over)
- [ ] Grid adapta para menos colunas
- [ ] Conteúdo permanece legível
- [ ] Scroll funciona corretamente

---

## 🔧 Edge Cases

- [ ] Criar membro só com espaços no nome → Erro
- [ ] Criar membro com emoji no nome → Funciona
- [ ] Criar 100 membros → Sem crash
- [ ] Deletar membro selecionado → `selectedMemberId` vira nil
- [ ] Abrir form → Rotacionar dispositivo → Form adapta
- [ ] Perder conexão durante sync → CloudKit retoma depois

---

## 📝 Notas

### Problemas Encontrados:
_Escreva aqui quaisquer bugs ou problemas que encontrar_

---

### Melhorias Sugeridas:
_Escreva aqui ideias de melhorias que surgirem durante os testes_

---

## ✅ Aprovação Final

- [ ] Todos os testes críticos passaram
- [ ] Nenhum crash durante uso normal
- [ ] Performance aceitável
- [ ] UI/UX fluida e responsiva
- [ ] Pronto para uso em produção (ou próxima fase)

---

**Data do teste**: _______________  
**Testador**: _______________  
**Dispositivo**: _______________  
**iOS Version**: _______________

---

## 🆘 Em Caso de Problemas

### Se o build falhar:
1. Clean build folder (`⇧⌘K`)
2. Fechar e reabrir Xcode
3. Deletar DerivedData (`~/Library/Developer/Xcode/DerivedData`)
4. Verificar se todos os arquivos estão no target

### Se CloudKit não sincronizar:
1. Verificar que iCloud está ativado nas Settings do simulador/device
2. Verificar entitlements (`iCloud.com.prontto.Catalyze`)
3. Esperar até 60 segundos para primeira sync
4. Checar console para erros de CloudKit
5. Considerar usar `makeLocalOnlyContainer()` temporariamente

### Se persistência não funcionar:
1. Verificar que `cloudKitDatabase: .automatic` está correto
2. Tentar com `makeLocalOnlyContainer()` para isolar problema
3. Deletar app do simulador e reinstalar
4. Checar logs de erro no console

### Se validação não funcionar:
1. Verificar que `ErrorHandling.swift` está no target
2. Conferir imports no `MemberForm.swift`
3. Adicionar breakpoints nos validadores
4. Verificar que alertas estão configurados corretamente

---

**Boa sorte com os testes! 🚀**
