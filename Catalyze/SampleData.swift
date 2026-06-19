//
//  SampleData.swift
//  Catalyze
//
//  Centralized sample data for Xcode Previews and demo mode.
//  10 members across iOS, Android, Frontend, Backend, and Full Stack,
//  each exercising all app features: strengths, weaknesses, tech stack,
//  observations, IDPs with actions, promotion readiness, and profile events.
//

import Foundation
import SwiftData

enum SampleDataProvider {

    // MARK: - Container factory -----------------------------------------------

    /// In-memory container pre-populated with 10 demo members.
    static func makePreviewContainer() -> ModelContainer {
        let container = try! PersistenceController.makePreviewContainer()
        let context = ModelContext(container)
        populate(in: context)
        return container
    }

    // MARK: - Populate ---------------------------------------------------------

    /// Inserts 10 demo members into `context` and saves.
    @discardableResult
    static func populate(in context: ModelContext) -> [TeamMember] {
        let now = Date()

        func ago(days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        }
        func future(months: Int) -> Date {
            Calendar.current.date(byAdding: .month, value: months, to: now) ?? now
        }

        // ── Helpers ────────────────────────────────────────────────────────

        func addStack(_ tags: [(StackTag, StackProficiency)], to member: TeamMember) {
            for (tag, level) in tags {
                let entry = StackEntry(tag: tag, level: level)
                entry.member = member
                context.insert(entry)
            }
        }

        func sw(_ kind: SWKind, _ category: String, _ intensity: Intensity, _ note: String? = nil) -> StrengthWeakness {
            StrengthWeakness(kind: kind, category: category, intensity: intensity, note: note)
        }

        func obs(_ memberId: String, _ text: String, _ ctx: ObservationContext, _ daysAgo: Int) -> TeamObservation {
            TeamObservation(memberId: memberId, text: text, context: ctx, createdAt: ago(days: daysAgo))
        }

        func event(_ memberId: String, _ type: ProfileEventType, _ category: String,
                   before: Intensity? = nil, after: Intensity? = nil, _ daysAgo: Int) -> ProfileEvent {
            ProfileEvent(memberId: memberId, type: type, category: category,
                         intensityBefore: before, intensityAfter: after, createdAt: ago(days: daysAgo))
        }

        // ── 1. Lucas Tavares — Senior iOS Engineer (T3-1) ─────────────────
        let lucas = TeamMember(name: "Lucas Tavares", role: "Senior iOS Engineer",
                               seniority: .t3_1, createdAt: ago(days: 180), updatedAt: ago(days: 5))
        context.insert(lucas)

        addStack([(.swiftUI, .expert), (.aiAssistedDev, .proficient), (.dynatrace, .learning)], to: lucas)

        let lucasS1 = sw(.strength, "Architecture", .strong, "Designs clean module boundaries; consistently reduces coupling across features")
        let lucasS2 = sw(.strength, "Code Quality", .solid)
        let lucasS3 = sw(.strength, "Leadership", .emerging)
        let lucasW1 = sw(.weakness, "Mentoring", .emerging, "Struggles to create structured learning paths for junior engineers")
        [lucasS1, lucasS2, lucasS3, lucasW1].forEach { $0.member = lucas; context.insert($0) }
        lucas.tags = [lucasS1, lucasS2, lucasS3, lucasW1]

        let lucasObs1 = obs(lucas.id, "Delivered the SwiftUI navigation refactor ahead of schedule. The new Coordinator pattern is clean and well-documented.", .sprintReview, 14)
        let lucasObs2 = obs(lucas.id, "Mentioned feeling unsure about how to structure mentoring conversations with Aline. Doesn't have a framework yet.", .oneOnOne, 7)
        let lucasObs3 = obs(lucas.id, "Strong quarter: 3 major features shipped, led the architecture review, and received positive peer feedback on code quality.", .performanceCycle, 30)
        [lucasObs1, lucasObs2, lucasObs3].forEach { $0.member = lucas; context.insert($0) }
        lucas.observations = [lucasObs1, lucasObs2, lucasObs3]

        let lucasIDP = DevelopmentPlan(memberId: lucas.id,
                                       title: "Mobile Architecture Evolution",
                                       objective: "Lead the migration from MVC to MVVM+Coordinator across the iOS codebase, becoming the architectural reference for the team.",
                                       targetDate: future(months: 3), status: .active, createdAt: ago(days: 60))
        lucasIDP.member = lucas
        context.insert(lucasIDP)
        let la1 = IDPAction(text: "Document current MVC anti-patterns and their pain points", done: true, sortIndex: 0)
        let la2 = IDPAction(text: "Prototype MVVM+Coordinator on the Profile module", done: true, sortIndex: 1)
        let la3 = IDPAction(text: "Present architecture proposal to the team and collect feedback", done: false, sortIndex: 2)
        let la4 = IDPAction(text: "Migrate 2 additional modules and document the pattern", done: false, sortIndex: 3)
        [la1, la2, la3, la4].forEach { $0.plan = lucasIDP; context.insert($0) }
        lucasIDP.actions = [la1, la2, la3, la4]
        lucas.idps = [lucasIDP]

        let lucasPromo = PromotionReadiness(memberId: lucas.id, targetTier: .t3_2, status: .inProgress,
                                            notes: "Architecture work is strong. Needs to show broader team influence and a mentoring track record.", createdAt: ago(days: 45))
        lucasPromo.member = lucas
        context.insert(lucasPromo)
        let lc1 = PromotionCriterion(category: "Technical", label: "Owns cross-module architecture decisions with measurable quality impact", met: true, sortIndex: 0)
        let lc2 = PromotionCriterion(category: "Technical", label: "Contributes to platform-wide standards beyond the squad", met: true, sortIndex: 1)
        let lc3 = PromotionCriterion(category: "Leadership", label: "Mentors at least 1 engineer with a structured, goal-oriented plan", met: false, sortIndex: 2)
        let lc4 = PromotionCriterion(category: "Leadership", label: "Leads a team-level initiative end-to-end", met: false, note: "Architecture migration counts if delivered", sortIndex: 3)
        [lc1, lc2, lc3, lc4].forEach { $0.record = lucasPromo; context.insert($0) }
        lucasPromo.criteria = [lc1, lc2, lc3, lc4]
        lucas.promotionRecords = [lucasPromo]

        let lev1 = event(lucas.id, .strengthAdded, "Architecture", after: .emerging, 120)
        let lev2 = event(lucas.id, .strengthUpdated, "Architecture", before: .emerging, after: .strong, 30)
        [lev1, lev2].forEach { $0.member = lucas; context.insert($0) }
        lucas.profileEvents = [lev1, lev2]

        // ── 2. Aline Costa — iOS Engineer (T2-3) ──────────────────────────
        let aline = TeamMember(name: "Aline Costa", role: "iOS Engineer",
                               seniority: .t2_3, createdAt: ago(days: 270), updatedAt: ago(days: 10))
        context.insert(aline)
        aline.mentor = lucas

        addStack([(.swiftUI, .advanced), (.typescript, .learning), (.aiAssistedDev, .learning)], to: aline)

        let alineS1 = sw(.strength, "Code Quality", .solid)
        let alineS2 = sw(.strength, "Testing", .emerging)
        let alineS3 = sw(.strength, "Growth Mindset", .solid, "Proactively seeks feedback and acts on it quickly")
        let alineW1 = sw(.weakness, "Architecture", .developing, "Struggles to reason about module boundaries at scale")
        [alineS1, alineS2, alineS3, alineW1].forEach { $0.member = aline; context.insert($0) }
        aline.tags = [alineS1, alineS2, alineS3, alineW1]

        let alineObs1 = obs(aline.id, "Asked great questions during Lucas's architecture session. Shows genuine curiosity about system design patterns.", .sprintReview, 10)
        let alineObs2 = obs(aline.id, "Completed the iOS Architecture book chapter on coordinators. Starting to apply patterns on small components.", .oneOnOne, 4)
        [alineObs1, alineObs2].forEach { $0.member = aline; context.insert($0) }
        aline.observations = [alineObs1, alineObs2]

        let alineIDP = DevelopmentPlan(memberId: aline.id,
                                       title: "Architecture & System Design",
                                       objective: "Build enough architectural knowledge to independently design a new feature module with minimal guidance from Lucas.",
                                       targetDate: future(months: 4), status: .active, createdAt: ago(days: 45))
        alineIDP.member = aline
        context.insert(alineIDP)
        let aa1 = IDPAction(text: "Read 'iOS App Architecture' and summarize key patterns (coordinator, MVVM)", done: true, sortIndex: 0)
        let aa2 = IDPAction(text: "Pair with Lucas on 2 architecture design sessions", done: true, sortIndex: 1)
        let aa3 = IDPAction(text: "Design the Notifications module independently — draft + team review", done: false, sortIndex: 2)
        [aa1, aa2, aa3].forEach { $0.plan = alineIDP; context.insert($0) }
        alineIDP.actions = [aa1, aa2, aa3]
        aline.idps = [alineIDP]

        let aev1 = event(aline.id, .strengthAdded, "Growth Mindset", after: .emerging, 60)
        let aev2 = event(aline.id, .strengthUpdated, "Growth Mindset", before: .emerging, after: .solid, 15)
        [aev1, aev2].forEach { $0.member = aline; context.insert($0) }
        aline.profileEvents = [aev1, aev2]

        // ── 3. Rafael Mendes — Senior Android Engineer (T3-1) ─────────────
        let rafael = TeamMember(name: "Rafael Mendes", role: "Senior Android Engineer",
                                seniority: .t3_1, createdAt: ago(days: 365), updatedAt: ago(days: 3))
        context.insert(rafael)

        addStack([(.kotlin, .expert), (.java, .advanced), (.docker, .proficient), (.aiAssistedDev, .proficient)], to: rafael)

        let rafaelS1 = sw(.strength, "Code Review", .strong, "Reviews are thorough and educational — engineers proactively request his review")
        let rafaelS2 = sw(.strength, "Problem Solving", .solid)
        let rafaelS3 = sw(.strength, "Ownership", .emerging)
        let rafaelW1 = sw(.weakness, "Communication", .developing, "Can be terse in async threads; stakeholders sometimes misread the tone as dismissive")
        [rafaelS1, rafaelS2, rafaelS3, rafaelW1].forEach { $0.member = rafael; context.insert($0) }
        rafael.tags = [rafaelS1, rafaelS2, rafaelS3, rafaelW1]

        let rafaelObs1 = obs(rafael.id, "Caught a critical race condition in the payment flow during code review. Saved us from a likely P1 incident in production.", .incident, 21)
        let rafaelObs2 = obs(rafael.id, "Had a candid conversation about async communication patterns. He's aware of the feedback but needs practical strategies to change the habit.", .oneOnOne, 7)
        [rafaelObs1, rafaelObs2].forEach { $0.member = rafael; context.insert($0) }
        rafael.observations = [rafaelObs1, rafaelObs2]

        let rafaelIDP = DevelopmentPlan(memberId: rafael.id,
                                        title: "Written Communication",
                                        objective: "Improve async communication quality so intent and context are always clear without requiring follow-up questions.",
                                        targetDate: future(months: 2), status: .onHold, createdAt: ago(days: 30))
        rafaelIDP.member = rafael
        context.insert(rafaelIDP)
        let ra1 = IDPAction(text: "Document personal async communication principles (3 core rules)", done: true, sortIndex: 0)
        let ra2 = IDPAction(text: "Request feedback from 3 stakeholders on recent Slack interactions", done: false, sortIndex: 1)
        [ra1, ra2].forEach { $0.plan = rafaelIDP; context.insert($0) }
        rafaelIDP.actions = [ra1, ra2]
        rafael.idps = [rafaelIDP]

        let rev1 = event(rafael.id, .strengthAdded, "Code Review", after: .solid, 90)
        let rev2 = event(rafael.id, .strengthUpdated, "Code Review", before: .solid, after: .strong, 20)
        [rev1, rev2].forEach { $0.member = rafael; context.insert($0) }
        rafael.profileEvents = [rev1, rev2]

        // ── 4. Fernanda Lima — Android Engineer (T2-2) ────────────────────
        let fernanda = TeamMember(name: "Fernanda Lima", role: "Android Engineer",
                                  seniority: .t2_2, createdAt: ago(days: 200), updatedAt: ago(days: 8))
        context.insert(fernanda)

        addStack([(.kotlin, .advanced), (.aws, .learning), (.kubernetes, .learning)], to: fernanda)

        let fernandaS1 = sw(.strength, "Collaboration", .solid, "Go-to person for cross-team alignment — builds trust quickly with Android/Backend interfaces")
        let fernandaS2 = sw(.strength, "Ownership", .emerging)
        let fernandaW1 = sw(.weakness, "Architecture", .developing, "Scopes designs locally and misses system-wide implications")
        let fernandaW2 = sw(.weakness, "Debugging Logic", .emerging)
        [fernandaS1, fernandaS2, fernandaW1, fernandaW2].forEach { $0.member = fernanda; context.insert($0) }
        fernanda.tags = [fernandaS1, fernandaS2, fernandaW1, fernandaW2]

        let fernandaObs1 = obs(fernanda.id, "Coordinated the Android/Backend API contract sync without any dropped tasks — all stakeholders were informed throughout.", .sprintReview, 12)
        let fernandaObs2 = obs(fernanda.id, "Debugging the ANR issue took her much longer than expected. Root cause was obvious in hindsight — she needs a more systematic debugging approach.", .oneOnOne, 5)
        [fernandaObs1, fernandaObs2].forEach { $0.member = fernanda; context.insert($0) }
        fernanda.observations = [fernandaObs1, fernandaObs2]

        let fernandaPromo = PromotionReadiness(memberId: fernanda.id, targetTier: .t2_3, status: .notReady,
                                               notes: "Architecture gap is the main blocker. Collaboration and ownership are strong signals for future growth.", createdAt: ago(days: 30))
        fernandaPromo.member = fernanda
        context.insert(fernandaPromo)
        let fc1 = PromotionCriterion(category: "Technical", label: "Can independently design and implement a feature module end-to-end", met: false, note: "Needs one full cycle with minimal guidance", sortIndex: 0)
        let fc2 = PromotionCriterion(category: "Technical", label: "Understands system-level trade-offs when making architecture decisions", met: false, sortIndex: 1)
        let fc3 = PromotionCriterion(category: "Collaboration", label: "Consistently demonstrates ownership beyond own task scope", met: true, sortIndex: 2)
        [fc1, fc2, fc3].forEach { $0.record = fernandaPromo; context.insert($0) }
        fernandaPromo.criteria = [fc1, fc2, fc3]
        fernanda.promotionRecords = [fernandaPromo]

        let fev1 = event(fernanda.id, .strengthAdded, "Collaboration", after: .emerging, 80)
        let fev2 = event(fernanda.id, .strengthUpdated, "Collaboration", before: .emerging, after: .solid, 10)
        [fev1, fev2].forEach { $0.member = fernanda; context.insert($0) }
        fernanda.profileEvents = [fev1, fev2]

        // ── 5. Diego Santos — Frontend Engineer (T2-1) ────────────────────
        let diego = TeamMember(name: "Diego Santos", role: "Frontend Engineer",
                               seniority: .t2_1, createdAt: ago(days: 150), updatedAt: ago(days: 6))
        context.insert(diego)

        addStack([(.react, .advanced), (.typescript, .proficient), (.reduxRTK, .proficient)], to: diego)

        let diegoS1 = sw(.strength, "Collaboration", .strong, "Energizes the team and actively unblocks others even when it's outside his scope")
        let diegoS2 = sw(.strength, "Growth Mindset", .solid)
        let diegoW1 = sw(.weakness, "Testing", .developing, "Rarely writes tests; relies on QA to catch regressions instead of building a safety net")
        let diegoW2 = sw(.weakness, "Code Review", .emerging)
        [diegoS1, diegoS2, diegoW1, diegoW2].forEach { $0.member = diego; context.insert($0) }
        diego.tags = [diegoS1, diegoS2, diegoW1, diegoW2]

        let diegoObs1 = obs(diego.id, "Helped the backend team debug a GraphQL schema mismatch even though it wasn't his ticket. Classic team-player behavior.", .sprintReview, 15)
        let diegoObs2 = obs(diego.id, "Acknowledged the testing gap during 1:1. Motivated to change — needs tooling guidance and a clear habit loop to bootstrap the practice.", .oneOnOne, 5)
        [diegoObs1, diegoObs2].forEach { $0.member = diego; context.insert($0) }
        diego.observations = [diegoObs1, diegoObs2]

        let diegoIDP = DevelopmentPlan(memberId: diego.id,
                                       title: "Testing Culture",
                                       objective: "Adopt test-driven development for new features and reach >70% coverage on owned modules by end of quarter.",
                                       targetDate: future(months: 2), status: .active, createdAt: ago(days: 20))
        diegoIDP.member = diego
        context.insert(diegoIDP)
        let da1 = IDPAction(text: "Complete Vitest + React Testing Library crash course", done: true, sortIndex: 0)
        let da2 = IDPAction(text: "Write tests for the 3 most fragile existing components", done: false, sortIndex: 1)
        let da3 = IDPAction(text: "Implement TDD on next 2 feature tickets — write tests first", done: false, sortIndex: 2)
        [da1, da2, da3].forEach { $0.plan = diegoIDP; context.insert($0) }
        diegoIDP.actions = [da1, da2, da3]
        diego.idps = [diegoIDP]

        let dev1 = event(diego.id, .strengthAdded, "Collaboration", after: .solid, 60)
        let dev2 = event(diego.id, .weaknessAdded, "Testing", after: .developing, 20)
        [dev1, dev2].forEach { $0.member = diego; context.insert($0) }
        diego.profileEvents = [dev1, dev2]

        // ── 6. Camila Ferreira — Senior Frontend Engineer (T3-2) ──────────
        let camila = TeamMember(name: "Camila Ferreira", role: "Senior Frontend Engineer",
                                seniority: .t3_2, createdAt: ago(days: 400), updatedAt: ago(days: 2))
        context.insert(camila)

        addStack([(.react, .expert), (.typescript, .expert), (.graphql, .advanced), (.reduxRTK, .proficient)], to: camila)

        let camilaS1 = sw(.strength, "Leadership", .strong, "Sets technical direction for the frontend chapter; proposals adopted without debate")
        let camilaS2 = sw(.strength, "Communication", .solid)
        let camilaS3 = sw(.strength, "Architecture", .solid)
        let camilaS4 = sw(.strength, "Code Review", .solid)
        let camilaW1 = sw(.weakness, "Adaptability", .emerging, "Occasionally resists context switches; prefers deep focus over parallel workstreams")
        [camilaS1, camilaS2, camilaS3, camilaS4, camilaW1].forEach { $0.member = camila; context.insert($0) }
        camila.tags = [camilaS1, camilaS2, camilaS3, camilaS4, camilaW1]

        let camilaObs1 = obs(camila.id, "Redesigned the state management layer with RTK Query — reduced API boilerplate by 60%. The migration guide she wrote is excellent.", .sprintReview, 20)
        let camilaObs2 = obs(camila.id, "Exceptional H1: 3 features shipped, design system ownership, and a team tech talk on TypeScript generics.", .performanceCycle, 45)
        let camilaObs3 = obs(camila.id, "Interested in expanding into product/engineering collaboration. Would benefit from exposure to product discovery conversations.", .oneOnOne, 7)
        [camilaObs1, camilaObs2, camilaObs3].forEach { $0.member = camila; context.insert($0) }
        camila.observations = [camilaObs1, camilaObs2, camilaObs3]

        let camilaIDP = DevelopmentPlan(memberId: camila.id,
                                        title: "Team Mentoring Program",
                                        objective: "Establish structured mentoring relationships with two engineers to build the frontend leadership pipeline.",
                                        targetDate: nil, status: .completed, createdAt: ago(days: 120))
        camilaIDP.member = camila
        context.insert(camilaIDP)
        let ca1 = IDPAction(text: "Define mentoring framework (cadence, goals, feedback loops)", done: true, sortIndex: 0)
        let ca2 = IDPAction(text: "Conduct bi-weekly sessions for 2 months with Diego and Isabela", done: true, sortIndex: 1)
        let ca3 = IDPAction(text: "Present the framework to the broader team for reuse", done: true, sortIndex: 2)
        [ca1, ca2, ca3].forEach { $0.plan = camilaIDP; context.insert($0) }
        camilaIDP.actions = [ca1, ca2, ca3]
        camila.idps = [camilaIDP]

        let cev1 = event(camila.id, .strengthAdded, "Leadership", after: .solid, 200)
        let cev2 = event(camila.id, .strengthUpdated, "Leadership", before: .solid, after: .strong, 50)
        let cev3 = event(camila.id, .strengthAdded, "Code Review", after: .solid, 100)
        [cev1, cev2, cev3].forEach { $0.member = camila; context.insert($0) }
        camila.profileEvents = [cev1, cev2, cev3]

        // ── 7. Bruno Oliveira — Backend Engineer (T2-3) ───────────────────
        let bruno = TeamMember(name: "Bruno Oliveira", role: "Backend Engineer",
                               seniority: .t2_3, createdAt: ago(days: 220), updatedAt: ago(days: 4))
        context.insert(bruno)

        addStack([(.golang, .advanced), (.docker, .expert), (.kubernetes, .proficient), (.helm, .learning), (.kibana, .learning)], to: bruno)

        let brunoS1 = sw(.strength, "Problem Solving", .strong, "Debugging and root cause analysis is consistently excellent — methodical and hypothesis-driven")
        let brunoS2 = sw(.strength, "Observability", .solid, "Set up the logging standards for the team; evangelizes dashboards and tracing")
        let brunoS3 = sw(.strength, "DevOps", .emerging)
        let brunoW1 = sw(.weakness, "Mentoring", .developing, "Solves problems for others instead of guiding them — needs to switch from 'doing' to 'coaching'")
        [brunoS1, brunoS2, brunoS3, brunoW1].forEach { $0.member = bruno; context.insert($0) }
        bruno.tags = [brunoS1, brunoS2, brunoS3, brunoW1]

        let brunoObs1 = obs(bruno.id, "Debugged a complex memory leak in the Go service under production load. Created a detailed postmortem with prevention checklist.", .incident, 18)
        let brunoObs2 = obs(bruno.id, "Wants to grow into Platform Engineering. Helm is the current focus — has a self-structured learning plan already.", .oneOnOne, 6)
        [brunoObs1, brunoObs2].forEach { $0.member = bruno; context.insert($0) }
        bruno.observations = [brunoObs1, brunoObs2]

        let brunoIDP = DevelopmentPlan(memberId: bruno.id,
                                       title: "Platform Engineering Ramp-Up",
                                       objective: "Gain Kubernetes and Helm expertise to independently manage deployments and contribute to infrastructure improvements.",
                                       targetDate: future(months: 3), status: .active, createdAt: ago(days: 25))
        brunoIDP.member = bruno
        context.insert(brunoIDP)
        let ba1 = IDPAction(text: "Complete Helm fundamentals: charts, templates, and values files", done: true, sortIndex: 0)
        let ba2 = IDPAction(text: "Deploy a staging service using a Helm chart from scratch", done: false, sortIndex: 1)
        let ba3 = IDPAction(text: "Review and propose improvements to one existing Helm chart in production", done: false, sortIndex: 2)
        [ba1, ba2, ba3].forEach { $0.plan = brunoIDP; context.insert($0) }
        brunoIDP.actions = [ba1, ba2, ba3]
        bruno.idps = [brunoIDP]

        let bev1 = event(bruno.id, .strengthAdded, "Observability", after: .emerging, 100)
        let bev2 = event(bruno.id, .strengthUpdated, "Observability", before: .emerging, after: .solid, 30)
        [bev1, bev2].forEach { $0.member = bruno; context.insert($0) }
        bruno.profileEvents = [bev1, bev2]

        // ── 8. Mariana Souza — Staff Engineer (T4) ────────────────────────
        let mariana = TeamMember(name: "Mariana Souza", role: "Staff Engineer",
                                 seniority: .t4, createdAt: ago(days: 730), updatedAt: ago(days: 1))
        context.insert(mariana)

        addStack([(.golang, .expert), (.aws, .expert), (.kubernetes, .expert), (.dynatrace, .advanced), (.kibana, .proficient)], to: mariana)

        let marianaS1 = sw(.strength, "Architecture", .strong, "Designs systems that scale — both technically and organizationally")
        let marianaS2 = sw(.strength, "Leadership", .strong)
        let marianaS3 = sw(.strength, "Mentoring", .strong, "Structured mentoring program for 3 engineers; measurable progression in all of them")
        let marianaS4 = sw(.strength, "Problem Solving", .solid)
        [marianaS1, marianaS2, marianaS3, marianaS4].forEach { $0.member = mariana; context.insert($0) }
        mariana.tags = [marianaS1, marianaS2, marianaS3, marianaS4]

        let marianaObs1 = obs(mariana.id, "Presented the distributed tracing proposal to platform leadership and received full buy-in. Will reshape how we monitor latency.", .performanceCycle, 60)
        let marianaObs2 = obs(mariana.id, "Mentoring check-in: Lucas and Bruno are both progressing well. She keeps detailed notes and adjusts her approach per person.", .oneOnOne, 7)
        let marianaObs3 = obs(mariana.id, "Facilitated the Q3 architecture review. Kept everyone aligned and surfaced 2 critical dependency risks early in the planning cycle.", .sprintReview, 25)
        [marianaObs1, marianaObs2, marianaObs3].forEach { $0.member = mariana; context.insert($0) }
        mariana.observations = [marianaObs1, marianaObs2, marianaObs3]

        // Mariana mentors Lucas (internal)
        lucas.mentor = mariana

        let mev1 = event(mariana.id, .strengthAdded, "Architecture", after: .solid, 365)
        let mev2 = event(mariana.id, .strengthUpdated, "Architecture", before: .solid, after: .strong, 200)
        let mev3 = event(mariana.id, .strengthAdded, "Mentoring", after: .solid, 180)
        let mev4 = event(mariana.id, .strengthUpdated, "Mentoring", before: .solid, after: .strong, 90)
        [mev1, mev2, mev3, mev4].forEach { $0.member = mariana; context.insert($0) }
        mariana.profileEvents = [mev1, mev2, mev3, mev4]

        // ── 9. Thiago Nunes — Backend Engineer (T2-2) ─────────────────────
        let thiago = TeamMember(name: "Thiago Nunes", role: "Backend Engineer",
                                seniority: .t2_2, createdAt: ago(days: 120), updatedAt: ago(days: 9))
        context.insert(thiago)

        addStack([(.java, .advanced), (.docker, .proficient), (.aws, .learning), (.kibana, .learning)], to: thiago)

        let thiagoS1 = sw(.strength, "Debugging Logic", .solid, "Methodical debugger — uses binary search and hypothesis-driven approach consistently")
        let thiagoS2 = sw(.strength, "Testing", .emerging)
        let thiagoW1 = sw(.weakness, "Communication", .developing, "Goes quiet when blocked; surfaces issues only at sprint review instead of within hours")
        let thiagoW2 = sw(.weakness, "Collaboration", .emerging)
        [thiagoS1, thiagoS2, thiagoW1, thiagoW2].forEach { $0.member = thiago; context.insert($0) }
        thiago.tags = [thiagoS1, thiagoS2, thiagoW1, thiagoW2]

        let thiagoObs1 = obs(thiago.id, "Blocked for 2 days on an AWS IAM permissions issue but didn't flag it until sprint review. Lost 2 story points of velocity.", .incident, 10)
        let thiagoObs2 = obs(thiago.id, "Acknowledged the pattern and is motivated to change. Agreed on a 'stuck emoji' signal in Slack when blocked >2 hours.", .oneOnOne, 3)
        [thiagoObs1, thiagoObs2].forEach { $0.member = thiago; context.insert($0) }
        thiago.observations = [thiagoObs1, thiagoObs2]

        let thiagoIDP = DevelopmentPlan(memberId: thiago.id,
                                        title: "Communication & Async Visibility",
                                        objective: "Build a habit of surfacing blockers early and contributing actively to team rituals and async discussions.",
                                        targetDate: future(months: 2), status: .active, createdAt: ago(days: 15))
        thiagoIDP.member = thiago
        context.insert(thiagoIDP)
        let ta1 = IDPAction(text: "Agree on a 'blocked signal' with the team (Slack emoji protocol)", done: true, sortIndex: 0)
        let ta2 = IDPAction(text: "For 4 consecutive sprints, flag blockers within 2 hours of being stuck", done: false, sortIndex: 1)
        let ta3 = IDPAction(text: "Contribute at least 1 substantive async comment per sprint review thread", done: false, sortIndex: 2)
        [ta1, ta2, ta3].forEach { $0.plan = thiagoIDP; context.insert($0) }
        thiagoIDP.actions = [ta1, ta2, ta3]
        thiago.idps = [thiagoIDP]

        let thiagoPromo = PromotionReadiness(memberId: thiago.id, targetTier: .t2_3, status: .inProgress,
                                              notes: "Technical skills are on track. Communication and collaboration patterns need to improve first.", createdAt: ago(days: 20))
        thiagoPromo.member = thiago
        context.insert(thiagoPromo)
        let tc1 = PromotionCriterion(category: "Technical", label: "Delivers features end-to-end with minimal rework", met: true, sortIndex: 0)
        let tc2 = PromotionCriterion(category: "Technical", label: "Proactively writes and maintains test coverage", met: false, note: "Coverage improving but not yet consistent", sortIndex: 1)
        let tc3 = PromotionCriterion(category: "Collaboration", label: "Surfaces blockers within the same day they arise", met: false, note: "Working on this via IDP", sortIndex: 2)
        [tc1, tc2, tc3].forEach { $0.record = thiagoPromo; context.insert($0) }
        thiagoPromo.criteria = [tc1, tc2, tc3]
        thiago.promotionRecords = [thiagoPromo]

        let tev1 = event(thiago.id, .strengthAdded, "Debugging Logic", after: .emerging, 60)
        let tev2 = event(thiago.id, .strengthUpdated, "Debugging Logic", before: .emerging, after: .solid, 15)
        [tev1, tev2].forEach { $0.member = thiago; context.insert($0) }
        thiago.profileEvents = [tev1, tev2]

        // ── 10. Isabela Rodrigues — Full Stack Engineer (T2-1) ────────────
        let isabela = TeamMember(name: "Isabela Rodrigues", role: "Full Stack Engineer",
                                 seniority: .t2_1, createdAt: ago(days: 90), updatedAt: ago(days: 11))
        context.insert(isabela)
        isabela.mentor = camila

        addStack([(.typescript, .advanced), (.react, .proficient), (.golang, .learning), (.docker, .proficient)], to: isabela)

        let isabelaS1 = sw(.strength, "Adaptability", .strong, "Quickly pivots between frontend and backend tasks — rare capability in the team")
        let isabelaS2 = sw(.strength, "Collaboration", .solid)
        let isabelaS3 = sw(.strength, "Growth Mindset", .emerging)
        let isabelaW1 = sw(.weakness, "Code Review", .developing, "Reviews are shallow — catches style issues but misses logic bugs and edge cases")
        [isabelaS1, isabelaS2, isabelaS3, isabelaW1].forEach { $0.member = isabela; context.insert($0) }
        isabela.tags = [isabelaS1, isabelaS2, isabelaS3, isabelaW1]

        let isabelaObs1 = obs(isabela.id, "Onboarded quickly to the Go service — shipped a small feature after only 2 weeks with a language she'd never used before.", .sprintReview, 15)
        let isabelaObs2 = obs(isabela.id, "Wants to improve code reviews. Will experiment with a review checklist template — identified that she needs a structured mental model.", .oneOnOne, 6)
        [isabelaObs1, isabelaObs2].forEach { $0.member = isabela; context.insert($0) }
        isabela.observations = [isabelaObs1, isabelaObs2]

        let isabelaIDP = DevelopmentPlan(memberId: isabela.id,
                                         title: "Code Review Excellence",
                                         objective: "Develop a structured review practice that consistently catches logic bugs, not just style issues.",
                                         targetDate: future(months: 2), status: .active, createdAt: ago(days: 10))
        isabelaIDP.member = isabela
        context.insert(isabelaIDP)
        let ia1 = IDPAction(text: "Research and adopt a code review checklist template", done: true, sortIndex: 0)
        let ia2 = IDPAction(text: "Apply checklist on next 5 reviews and note what you catch vs. miss", done: false, sortIndex: 1)
        [ia1, ia2].forEach { $0.plan = isabelaIDP; context.insert($0) }
        isabelaIDP.actions = [ia1, ia2]
        isabela.idps = [isabelaIDP]

        let iev1 = event(isabela.id, .strengthAdded, "Adaptability", after: .solid, 40)
        let iev2 = event(isabela.id, .strengthUpdated, "Adaptability", before: .solid, after: .strong, 5)
        [iev1, iev2].forEach { $0.member = isabela; context.insert($0) }
        isabela.profileEvents = [iev1, iev2]

        // ── Save ──────────────────────────────────────────────────────────
        try? context.save()

        return [lucas, aline, rafael, fernanda, diego, camila, bruno, mariana, thiago, isabela]
    }
}
