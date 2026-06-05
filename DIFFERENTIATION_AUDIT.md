# GoThere — Chatbot-Proof Differentiation Audit

**Date:** 2026-06-05
**Branch:** `chatbot-proof-differentiation` (off `wave-2`)
**Repo audited:** `C:\Users\JGM\Projects\GoThere\ios` (the live `monroju/ReloApp` iOS repo — the parent `GoThere/` folder is under the home clone and also holds `android/`, but the iOS app is its own git repo at `ios/`).
**Scope of read:** all 90 Swift files under `GoThere/`, `project.yml`, entitlements, `GoThereTests/`, plus targeted searches across seeds/config and `android/`.

> **Verdict up front:** This is a mature codebase, not a greenfield. Feature 1 has a real metadata scaffold already shipped (apostille/sworn-translation flags, free-text validity, badges in the UI). Feature 3's *data* is almost entirely persisted already (visa, household, target date, tasks, income rules) — only the calculator output and the aggregate read-model/UI are missing. Feature 2 is genuinely absent and is the only one with an infrastructure blocker. **Most of the "build" here is completion and aggregation, not from-scratch construction.**

---

## Section 1 — Feature Existence Check

### Feature 1 — Document Vault with Expiration Tracking + Push

| Sub-feature | Status | Location | Notes |
|---|---|---|---|
| Document model with expiration **date** field | **Absent** | `Models/Document.swift:3-13`, `Models/DocumentSlot.swift` | `UserDocument` has no date fields at all. `DocumentSlot` has only a free-text `validityPeriod: String?`, never a `Date`. |
| Document model with **validity period** field | **Partial** | `Models/DocumentSlot.swift:24` | `validityPeriod: String?` is free text ("90 days from issue"), authored per-slot in `wizard_config.json`. Not a numeric `Int` days value, and lives on the slot, not the uploaded doc. |
| Document model with **apostille required** flag | **Exists** | `Models/DocumentSlot.swift:26` | `apostilleRequired: Bool?` — already persisted (`DocumentsRepository.swift:139`) and rendered as a badge. |
| Document model with **sworn translation** flag | **Exists** | `Models/DocumentSlot.swift:28` | `swornTranslationRequired: Bool?` — persisted (`DocumentsRepository.swift:140`) and badged. |
| Document model with **status enum** | **Partial** | `Models/DocumentSlot.swift:35-39` | `SlotStatus` = `{pending, uploaded}` only. No `expired / apostillePending / translationPending / complete`. `UserDocument` itself has no status. |
| Document model with **linked visa/task IDs** | **Exists** | `Models/DocumentSlot.swift:13,32`; `Models/Document.swift:11-12` | Slots carry `visaTrackId` + `sourceTaskRuleKey`; uploads carry `slotKey` + `slotTrackId`. |
| Visa-rules **expiration lookup table** | **Absent** | — | No `validityDays` lookup keyed by document type. Validity is hand-authored free text inside `wizard_config.json` slot annotations. The proposed JSON table does not exist. |
| **Auto-suggest** document names on upload | **Absent** | `Views/Documents/DocumentsView.swift:330-334` | Upload uses the raw OS filename verbatim. No name matching. |
| **Expiration date auto-calculated** on upload | **Absent** | `Services/DocumentsRepository.swift:85-104` | Upload writes `{name, downloadUrl, path, slotKey?, slotTrackId?}` only. |
| **Vault header** with status summary | **Absent** | `Views/Documents/DocumentsView.swift:17-45` | Header is title + refresh + Upload button + a static info card. No "X complete · Y expiring · Z missing" counts. |
| Document **list sorted by urgency** | **Absent** | `Views/Documents/DocumentsView.swift:106-124` | Slots grouped by visa track, in generation order. No urgency/expiry sort. |
| Document **status chip** (color-coded) | **Partial** | `Views/Documents/DocumentsView.swift:127-235` | Checkmark/circle for uploaded state; validity shown in `goWarning`; apostille/sworn badges. But no expiry-driven red/amber/green status chip. |
| **Days-until-expiration** display | **Absent** | — | No date math anywhere in the Documents UI. |
| **Apostille / translation badges** | **Exists** | `Views/Documents/DocumentsView.swift:210-235` | `slotBadges(_:)` renders both. Match this exact style. |
| **Document detail screen** with all metadata | **Absent** | `Views/Documents/DocumentsView.swift:203-207` | Tapping a doc opens its `downloadUrl` via `UIApplication.shared.open`. No detail/edit screen. |
| **UNUserNotificationCenter** configured | **Exists** | `Services/NotificationManager.swift`, `Services/PushNotificationService.swift:18`, `App/GoThereApp.swift:19` | Delegate set on launch; permission helpers exist. |
| **Push notifications for document expiry** | **Absent** | `Services/PushNotificationService.swift:10-42` | Remote push is FCM topic `us_policy_alerts` only. No per-document expiry push. |
| **Local notification scheduling** on upload | **Absent** | `Services/NotificationManager.swift:18-44` | `scheduleNotification` only handles `EventItem` (calendar). Nothing for documents. |
| **Notification permission prompt** | **Exists** | `Services/PushNotificationService.swift:23-31`, `Services/NotificationManager.swift:10-16` | Two entry points exist; neither is wired to document upload. |

**Feature 1 classification: PARTIAL.** The metadata vocabulary (apostille/sworn/validity-text), persistence plumbing (Firestore upsert with optional fields, lossless merge), badge UI, and a configured notification stack all exist. What is missing is the *active expiration engine*: a real `Date`, a numeric validity lookup, auto-calc on upload, urgency sorting, the status-summary header, days-until display, a detail screen, and document-expiry local notifications.

---

### Feature 2 — Cita Previa Slot Monitor

| Sub-feature | Status | Location | Notes |
|---|---|---|---|
| Cita monitor configuration UI | **Absent** | — | No monitor concept anywhere in Swift. |
| Cita monitor toggle (active/paused) | **Absent** | — | — |
| Cita monitor status display | **Absent** | — | — |
| Backend: register monitor | **Absent** | — | — |
| Backend: list monitors | **Absent** | — | — |
| Backend: delete/pause monitor | **Absent** | — | — |
| Background polling job | **Absent** | — | No GoThere polling service found. |
| APNs push from backend to device | **Absent** | — | App never uploads its APNs/FCM device token to any GoThere backend (FCM is topic-based only — `PushNotificationService.swift:33-41`). |
| Rate limiting on poll frequency | **Absent** | — | — |
| Auto-pause after slot detection | **Absent** | — | — |

**Feature 2 classification: ABSENT.** The only cita-related code is *content*: deep-links to government portals as wizard tasks/resources — e.g. `Seeds/spain_tasks.json:344-350` ("Schedule TIE appointment (Cita Previa)" + "Cita Previa Portal" link), `Views/Resources/ResourcesView.swift:1131` (INM appointments link), `wizard_config.json` portal URLs. No monitoring machinery of any kind.

---

### Feature 3 — Co-Pilot Dashboard

| Sub-feature | Status | Location | Notes |
|---|---|---|---|
| Dashboard / summary screen of any kind | **Partial (orphaned)** | `Views/Home/HomeView.swift` | A full dashboard-lite screen exists (country selector, visa-track card, task-progress stats, upcoming events, quick links) — **but it is NOT in the tab bar** (`MainTabView.swift` ships 5 tabs: Tasks/Calendar/Documents/Resources/Decision Tree). HomeView is only referenced by a comment in `AIWhereToStartView.swift:5`. It is effectively dead/unreachable code. |
| Readiness score / overall progress indicator | **Partial** | `Views/Home/HomeView.swift:233-252` | HomeView computes task completion % + `ProgressView`. The Tasks tab also has a 49-task ring (`TasksView.swift`). No *weighted* readiness score blending tasks/docs/income/timeline. |
| Compound intelligence cards / insight summaries | **Absent** | — | No cross-domain insight generation exists. |
| Selected visa persisted beyond Wizard | **Exists** | `Services/DestinationRepository.swift:11,31`; `ViewModels/DestinationsViewModel.swift:73-74` | `activeVisaTrackId` persisted to Firestore per user. |
| Calculator monthly cost persisted between sessions | **Absent** | `Views/CostCalculator/CostCalculatorView.swift` | View computes `monthlyCostBreakdown(city)` live; no `UserDefaults`/`@AppStorage`/Firestore write of the total. (grep for persistence in the file: zero hits.) |
| Household composition persisted from Decision Tree | **Exists** | `Services/CountrySafetyProfiles.swift:73-88` | `UserConsiderationsStore.save/load` persists household + personal considerations to `UserDefaults`. |
| Target move date stored anywhere | **Exists** | `ViewModels/VisaWizardViewModel.swift:121`; read at `Views/Tasks/TasksView.swift:221` | `UserDefaults` key `target_move_millis`, written on wizard completion. |
| Task completion state accessible cross-screen | **Exists** | `Services/TaskRepository.swift` (shared singleton); consumed in `HomeView.swift:234-236`, `TasksViewModel` | Core app mechanic, Firestore-backed, already read from multiple screens. |
| Income requirement pulled from visa rules | **Exists** | `Models/VisaInfo.swift:41,46,129-135` | `monthlyIncomeEUR`, `dependentMultiplier`, and `requiredMonthlyEUR(dependents:)` already implemented. |
| Income gap / surplus calculated | **Partial** | `Models/VisaInfo.swift:129-135` | The threshold-side primitive exists. No UI computes a gap, and the *user's* income/cost figure isn't captured/persisted (the calculator estimates lifestyle cost, not income, and doesn't persist it). |
| Timeline velocity (tasks/week pace) | **Absent** | — | No pace/velocity computation. (`target_move_millis` + task timestamps make it derivable.) |
| Cross-screen shared state layer / data store | **Partial** | `Services/IntegrationEvents.swift`; domain singletons (`DocumentsRepository`, `TaskRepository`, `DestinationRepository`, `CountrySelection`, …) | A Combine event bus exists (`visaCompletion`, `visaTaskCompletion`, `visaUpdate`, `documentSlotStatusChanged`) plus shared singletons. No single aggregate `UserMoveState` read-model that joins them. |
| Setup nudge for incomplete user profile | **Absent** | — | No "complete your setup" affordance. |

**Feature 3 classification: PARTIAL (data ready, presentation absent).** Four of five data sources are already persisted and reachable cross-screen; the income-requirement math exists. The genuine gaps are: persist the calculator's computed cost, add a `UserMoveState` aggregate read-model, build the pure `generateInsightCards` function, and present a dashboard — plus decide its entry point.

---

## Section 2 — Infrastructure Audit

### Persistence layer
- **Library:** Firebase. **Firestore** for structured per-user data (`users/{uid}/documents`, `users/{uid}/documentSlots`, destination/visa state, tasks, events), **Firebase Storage** for uploaded files, **UserDefaults** for device-local prefs/flags/counters. **No SwiftData, Core Data, or Realm.**
- **Shape:** per-domain singleton repositories, each owning its own Firestore listeners — `DocumentsRepository.shared`, `TaskRepository.shared`, `DestinationRepository`, `EventsRepository.shared`, `CountrySelection.shared`, etc. Not a single shared container; isolated stores joined ad hoc by views.
- **Persistent entities & key fields:**
  - `UserDocument` — `id, name, downloadUrl, path, slotKey?, slotTrackId?`
  - `DocumentSlot` — `key, label, slotDescription?, countryId, visaTrackId, status, uploadedDocumentId?, generatedAt, whereToObtain?, validityPeriod?, apostilleRequired?, swornTranslationRequired?, sourceTaskRuleKey?`
  - Destination/visa state — `activeDestinationId, activeVisaTrackId` (Firestore)
  - Tasks / events — `TaskRepository` / `EventsRepository`
  - UserDefaults keys — `target_move_millis`, `gothere.user.considerations`, `gothere.user.household`, country selection, trial install date, FCM-subscribed flag, AI message counter.
- **Migration risk for new work:** LOW. `UserDocument`/`DocumentSlot` are `Codable` with optional fields and Firestore writes use `merge: true` (`DocumentsRepository.swift:144`). Adding new optional fields is lossless for existing user docs (the established "Foundation Wave 1" pattern, per the comments at `DocumentSlot.swift:18-19`).

### Push notifications
- **`UNUserNotificationCenter`:** configured. Delegate set on launch (`PushNotificationService.swift:18`, called from `GoThereApp.swift:19`). `willPresent` returns banner/sound/badge.
- **Existing categories/identifiers/scheduled notifications:** only `NotificationManager` local notifications for calendar `EventItem`s, identifier pattern `event_<id>` (`NotificationManager.swift:31-44`). No notification *categories/actions* registered.
- **APNs in Xcode entitlements:** **enabled.** `GoThere/App/GoThere.entitlements` → `aps-environment = production`. `project.yml:50` wires `CODE_SIGN_ENTITLEMENTS`. App registers for remote notifications and hands the APNs token to FCM (`GoThereApp.swift:24-27`).
- **APNs in App Store Connect:** APNs auth key `AuthKey_U67B9NAV79.p8` is present in the iOS repo root, and per project memory the APNs key was uploaded to the `com.gothere.ios` Firebase app (the FCM-bundle-fix). Remote push via FCM topic `us_policy_alerts` is live. **Caveat:** this is FCM **topic** based — the app never uploads its device token to a GoThere-owned backend, so backend→specific-device push (needed for Feature 2) is not currently wired.

### Backend connectivity
- **Protocol:** REST. The only first-party backend call is the AI proxy: `https://api.getgothere.app/ai/messages` (`AIService.swift:34`, override key `ai_proxy_url_override`). Everything else (auth, docs, tasks, storage) goes directly to Firebase.
- **Auth:** Firebase Auth (`AuthService.shared`, `uid`/guest gating throughout repositories).
- **GoThere-specific FastAPI on Lightsail:** **not found / unconfirmed.** `api.getgothere.app` is an AI proxy (per the comment, it injects the model + API key) and per project memory was deployed as a Firebase-hosted site/function, not a persistent polling server. The Lightsail "gabriel" box runs unrelated crew agents / trading bots (project memory), not a GoThere cita service.
- **Background job infra for GoThere:** **none found.** No APScheduler/Celery/cron tied to this app in-repo.
- **Existing Playwright/polling adaptable to cita:** none in this repo. (Playwright assets referenced in project memory belong to the crew/Mac-Mini stack, not GoThere.)

### Navigation & design system
- **Pattern:** `TabView` with `NavigationStack`s inside; cross-screen deep-links via a `NotificationCenter` route (`MainTabView.swift:3-8,51-60`).
- **Tabs (5, in order):** Tasks(0) · Calendar(1) · Documents(2) · Resources(3) · Decision Tree(4) — `MainTabView.swift:16-49`.
- **New entry point feasibility:** iOS collapses a `TabView` into a "More" list once it exceeds 5 tabs. **A 6th tab would push tabs into "More" — undesirable.** Lowest-disruption options for a Co-Pilot screen: (a) repurpose the orphaned `HomeView` and **replace** one tab (e.g. surface "My Move" in place of, or merged with, one existing tab), or (b) add a prominent dashboard **card at the top of the Tasks tab** with a push into a full Co-Pilot screen. No navigation refactor is otherwise required. **This needs an operator decision.**
- **Design tokens (`Theme/Theme.swift`):** `goPrimary #15B8A6` (teal), `goPrimaryDark/Light`, `goSecondary`, `goTertiary #2E8BC0`; surfaces `goSurfaceLight=white` / `goSurfaceDark #1E2530`; status colors `goSuccess #4DC77B`, `goWarning #FFAB00`, `goError #BA1A1A`. Card modifier `goCard()` = padding + surface bg + corner radius **12** + soft shadow. Status-chip/badge pattern already established in `DocumentsView.slotBadges` (caption2 semibold, `opacity(0.15)` tinted bg, radius 4). **All three features can match existing tokens exactly — no design-system changes needed.**

### Test infrastructure
- `GoThereTests/` (XCTest, wired in `project.yml:63-78`): 10 files incl. `CalculatorBucketingTests`, `EligibilityRuleTests`, `MilestoneDateMathTests`, `SchemaMigrationTests`, `VisaInfoTests`, `WizardConfigDecodeTests`. New pure-logic code (validity lookup, insight-card generation, readiness scoring) fits this suite cleanly. **Note:** tests run via Xcode on macOS — they cannot be executed from this Windows dev machine; they ship for the operator's CI/local run.

---

## Section 3 — Gaps to Build

```
FEATURE 1 GAPS (Vault is PARTIAL — extend, do not rebuild):
- expirationDate: Date? on the upload/slot model (ABSENT) — add, lossless optional
- numeric validity lookup table keyed by document type (ABSENT) — new local JSON/Swift resource
  (NOTE: free-text validityPeriod String already exists on DocumentSlot — keep it; add numeric beside it)
- auto-calc expirationDate = uploadDate + validityDays on upload (ABSENT)
- auto-suggest document name from lookup on upload (ABSENT)
- expanded status enum: + expired / apostillePending / translationPending / complete (PARTIAL — SlotStatus is pending/uploaded only)
- vault header status summary "X complete · Y expiring · Z missing" (ABSENT)
- urgency sort of the document list (ABSENT)
- days-until-expiration label + color-coded expiry status chip (ABSENT)
  (KEEP existing apostille/sworn badges + validity-text — already shipped)
- document detail screen (editable metadata, re-upload, apostille/translation sub-checklist) (ABSENT)
- local notification scheduling on upload at 30/14/3 days (ABSENT) — extend NotificationManager, do not fork it
- wire the EXISTING permission prompt to first document upload (PARTIAL — helper exists, not triggered here)
- reschedule-on-foreground + cancel-on-delete for doc notifications (ABSENT)

FEATURE 2 GAPS (entirely ABSENT + has an infra blocker — see Section 4):
- everything: config UI, toggle, status display, all 4 backend endpoints, polling job,
  device-token upload + backend→device APNs, rate limiting, auto-pause
- BLOCKER: no confirmed persistent GoThere backend/job runner; no device-token pipeline
- CONSTRAINT: ToS/robots (below) imposes crawl-delay + an overnight visit-time window

FEATURE 3 GAPS (data READY — only aggregation + presentation missing):
- persist Calculator computed monthly cost (ABSENT) — small additive write, no screen refactor
- UserMoveState aggregate READ-model joining the existing stores (PARTIAL — stores exist, aggregate doesn't)
- generateInsightCards(_:) pure function + InsightCard/InsightType model (ABSENT)
- weighted readiness score (tasks 40 / docs 30 / income 20 / timeline 10) (PARTIAL — only raw task % exists)
- timeline velocity (tasks/week) calc (ABSENT)
- income gap/surplus UI computation vs persisted cost (PARTIAL — threshold primitive exists)
- the Co-Pilot dashboard screen itself + setup nudge (ABSENT / orphaned HomeView available to repurpose)
- entry-point decision (no 6th tab — needs operator call)

INFRASTRUCTURE GAPS:
- Feature 2 backend: no persistent polling service + no device-token→backend pipeline (BLOCKER)
- everything else needed is already in place (Firestore, Storage, UNUserNotificationCenter,
  APNs production entitlement + key, REST proxy, XCTest, design tokens)

NOTHING TO BUILD (already fully shipped — skip entirely, document as existing capability):
- apostilleRequired / swornTranslationRequired flags + their badges
- apostille/sworn-translation badge UI in the Documents list
- UNUserNotificationCenter setup + notification permission helpers + APNs prod entitlement/key
- selected visa/country persistence; household + considerations persistence; target-move-date persistence
- task-completion cross-screen access; income-requirement rules (monthlyIncomeEUR / requiredMonthlyEUR)
- IntegrationEvents cross-feature bus
```

---

## Section 3b — Cita Previa ToS / robots.txt finding (required pre-build check)

Checked 2026-06-05:

- **`sede.administracionespublicas.gob.es/robots.txt`** — reachable. Disallows only `/valida/validar/` and `*.pdf$` (neither is the booking path). **But** it sets `Crawl-delay: 60`, `Request-rate: 1/1m`, and `Visit-time: 0100-0645` (GMT). I.e. automated access is *permitted but rate-limited*, and a strict reading restricts crawling to a ~01:00–06:45 GMT overnight window.
- **`icp.administracionelectronica.gob.es/robots.txt`** (Extranjería cita previa) — could not verify: TLS certificate chain failed validation from this environment. **Unresolved — must be re-checked from a trusted network before any automated polling of this host.**

**Interpretation:** not silent, not flatly restrictive — it's *conditionally permissive*. A 2–5 min poll honors `Crawl-delay: 60` and `Request-rate: 1/1m`, but the `Visit-time` window is a genuine constraint, and these portals are known to deploy anti-bot defenses beyond robots.txt. Given that **plus** the backend blocker, the recommended default is the **user-guided alternative** (deep-link straight into the booking page pre-filtered by province + appointment type, with a manual "check now" + reminder concept) rather than server-side scraping — unless the operator both stands up a polling backend and accepts the ToS posture. This is a Section-4 decision point, not a unilateral call.

---

## Section 4 — Revised Build Plan

The standard "all three absent → full build" path does **not** apply. Adjusted scope:

**Recommended this session (client-only, no backend, low risk):**
1. **Feature 1 — complete the Vault.** Extend the existing model/UI/notification stack with the expiration engine (date field, numeric validity lookup, auto-calc, status summary header, urgency sort, days-until + status chip, detail screen, doc-expiry local notifications). Entirely on-device; reuses shipped scaffolding. ~highest value-to-risk.
2. **Feature 3 — build the Co-Pilot dashboard on already-persisted data.** Add calculator-cost persistence, a `UserMoveState` read-model, the pure `generateInsightCards` + readiness score, and the dashboard screen. **Blocked on one operator decision:** the entry point (no 6th tab).

**Defer / decide — Feature 2 (Cita Monitor):**
- Has a real infrastructure blocker (no persistent GoThere polling backend; no device-token→backend pipeline) **and** a ToS constraint (overnight visit-time window; second portal's robots.txt unverifiable from here).
- **Two viable paths:**
  - **(A) User-guided alternative — client-only, shippable now, no ToS exposure:** a "Cita Monitor" config screen that deep-links into the correct portal pre-selected by province + appointment type, with a local reminder to check during known slot-release windows. Meaningfully better than any competitor; no scraping.
  - **(B) True server-side monitor:** requires the operator to (i) stand up a persistent FastAPI + scheduler service, (ii) add device-token registration + a `cita-monitors` table, (iii) wire server APNs (`apns2`/`aioapns`), and (iv) accept the ToS/anti-bot posture. Larger; not buildable from this machine alone.

**Migration note:** all Feature 1 + Feature 3 schema additions are optional Firestore fields written with `merge: true` (or new UserDefaults keys) → **lossless, no destructive migration**, consistent with the existing "Foundation Wave 1" pattern.

---

## ⛔ Mandatory pause — operator decisions needed before any implementation code

1. **Scope confirmation:** proceed with **Feature 1 (complete) + Feature 3 (build on existing data)** this session, deferring Feature 2? Or a different cut?
2. **Feature 3 entry point** (no 6th tab possible without a "More" collapse): **(a)** repurpose orphaned `HomeView` and replace/merge a tab into a "My Move / Co-Pilot" tab, or **(b)** add a prominent Co-Pilot card atop the Tasks tab that pushes into a full screen?
3. **Feature 2 direction:** **(A)** ship the client-only user-guided deep-link alternative now, or **(B)** invest in the server-side monitor (operator provisions backend + accepts ToS posture), or **defer entirely** to a later wave?

No implementation code will be written until these are answered.
