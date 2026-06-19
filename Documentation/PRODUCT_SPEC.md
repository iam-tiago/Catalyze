# Catalyze — Product Specification

**Version:** 1.1  
**Last updated:** 2026-06-18  
**Status:** Active  

This document describes **what Catalyze does** — features, data model, business rules, and user flows — independently of any implementation platform. It is the source of truth for building a new version of Catalyze on any stack (web, mobile, desktop).

---

## 1. Product Overview

Catalyze is a **people management tool for Engineering Managers**. It helps an EM track their team's behavioral strengths and growth areas, technical skills, development plans, promotion readiness, and observations — and generates AI-powered insights to support coaching decisions.

**Core principles:**
- **Local-first** — all data belongs to the EM, no shared backend required
- **Action-oriented** — every view surfaces something the EM can act on
- **AI-augmented, not AI-dependent** — the app is fully functional without AI; insights are additive
- **Single EM** — one user, one team; no multi-tenant or collaboration features

**Primary user:** An Engineering Manager responsible for a team of 5–15 engineers.

---

## 2. Information Architecture

The app has three top-level sections:

```
Catalyze
├── Team          — team grid + member profiles
├── Insights      — AI-generated analysis
└── Settings      — EM profile, API credentials, organization config
```

---

## 3. Data Model

### 3.1 Entities overview

```
TeamMember
  ├── StrengthWeakness[]   (behavioral tags: strengths & growth areas)
  ├── StackEntry[]         (tech stack with proficiency levels)
  ├── TeamObservation[]    (freeform notes with context)
  ├── DevelopmentPlan[]    (IDPs with action items)
  │     └── IDPAction[]
  ├── PromotionReadiness[] (promotion tracking with criteria)
  │     └── PromotionCriterion[]
  └── ProfileEvent[]       (append-only change log)

OrganizationConfig
  └── SeniorityLevel[]     (customizable career ladder)

CustomStackTag[]           (user-defined tech stack tags)
Insight[]                  (cached AI responses)
EMProfile                  (the EM's own profile)
```

### 3.2 TeamMember

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | Unique identifier |
| `name` | string | Full name |
| `role` | string | Job title (e.g., "Senior iOS Engineer") |
| `seniority` | string | Level code (e.g., "T2-1", "Senior") — matches an active `SeniorityLevel.code` |
| `photoUrl` | string? | Avatar URL |
| `mentor` | TeamMember? | Internal mentor (another team member) |
| `mentorName` | string? | External mentor name (free text) |
| `externalMentees` | string[] | Names of people outside the team this member mentors |
| `createdAt` | date | |
| `updatedAt` | date | Updated on any mutation |

### 3.3 StrengthWeakness

Represents a single behavioral tag on a member. Both strengths and growth areas use the same entity — the `kind` field discriminates them.

| Field | Type | Values |
|---|---|---|
| `id` | UUID string | |
| `kind` | enum | `strength` \| `weakness` |
| `category` | string | Predefined behavioral category or custom free-text |
| `intensity` | enum | See intensity rules below |
| `note` | string? | Optional context |
| `createdAt` | date | |

**Predefined behavioral categories:**
`Communication`, `Ownership`, `EQ`, `Collaboration`, `Growth Mindset`, `Leadership`, `Adaptability`, `Mentoring`

Custom categories are allowed (free-form string).

**Intensity rules — valid values per kind:**

| Kind | Valid intensities |
|---|---|
| `strength` | `Emerging` · `Solid` · `Strong` |
| `weakness` | `Emerging` · `Developing` · `Blocking` |

Intensity semantics:
- **Emerging** — signal is there but nascent (applies to both kinds)
- **Solid** — consistent, reliable strength
- **Strong** — exceptional, defining characteristic
- **Developing** — noticeable gap, being worked on
- **Blocking** — actively hindering performance or promotion

### 3.4 StackEntry

A technology proficiency entry for a team member.

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `tag` | string | Technology name — from predefined list or `CustomStackTag.name` |
| `level` | enum | `Learning` \| `Proficient` \| `Advanced` \| `Expert` |

**Predefined tech stack tags:**
`Golang`, `Java`, `Kotlin`, `Swift (UI)`, `React`, `TypeScript`, `Redux (RTK)`, `AWS`, `Kubernetes`, `Docker`, `Helm`, `GraphQL`, `AI Assisted-Dev`, `Dynatrace`, `Kibana`

Custom tags can be defined by the user via `CustomStackTag`.

### 3.5 TeamObservation

A freeform note about a team member, captured in a specific context.

| Field | Type | Values |
|---|---|---|
| `id` | UUID string | |
| `memberId` | string | Reference to TeamMember |
| `text` | string | The observation content |
| `context` | enum | `1:1` \| `Incident` \| `Sprint Review` \| `Performance Cycle` \| `Other` |
| `createdAt` | date | |

### 3.6 DevelopmentPlan (IDP)

An Individual Development Plan with a structured objective and action items.

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `memberId` | string | Reference to TeamMember |
| `title` | string | Short plan name |
| `objective` | string | What the member should achieve |
| `linkedGrowthAreaId` | string? | ID of a `StrengthWeakness` (weakness) this plan addresses |
| `targetDate` | date? | Optional deadline |
| `status` | enum | `Active` \| `On Hold` \| `Completed` |
| `createdAt` / `updatedAt` | date | |

#### IDPAction

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `text` | string | Action description |
| `done` | boolean | Completion state |
| `sortIndex` | integer | Display order |

### 3.7 PromotionReadiness

Tracks a member's progress toward a promotion target.

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `memberId` | string | Reference to TeamMember |
| `targetTier` | string | Target seniority level code |
| `status` | enum | `Not Ready` \| `In Progress` \| `Ready` |
| `aiAssessment` | string? | AI-generated assessment text |
| `notes` | string? | EM's freeform notes |
| `createdAt` / `updatedAt` | date | |

#### PromotionCriterion

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `category` | string | Grouping label (e.g., "Technical", "Leadership") |
| `label` | string | The specific criterion description |
| `met` | boolean | Whether this criterion is satisfied |
| `note` | string? | Evidence or context |
| `isCustom` | boolean | User-added (vs. from a preset) |
| `sortIndex` | integer | Display order |

### 3.8 ProfileEvent

An append-only log of changes to a member's behavioral profile (strengths and growth areas). Enables a timeline view of how a member has evolved.

| Field | Type | Values |
|---|---|---|
| `id` | UUID string | |
| `memberId` | string | |
| `type` | enum | `strength_added` \| `strength_updated` \| `strength_removed` \| `weakness_added` \| `weakness_updated` \| `weakness_removed` |
| `category` | string | The affected skill category |
| `intensityBefore` | Intensity? | Previous value (for updates) |
| `intensityAfter` | Intensity? | New value (for adds/updates) |
| `createdAt` | date | |

### 3.9 SeniorityLevel & OrganizationConfig

The career ladder is fully customizable per organization.

**OrganizationConfig** holds one active preset and a list of `SeniorityLevel` entries.

**SeniorityLevel:**

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `code` | string | Short badge label (e.g., "T2-1", "Senior", "L5") |
| `displayName` | string | Full name (e.g., "Senior Engineer I") |
| `order` | integer | Sort order — lower = more junior |
| `colorHex` | string | Hex color for visual encoding |
| `category` | string | Grouping (e.g., "Specialist", "Senior", "Expert") |
| `isActive` | boolean | Soft-delete flag |
| `levelDescription` | string? | Promotion criteria description |

**Built-in presets:**

| Preset | Levels |
|---|---|
| **T-Level** | T1-3, T2-1, T2-2, T2-3, T3-1, T3-2, T3-3, T4 |
| **Traditional** | Junior, Mid, Senior, Lead |
| **FAANG** | L3, L4, L5, L6, L7, L8 |
| **IC + Management** | IC1–IC4 (Individual Contributor), M1–M4 (Management) |
| **Startup** | Junior, Mid, Senior, Lead |
| **Custom** | User-defined |

### 3.10 CustomStackTag

User-defined technology tag extending the predefined `StackTag` list.

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `name` | string | Technology name |
| `isActive` | boolean | Soft-delete flag |

### 3.11 Insight

Cached AI-generated insight response.

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | |
| `type` | enum | `individual` \| `situational` \| `team` \| `1on1-prep` \| `perf-review` |
| `memberId` | string? | `null` for team-level insights |
| `prompt` | string | The full prompt sent to the AI |
| `response` | string | The AI response (markdown) |
| `createdAt` | date | |

### 3.12 EMProfile

The EM's own identity, stored separately from the team roster.

| Field | Type |
|---|---|
| `name` | string |
| `role` | string |
| `teamName` | string? |
| `photoUrl` | string? |

---

## 4. Features

### 4.1 Team Section

**Team grid:** Shows all members as cards, sorted by name. Each card displays:
- Avatar (photo or initials fallback)
- Name + role
- Seniority badge (color-coded from active SeniorityLevel)
- Top 2 behavioral strengths with intensity indicator

#### Team Overview Dashboard

A collapsible panel above the grid with three preset layouts the user can toggle between:

**Behavioral layout** (default)
- 3 stat cards: Team Size · Active IDPs · In Promotion
- Aggregated behavioral radar chart (averaged intensity across all members for each behavioral category)
- Shows "Strongest" and "Needs Focus" summary

**Technical layout**
- 3 stat cards
- Tech stack distribution (technologies ranked by how many members have them, broken down by proficiency)
- Aggregated technical radar chart

**Growth layout**
- 3 stat cards
- **Development Plans board** — members with active IDPs listed with IDP title and action progress (done/total). Tapping navigates to that member's IDP section.
- **Promotion Pipeline** — members in promotion with target level badge and status. Tapping navigates to that member's Promotion section.

The selected layout persists across sessions.

#### Member Profile

Full detail view for a single team member. Contains these sections in order:

1. **Header** — avatar, name, role, seniority badge, edit/delete actions, mentor info
2. **Behavioral Profile** — strengths and growth areas as chips with intensity dots; radar chart
3. **Technical Skills** — hard skills (Code Quality, Architecture, etc.) with proficiency; technical radar chart
4. **Tech Stack** — technologies and proficiency levels; distribution chart
5. **Observations** — chronological list of notes; add/delete; filter by context
6. **Development Plans** — IDPs grouped by status (Active / On Hold / Completed); progress checkboxes
7. **Promotion Readiness** — target tier, criteria checklist, AI assessment, notes
8. **Profile Evolution** — append-only timeline of behavioral profile changes

#### Member Form (Add / Edit)

Fields: name, role, seniority (from active SeniorityLevel list), photo, internal mentor (team member picker), external mentor (free text), tech stack entries (tag + proficiency).

### 4.2 Insights Section

Five AI-powered insight types, each with dedicated input controls and a streaming output area. Completed insights are saved to history.

| Type | Input | Output |
|---|---|---|
| **Individual** | Member picker | Key patterns · Coaching recommendations · Watch-outs |
| **Situational** | Situation textarea + optional member context | Recommended approach · Key considerations · Next steps |
| **Team** | (all members, automatic) | Team health assessment · Capability gaps · Recommended actions |
| **1:1 Prep** | Member picker | Key topics · Questions to ask · Follow-ups |
| **Performance Review** | Member picker | Summary · Key accomplishments · Areas for growth · Goals |

All outputs are markdown-formatted and rendered with heading/bold/list support.

**Context passed to AI:**
- Individual / 1:1 Prep / Perf Review: member profile (name, role, seniority, strengths, weaknesses, observations, IDPs)
- Team: aggregated data for all members (seniority distribution, common strengths/weaknesses, IDP activity)
- Situational: user-provided situation text + optional member profile

### 4.3 Settings

| Section | Contents |
|---|---|
| **Your Profile** | EM name, role, team name, photo |
| **API Credentials** | Claude API key (stored securely), base URL (supports LiteLLM proxy), connection test |
| **Data Management** | Reset to Demo Data (loads 10 sample members), Export (JSON), Import (JSON) |
| **Organization** | Seniority Levels config, Tech Stack Tags manager |
| **Appearance** | System / Light / Dark theme |

---

## 5. Navigation & Deep Linking

### 5.1 Top-level navigation

Three sections accessible from a persistent sidebar (desktop/tablet) or tab bar (mobile):
- **Team** → shows team grid with Team Overview
- **Insights** → shows insight generator
- **Settings** → shows settings form

### 5.2 Member navigation

From any member card or search result → navigate to Member Profile.

From the EM Profile card (bottom of sidebar) → navigate to Settings.

### 5.3 Deep navigation

The Growth layout supports direct navigation to specific member sections:
- Tap IDP row → navigate to member + scroll to **Development Plans** section
- Tap Promotion row → navigate to member + scroll to **Promotion Readiness** section

### 5.4 Global Search (⌘K)

Searches across:
- Members (name, role, seniority)
- Observations (text, context)
- Development Plans (title, objective)

Results grouped by type. Selecting any result navigates to the relevant member.

---

## 6. Business Rules

### 6.1 Intensity validation

When creating or editing a `StrengthWeakness`:
- If `kind = strength`, only `Emerging`, `Solid`, `Strong` are valid
- If `kind = weakness`, only `Emerging`, `Developing`, `Blocking` are valid
- The UI should enforce this at the picker level

### 6.2 Profile Events (change log)

A `ProfileEvent` must be written whenever:
- A `StrengthWeakness` is **added** (type: `strength_added` or `weakness_added`, `intensityAfter` = new value)
- A `StrengthWeakness` intensity is **updated** (type: `strength_updated` or `weakness_updated`, both before/after)
- A `StrengthWeakness` is **removed** (type: `strength_removed` or `weakness_removed`)

### 6.3 Deletion cascades

Deleting a `TeamMember` must cascade-delete all owned data:
- All `StrengthWeakness`, `StackEntry`, `TeamObservation`, `DevelopmentPlan` (and their `IDPAction` children), `PromotionReadiness` (and their `PromotionCriterion` children), `ProfileEvent`

Deleting a `DevelopmentPlan` must cascade-delete all its `IDPAction` entries.  
Deleting a `PromotionReadiness` must cascade-delete all its `PromotionCriterion` entries.

### 6.4 Deletion confirmation

All destructive deletes (member, observation, IDP, promotion record) must require explicit user confirmation before executing.

### 6.5 IDP action ordering

`IDPAction` items within a plan are ordered by `sortIndex` (ascending). The UI should support reordering, persisting the new `sortIndex` values.

### 6.6 Seniority levels

A `TeamMember.seniority` value must correspond to an active `SeniorityLevel.code` in the organization's configuration. The default configuration is the T-Level preset.

### 6.7 Tech stack tags

A `StackEntry.tag` can be either a predefined tag name or a user-defined `CustomStackTag.name`. Both use the same string field — the distinction is only for UI categorization.

---

## 7. AI Integration

### 7.1 Provider

Anthropic Claude API (Messages API). The implementation should support a configurable base URL to allow LiteLLM or other compatible proxies.

**Authentication:** API key stored in secure storage (not in the database or config files). Per-device — not synced.

**Model selection:**
- Direct Anthropic endpoint → use latest Sonnet model
- Proxy endpoint → model name may differ (LiteLLM format)

### 7.2 Streaming

All AI responses should stream token-by-token to the UI. The accumulated text (not delta) should be what the UI binds to, so the display grows progressively.

### 7.3 Prompt guidelines (all types)

- Always provide a system role establishing the EM coaching context
- Keep responses under the word limit for the type
- Output is always markdown (headings, bold, bullet lists)
- Completed insights are auto-saved to history after streaming finishes

### 7.4 Insight type specs

| Type | Context sent | Max tokens | Word limit |
|---|---|---|---|
| Individual | Member profile + 10 most recent observations | 800 | 300 |
| Situational | Situation text + optional member profile | 800 | 300 |
| Team | All members (seniority, top 5 strengths/weaknesses, IDP activity) | 1000 | 400 |
| 1:1 Prep | Member profile + 10 recent observations + active IDPs | 800 | 300 |
| Perf Review | Member profile + 15 observations + completed + active IDPs | 1200 | 500 |

---

## 8. Demo & Sample Data

The app includes a "Reset to Demo Data" feature (in Settings → Data Management) that:
1. Deletes all existing team data
2. Populates with 10 representative demo members

**Demo team composition:**

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

Each member has behavioral strengths/weaknesses, tech stack, observations (multiple contexts), at least one IDP with actions, promotion data (for selected members), profile events, and mentor relationships.

---

## 9. Known Limitations & Planned Features

| Limitation | Notes |
|---|---|
| Single EM | No multi-user or team sharing |
| No notifications | IDP target dates, 1:1 reminders — not yet implemented |
| No bulk operations | No multi-select for batch edits |
| Export/Import | JSON export/import present but basic |
| API key per device | Deliberate security decision — not synced |
| No offline AI indicator | App doesn't show connectivity status for AI calls |

**Potential future features:**
- PhotosPicker integration for member avatars
- Insights history browsable in UI
- Local notifications for IDP deadlines
- Custom fields on member profiles
- Collaboration mode (shared data between multiple EMs)
- Cross-platform companion (read-only on phone)
