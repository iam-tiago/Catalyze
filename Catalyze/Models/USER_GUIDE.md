# Catalyze for iPad — User Guide

**Version 1.0.0**  
**Local-first people management for Engineering Managers**

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Team Management](#team-management)
3. [Member Profiles](#member-profiles)
4. [AI Insights](#ai-insights)
5. [Charts & Visualizations](#charts--visualizations)
6. [Search](#search)
7. [Settings](#settings)
8. [Tips & Shortcuts](#tips--shortcuts)

---

## Getting Started

### First Launch

When you first open Catalyze, you'll see an empty team view. Here's what to do:

1. **Set up your profile** (optional but recommended)
   - Tap the profile card at the bottom of the sidebar
   - Or navigate to Settings → Your Profile
   - Enter your name, role, and optionally your team name

2. **Configure AI credentials** (required for Insights)
   - Go to Settings → API Credentials
   - Enter your Anthropic API key
   - Optionally set a custom base URL (for LiteLLM proxies)
   - Tap "Test Connection" to verify
   - Tap "Save Credentials"

3. **Add your first team member**
   - Return to Team view
   - Tap the "+" button in the toolbar
   - Fill in the member's details

---

## Team Management

### Adding a Team Member

1. In the **Team** view, tap the **"+"** button (top-right)
2. Fill in the form:
   - **Name** (required)
   - **Role** (required)
   - **Seniority** — select from T1-3 through T4
   - **Photo URL** (optional) — paste a URL to display their avatar
   - **Internal Mentor** — select another team member
   - **External Mentor** — free text for mentors outside the team
   - **Technical Stack** — add technologies and proficiency levels
3. Tap **"Add"** to save

### Editing a Member

- Tap a member card in the team grid
- In their detail page, tap **"Edit"**
- Make changes and tap **"Save"**

### Deleting a Member

- Open the member's detail page
- Tap **"Delete"**
- Confirm the deletion
- ⚠️ **Warning:** This will also delete all associated observations, IDPs, and promotion records

### Team Overview Dashboard

At the top of the Team view, you'll see a collapsible dashboard showing:

- **Team Size** — total number of members
- **Active IDPs** — count of active development plans
- **In Promotion** — members with active promotion tracking
- **Seniority Distribution** — visual breakdown by level
- **Team Behavioral Radar** — aggregated strengths across the team

Tap the header to expand/collapse the dashboard.

---

## Member Profiles

### Profile Sections

Each member's detail page contains several sections (scroll to see all):

#### 1. Header
- Avatar, name, role, seniority
- Edit and Delete buttons
- Mentorship information (if configured)

#### 2. Strengths & Growth Areas
- **Strengths** — positive behavioral and technical traits
  - Each has a category, intensity (Emerging/Solid/Strong), and optional note
- **Growth Areas** — areas for improvement
  - Each has a category, intensity (Emerging/Developing/Blocking), and optional note

**Adding tags:**
- Tap the **"+"** next to Strengths or Growth Areas
- Select a predefined category or enter a custom one
- Choose intensity level
- Add an optional note
- Tap **"Add"**

**Editing tags:**
- Tap any tag chip to edit
- Tap the trash icon to delete

#### 3. Charts
- **Behavioral Radar** — visual profile across behavioral categories (Communication, Leadership, etc.)
- **Technical Radar** — proficiency across technologies in their stack

#### 4. Observations
- Timestamped notes about the member's performance, behavior, or growth
- Grouped by context: 1:1, Incident, Sprint Review, Performance Cycle, Other
- Swipe left to delete

**Adding observations:**
- Tap **"+"** in the Observations section
- Enter the observation text
- Select context
- Tap **"Add"**

#### 5. Development Plans (IDPs)
- Grouped by status: Active, On Hold, Completed
- Each shows:
  - Title and objective
  - Optional link to a growth area
  - Target date
  - Actions with checkboxes
  - Progress indicator (X/Y done)

**Creating an IDP:**
- Tap **"+"** in the Development Plans section
- Enter title and objective
- Optionally link to a growth area tag
- Set target date (optional)
- Add actions (each action can be marked done/not done)
- Reorder actions by dragging
- Tap **"Add"**

**Updating an IDP:**
- Tap the IDP card
- Check/uncheck actions
- Edit details
- Change status (Active / On Hold / Completed)
- Tap **"Save"**

#### 6. Promotion Readiness
- Track progress toward the next seniority level
- Shows:
  - Target tier
  - Status (Not Ready / In Progress / Ready)
  - Criteria checklist with met/not-met indicators
  - AI-generated assessment
  - Notes

**Starting promotion tracking:**
- Tap **"Start Tracking"**
- Select target tier
- Add criteria (or use defaults)
- Optionally generate AI assessment
- Tap **"Start"**

**AI Assessment:**
- Tap **"Generate AI Assessment"** in the form
- The AI analyzes the member's profile and provides readiness feedback
- You can regenerate or clear the assessment

#### 7. Profile Evolution
- Append-only timeline of all changes to strengths and growth areas
- Shows:
  - What changed (added/updated/removed)
  - Category and intensity changes
  - Timestamp

---

## AI Insights

The Insights view provides AI-powered coaching recommendations using Claude. **You must configure your API key in Settings first.**

### Five Types of Insights

#### 1. Individual Insight
- Analyzes a single team member
- Based on their strengths, growth areas, and recent observations
- Provides:
  - Key patterns (2-3)
  - Coaching recommendations (2-3)
  - Watch-outs

**How to use:**
1. Select a member from the dropdown
2. Tap **"Generate Insight"**
3. Watch the response stream in real-time
4. Completed insights are saved automatically

#### 2. Situational Advice
- Get coaching advice for a specific situation
- Optionally contextualized with a team member

**How to use:**
1. Describe the situation in the text field
2. Optionally select a related member
3. Tap **"Get Advice"**
4. The AI provides:
   - Recommended approach
   - Key considerations
   - Next steps

#### 3. Team Insight
- Analyzes the entire team
- Based on seniority distribution, common strengths/weaknesses, and IDP activity
- Provides:
  - Team health assessment
  - Capability gaps
  - Recommended strategic actions

**How to use:**
1. Tap **"Analyze Team"**
2. The AI reviews all \(N\) members
3. Watch the streaming response

#### 4. 1:1 Prep
- Prepares talking points for an upcoming one-on-one
- Based on recent observations, active IDPs, and the member's profile
- Provides:
  - Key topics to discuss
  - Open-ended questions to ask
  - Follow-ups from previous 1:1s

**How to use:**
1. Select the member you're meeting with
2. Tap **"Prepare 1:1"**
3. Review the suggested agenda

#### 5. Performance Review
- Generates a performance review draft
- Based on observations (up to 15 recent), completed/active IDPs, and profile
- Provides:
  - Summary of performance
  - Key accomplishments (3-4 bullets)
  - Areas for growth (2-3 bullets)
  - Goals for next period

**How to use:**
1. Select the member
2. Tap **"Generate Review"**
3. Copy the result and refine as needed

### Streaming Responses

All AI insights stream in real-time — you'll see the text appear progressively as Claude generates it. This makes the experience feel responsive even for longer responses.

### Saved Insights

Completed insights are automatically saved to the database. You can reference them later (though there's no dedicated "history" view yet — this could be a future enhancement).

---

## Charts & Visualizations

### Member Charts

On each member's detail page, you'll find two radar charts:

#### Behavioral Radar
- Shows intensity across behavioral categories (Communication, Leadership, Problem Solving, etc.)
- Data comes from the member's strengths and growth areas
- Scale: 0 (None) → 1 (Emerging) → 2 (Solid) → 3 (Strong)
- Empty if no behavioral tags exist

#### Technical Radar
- Shows proficiency across technologies in the member's stack
- Scale: 0 (None) → 1 (Learning) → 2 (Proficient) → 3 (Expert)
- Empty if no stack entries exist

### Team Radar

In the Team Overview dashboard, the **Team Behavioral Radar** shows:
- Aggregated (averaged) intensity across behavioral categories
- Calculated from all team members' tags
- Annotations show the exact average value per category
- Stats boxes highlight the **Strongest** and **Needs Focus** categories

---

## Search

### Global Search (⌘K)

Press **⌘K** (Command-K) on an iPad keyboard to open global search.

**What you can search:**
- **Members** — by name, role, or seniority
- **Observations** — by text or context
- **Development Plans** — by title or objective

**How to use:**
1. Press **⌘K** (or tap the search button if added to toolbar)
2. Type your query
3. Results appear grouped by type
4. Tap any result to navigate to that member's detail page
5. Press **Escape** or tap **"Close"** to dismiss

---

## Settings

### Your Profile
- **Name** — your name (shows in the sidebar profile card)
- **Role** — your job title
- **Team Name** — custom name for your team (shows as the Team view title)
- **Photo URL** — paste a URL to display your avatar in the sidebar

Tap **"Save Profile"** after making changes.

### API Credentials

**API Key** — your Anthropic API key (required for Insights)
- Stored securely in the system Keychain
- Not synced across devices via iCloud (you must enter it on each device)

**Base URL** — the API endpoint
- Default: `https://api.anthropic.com/v1`
- Change this if you're using a LiteLLM proxy or HAI proxy
- Leave blank to use default

**Test Connection** — sends a minimal request to verify your API key works

Tap **"Save Credentials"** after making changes.

### Data Management

*(Currently placeholders — Import/Export coming in a future update)*

- **Export Data** — export your team, observations, and IDPs to JSON
- **Import Data** — restore from a previous export

### About
- App version and build number

---

## Tips & Shortcuts

### iPad Optimizations

- **Multi-column grid** — the Team view automatically adjusts columns based on screen size (portrait vs. landscape, Split View, Stage Manager)
- **Hover effects** — if using a trackpad or Magic Keyboard, cards lift on hover
- **Keyboard shortcuts:**
  - **⌘K** — Open global search
  - **Escape** — Close search or modal sheets

### Sidebar Navigation

- Tap **Team**, **Insights**, or **Settings** to switch views
- Tap the **profile card at the bottom** to quickly jump to Settings

### Member Detail Navigation

- Tap any member card in the Team grid to open their detail page
- From search results, tap to navigate directly to that member
- The sidebar shows the active view highlighted in blue

### Empty States

Every section has a friendly empty state:
- Team view when no members exist → "Add your first team member"
- Charts when no data → "Add strengths to see the radar"
- Observations when none exist → "No observations yet"
- Empty search results → "Try a different search term"

### Data Persistence

- All data is stored locally on your device using **SwiftData**
- If iCloud is enabled and you're signed in, data syncs automatically across your devices via **CloudKit**
- API key is stored in **Keychain** and does NOT sync (security best practice)
- EM profile is stored in **UserDefaults** (could be synced in a future update)

### Best Practices

1. **Regular observations** — add observations after every 1:1, sprint review, or significant incident. This creates a rich history for AI insights and performance reviews.

2. **Update IDPs** — check off actions as they're completed. Set target dates to keep yourself and your team accountable.

3. **Use AI often** — the more data you add, the better the AI insights become. Generate individual insights before 1:1s, team insights before planning sessions.

4. **Link growth areas to IDPs** — when creating an IDP, link it to a specific growth area tag. This makes it clear what you're working on.

5. **Track promotions early** — start tracking promotion readiness 6+ months before the expected date. Add criteria incrementally as the member progresses.

6. **Customize tags** — don't limit yourself to predefined categories. Add custom categories that matter to your team's culture and values.

---

## Troubleshooting

### "No API key configured"
- Go to **Settings → API Credentials**
- Enter your Anthropic API key
- Tap **"Test Connection"** to verify
- Tap **"Save Credentials"**

### Insights not streaming
- Check your internet connection
- Verify your API key is correct
- If using a proxy, verify the base URL is correct
- Check the error message displayed

### Charts not showing
- Make sure the member has tags (strengths/weaknesses) or stack entries
- Behavioral radar only shows behavioral categories (not technical ones like "Code Quality")
- Technical radar only shows stack entries (not tags)

### Data not syncing
- Verify you're signed in to iCloud on all devices
- Go to iOS Settings → [Your Name] → iCloud → verify Catalyze is enabled
- CloudKit sync can take 30-60 seconds
- API key does NOT sync (by design — enter it on each device)

### Performance issues
- The app is optimized for up to ~50 members
- If you have more observations/IDPs, older ones may load slower (this is expected)
- Charts are lightweight but recalculate on every change

---

## Roadmap / Future Features

Possible enhancements (not yet implemented):

- **Export/Import** — JSON and Markdown export (currently placeholders)
- **Insights History** — view previously generated insights
- **Notifications** — reminders for IDP target dates, upcoming 1:1s
- **Offline mode indicators** — show when data is syncing
- **Team member photos** — upload from Photos instead of URL
- **More chart types** — bar charts for observations over time, IDP completion trends
- **Bulk actions** — multi-select members for batch operations
- **Custom fields** — add your own fields to member profiles

---

## Support

Catalyze is a local-first app — your data lives on your device and optionally syncs via iCloud. There's no cloud service or account to manage.

**Privacy:** Your data never leaves your devices except:
1. **iCloud sync** (if enabled) — goes to your private iCloud account
2. **AI requests** — observations and profile data are sent to Anthropic (or your configured proxy) when you generate insights. These requests are not stored by Anthropic per their API terms.

**Security:** Your API key is stored in the system Keychain and encrypted. It's never synced to iCloud.

---

**Enjoy using Catalyze!** 🚀
