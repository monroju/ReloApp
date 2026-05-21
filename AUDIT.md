# GoThere iOS — Audit (Phase 0)

Branch: `mission-foundation-wave1`
Auditor: Claude Code (Opus 4.7, 1M context)
Date: 2026-05-21
Scope: iOS only. Android is out of scope for this mission; parity work is a separate session.

## TL;DR — What the operator briefing didn't know

The briefing lists Wizard→Documents, Wizard→Calendar, and Calculator↔Wizard income verification as gaps. **They are partially or fully shipped already.** This is the single most important finding of the audit and reframes Wave 1 from "build the integration plumbing" to "harden + extend the integration plumbing that already exists, and add the structured data model the next 8 features will depend on."

| Briefing gap | Reality |
| --- | --- |
| T1a Wizard → Documents auto-populate | **SHIPPED** (commit `94d73f7`). `DocumentSlot` model + idempotent upsert + 2-section Documents UI. 38 `documentSlot` rules in wizard_config.json. |
| T1b Wizard → Calendar milestones | **PARTIAL.** Every wizard task with a `dueAt` becomes a calendar event tagged `source=wizard`. No typed milestone (no category, no color, no notification on wizard-emitted events). |
| T1c Calculator → Wizard income check | **PARTIAL.** Calculator already shows Comfortable / Tight / Below threshold visa groups with Wizard deep-links. The reverse — Wizard summary surfacing income-fit feedback — is missing. No per-dependent multiplier in math (it's only in marketing prose, and one entry's prose is wrong — see Known bugs below). |
| Self-employed / Autónomo pathway | **SHIPPED** for Spain (`es_autonomo`) and Portugal (`pt_d2`). |
| Citizenship-by-Descent pathway | **SHIPPED** for Italy (Jure Sanguinis), Ireland, Hungary, Poland, Germany, UK Ancestry, Argentina (and Canada has a track). |
| Country comparison engine | **SHIPPED** (`VisaCompareView`). |

Wave 1 should therefore be: **the schema additions** (so the existing plumbing can carry richer metadata) **plus the two real gaps in the existing integrations** (typed milestones on the calendar side; income-fit card on the wizard side).

## 1. Architecture map

| Concern | Implementation |
| --- | --- |
| Language / SDK | Swift 5.9, SwiftUI, iOS 17 deployment target, Xcode 26 |
| Project generation | XcodeGen via `project.yml` (no `.xcodeproj` committed) |
| Navigation | Root `MainTabView` with `TabView` (5 tabs) + per-tab `NavigationStack`. Cross-tab routing via `NotificationCenter` (`gothereDeepLink`) + `gothere://` URL scheme |
| State | `ObservableObject` + `@StateObject` / `@EnvironmentObject`. No SwiftData, no Core Data, no Realm |
| Persistence | Firebase Firestore (per-user subcollections `users/{uid}/...`), Firebase Storage for document uploads. Guest-mode local arrays for unauthenticated users (only some repos: EventsRepository yes, DocumentsRepository no). `UserDefaults` for one-shot prefs (target_move_millis, etc.) |
| Networking | Firebase SDK directly. No custom URLSession layer. No GraphQL / REST client beyond Firebase |
| Auth | Firebase Auth via `AuthService.shared` (`uid`, `isGuest`). No Sign in with Apple wired |
| Theming | Custom `Color.goPrimary` / `goSurfaceLight/Dark` / `goSuccess` palette. Manual dark-mode handling via `@Environment(\.colorScheme)`. No design-token JSON |
| IAP | StoreKit 2 via `PurchaseManager` (`hasAllAccess`). No RevenueCat. Tier model: paid-to-install + per-country IAPs |
| Analytics | PostHog (`posthog-ios` SPM dep). Wrapper at `Services/Analytics.swift` with an enum of event names |
| Push notifications | `NotificationManager` wraps `UNUserNotificationCenter`. Wired into `CalendarViewModel` for manual events only — **not** wired for the wizard-generated events that go through `EventsRepository.addEventFromTask` |
| Localization | English only. No `.xcstrings` or `Localizable.strings` |
| Feature flags | None. `PurchaseManager.hasAllAccess` gates premium content |
| CI | Codemagic (`codemagic.yaml`). Increments build number via `max(ASC latest, git commit count) + 1` |
| Linter / formatter | None configured |

## 2. Per-tab feature inventory

### Tab 1 — Tasks (`Views/Tasks/TasksView.swift`)
- View: country-grouped task list; rows auto-expand when a task has details (post commit `c5231e7`).
- Repo: `TaskRepository` → Firestore `users/{uid}/tasks`. Per-country seed import via `Seeds/<country>_tasks.json` (11 countries).
- Models: `TaskItem` (loose), `DestinationTask` (phased with `seedKey` for idempotent seed import).
- Deep-link router: `gothere://wizard|compare|tasks|calendar|documents|resources|decision`.
- **No structured fields for**: required documents, milestone metadata, income requirement.

### Tab 2 — Calendar (`Views/Calendar/CalendarScreenView.swift`)
- View: month/week toggle. `.graphical` DatePicker.
- Repo: `EventsRepository` → Firestore `users/{uid}/events` with guest fallback to a local array.
- Model: `EventItem` (title, dateMillis, notes, optional `source`).
- **No categorization** (no color/type/icon) and no notification triggered when wizard creates events; the wizard fans out via `addEventFromTask`, which doesn't call `NotificationManager.scheduleNotification`. Likely a bug — manually-added events do get notifications, wizard-added events don't.

### Tab 3 — Documents (`Views/Documents/DocumentsView.swift`)
- View: two sections — "Documents you need" (wizard-emitted slots, grouped by track) and "Other uploads" (legacy free-form list).
- Repo: `DocumentsRepository` with two Firestore subcollections (`documents` + `documentSlots`). `upsertSlots` is idempotent on `firestoreId = "<trackId>__<key>"`; rerunning the wizard does not duplicate or clobber status.
- Model: `DocumentSlot` (key, label, description, countryId, visaTrackId, status `.pending`/`.uploaded`).
- **Missing**: where-to-obtain text, validity period, apostille flag, sworn-translation flag, link from slot → originating task (so completing a slot can progress the task).

### Tab 4 — Resources (`Views/Resources/ResourcesView.swift`)
- View: categorized quick links + downloadable PDFs + **Real Journey CTA card** (premium). Sheet presents `RealJourneyView`.
- Repo: `ResourcesRepository`.
- Real Journey: 8-phase Spain DNV walkthrough derived from anonymized lawyer correspondence (commit `e10b621`), paywalled behind `PurchaseManager.hasAllAccess`.
- **No verified-as-of-date** anywhere on links.

### Tab 5 — Decision Tree (`Views/DecisionTree/DecisionTreeView.swift`)
- Filters: country, household, personal considerations, budget.
- Recommender: `VisaRecommender`. Routes to `VisaWizardView` if a wizardTrackId is wired, else `VisaCompareView`.
- Country comparison engine: `VisaCompareView` shows visas side-by-side.

### Shared — Visa Wizard (`Views/VisaWizard/VisaWizardView.swift` + ViewModel)
- 21 tracks across 11 countries (per session notes).
- 309 `estimatedWeeks` entries and 38 `documentSlot` annotations in `wizard_config.json`.
- Fans out on save to: `TaskRepository.insertTasks`, `EventsRepository.addEventFromTask` (for tasks with dueAt), `DocumentsRepository.upsertSlots`.
- **No income-fit feedback card** on the summary step. **No anchor-date question** — target date is bucketed to `asap`/`3_months`/`6_months`/`1_year`; the user can't pick a real consulate-appointment-target date.

### Shared — Cost Calculator (`Views/CostCalculator/CostCalculatorView.swift`)
- Already shows "Affordable visas" section grouping into Comfortable / Tight / Below threshold using `VisaInfo.monthlyIncomeEUR` and a 0.92 USD→EUR rate.
- Wizard pill on each row; tapping deep-links to `VisaWizardView` for visas with a `wizardTrackId`.
- **No per-dependent math.** `monthlyIncomeEUR` is single-applicant only.

## 3. Shared data model audit

| Need | Have? | Gap |
| --- | --- | --- |
| Document-metadata on tasks | No | `DestinationTask`/`TaskRule` carry no document fields. `DocumentSlot` exists as a sibling concept emitted from `TaskRule.documentSlot` but slots themselves lack where-to-obtain, validity, apostille, translation. |
| Time-bound milestone metadata | No | `EventItem` has only title+date+notes+source. No `Milestone` model with category, days-before-anchor, push flag. `TaskRule.estimatedWeeks` is the closest existing field and is used only to set `dueAt` on the task. |
| Income requirement (structured) | Partial | `VisaInfo.monthlyIncomeEUR: Int?` exists. No per-dependent multiplier. |
| Dependent multiplier | No | Free-text prose only (and one is misleading — see Known bugs). |

**Conclusion:** the foundation work (Phase 2) is real. T1a and T1b are not "mechanical wires" — they need schema additions. But the integration seams already exist (`VisaWizardViewModel.saveTasks` is the central fan-out point), so adding metadata does not require restructuring the app.

## 4. Integration surfaces

- **Central fan-out**: `VisaWizardViewModel.saveTasks` (lines 104–146 in `VisaWizardViewModel.swift`). Already calls into `TaskRepository`, `EventsRepository`, `DocumentsRepository`. This is the right seam to extend.
- **Deep-linking**: `Notification.Name.gothereDeepLink` (`MainTabView.swift:7`) with a switch on `route` in `userInfo`. Task rows post these via `handleTaskLink`.
- **Country selection**: `CountrySelection` (`Services/CountrySelection.swift`) shared as `@EnvironmentObject`. Read by Calculator, Decision Tree, Resources.
- **No event bus / Combine pipeline.** Services talk to each other via direct singleton method calls. Acceptable for current scale.

## 5. Test coverage

**There are no tests.** No XCTest target in `project.yml`. No `*Test*.swift` files. No XCUITest target.

This is the single largest tech-debt item and a blocker for the mission's "tests are non-negotiable for Wave 1" guardrail. The Wave 1 work must include creating an XCTest target.

## 6. Known bugs / TODOs / tech debt

- **`VisaCatalog.swift:39`** — Spain NLV pros says "Family included with +75% per dependent". The Spanish rule is 4× IPREM (principal) + ~25% IPREM per additional family member. The prose conflates two different multipliers; will be confusing once `dependentMultiplier` is introduced. Fix during foundation.
- **`VisaWizardViewModel.saveTasks`** — wizard-generated events go through `EventsRepository.addEventFromTask` which does **not** call `NotificationManager.scheduleNotification`. So manually-added events fire reminders; wizard-added events don't. This is a regression risk and should be fixed in foundation.
- **No anchor-date question in wizard** — `targetWeeksFromNow` is bucketed (`asap`/`3_months`/`6_months`/`1_year`). A real "consulate appointment target date" question is needed before milestone scheduling can be meaningful.
- **Code-signing artifacts in repo root** — `AuthKey_U67B9NAV79.p8`, `distribution.p12`, `provisioning_profile.b64`, etc. are present in `ios/` (untracked per `git status` but visible). Confirm `.gitignore` covers them all before any future commit. Not a foundation blocker.
- **No grep TODO/FIXME hits.** Code is clean of stale markers, which is a good sign.

## 7. Build / CI status

- Cannot run `xcodebuild` from the Windows dev host. Build verification happens on Codemagic on every push.
- Most-recent successful build per session notes: v1.5.2 LIVE 2026-05-18, v1.6.0 build 1 Waiting for Review. Wave 1 will target v1.6.0 build 2+ or v1.7.0.
- Build-number floor fix (`d4b04f6`) means the Codemagic increment is now self-healing.
- One known build-side risk: introducing an XCTest target will require regenerating `.xcodeproj` from `project.yml`, which Codemagic does on every run — so the change is portable, but the local dev experience is degraded on Windows. Acceptable.

## 8. Decisions that need operator sign-off before Phase 2

1. **Test target**: add it. There is no path to "tests are non-negotiable" without one. Yes/no?
2. **Foundation as separate PR vs. bundled with Wave 1**: the mission says "Commit the foundation as a single PR / commit before any feature work." This implies operator review between. **Recommend**: ship foundation as one commit on `mission-foundation-wave1`, then Wave 1 as a second commit on the same branch; PR contains both with a clear commit boundary.
3. **`DocumentSlot` evolution vs. new `DocumentRequirement` model**: the briefing says add `documentRequirements: [DocumentRequirement]` to the task model. We already have `DocumentSlot` emitted from `TaskRule.documentSlot`. **Recommend**: extend `DocumentSlotRule` (and therefore `DocumentSlot`) with the missing fields (`whereToObtain`, `validityPeriod`, `apostilleRequired`, `swornTranslationRequired`, `sourceTaskRuleKey`) rather than introduce a parallel `DocumentRequirement` model. Single source of truth, no migration mess.
4. **`Milestone` model placement**: a new `Milestone` struct on `TaskRule` (`milestones: [MilestoneRule]?`) emitted into `EventItem` with new fields (`category`, `daysOffsetFromAnchor`, `notificationEnabled`). Anchor date is a new wizard question. Yes/no?
5. **Push permission prompt**: ask once on wizard completion with clear copy. Yes/no?

## 9. Open question for the operator

The briefing was iOS-only but the operator has an Android codebase at full parity. **Wave 1 ships iOS only; Android parity is a separate session.** Confirm.
