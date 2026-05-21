# GoThere iOS — Wave 2/3/4/5+ Claude Code Prompts

Each block below is a ready-to-paste prompt for a fresh Claude Code session.
They assume Wave 1 (foundation + T1a/T1b/T1c finishes on branch
`mission-foundation-wave1`) has shipped. Each prompt is self-contained — it
should not require operator memory of prior conversations.

---

## Wave 2 prompt — Autónomo deepening + Ancestry deepening + AI entry point

```
Repository: C:/Users/JGM/Projects/GoThere/ios

Read AUDIT.md and BUILD_PLAN.md first — they describe the codebase state
after the foundation + Wave 1 PR landed. The foundation introduced:
- DocumentSlot enrichment (whereToObtain, validityPeriod, apostilleRequired,
  swornTranslationRequired, sourceTaskRuleKey)
- TaskRule.milestones with MilestoneRule (category, daysOffsetFromAnchor,
  notificationEnabled)
- WizardConfig.anchorDateQuestion (top-level)
- EventItem typed metadata + MilestoneCategory enum (deadline/expiration/
  appointment/milestone)
- VisaInfo.dependentMultiplier + requiredMonthlyEUR(dependents:) helper
- Services/IntegrationEvents.swift event bus
- GoThereTests/ XCTest target — see existing tests as the style guide

Wave 2 has three deliverables. Ship as one branch, three commits, one PR.

DELIVERABLE 1 — Autónomo / Self-Employed deepening (~1.5 dev days)
- Spain `es_autonomo` and Portugal `pt_d2` are the two existing self-employed
  tracks. Read their task rules in wizard_config.json.
- Add a `TaxRegime` struct to VisaInfo (optional). Fields:
  - `name: String` (e.g. "Beckham Law", "NHR successor (IFICI)", "RFA")
  - `flatRatePercent: Double?` (e.g. 0.24 for Beckham)
  - `eligibilityCriteria: [String]`
  - `applicationWindow: String?` (e.g. "Within 6 months of becoming Spanish tax resident")
- Wire Beckham Law on Spain DNV + Autónomo where eligible.
- Add an autónomo-specific Real Journey to Data/RealJourneys.swift covering
  registering with Hacienda + Seguridad Social. Anonymize all client detail.
- Add 6-8 milestones to es_autonomo wizard track (modelo 036/037 deadlines,
  trimestral IVA/IRPF dates, autónomo cuota grace window for first 12 months).

DELIVERABLE 2 — Ancestry deepening (~1.5 dev days)
- Italy, Ireland, Hungary, Poland, Germany, UK Ancestry, Argentina, Canada
  all have wizard tracks. Read their conditions.
- Add an `EligibilityRule` struct to wizard config (per-track), capturing:
  - Generation cutoff (e.g. Italy 4 gen incl. minor-line carve-outs)
  - 1948-rule eligibility for Italian Jure Sanguinis maternal line
  - Bill C-3 / Italian DL 36/2025 current status (verify with web search at run time)
- Add Real Journey entries for Italy and Ireland walking through document
  ordering, apostille, sworn translation chain.
- Surface a "rules changing — verify before you start" banner on tracks where
  the underlying law is in flux. Hard-code an `inFlux: Bool` on
  EligibilityRule — set true for Italy + Canada now.

DELIVERABLE 3 — AI conversational entry point (~2.0 dev days)
- New CTA on HomeView: "I don't know where to start" tile.
- New Services/AIService.swift. Streams from Claude API. Use the model name
  `claude-sonnet-4-6` or the most recent Sonnet available at build time.
- API key handling: do NOT embed in the binary. Either:
  (a) Add a thin Cloud Function proxy at api.gothere.app/ai (recommended), or
  (b) Document in WAVE_PROMPTS.md why you chose differently.
  If you go with (a), the function takes the user message + a system prompt
  set on the server side, forwards to Anthropic, streams back. Don't change
  the API key on the device.
- Tool use: surface VisaRecommender.recommend, CostDatabase.cities(for:),
  WizardRepository.tracksForCountry as tools the model can call.
- Paywall: free for first 5 messages per device, then gated by
  PurchaseManager.hasAllAccess. Show paywall before message 6.
- System prompt: must include "Informational only, verify with official
  sources" framing. Never give specific legal advice.

Tests
- VisaInfo+TaxRegime decode + encode roundtrip
- EligibilityRule + inFlux flag presence on Italy + Canada tracks
- AIService streaming response handler unit test (using a recorded fixture
  — do NOT hit the live API in CI)

Constraints
- Match existing voice and design system (goPrimary teal, goSurface light/
  dark, font scales already in use)
- Promote the Codemagic xcodebuild test step from non-blocking to blocking
  if it has stayed green for the prior 2 builds
- Do not introduce RevenueCat or new SDKs — stick to StoreKit 2 +
  Firebase + PostHog
```

---

## Wave 3 prompt — Apostille tracker + Decision Tree handoff + Resources verification

```
Repository: C:/Users/JGM/Projects/GoThere/ios

Wave 2 (autónomo + ancestry + AI) has shipped. Read AUDIT.md and BUILD_PLAN.md.

Wave 3 has three deliverables. One branch, three commits, one PR.

DELIVERABLE 1 — Apostille / sworn-translation tracker (~2.0 dev days)
- DocumentSlot already has apostilleRequired + swornTranslationRequired flags.
  Extend SlotStatus enum:
  pending -> obtained -> apostilled -> translated -> submitted
  Order matters; UI shows progression as a 4-step indicator.
- DocumentSlot UI in DocumentsView gains a small step indicator for slots
  where apostille/translation is required.
- DocumentsRepository adds advanceStatus(slotId:to:) — guards transitions
  (can't skip from pending straight to submitted).
- Add an "Apostille Tracker" overlay sheet listing all slots-in-progress
  with their current step + next action.
- Surface push reminders when a slot has been .obtained for > 30 days
  without progressing (apostille bottleneck warning).

DELIVERABLE 2 — Decision Tree → Wizard handoff explanation (~1.0 dev day)
- VisaRecommender already routes to VisaWizardView via wizardTrackId. Add an
  interstitial "Why we picked X for you" screen showing:
  - Filter inputs (country, household, considerations, budget)
  - Top 3 matching visas with one-line reasoning
  - "Open Wizard" CTA per visa
  - "See all visas in this country" CTA
- Pull reasoning text from the structured EligibilityRule + TaxRegime fields
  introduced in Wave 2. Don't hard-code marketing prose.

DELIVERABLE 3 — Verified-as-of-date on Resources (~2.0 dev days)
- New `verifiedAt: Date?` field on Resource. Persist in
  ResourcesRepository as a Firestore timestamp on each resource doc.
- UI: show "Verified MMM YYYY" pill on each resource in light teal; flip to
  a warning "Verify before relying on this — last checked > 90 days ago"
  in orange when stale.
- Add a cadence doc at _marketing/resources_audit_log.md describing the
  manual quarterly refresh process. Don't build the automated freshness
  job in this wave — that's Wave 4+ if signal demands it.

Tests
- Status transition guards (rejected jumps from pending to submitted)
- Decision Tree → Wizard handoff reasoning rendering against fixture inputs
- Resource verifiedAt formatting (>90 days warning, missing field => no pill)
```

---

## Wave 4 prompt — Country comparison + Marketplace + Tax foundation

```
Repository: C:/Users/JGM/Projects/GoThere/ios

Waves 1-3 have shipped. Read AUDIT.md, BUILD_PLAN.md, and recent git log.

Wave 4 has three deliverables. One branch, three commits, one PR.

DELIVERABLE 1 — Cross-country comparison engine (~2.0 dev days)
- VisaCompareView exists but is single-country. Add CrossCountryCompareView
  that places 2-3 visas side by side regardless of country (e.g. Spain DNV
  vs. Portugal D8 vs. Mexico Remote Work).
- New PreferenceProfile model:
  - `weightsSpeed: Double` (0-1)
  - `weightsCostOfLiving: Double`
  - `weightsCitizenshipTimeline: Double`
  - `weightsFamilyFriendliness: Double`
- Score each visa against the profile + render in sorted order.
- Wire from Decision Tree as a "Compare top 3 across countries" CTA.

DELIVERABLE 2 — Attorney / genealogist referral marketplace (~2.5 dev days)
- New Referral model:
  - name, country, specialty (visa, ancestry, tax), bio, fees range, contact
  - paidPlacement: Bool — drives sort order
  - ftcDisclosure: String — surfaced when card expands
- Seed 5-10 vetted entries per country in Data/Referrals.swift. Use ONLY
  professionals operator has personally vetted; everyone else gets "Search
  the bar association in [country]" placeholder.
- New ReferralsView accessible from Resources tab.
- App Store risk mitigation: every card carries the FTC disclosure
  "GoThere may receive a referral fee. Verify independently." Never frame
  recommendations as legal advice.
- Document the revenue model in _marketing/referrals_business_model.md
  (subscription vs. per-lead vs. flat-fee partnership) — decide before
  going live.

DELIVERABLE 3 — Tax pre-move planner (foundational, US-side only) (~2.5 dev days)
- New TaxPlannerView module under Views/TaxPlanner/.
- Six structured checklists:
  1. Residency exit date (last day in US state, last 183-day rolling window)
  2. FEIE eligibility (Physical Presence Test, Bona Fide Residence Test)
  3. FBAR awareness ($10K aggregate, FinCEN 114, calendar-year filing)
  4. FATCA threshold ($50K/$100K depending on filing status)
  5. State exit caveats (CA "domicile follows you" + NY 11-month residency
     rule + state-specific 183-day tests)
  6. Self-employment tax abroad (FEIE doesn't shield SE tax — totalization
     agreement may)
- Foreign-side tax planning is OUT OF SCOPE here — defer to Wave 5+.
- Copy must say "Informational; consult a CPA familiar with international
  tax" prominently on every screen. Foundation-level — Wave 5+ deepens.

Tests
- PreferenceProfile scoring math against fixtures
- Referral FTC disclosure presence on every card
- TaxPlanner FBAR threshold display correct ($10K aggregate)
```

---

## Wave 5+ prompts — Tier 2 modules

The order below is the recommended sequence absent user-feedback signal. Once
Wave 4 ships, the operator will have App Store review + support email data;
sequence Wave 5+ based on what users actually ask for.

### T2c — Banking pre-move (~1.5 dev days)

```
Build a "Banking pre-move" module under Views/Banking/. Inventory expat-friendly
account options per destination country (Wise, Revolut, N26, BBVA, Sabadell,
HSBC Expat). Include US-address-after-move guidance (mail forwarding services,
USPS forms, IRS PoA implications). Add to Resources tab as a top-level item.
No SDK additions. Affiliate links allowed; mark with FTC disclosure.
```

### T2g — Currency transfer cost calculator (~1.0 dev day)

```
Build a CurrencyTransferView comparing Wise, Revolut, Western Union, and
traditional bank wires for $X → €X transfer cost. Calculator only — no live
rate APIs. Use weekly-refreshed static estimates; refresh cadence document at
_marketing/currency_rates_audit_log.md.
```

### T2d — FBAR/FATCA compliance tracker (~2.0 dev days)

```
Extend the Wave-4 tax planner (T1i) with a tracking module: user enters their
foreign account count + max balances; module computes whether FBAR and/or
FATCA filing is required this year. Bundle education content. Doesn't file
anything; user submits at FinCEN themselves.
```

### T2e — Voting from abroad (~1.0 dev day)

```
Build a VoteFromAbroadView walking US citizens through FVAP / FPCA
registration, state-by-state ballot return rules, and the 45-day overseas
ballot transmission deadline. State-by-state matrix; cite official sources.
Calendar integration: register milestones for election deadlines tied to
the user's voting state.
```

### T2f — Social Security totalization (~1.5 dev days)

```
Surface totalization agreement status per destination country (which
countries have agreements with the US; which work credits transfer; how
Windfall Elimination Provision applies). Read-only educational module
with links to ssa.gov totalization page. Calculator: estimated SS benefit
reduction under WEP based on years-of-substantial-earnings input.
```

### T2b — International moving logistics (~2.5 dev days)

```
Build per-topic modules under Views/Moving/: customs (per destination),
pet travel (USDA APHIS + destination-specific), drivers license
(international permit + reciprocity table), shipping (full-container vs
LCL vs air vs sell-and-buy). Each is its own NavigationLink destination.
Country-aware via CountrySelection.
```

### T2a — Healthcare planning (~2.5 dev days)

```
Build HealthcarePlannerView with three sub-modules: COBRA (cost, duration,
when worth it vs ACA marketplace), destination enrollment (Spain SS,
Portugal SNS, Mexico IMSS, Canada provincial), ACA reporting from abroad
(Form 8965 history, foreign coverage as MEC, premium tax credit rules).
Foundational; no carrier-specific quote engines.
```

### T2h — Real estate exploratory (~3.0 dev days)

```
Add Views/RealEstate/ as a deep-link out layer rather than an API
integration. Curate Idealista + Imovirtual + realtor.ca + Inmuebles24
searches with the user's CountrySelection + city pre-filled. Surface
average price per m² from Numbeo (cached, weekly refresh, manual). No
agent recommendations (those live in the referral marketplace).
```

### T2i — Community feed (~5.0+ dev days)

```
DO NOT START until:
- Tier 1 + above-T2i Tier-2 modules have shipped
- App Store retention shows >50% D30 (signal users want to stay)
- Operator has a moderation policy committed in writing

Building this earlier creates an ongoing ops burden (moderation, abuse,
age-gating, App Store rejection risk on UGC) that displaces feature work.
When the time comes, scope: gated by Pro subscription, post-only-with-
verified-email, country + topic channels, hard rate limit, automated
profanity filter via a Cloud Function, manual moderator queue.
```

---

## Cross-wave guardrails (apply to every wave)

1. Honor the existing voice and design system. goPrimary teal, goSurface
   light/dark, the font scales already used in the codebase.
2. Do not introduce RevenueCat. PurchaseManager + StoreKit 2 is the path.
3. Do not introduce new analytics SDKs. PostHog is the path.
4. Do not change the data model in destructive ways. Forward-only, lossless
   migrations.
5. Tests for every wave: schema migrations 100% coverage, feature logic
   covers critical paths, UI gets smoke tests at minimum.
6. Privacy nutrition label review every wave — flag any new data collection
   to the operator before merging.
7. Match the audit-then-implement structure of Wave 1. Don't skip the audit.
8. App Store risk: anything resembling legal/tax/medical advice must carry
   the "Informational; verify with [appropriate professional]" framing in
   user-facing copy.
