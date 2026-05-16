#!/bin/bash
# Script para resetar completamente o app após correção do schema CloudKit

echo "🔧 Reset Completo do Catalyze - CloudKit Schema Fix"
echo "=================================================="
echo ""

# 1. Deletar app do simulador em execução
echo "📱 Passo 1: Deletando app do simulador..."
xcrun simctl uninstall booted com.prontto.Catalyze 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ App deletado com sucesso"
else
    echo "   ⚠️  App não encontrado no simulador (OK se ainda não instalado)"
fi
echo ""

# 2. Deletar DerivedData
echo "🗑️  Passo 2: Limpando DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Catalyze-*
echo "   ✅ DerivedData limpo"
echo ""

# 3. Opcional: Reset completo do simulador (CUIDADO: apaga TUDO!)
read -p "⚠️  Resetar simulador completamente? (apaga TODOS os dados) [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🔄 Resetando simuladores..."
    xcrun simctl erase all
    echo "   ✅ Simuladores resetados"
else
    echo "   ⏭️  Pulando reset de simulador"
fi
echo ""

# 4. Instruções finais
echo "✅ Limpeza completa!"
echo ""
echo "📝 Próximos passos:"
echo "   1. Abra o projeto no Xcode"
echo "   2. Clean Build Folder (⇧⌘K)"
echo "   3. Build and Run (⌘R)"
echo ""
echo "🔍 Verifique no console:"
echo "   ✅ 'ModelContainer initialized successfully'"
echo "   ✅ 'SwiftData container created with CloudKit' (se CloudKit configurado)"
echo "   OU"
echo "   ⚠️  'using local-only storage' (OK se CloudKit não configurado)"
echo ""
echo "📚 Documentação:"
echo "   - FINAL_FIX_SUMMARY.md - Resumo completo da correção"
echo "   - CLOUDKIT_SCHEMA_FIX.md - Detalhes técnicos"
echo "   - QUICK_CLOUDKIT_SETUP.md - Como configurar CloudKit"
echo ""
echo "🎉 Pronto para começar!"
