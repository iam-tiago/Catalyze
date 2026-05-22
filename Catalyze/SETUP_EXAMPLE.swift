//
//  SETUP_EXAMPLE.swift
//  Catalyze
//
//  ⚠️ Este é um arquivo de exemplo/referência, NÃO substitua seu código atual!
//
//  Este arquivo mostra como integrar o novo sistema de senioridade customizável
//  no seu app. Use como referência para fazer as mudanças necessárias.
//

import SwiftUI
import SwiftData

// MARK: - Exemplo 1: Setup no App Principal

/*
@main
struct CatalyzeApp: App {
    private let container: ModelContainer
    @State private var store = AppStore()
    
    // ✅ ADICIONAR: Criar SeniorityService
    @State private var seniorityService: SeniorityService?
    
    init() {
        do {
            self.container = try PersistenceController.makeContainer()
            Logger.log("ModelContainer initialized successfully", level: .success)
        } catch {
            Logger.error(error, context: "Failed to initialize persistent store")
            fatalError("Failed to initialize storage")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppLayout()
                .environment(store)
                // ✅ ADICIONAR: Injetar SeniorityService
                .seniorityService(seniorityService ?? SeniorityService(modelContext: container.mainContext))
                .onAppear {
                    // Inicializar SeniorityService na primeira vez
                    if seniorityService == nil {
                        seniorityService = SeniorityService(modelContext: container.mainContext)
                        seniorityService?.ensureDefaultConfig()
                    }
                }
        }
        .modelContainer(container)
    }
}
*/

// MARK: - Exemplo 2: Atualizar ModelContainer com novos modelos

/*
// Em PersistenceController.swift:

static func makeContainer() throws -> ModelContainer {
    let schema = Schema([
        TeamMember.self,
        StrengthWeakness.self,
        StackEntry.self,
        TeamObservation.self,
        DevelopmentPlan.self,
        DevelopmentAction.self,
        PromotionReadiness.self,
        PromotionCriterion.self,
        ProfileEvent.self,
        
        // ✅ ADICIONAR: Novos modelos de senioridade
        OrganizationConfig.self,
        SeniorityLevel.self
    ])
    
    let config = ModelConfiguration(
        schema: schema,
        cloudKitDatabase: .private("iCloud.com.yourcompany.catalyze")
    )
    
    return try ModelContainer(for: schema, configurations: [config])
}
*/

// MARK: - Exemplo 3: Usar em Views

struct ExampleMemberFormView: View {
    @Environment(\.seniorityService) private var seniorityService
    @State private var selectedLevelCode: String = ""
    
    var body: some View {
        Form {
            // Picker com níveis customizados
            Picker("Seniority Level", selection: $selectedLevelCode) {
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
            
            // Preview do badge
            if let level = seniorityService?.level(byCode: selectedLevelCode) {
                TierBadge(level: level)
            }
        }
    }
}

// MARK: - Exemplo 4: Migração em Views Existentes

struct ExampleTeamView: View {
    @Environment(\.seniorityService) private var seniorityService
    @Query private var members: [TeamMember]
    
    var body: some View {
        List(members) { member in
            HStack {
                Text(member.name)
                Spacer()
                
                // ANTES:
                // TierBadge(tier: member.seniority.rawValue)
                
                // DEPOIS (com cores customizadas):
                if let level = seniorityService?.level(byCode: member.seniority.rawValue) {
                    TierBadge(level: level)
                } else {
                    // Fallback para compatibilidade
                    TierBadge(tier: member.seniority.rawValue)
                }
            }
        }
    }
}

// MARK: - Exemplo 5: Promotion Planning

struct ExamplePromotionView: View {
    @Environment(\.seniorityService) private var seniorityService
    let member: TeamMember
    
    @State private var targetLevel: String = ""
    
    var availablePromotionTargets: [SeniorityLevel] {
        seniorityService?.higherLevels(than: member.seniority.rawValue) ?? []
    }
    
    var nextSuggestedLevel: SeniorityLevel? {
        seniorityService?.nextLevel(after: member.seniority.rawValue)
    }
    
    var body: some View {
        Form {
            Section("Current Level") {
                if let current = seniorityService?.level(byCode: member.seniority.rawValue) {
                    HStack {
                        TierBadge(level: current)
                        Text(current.displayName)
                            .foregroundStyle(CColor.neutral700)
                    }
                }
            }
            
            Section("Suggested Next Level") {
                if let next = nextSuggestedLevel {
                    HStack {
                        TierBadge(level: next)
                        VStack(alignment: .leading) {
                            Text(next.displayName)
                                .font(CFont.headline)
                            if let levelDescription = next.levelDescription {
                                Text(levelDescription)
                                    .font(CFont.caption1)
                                    .foregroundStyle(CColor.neutral600)
                            }
                        }
                    }
                }
            }
            
            Section("All Available Targets") {
                Picker("Target Level", selection: $targetLevel) {
                    ForEach(availablePromotionTargets, id: \.code) { level in
                        HStack {
                            Text(level.displayName)
                            Spacer()
                            TierBadge(level: level)
                        }
                        .tag(level.code)
                    }
                }
            }
        }
    }
}

// MARK: - Exemplo 6: Settings Integration

struct ExampleSettingsView: View {
    @Environment(\.seniorityService) private var seniorityService
    
    var body: some View {
        Form {
            Section {
                // Outras configurações...
            }
            
            // ✅ ADICIONAR: Link para configuração de senioridade
            Section("Organization") {
                NavigationLink {
                    SeniorityConfigView()
                } label: {
                    HStack {
                        Label("Seniority Levels", systemImage: "chart.bar.fill")
                        Spacer()
                        Text(seniorityService?.currentPreset.displayName ?? "")
                            .foregroundStyle(CColor.neutral600)
                            .font(CFont.caption1)
                    }
                }
            }
        }
    }
}

// MARK: - Exemplo 7: Dashboard com Métricas por Nível

struct ExampleDashboardView: View {
    @Environment(\.seniorityService) private var seniorityService
    @Query private var members: [TeamMember]
    
    var membersByLevel: [(level: SeniorityLevel, count: Int)] {
        let levels = seniorityService?.levels ?? []
        let grouped = Dictionary(grouping: members, by: \.seniority.rawValue)
        
        return levels.compactMap { level in
            let count = grouped[level.code]?.count ?? 0
            return (level: level, count: count)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: CSpace.lg) {
            Text("Team Distribution")
                .font(CFont.title2)
            
            ForEach(membersByLevel, id: \.level.id) { item in
                HStack {
                    TierBadge(level: item.level)
                    
                    Text(item.level.displayName)
                        .font(CFont.body)
                    
                    Spacer()
                    
                    Text("\(item.count)")
                        .font(CFont.headline)
                        .foregroundStyle(item.level.color)
                }
                .padding()
                .background(item.level.color.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: CRadius.sm))
            }
        }
        .padding()
    }
}

// MARK: - Exemplo 8: Preview Helper

#Preview("With Seniority Service") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: TeamMember.self, OrganizationConfig.self, SeniorityLevel.self,
        configurations: config
    )
    
    let context = container.mainContext
    let seniorityService = SeniorityService(modelContext: context)
    
    return ExampleMemberFormView()
        .seniorityService(seniorityService)
        .modelContainer(container)
}

// MARK: - Exemplo 9: Migration Script (se necessário)

/*
/// Execute esta função UMA VEZ após atualizar o app para migrar dados existentes
@MainActor
func migrateExistingMembersToNewSystem(context: ModelContext, seniorityService: SeniorityService) {
    let descriptor = FetchDescriptor<TeamMember>()
    
    do {
        let members = try context.fetch(descriptor)
        
        for member in members {
            // Verificar se o código atual existe no novo sistema
            if seniorityService.level(byCode: member.seniority.rawValue) == nil {
                Logger.log("⚠️ Member \(member.name) has unmapped level: \(member.seniority.rawValue)", level: .warning)
                
                // Opção 1: Mapear para um nível padrão
                // member.seniorityRaw = "T2-1"
                
                // Opção 2: Criar um nível customizado
                // let customLevel = SeniorityLevel(...)
                // context.insert(customLevel)
            }
        }
        
        try context.save()
        Logger.log("✅ Migration completed successfully", level: .success)
    } catch {
        Logger.error(error, context: "Migration failed")
    }
}
*/
