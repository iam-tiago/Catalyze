# Catalyze for iPad — Technical Specification

**Version:** 1.0.0  
**Platform:** iPadOS 17.0+  
**Language:** Swift 6.0  
**Frameworks:** SwiftUI, SwiftData, Swift Charts, CloudKit  

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
| Settings Storage | UserDefaults (EM profile, preferences) |
| Testing | Swift Testing (XCTest macros) |

### 2.2 Project Structure

```
Catalyze/
  CatalyzeApp.swift            — @main entry, ModelContainer + AppStore
  
  Models/
    Enums.swift                — All enumerations (Seniority, Intensity, etc.)
    TeamMember.swift           — TeamMember + StrengthWeakness + StackEntry
    MemberObservation.swift    — TeamObservation (renamed to avoid Observation framework conflict)
    Insight.swift              — Cached AI insight results
    DevelopmentPlan.swift      — DevelopmentPlan + IDPAction
    PromotionReadiness.swift   — PromotionReadiness + PromotionCriterion
    ProfileEvent.swift         — Append-only profile change log
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
      AppLayout.swift          — NavigationSplitView root (sidebar + detail)
    
    Team/
      TeamView.swift           — Member grid + toolbar
      TeamOverview.swift       — Collapsible dashboard (stats + team radar)
      MemberForm.swift         — Add/edit member sheet
    
    Member/
      MemberView.swift         — Member detail page (header + sections)
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
    
    Insights/
      InsightsView.swift       — TabView with 5 insight types
    
    Settings/
      SettingsView.swift       — EM profile + API credentials
    
    Search/
      GlobalSearch.swift       — ⌘K global search (members, observations, IDPs)
```

---

## 3. Data Model

All models use `@Model` (SwiftData) and are part of `CatalyzeSchemaV1`.

### 3.1 Enumerations

```swift
enum Seniority: String {
    case t1_3 = "T1-3"
    case t2_1 = "T2-1"
    case t2_2 = "T2-2"
    case t2_3 = "T2-3"
    case t3_1 = "T3-1"
    case t3_2 = "T3-2"
    case t3_3 = "T3-3"
    case t4   = "T4"
}

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

### 3.2 TagCategory (Predefined)

Not an enum — predefined `[String]`:

```swift
"Communication", "Ownership", "Emotional Intelligence", "Collaboration",
"Growth Mindset", "Problem Solving", "Leadership", "Adaptability",
"Mentoring", "Language Mastery", "Code Quality", "Code Review",
"Testing", "Architecture", "DevOps", "Debugging Logic",
"Observability", "Security"
```

Custom categories are allowed (just free-form `String`).

### 3.3 StackTag (Fixed)

```swift
enum StackTag: String {
    case golang, java, kotlin, swiftUI = "Swift (UI)", react, typescript,
         reduxRTK = "Redux (RTK)", aws, kubernetes, docker, helm, graphql,
         aiAssistedDev = "AI Assisted-Dev", dynatrace, kibana
}
```

### 3.4 Models

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
    var member: TeamMember?          // inverse relationship
}
```

#### StackEntry
```swift
@Model
final class StackEntry {
    @Attribute(.unique) var id: String
    var tagRaw: String               // StackTag.rawValue
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
    var seniorityRaw: String
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
    var seniority: Seniority
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

#### EMProfile (Codable, not @Model)
```swift
struct EMProfile: Codable {
    var name: String
    var role: String
    var teamName: String?
    var photoUrl: String?
}
```

---

## 4. State Management

### 4.1 AppStore

`@Observable` class (equivalent to Zustand in the web app).

**State:**
- `activeView: ActiveView` — current navigation view (.team | .member | .insights | .settings)
- `selectedMemberId: String?` — ID of the currently viewed member
- `apiKey: String` — Claude API key (loaded from Keychain)
- `baseURL: String` — API base URL (default: `https://api.anthropic.com/v1`)
- `emProfile: EMProfile` — EM's profile (loaded from UserDefaults)

**Actions:**
- `setActiveView(_:)` — switch navigation
- `setSelectedMember(_:)` — navigate to a member (also sets activeView to .member)
- `setApiKey(_:)` — save to Keychain
- `setBaseURL(_:)` — save to UserDefaults
- `setEMProfile(_:)` — save to UserDefaults (JSON-encoded)
- `addMember(_:in:)` — insert + save
- `updateMember(_:in:)` — update timestamp + save
- `deleteMember(_:in:)` — delete + cascade + save
- `addObservation(_:in:)`, `deleteObservation(_:in:)`
- `addInsight(_:in:)`
- `addIDP(_:in:)`, `updateIDP(_:in:)`, `deleteIDP(_:in:)`
- `addPromotionReadiness(_:in:)`, `updatePromotionReadiness(_:in:)`, `deletePromotionReadiness(_:in:)`
- `addProfileEvent(_:in:)`

**Key difference from web app:**
- **NO arrays of members/observations/etc. in the store**
- Views use `@Query` directly (SwiftData's reactive query system)
- Store only holds transient UI state and settings

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

- `catalyze_base_url` — API base URL
- `catalyze_em_profile` — JSON-encoded `EMProfile`

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
- Mirrors the web app's callback shape exactly

### 6.2 ClaudePrompts

Five prompt functions:

1. **`generateIndividualInsight`**
   - Input: member, observations (up to 10 recent)
   - Output: Key patterns (2-3), Coaching recommendations (2-3), Watch-outs
   - Max tokens: 800
   - Limit: 300 words

2. **`generateSituationalAdvice`**
   - Input: situation text, optional member context
   - Output: Recommended approach, Key considerations, Next steps
   - Max tokens: 800
   - Limit: 300 words

3. **`generateTeamInsight`**
   - Input: all members
   - Analyzes: seniority distribution, common strengths/weaknesses (top 5 each), IDP activity
   - Output: Team health assessment, Capability gaps, Recommended actions
   - Max tokens: 1000
   - Limit: 400 words

4. **`generateOneOnOnePrep`**
   - Input: member, recent observations (up to 10), active IDPs
   - Output: Key topics, Questions to ask, Follow-ups
   - Max tokens: 800
   - Limit: 300 words

5. **`generatePerformanceReview`**
   - Input: member, observations (up to 15), IDPs (completed + active)
   - Output: Summary, Key accomplishments (3-4), Areas for growth (2-3), Goals for next period
   - Max tokens: 1200
   - Limit: 500 words

---

## 7. Views

### 7.1 Navigation

**Root:** `NavigationSplitView` (iPad-optimized)
- **Sidebar:** Team / Insights / Settings (List with buttons)
- **Detail:** switches based on `AppStore.activeView`

**EM Profile Card** (bottom of sidebar):
- Shows avatar, name, role
- Tappable → navigates to Settings

### 7.2 Team Flow

**TeamView:**
- `LazyVGrid` with adaptive columns (minimum 280pt)
- Each `MemberCard` shows:
  - Avatar (AsyncImage with SF Symbol placeholder)
  - Name + role
  - Seniority chip
  - Top 2 strengths (chips with intensity dots)
- Toolbar: "+" button → `MemberForm`
- Empty state: friendly CTA (only when no members exist)

**TeamOverview** (collapsible):
- **Only shown when team is not empty** (prevents overlap with empty state)
- Stat cards: Team Size, Active IDPs, In Promotion
- Seniority distribution (bars)
- TeamRadar (aggregated behavioral chart)

**MemberForm:**
- Name, role, seniority (Picker)
- Photo URL
- Mentor picker (internal + external)
- Stack proficiencies (add/remove rows)
- Save → `store.addMember` or `updateMember`

### 7.3 Member Detail

**MemberView:**
- Header: avatar, name, role, seniority, Edit/Delete buttons, mentorship info
- Sections (vertical stack):
  1. **TagSection** — strengths + growth areas (chips, tap to edit, + to add)
  2. **Charts** — MemberRadar + TechnicalRadar
  3. **ObservationSection** — list sorted by date, swipe-to-delete
  4. **IDPSection** — grouped by status (Active/On Hold/Completed), progress indicators
  5. **PromotionReadinessSection** — target tier, criteria checklist, AI assessment
  6. **ProfileEvolutionSection** — timeline of profile changes

**Forms:**
- `TagForm` — category picker (predefined + custom), intensity picker (filtered by kind), note
- `ObservationForm` — TextEditor (text), Picker (context), DatePicker (when editing)
- `IDPForm` — title, objective, link to growth area, target date, status, actions list (checkboxes + reorder)
- `PromotionReadinessForm` — target tier picker, status picker, criteria list (expandable rows), AI assessment generator, notes

### 7.4 Charts

**MemberRadar:**
- Polar chart (Area + Line + Points)
- Behavioral categories only (Communication, Leadership, etc.)
- Y-axis: 0–3 (None → Emerging → Solid → Strong)
- Color: blue
- Empty state if no behavioral tags

**TechnicalRadar:**
- Same structure, but for stack entries
- Y-axis: 0–3 (None → Learning → Proficient → Expert)
- Color: purple
- Empty state if no stack data

**TeamRadar:**
- Aggregated (averaged) behavioral profile
- Annotations show exact values
- Stats: "Strongest" and "Needs Focus" categories
- Color: green

### 7.5 Insights

**InsightsView:**
- `TabView` with 5 tabs (Individual, Situational, Team, 1:1 Prep, Perf Review)
- Each tab:
  - Input controls (member picker, situation textarea, etc.)
  - "Generate" button (disabled when inputs invalid or generating)
  - Output area (streaming text bound to `@State var streamingText`)
  - Progress indicator during generation
  - Error message if request fails
  - Completed insights auto-saved to database

### 7.6 Settings

**SettingsView:**
- Form with 4 sections:
  1. **Your Profile** — name, role, team name, photo URL, preview, "Save Profile"
  2. **API Credentials** — SecureField (API key), TextField (base URL), "Test Connection", "Save Credentials"
  3. **Data Management** — Export/Import (placeholders)
  4. **About** — version, build number

### 7.7 Search

**GlobalSearch:**
- Presented as sheet via ⌘K
- `.searchable()` with prompt
- Searches: members (name, role, seniority), observations (text, context), IDPs (title, objective)
- Results grouped by type
- Tap → navigate to member detail → dismiss
- Empty states: "Search" (no query), "No results" (no matches)

---

## 8. iPad Polish

- **NavigationSplitView** (not NavigationStack) — sidebar + detail
- **SF Symbols** everywhere (no custom PNGs for icons)
- **Animations** — `.animation(.smooth)`, `.contentTransition(.numericText())`
- **Hover effects** — `.hoverEffect(.lift)` on cards
- **Multi-column grids** — `.adaptive(minimum: 280)` → reflows in portrait/landscape/Split View
- **Keyboard shortcuts** — ⌘K (search)
- **Empty states** — friendly SF Symbol + text + CTA
- **Form sheets** — `.formSheet` or `.pageSheet` presentation
- **Previews** — every view has `#Preview` with in-memory container + sample data

---

## 9. Testing Strategy

- **Unit tests** — Swift Testing macros (`@Test`, `#expect`, `#require`)
- **Preview-driven development** — visual verification via Xcode Previews
- **Smoke tests** (from HANDOFF §9):
  1. Clean build (⇧⌘K → ⌘B)
  2. Add → edit → delete member → verify persistence across relaunch
  3. Add observation/IDP/promotion → delete member → verify cascade
  4. Enter API key → run insight → verify streaming + save
  5. (Optional) iCloud sync test on two simulators with same iCloud account

---

## 10. CloudKit Constraints

Every `@Model` property:
- Has a default value OR is optional
- Relationships are optional with appropriate delete rules:
  - `.cascade` for owned children (observations, IDPs, tags)
  - `.nullify` for independent relationships (mentor)

**Array ordering:**
- CloudKit doesn't preserve array order reliably
- Use `sortIndex: Int` on child entities (IDPAction, PromotionCriterion)
- Always sort by `sortIndex` when displaying

**String arrays:**
- Avoid `[String]` in @Model (CloudKit stores as transformable `NSArray`, doesn't merge well)
- Use newline-separated `String?` with computed property accessor (see `externalMentees`)

---

## 11. Migration Plan

**Current:** `CatalyzeSchemaV1` (v1.0.0)

**Future migrations:**
- Add `VersionedSchema` for each new version (e.g., `CatalyzeSchemaV2`)
- Add `MigrationStage` to `CatalyzeMigrationPlan.stages`
- **Never mutate existing schema versions** (breaks users with data)

---

## 12. Known Limitations

1. **No offline indicator** — app assumes internet for AI, but doesn't show connection status
2. **No import/export** — placeholders in Settings (JSON/Markdown export coming later)
3. **No insights history view** — insights are saved but not browsable in UI
4. **No notifications** — IDP target dates, upcoming 1:1s could trigger reminders (future)
5. **No custom fields** — member profiles have fixed schema
6. **No bulk operations** — no multi-select for batch edits
7. **Single EM** — app assumes one EM (the user); no multi-user mode
8. **API key per device** — doesn't sync (security trade-off)

---

## 13. Performance Characteristics

- **Optimized for:** ~50 members, ~500 observations, ~100 IDPs
- **Charts recalculate** on every change (lightweight, < 10ms even with 50 members)
- **@Query is reactive** — views auto-update when data changes
- **CloudKit sync** — typically < 30 seconds, happens in background
- **Streaming AI** — first chunk appears in ~200-500ms, full response in 2-5 seconds (depends on prompt size)

---

## 14. Security & Privacy

- **API key:** Keychain (encrypted, not synced)
- **Data at rest:** Local SQLite (SwiftData) — not encrypted by default (relies on device encryption)
- **Data in transit:** HTTPS to Claude API
- **iCloud sync:** Private CloudKit database (user's iCloud account, not shared)
- **AI requests:** Observations/profile data sent to Anthropic (or proxy) — Anthropic's [API terms](https://www.anthropic.com/legal/consumer-terms) say they don't train on API data

---

## 15. Deployment

**Minimum target:** iPadOS 17.0 (SwiftData + @Observable require iOS 17+)

**Bundle ID:** `com.prontto.Catalyze` (example — update to your team's ID)

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

## 16. Future Roadmap

Possible enhancements (not prioritized):

- **Export/Import** — JSON + Markdown export (round-trip with web app)
- **Insights History** — browsable list of past AI insights
- **Notifications** — local notifications for IDP deadlines, 1:1 reminders
- **Photos integration** — PhotosPicker instead of URL for avatars
- **Custom fields** — user-defined fields on member profiles
- **Team member photos** — embedded in database (Data?) instead of URLs
- **Bulk actions** — multi-select members for batch edits
- **More charts** — observations over time (bar chart), IDP completion trends
- **Offline mode indicators** — show sync status, cache AI responses
- **Cross-platform** — iPhone companion (read-only? limited editing?), Mac Catalyst
- **Collaboration** — shared iCloud container for multiple EMs (requires auth layer)

---

**End of Specification**
