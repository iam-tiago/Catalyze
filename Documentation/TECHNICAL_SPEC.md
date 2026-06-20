# Catalyze for iPad — Technical Specification

**Version:** 1.2.0  
**Platform:** iPadOS 26.0+  
**Language:** Swift 6.0  
**Frameworks:** SwiftUI, SwiftData, Swift Charts, CloudKit, MeshGradient  

---

## 1. Overview

Catalyze is a **local-first people management tool** for Engineering Managers. It helps track team members' skills, development, and readiness for promotion, with AI-powered insights from Claude.

**Key characteristics:**
- Native iPad app (SwiftUI)
- All data stored locally (SwiftData)
- Optional iCloud sync (CloudKit)
- AI-powered insights (Anthropic Claude API)
- No backend / no cloud service / no authentication

---

## 2. Architecture

### 2.1 Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Language | Swift 6.0 |
| Build | Xcode 16.3+ |
| Database | SwiftData (Core Data abstraction) |
| Sync | CloudKit (private database) |
| Charts | Swift Charts |
| Icons | SF Symbols |
| AI Client | Hand-rolled SSE client (Claude Messages API) |
| Secure Storage | Keychain (API key) |
| Settings Storage | UserDefaults (EM profile, preferences, layout state) |
| Testing | Swift Testing (XCTest macros) |

### 2.2 Project Structure

```
Catalyze/
  CatalyzeApp.swift            — @main entry, ModelContainer + AppStore + SeniorityService
  SampleData.swift             — SampleDataProvider (Previews + Settings reset)
  SeniorityLevel.swift         — SeniorityPreset enum + SeniorityService @Observable
  
  Models/
    Enums.swift                — All enumerations (Intensity, SWKind, etc.)
    TeamMember.swift           — TeamMember + StrengthWeakness + StackEntry
    MemberObservation.swift    — TeamObservation (renamed to avoid Observation framework conflict)
    Insight.swift              — Cached AI insight results
    DevelopmentPlan.swift      — DevelopmentPlan + IDPAction
    PromotionReadiness.swift   — PromotionReadiness + PromotionCriterion
    ProfileEvent.swift         — Append-only profile change log
    OrganizationConfig.swift   — OrganizationConfig + SeniorityLevel (@Model)
    CustomStackTag.swift       — User-defined tech stack tags (@Model)
    EMProfile.swift            — EM's own profile (Codable struct, not @Model)
  
  Persistence/
    Persistence.swift          — VersionedSchema + ModelContainer factory + CloudKit config
    Keychain.swift             — Secure API key storage
  
  Store/
    AppStore.swift             — @Observable store (navigation state, settings, mutations)
  
  AI/
    ClaudeClient.swift         — Streaming SSE client for Claude Messages API
    ClaudePrompts.swift        — High-level prompt functions (5 insight types)
  
  Views/
    Layout/
      AppLayout.swift          — NavigationSplitView root (dark sidebar + detail)
    
    Team/
      TeamView.swift           — Member grid + toolbar
      TeamOverview.swift       — Hero banner + collapsible dashboard (3 layout presets)
      MemberForm.swift         — Add/edit member sheet
    
    Member/
      MemberView.swift         — Member detail page (gradient header + sections, ScrollViewReader)
      TagSection.swift         — Strengths & growth areas
      TagForm.swift            — Add/edit tag sheet
      ObservationSection.swift — Observations list
      ObservationForm.swift    — Add observation sheet
      IDPSection.swift         — Development plans grouped by status
      IDPForm.swift            — Add/edit IDP sheet (with actions list)
      PromotionReadinessSection.swift — Promotion tracking summary
      PromotionReadinessForm.swift    — Promotion form (criteria + AI assessment)
      ProfileEvolutionSection.swift   — Profile change timeline
    
    Charts/
      MemberRadar.swift        — Behavioral radar (single member)
      TechnicalRadar.swift     — Technical stack radar (single member)
      TeamRadar.swift          — Aggregated behavioral radar (whole team)
      TeamTechnicalRadar.swift — Aggregated technical radar (whole team)
      TeamTechStackDistribution.swift — Tech stack usage across team
      TechStackDistribution.swift     — Stack distribution for single member
    
    Insights/
      InsightsView.swift       — 5 insight tabs + streaming output
      InsightHistoryView.swift — Browsable history with filter + detail view
    
    Settings/
      SettingsView.swift       — Two-column layout: dark sidebar + section content
    
    Search/
      GlobalSearch.swift       — ⌘K global search (members, observations, IDPs)
  
  DesignSystem/
    CatalyzeTokens.swift          — CColor, CFont, CSpace, CRadius, CGradient (adaptive)
    CatalyzeComponents.swift      — StatCard, TierBadge, SkillChip, EmptyState, etc.
    DesignSystemCatalystTokens.swift   — CatalystSpacing, CatalystTypography, etc.
    DesignSystemCatalystCard.swift     — CatalystCard, CatalystCardHeader
    DesignSystemCatalystButton.swift   — CatalystPrimaryButton
    DesignSystemCatalystEmptyState.swift — CatalystEmptyState
    DesignSystemCatalystInsightLayout.swift — CatalystInsightLayout, AIOutputCard
```

---

## 3. Data Model

All models use `@Model` (SwiftData) and are part of `CatalyzeSchemaV1`.

### 3.1 Enumerations

```swift
enum Intensity: String {
    case emerging   = "Emerging"    // strengths & weaknesses
    case solid      = "Solid"       // strengths only
    case strong     = "Strong"      // strengths only
    case developing = "Developing"  // weaknesses only
    case blocking   = "Blocking"    // weaknesses only
}

enum SWKind: String {
    case strength
    case weakness
}

enum ObservationContext: String {
    case oneOnOne         = "1:1"
    case incident         = "Incident"
    case sprintReview     = "Sprint Review"
    case performanceCycle = "Performance Cycle"
    case other            = "Other"
}

enum IDPStatus: String {
    case active    = "Active"
    case onHold    = "On Hold"
    case completed = "Completed"
}

enum InsightType: String {
    case individual   = "individual"
    case situational  = "situational"
    case team         = "team"
    case oneOnOnePrep = "1on1-prep"
    case perfReview   = "perf-review"
}

enum PromotionStatus: String {
    case notReady   = "Not Ready"
    case inProgress = "In Progress"
    case ready      = "Ready"
}

enum ProfileEventType: String {
    case strengthAdded   = "strength_added"
    case strengthUpdated = "strength_updated"
    case strengthRemoved = "strength_removed"
    case weaknessAdded   = "weakness_added"
    case weaknessUpdated = "weakness_updated"
    case weaknessRemoved = "weakness_removed"
}

enum StackProficiency: String {
    case learning   = "Learning"
    case proficient = "Proficient"
    case advanced   = "Advanced"
    case expert     = "Expert"
}
```

> **Note:** The old `Seniority` enum (with fixed T-Level codes) has been replaced by the dynamic `SeniorityLevel` @Model. Member seniority is now a free `String` matching a `SeniorityLevel.code` in the active configuration.

### 3.2 SeniorityPreset

```swift
enum SeniorityPreset: String, CaseIterable {
    case tLevel      = "T-Level"
    case traditional = "Traditional"
    case faang       = "FAANG"
    case management  = "IC + Management"
    case startup     = "Startup"
    case custom      = "Custom"
}
```

Built-in level codes per preset:

| Preset | Codes |
|---|---|
| T-Level | T1-3, T2-1, T2-2, T2-3, T3-1, T3-2, T3-3, T4 |
| Traditional | Junior, Mid, Senior, Lead |
| FAANG | L3, L4, L5, L6, L7, L8 |
| IC + Management | IC1, IC2, IC3, IC4, M1, M2, M3, M4 |
| Startup | Junior, Mid, Senior, Lead |

### 3.3 TagCategory (Behavioral — Predefined)

Declared in `ModelsSkillCategories.swift`:

```swift
BehavioralCategory.all:
  "Communication", "Ownership", "EQ", "Collaboration",
  "Growth Mindset", "Leadership", "Adaptability", "Mentoring"

TechnicalCategory.all:
  "Code Quality", "Code Review", "Testing", "Architecture",
  "DevOps", "Infrastructure", "Debugging", "Observability"
```

Custom categories are allowed (just a free-form `String`).

### 3.4 StackTag (Fixed + Extensible)

```swift
enum StackTag: String {
    case golang, java, kotlin, swiftUI = "Swift (UI)", react, typescript,
         reduxRTK = "Redux (RTK)", aws, kubernetes, docker, helm, graphql,
         aiAssistedDev = "AI Assisted-Dev", dynatrace, kibana
}
```

Custom tags extend via `CustomStackTag` @Model.

### 3.5 Models

#### StrengthWeakness
```swift
@Model
final class StrengthWeakness {
    @Attribute(.unique) var id: String
    var kindRaw: String              // SWKind.rawValue
    var category: String             // TagCategory | custom string
    var intensityRaw: String         // Intensity.rawValue
    var note: String?
    var createdAt: Date
    var member: TeamMember?
}
```

#### StackEntry
```swift
@Model
final class StackEntry {
    @Attribute(.unique) var id: String
    var tagRaw: String               // StackTag.rawValue or CustomStackTag.name
    var levelRaw: String             // StackProficiency.rawValue
    var member: TeamMember?
}
```

#### TeamMember
```swift
@Model
final class TeamMember {
    @Attribute(.unique) var id: String
    var name: String
    var role: String
    var seniorityRaw: String         // SeniorityLevel.code (dynamic, not enum)
    var photoUrl: String?
    
    @Relationship(deleteRule: .cascade, inverse: \StackEntry.member)
    var stack: [StackEntry]?
    
    @Relationship(deleteRule: .nullify)
    var mentor: TeamMember?          // internal mentor
    
    var mentorName: String?          // external mentor (free text)
    var externalMenteesRaw: String?  // newline-separated string
    
    @Relationship(deleteRule: .cascade, inverse: \StrengthWeakness.member)
    var tags: [StrengthWeakness]?    // single collection (kind discriminator)
    
    @Relationship(deleteRule: .cascade)
    var observations: [TeamObservation]?
    
    @Relationship(deleteRule: .cascade)
    var idps: [DevelopmentPlan]?
    
    @Relationship(deleteRule: .cascade)
    var promotionRecords: [PromotionReadiness]?
    
    @Relationship(deleteRule: .cascade)
    var profileEvents: [ProfileEvent]?
    
    var createdAt: Date
    var updatedAt: Date
    
    // Computed properties:
    var strengths: [StrengthWeakness]  // tags.filter { $0.kind == .strength }
    var weaknesses: [StrengthWeakness] // tags.filter { $0.kind == .weakness }
    var externalMentees: [String]      // splits externalMenteesRaw on \n
}
```

#### TeamObservation
```swift
@Model
final class TeamObservation {
    @Attribute(.unique) var id: String
    var memberId: String
    var text: String
    var contextRaw: String
    var createdAt: Date
    var member: TeamMember?
}
```

#### Insight
```swift
@Model
final class Insight {
    @Attribute(.unique) var id: String
    var typeRaw: String
    var memberId: String?            // nil for team-level insights
    var prompt: String
    var response: String
    var createdAt: Date
}
```

#### DevelopmentPlan
```swift
@Model
final class DevelopmentPlan {
    @Attribute(.unique) var id: String
    var memberId: String
    var title: String
    var linkedGrowthAreaId: String?  // ID of a StrengthWeakness (weakness)
    var objective: String
    var targetDate: Date?
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \IDPAction.plan)
    var actions: [IDPAction]?
    
    var member: TeamMember?
    
    var sortedActions: [IDPAction]   // sorted by sortIndex
}
```

#### IDPAction
```swift
@Model
final class IDPAction {
    @Attribute(.unique) var id: String
    var text: String
    var done: Bool
    var sortIndex: Int               // for deterministic ordering (CloudKit)
    var plan: DevelopmentPlan?
}
```

#### PromotionReadiness
```swift
@Model
final class PromotionReadiness {
    @Attribute(.unique) var id: String
    var memberId: String
    var targetTierRaw: String
    var statusRaw: String
    var aiAssessment: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \PromotionCriterion.record)
    var criteria: [PromotionCriterion]?
    
    var member: TeamMember?
    
    var sortedCriteria: [PromotionCriterion]
}
```

#### PromotionCriterion
```swift
@Model
final class PromotionCriterion {
    @Attribute(.unique) var id: String
    var category: String
    var label: String
    var met: Bool
    var note: String?
    var isCustom: Bool
    var sortIndex: Int
    var record: PromotionReadiness?
}
```

#### ProfileEvent
```swift
@Model
final class ProfileEvent {
    @Attribute(.unique) var id: String
    var memberId: String
    var typeRaw: String
    var category: String
    var intensityBeforeRaw: String?
    var intensityAfterRaw: String?
    var createdAt: Date
    var member: TeamMember?
}
```

#### OrganizationConfig
```swift
@Model
final class OrganizationConfig {
    @Attribute(.unique) var id: String
    var activePresetRaw: String          // SeniorityPreset.rawValue
    var customLevels: [SeniorityLevel]?  // owned levels for this config
}
```

#### SeniorityLevel
```swift
@Model
final class SeniorityLevel {
    @Attribute(.unique) var id: String
    var code: String           // short badge label (e.g. "T2-1", "Senior")
    var displayName: String    // full name (e.g. "Senior Engineer I")
    var order: Int             // sort order — lower = more junior
    var colorHex: String       // hex color for badges
    var category: String       // grouping label (e.g. "Specialist")
    var isActive: Bool
    var levelDescription: String?
    var config: OrganizationConfig?
}
```

#### CustomStackTag
```swift
@Model
final class CustomStackTag {
    @Attribute(.unique) var id: String
    var name: String
    var isActive: Bool
}
```

#### EMProfile (Codable, not @Model)
```swift
struct EMProfile: Codable {
    var name: String
    var role: String
    var teamName: String?
    var photoUrl: String?
}
```

### 3.6 Schema

`CatalyzeSchemaV1` includes all @Model types in this order:
`TeamMember`, `StrengthWeakness`, `StackEntry`, `TeamObservation`, `Insight`, `DevelopmentPlan`, `IDPAction`, `PromotionReadiness`, `PromotionCriterion`, `ProfileEvent`, `OrganizationConfig`, `SeniorityLevel`, `CustomStackTag`

---

## 4. State Management

### 4.1 AppStore

`@Observable` class (equivalent to Zustand in the web app). Injected into the view hierarchy via `.environment(store)` from `CatalyzeApp`.

**State:**
- `activeView: ActiveView` — current navigation view (.team | .member | .insights | .settings)
- `selectedMemberId: String?` — ID of the currently viewed member
- `focusedMemberSection: MemberSection?` — section to scroll to after navigation (cleared after use)
- `apiKey: String` — Claude API key (loaded from Keychain)
- `baseURL: String` — API base URL (default: `https://api.anthropic.com/v1`)
- `emProfile: EMProfile` — EM's profile (loaded from UserDefaults)

**Navigation actions:**
- `setActiveView(_:)` — switch navigation
- `setSelectedMember(_:)` — navigate to a member (sets activeView to .member)
- `navigateToMember(_:section:)` — navigate to a member and optionally focus a section

**Deep link action — `navigateToMember`:**
```swift
func navigateToMember(_ id: String, section: MemberSection? = nil) {
    focusedMemberSection = section
    setSelectedMember(id)
}
```

Called from the Growth layout in TeamOverview. `MemberView` reads `focusedMemberSection` on appear and on change, scrolls to the target section anchor, then clears `focusedMemberSection`.

**Settings actions:**
- `setApiKey(_:)` — save to Keychain
- `setBaseURL(_:)` — save to UserDefaults
- `setEMProfile(_:)` — save to UserDefaults (JSON-encoded)

**Mutation actions:**
- `addMember(_:in:)`, `updateMember(_:in:)`, `deleteMember(_:in:)`
- `addObservation(_:in:)`, `deleteObservation(_:in:)`
- `addInsight(_:in:)`
- `addIDP(_:in:)`, `updateIDP(_:in:)`, `deleteIDP(_:in:)`
- `addPromotionReadiness(_:in:)`, `updatePromotionReadiness(_:in:)`, `deletePromotionReadiness(_:in:)`
- `addProfileEvent(_:in:)`

**Key design:**
- **NO arrays of members/observations/etc. in the store**
- Views use `@Query` directly (SwiftData's reactive query system)
- Store holds only transient UI state and settings

### 4.2 MemberSection

Enum declared at file scope in `AppStore.swift`:

```swift
enum MemberSection {
    case idp
    case promotion
}
```

Used as the `section` argument to `navigateToMember(_:section:)`. Drives `scrollToFocused(_:)` in `MemberView`.

### 4.3 SeniorityService

`@MainActor @Observable` class. Injected into the view hierarchy as an environment value.

```swift
@MainActor
@Observable
final class SeniorityService {
    private(set) var levels: [SeniorityLevel] = []
    private(set) var activePreset: SeniorityPreset = .tLevel

    func load(from context: ModelContext) { ... }
    func level(for code: String) -> SeniorityLevel? { ... }
    func applyPreset(_ preset: SeniorityPreset, in context: ModelContext) { ... }
}
```

Reads `OrganizationConfig` and its owned `SeniorityLevel` objects from the context. Views that need seniority label/color lookup use `@Environment(SeniorityService.self)` instead of hard-coding level codes.

---

## 5. Persistence

### 5.1 SwiftData

- Schema: `CatalyzeSchemaV1` (see `Persistence.swift`)
- Migration plan: `CatalyzeMigrationPlan` (currently no migrations)
- Container: `ModelContainer` created in `CatalyzeApp.init()`
- CloudKit: `.automatic` database (uses `iCloud.com.prontto.Catalyze` container ID from entitlements)

### 5.2 Keychain

- API key stored with `Keychain.set/get`
- Accessibility: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- **Not** synced via iCloud Keychain (security best practice — user enters per device)

### 5.3 UserDefaults

| Key | Type | Usage |
|---|---|---|
| `catalyze_base_url` | String | API base URL |
| `catalyze_em_profile` | Data (JSON) | EMProfile |
| `teamOverviewLayout` | String | Selected `OverviewLayout` preset — persisted via `@AppStorage` |

---

## 6. AI Integration

### 6.1 ClaudeClient

Hand-rolled streaming SSE client.

**Why hand-rolled?**
- Anthropic's SSE format is simple (well-documented)
- `URLSession.bytes(for:)` parses it cleanly
- No external dependencies

**Authentication:**
- Sends both `x-api-key` (Anthropic) and `Authorization: Bearer` (LiteLLM proxy)
- Harmless when one is ignored

**Model resolution:**
- If `baseURL` contains `anthropic.com`: uses `claude-sonnet-4-6`
- Else (proxy): uses `anthropic--claude-4.5-sonnet` (LiteLLM format)

**Contract:**
- `onChunk: (String) -> Void` receives accumulated text (not delta)

### 6.2 ClaudePrompts

Five prompt functions:

1. **`generateIndividualInsight`**
   - Input: member, observations (up to 10 recent)
   - Output: Key patterns (2-3), Coaching recommendations (2-3), Watch-outs
   - Max tokens: 800 / word limit: 300

2. **`generateSituationalAdvice`**
   - Input: situation text, optional member context
   - Output: Recommended approach, Key considerations, Next steps
   - Max tokens: 800 / word limit: 300

3. **`generateTeamInsight`**
   - Input: all members
   - Analyzes: seniority distribution, common strengths/weaknesses (top 5 each), IDP activity
   - Output: Team health assessment, Capability gaps, Recommended actions
   - Max tokens: 1000 / word limit: 400

4. **`generateOneOnOnePrep`**
   - Input: member, recent observations (up to 10), active IDPs
   - Output: Key topics, Questions to ask, Follow-ups
   - Max tokens: 800 / word limit: 300

5. **`generatePerformanceReview`**
   - Input: member, observations (up to 15), IDPs (completed + active)
   - Output: Summary, Key accomplishments (3-4), Areas for growth (2-3), Goals for next period
   - Max tokens: 1200 / word limit: 500

---

## 7. Views

### 7.1 Navigation

**Root:** `NavigationSplitView(.balanced)` (iPad-optimized)

**Sidebar** — always-dark visual treatment (intentional, theme-independent):
- Background: `MeshGradient` 3×3 (deep purple `#100828` → navy `#0a0a1a` → near-black)
- Dot grid overlay via `Canvas` at 6% opacity
- Nav items: custom `SidebarNavItem` — white text, active state `white.opacity(0.10)` + border
- `.toolbarBackground(.hidden)` + `.toolbarColorScheme(.dark)` → collapse button adapts

**EM Profile Card** (bottom of sidebar):
- Shows avatar (36pt circle), name, role
- Translucent dark card (`white.opacity(0.07)` + border)
- Tappable → navigates to Settings

**Detail pane:** switches based on `AppStore.activeView`

### 7.2 Team Flow

**TeamView:**
- `LazyVGrid` with adaptive columns (minimum 280pt)
- Each `TeamMemberCard` shows avatar, name, role, seniority badge, top 2 strengths
- **Seniority color coding** — accent color derived from tier:
  - T1: amber `#D97706` · T2: blue `#3B82F6` · T3: brand indigo `#5B5BD6` · T4: emerald `#10B981`
  - Applied to: avatar ring gradient, placeholder icon, TierBadge, hover border
- Toolbar: "+" button → `MemberForm`
- Empty state: friendly CTA (only when no members exist)

### 7.3 TeamOverview (Layout Presets)

Collapsible panel above the member grid. Composed of a persistent **hero banner** + expandable content section.

```swift
enum OverviewLayout: String, CaseIterable {
    case overview  = "overview"   // label: "Behavioral", icon: person.3.fill
    case technical = "technical"  // label: "Technical",  icon: chevron.left.forwardslash.chevron.right
    case growth    = "growth"     // label: "Growth",     icon: arrow.up.circle.fill
}
```

**Persistence:** `@AppStorage("teamOverviewLayout") private var selectedLayout: OverviewLayout = .overview`

**Hero banner** (152pt, always visible):
- `MeshGradient` 2×2: indigo `#3730a3` → brand `#5B5BD6` → dark indigo `#1e1b4b`
- Dot grid overlay 6%
- Team name (title2, white) + member count subtitle
- Two `HeroPill` capsules: Active IDPs count · In Promotion count
- Collapse/expand chevron top-right; tapping toggles content section

**Content section** (expandable, white `CColor.neutral0` background):
- 3 stat cards: Team Size · Active IDPs · In Promotion
- Layout picker (Behavioral / Technical / Growth)

**Behavioral layout** (`.overview`):
- `TeamRadar` — aggregated behavioral radar

**Technical layout** (`.technical`):
- `TeamTechStackDistribution` — tech adoption by member count/proficiency
- `TeamTechnicalRadar` — aggregated technical skills radar

**Growth layout** (`.growth`):
- **Development Plans board** — members with active IDPs, listed with IDP title and action progress
  - Each row is a `Button` → `store.navigateToMember(member.id, section: .idp)`
- **Promotion Pipeline** — members in promotion with target tier badge and status
  - Each row is a `Button` → `store.navigateToMember(item.member.id, section: .promotion)`
  - Both use `.buttonStyle(.plain)`, `.contentShape(Rectangle())`, chevron indicator

### 7.4 Member Detail

**MemberView** (file: `MemberView.swift`):

Top-level view that resolves the member from `@Query` and passes it to `MemberDetailContent`.

Key: `.id(memberId)` on `MemberDetailContent` forces SwiftUI to re-create the view (and re-fire `.onAppear`) when the selected member changes.

**MemberDetailContent:**
- Wraps `ScrollView` in `ScrollViewReader { proxy in ... }`
- Calls `scrollToFocused(proxy)` on `.onAppear` and `.onChange(of: store.focusedMemberSection)`

**Section anchors:**
```swift
IDPSection(member: member)
    .id("section-idp")
PromotionReadinessSection(member: member)
    .id("section-promotion")
```

**`scrollToFocused(_:)`:**
```swift
private func scrollToFocused(_ proxy: ScrollViewProxy) {
    guard let section = store.focusedMemberSection else { return }
    let anchor: String = switch section {
    case .idp:       "section-idp"
    case .promotion: "section-promotion"
    }
    store.focusedMemberSection = nil
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        withAnimation(.smooth) {
            proxy.scrollTo(anchor, anchor: .top)
        }
    }
}
```

The 0.35s delay lets the view hierarchy settle before scrolling. `focusedMemberSection` is cleared immediately to prevent double-scroll on change re-fires.

**MemberHeader** — gradient hero card at the top of each member detail:
- `MeshGradient` 2×2 background colored by seniority tier (same palette as TeamMemberCard)
- Dot grid overlay 6%
- Avatar 80pt centered with white ring (3pt) + shadow
- Name (title2, white) + role (footnote, white 60%) + seniority pill + stack count pill
- Below gradient: Edit/Delete buttons + mentorship info on white background
- Entire card clipped to `CRadius.md` with `cardShadow()`

**Member sections (vertical stack):**
1. `TagSection` — strengths + growth areas (chips, tap to edit, + to add)
2. `MemberRadar` — behavioral radar chart
3. `TechSkillsSection` + `TechnicalRadar`
4. `TechnicalStackSection` + `TechStackDistribution`
5. `ObservationSection` — list sorted by date, swipe-to-delete
6. `IDPSection` — grouped by status (Active/On Hold/Completed) — anchor: `section-idp`
7. `PromotionReadinessSection` — target tier, criteria checklist, AI assessment — anchor: `section-promotion`
8. `ProfileEvolutionSection` — timeline of profile changes

**Forms:**
- `TagForm` — category picker (predefined + custom), intensity picker (filtered by kind), note
- `ObservationForm` — TextEditor, context Picker, DatePicker
- `IDPForm` — title, objective, link to growth area, target date, status, actions list
- `PromotionReadinessForm` — target tier, status, criteria list, AI assessment, notes

### 7.5 Charts

**MemberRadar** — behavioral radar (single member), categories from `BehavioralCategory.all`  
**TechnicalRadar** — tech skills radar (single member), categories from `TechnicalCategory.all`  
**TeamRadar** — aggregated behavioral radar (team-wide average)  
**TeamTechnicalRadar** — aggregated technical skills radar  
**TeamTechStackDistribution** — horizontal bars showing how many members use each technology, broken down by proficiency  
**TechStackDistribution** — proficiency breakdown bars for a single member's stack

### 7.6 Insights

**InsightsView:**
- Segmented picker in toolbar: 5 insight types (Individual, Situational, Team, 1:1 Prep, Perf Review)
- Each tab uses `CatalystInsightLayout` or `CatalystSimpleInsightLayout`
- Streaming output bound to `@State var streamingText`
- Completed insights auto-saved to database

**AIOutputCard** (shared component in `DesignSystemCatalystInsightLayout.swift`):
- `MeshGradient` 2×2: violet `#2D1B69` → dark indigo `#1e1b4b` → near-black `#0f0b2a`
- Dot grid overlay 5%
- Sparkles icon in glowing circle + "AI Insight" title (white)
- `MarkdownText` with `.colorScheme(.dark)` — all system text/secondary colors adapt
- `ProgressView` tinted `.white.opacity(0.55)` during streaming
- Colored drop shadow (violet) for floating effect
- Used in both live generation and `InsightDetailView` (history)

**InsightHistoryView:**
- Full browsable history: filter by type, member, or keyword search
- `InsightHistoryRow`: left accent strip (3pt, type color) + type badge + member name + preview
- Tapping a row opens `InsightDetailView` with `AIOutputCard` for the response
- Swipe-to-delete with confirmation alert
- Accessible from toolbar in InsightsView

### 7.7 Settings

**SettingsView** — two-column layout (no nested NavigationSplitView):
```swift
HStack(spacing: 0) {
    SettingsSidebar(selectedSection: $selectedSection) // 220pt
    Divider()
    settingsContent
}
```

**SettingsSidebar** — same dark MeshGradient + dot grid as the app sidebar:
- "Settings" title in white
- Section items with colored SF Symbol squares (iOS Settings.app style)
- Selected state: `white.opacity(0.10)` + border (same as `SidebarNavItem`)

**Sections:**
1. **Profile** — name, role, team name, photo (URL or PhotosPicker)
2. **AI** — API key (SecureField), base URL, connection test
3. **Organization** — Seniority Levels config (sheet), Tech Stack Tags (sheet)
4. **Data** — Export JSON, Import JSON, Reset to Demo Data
5. **Appearance** — System / Light / Dark theme picker
6. **About** — version, build number

**Export/Import (v1.1.0 format):**
- Exports: members + strengths/weaknesses + stack + observations + IDPs + actions + promotion records + criteria + profile events
- Import preserves `seniorityRaw` string to avoid losing custom preset codes

### 7.8 Search

**GlobalSearch** — presented as sheet via ⌘K:
- Searches: members (name, role, seniority), observations (text, context), IDPs (title, objective)
- Results grouped by type
- Tap → navigate to member detail → dismiss

---

## 8. Sample Data

### 8.1 SampleDataProvider

`enum SampleDataProvider` in `SampleData.swift`. Stateless namespace with two entry points:

```swift
enum SampleDataProvider {
    // For Xcode Previews — creates an in-memory container pre-populated
    static func makePreviewContainer() -> ModelContainer

    // For Settings reset — inserts members into an existing context
    @discardableResult
    static func populate(in context: ModelContext) -> [TeamMember]
}
```

**`makePreviewContainer()`** calls `PersistenceController.makePreviewContainer()` then invokes `populate(in:)`.

**`populate(in:)`** creates all 10 demo members, inserts them, saves the context, and returns the array.

### 8.2 Demo Team

10 members covering iOS, Android, Frontend, Backend, and Full Stack:

| Name | Role | Level | Stack |
|---|---|---|---|
| Lucas Tavares | Senior iOS Engineer | T3-1 | Swift (UI), AI Assisted-Dev |
| Aline Costa | iOS Engineer | T2-3 | Swift (UI), TypeScript |
| Rafael Mendes | Senior Android Engineer | T3-1 | Kotlin, Java, Docker |
| Fernanda Lima | Android Engineer | T2-2 | Kotlin, AWS, Kubernetes |
| Diego Santos | Frontend Engineer | T2-1 | React, TypeScript, Redux (RTK) |
| Camila Ferreira | Senior Frontend Engineer | T3-2 | React, TypeScript, GraphQL |
| Bruno Oliveira | Backend Engineer | T2-3 | Golang, Docker, Kubernetes, Helm |
| Mariana Souza | Staff Engineer | T4 | Golang, AWS, Kubernetes, Dynatrace |
| Thiago Nunes | Backend Engineer | T2-2 | Java, Docker, AWS |
| Isabela Rodrigues | Full Stack Engineer | T2-1 | TypeScript, React, Golang, Docker |

Each member includes: behavioral strengths (`.emerging/.solid/.strong`) and weaknesses (`.emerging/.developing/.blocking`), tech stack entries, observations in multiple contexts, at least one IDP with actions, profile events, and selected members have promotion records.

**Mentor relationships:**
- Mariana → mentors Lucas
- Lucas → mentors Aline
- Camila → mentors Isabela

### 8.3 Usage in Previews

Every view that needs data uses:
```swift
.modelContainer(SampleDataProvider.makePreviewContainer())
```

### 8.4 Usage in Settings

`loadSampleData()` in `SettingsView`:
```swift
private func loadSampleData() {
    let descriptor = FetchDescriptor<TeamMember>()
    if let existing = try? context.fetch(descriptor) {
        existing.forEach { context.delete($0) }
    }
    try? context.save()
    SampleDataProvider.populate(in: context)
    withAnimation { showingSampleDataSuccess = true }
    Task {
        try? await Task.sleep(for: .seconds(3))
        withAnimation { showingSampleDataSuccess = false }
    }
}
```

Deletes all existing members first (cascade deletes their children), then populates.

---

## 9. Visual Design Language

### 9.1 Dark Sidebar System

All sidebar and hero elements use an **always-dark** treatment independent of the app's color scheme setting (intentional design language, like Raycast):

| Element | Background | Text |
|---|---|---|
| App sidebar | MeshGradient dark purple + dot grid | white |
| Settings sidebar | Same MeshGradient | white |
| TeamOverview hero | MeshGradient indigo | white |
| MemberHeader | MeshGradient (seniority color) | white |
| AI output card | MeshGradient violet | white (.colorScheme(.dark)) |

### 9.2 MeshGradient Pattern

`MeshGradient` (iPadOS 26+) with dot grid overlay. Used consistently across all dark surfaces:

```swift
// Dot grid (Canvas-based, 22pt spacing, 0.85pt radius dots, 5–6% opacity)
Canvas { ctx, size in
    let spacing: CGFloat = 22
    let radius: CGFloat = 0.85
    // ... draw white circles at regular intervals
}
.opacity(0.06)
```

### 9.3 Seniority Color Palette

Accent color derived from seniority tier, used in TeamMemberCard and MemberHeader gradient:

| Tier | Color | Hex |
|---|---|---|
| T1 | Amber | `#D97706` |
| T2 | Blue | `#3B82F6` |
| T3 | Brand Indigo | `#5B5BD6` |
| T4 | Emerald | `#10B981` |

### 9.4 Color System (Dark Mode)

`CColor` neutrals use `UIColor` semantic colors — fully adaptive:
- `neutral0` = `Color(.systemBackground)` → white light / near-black dark
- `neutral50` = `Color(.secondarySystemBackground)`
- `neutral900` = `Color(.label)` → dark light / white dark

Chart dot borders use `Color(.systemBackground)` (not `Color.white`) to remain visible in light mode.

## 10. iPad Polish

- **NavigationSplitView(.balanced)** — sidebar + detail
- **SF Symbols** everywhere (no custom PNGs for icons)
- **Animations** — `.animation(.smooth)`, `.contentTransition(.numericText())`
- **Spring animations** — `.spring(response: 0.3, dampingFraction: 0.8)` for UI interactions
- **Hover effects** — seniority-colored border on `TeamMemberCard` hover
- **Multi-column grids** — `.adaptive(minimum: 280)` → reflows in portrait/landscape/Split View
- **Keyboard shortcuts** — ⌘K (search)
- **Empty states** — SF Symbol + text + CTA
- **Form sheets** — `.formSheet` or `.pageSheet`
- **Previews** — every view has `#Preview` with `SampleDataProvider.makePreviewContainer()`

---

## 10. Testing Strategy

- **Unit tests** — Swift Testing macros (`@Test`, `#expect`, `#require`)
- **Preview-driven development** — visual verification via Xcode Previews
- **Smoke tests:**
  1. Clean build (⇧⌘K → ⌘B)
  2. Settings → Reset to Demo Data → verify 10 members appear
  3. Growth tab → tap IDP row → verify navigation to member + scroll to IDP section
  4. Growth tab → tap Promotion row → verify navigation to member + scroll to Promotion section
  5. Add → edit → delete member → verify persistence across relaunch
  6. Add observation/IDP/promotion → delete member → verify cascade
  7. Enter API key → run insight → verify streaming + save
  8. (Optional) iCloud sync test on two simulators with same iCloud account

---

## 11. CloudKit Constraints

Every `@Model` property:
- Has a default value OR is optional
- Relationships are optional with appropriate delete rules:
  - `.cascade` for owned children (observations, IDPs, tags, levels)
  - `.nullify` for independent relationships (mentor)

**Array ordering:**
- CloudKit doesn't preserve array order reliably
- Use `sortIndex: Int` on child entities (IDPAction, PromotionCriterion)
- Use `order: Int` on SeniorityLevel

**String arrays:**
- Avoid `[String]` in @Model (CloudKit stores as transformable `NSArray`, doesn't merge well)
- Use newline-separated `String?` with computed property accessor (see `externalMentees`)

---

## 12. Migration Plan

**Current:** `CatalyzeSchemaV1` (v1.1.0)

**Changes from v1.0.0 → v1.1.0 (no migration needed — first production data release):**
- Added `OrganizationConfig` @Model
- Added `SeniorityLevel` @Model
- Added `CustomStackTag` @Model
- Removed hard-coded `Seniority` enum — member seniority is now a free string

**Future migrations:**
- Add `VersionedSchema` for each new schema version (e.g., `CatalyzeSchemaV2`)
- Add `MigrationStage` to `CatalyzeMigrationPlan.stages`
- **Never mutate existing schema versions** (breaks users with data)

---

## 13. Known Limitations

1. **No offline indicator** — app assumes internet for AI, doesn't show connection status
2. **No notifications** — IDP target dates, upcoming 1:1s (future)
3. **No custom fields** — member profiles have fixed schema
4. **No bulk operations** — no multi-select for batch edits
5. **Single EM** — no multi-user mode
6. **API key per device** — doesn't sync (security trade-off)

---

## 14. Performance Characteristics

- **Optimized for:** ~50 members, ~500 observations, ~100 IDPs
- **Charts recalculate** on every change (lightweight, < 10ms even with 50 members)
- **@Query is reactive** — views auto-update when data changes
- **CloudKit sync** — typically < 30 seconds, happens in background
- **Streaming AI** — first chunk in ~200–500ms, full response in 2–5 seconds

---

## 15. Security & Privacy

- **API key:** Keychain (encrypted, not synced)
- **Data at rest:** Local SQLite (SwiftData) — relies on device encryption
- **Data in transit:** HTTPS to Claude API
- **iCloud sync:** Private CloudKit database (user's iCloud account, not shared)
- **AI requests:** Observations/profile data sent to Anthropic (or proxy)

---

## 16. Deployment

**Minimum target:** iPadOS 26.0 (MeshGradient + Liquid Glass require iPadOS 26+)

**Bundle ID:** `com.prontto.Catalyze`

**Entitlements:**
- `com.apple.developer.icloud-container-identifiers` → `iCloud.com.prontto.Catalyze`
- `com.apple.developer.ubiquity-kvstore-identifier` → `$(TeamIdentifierPrefix)com.prontto.Catalyze`
- `keychain-access-groups` → `$(AppIdentifierPrefix)com.prontto.Catalyze`

**Capabilities:**
- iCloud (CloudKit + Key-Value Storage)
- Keychain Sharing

**App Store:**
- Privacy nutrition label: "Data Not Collected" (all data local + iCloud)
- Category: Productivity / Business
- Age rating: 4+

---

## 17. Future Roadmap

- **Notifications** — local notifications for IDP deadlines, 1:1 reminders
- **Photos integration** — PhotosPicker instead of URL for avatars (partial: URL only today)
- **Custom fields** — user-defined fields on member profiles
- **Bulk actions** — multi-select members for batch edits
- **More charts** — observations over time, IDP completion trends
- **Offline indicators** — show sync status
- **Cross-platform** — iPhone companion (read-only), Mac Catalyst
- **Collaboration** — shared iCloud container for multiple EMs

---

**End of Specification**
