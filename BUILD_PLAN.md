# GoThere iOS — Build Plan (Phase 1)

Branch: `mission-foundation-wave1`
Date: 2026-05-21
Reads `AUDIT.md`; assumes its findings.

## Sizing convention

"Dev day" = one day of focused, uninterrupted work by a competent solo iOS engineer who knows the codebase. A solo developer working evenings typically delivers 1–3 dev-days per calendar week. So a 5-day wave usually lands in 2–3 calendar weeks.

Effort estimates are net new work *given the audit findings* — i.e. they assume the things the audit confirmed are already shipped do not need rebuilding. The briefing's implied effort was higher because it assumed plumbing didn't exist yet.

## Operator-confirmed Wave 1 decisions

1. XCTest target — **add it.**
2. Foundation + Wave 1 on the same branch, two commits, one PR — **yes.**
3. Extend `DocumentSlot` / `DocumentSlotRule` in place rather than introducing a parallel `DocumentRequirement` — **yes.**
4. Add `Milestone` struct on `TaskRule` + anchor-date wizard question + push permission prompt on wizard completion — **yes.**
5. iOS only this session; Android parity is a future session — **yes.**

## Wave 1 — this session (foundation + the 3 Tier-1 finishes)

**Goal:** add the structured metadata the next 8 features will depend on, close the two real gaps in the existing integrations, and stand up a test harness so future waves can land with confidence. Ship as one branch, two commits, one PR.

| ID | Feature | Effort (dev days) | Why now |
| --- | --- | --- | --- |
| F | **Foundation**: extend `DocumentSlotRule`/`DocumentSlot` with `whereToObtain`, `validityPeriod`, `apostilleRequired`, `swornTranslationRequired`, `sourceTaskRuleKey`. Add `Milestone`/`MilestoneRule`. Add `dependentMultiplier: Decimal?` and `incomeIncludesHousing: Bool?` to `VisaInfo`. Add anchor-date question to wizard config (one new top-level question, default `+90 days`). Wire `NotificationManager.scheduleNotification` into `EventsRepository.addEventFromTask`. Migrations + tests. | **2.0** | Every Wave-2+ feature depends on this metadata being in place. Doing it now buys 8 future features cheaper. |
| T1a-finish | Extend Documents UI to render new slot fields (where-to-obtain copy, apostille badge, translation badge). Wire slot completion → task completion mirror. | 0.5 | Slots already exist; this is finishing-touches. |
| T1b-finish | Typed milestones: category enum (expiration/appointment/milestone), color in Calendar, push notification on emit, anchor-date question wired. Backfill existing wizard tracks' `estimatedWeeks` into the new milestone schema where it makes sense. | 1.5 | The bug (no push on wizard events) plus the missing typed-milestone concept land together. |
| T1c-finish | Income-fit card on Wizard summary step (mirrors the Calculator's Comfortable/Tight/Below grouping). Per-dependent math via `dependentMultiplier`. Fix `VisaCatalog.swift:39` NLV prose ambiguity. | 1.0 | Closes the reverse direction so income-fit shows on whichever surface the user is on. |
| TH | **Test harness**: new `GoThereTests` target in `project.yml`, basic test for `WizardRepository.generateSlots` (idempotency), `EventsRepository.addEventFromTask` (notification scheduled), schema migration test (existing users' slots survive new fields), date-math test for milestones across time zones. | 1.0 | Mission guardrail. |
| QA | App Store readiness: privacy nutrition label review, "What's New" draft, manual run through Wizard → Calc → Decision Tree → Documents flow. | 0.5 | Pre-merge polish. |

**Wave 1 total: ~6.5 dev days.** Realistic operator throughput: 2–3 weeks calendar.

**Risk flags:**
- *Schema migration risk*: medium. Existing users have `DocumentSlot` docs without the new fields. Firestore is schemaless on read, so missing fields default to nil on `Codable` decode. Backfill is a one-shot batch update on app first-launch (already a pattern: see Android `KEY_LINKS_BACKFILLED`).
- *Push permission denial*: low. If denied, milestones still show on calendar; only reminders are skipped.
- *Codemagic test step*: medium. Adding `xcodebuild test` to the pipeline can flake on first integration. Mitigation: add the test step as `non-blocking` for first 1-2 runs, then promote to blocking once green.

## Wave 2 — next session (~5 dev days)

**Goal:** deepen the high-value visa pathways the operator personally lives + add the AI entry point now that the data model is rich enough to inform it.

| ID | Feature | Effort | Notes / dependencies |
| --- | --- | --- | --- |
| T1g | **Self-Employed / Autónomo deepening**: structured tax-regime field (Beckham Law eligibility, autónomo cuota tiers), real-journey extension covering autónomo registration timeline. Tax-pre-move foundation hook (so T1i can stack on this). | 1.5 | Spain `es_autonomo` + Portugal `pt_d2` tracks exist; this is content + small schema add. Highest credibility content because the operator lives this visa. |
| T1f | **Citizenship-by-Descent deepening**: structured eligibility-rule field per country (4-generation rule for Italy, grandparent rule for Ireland, etc.). Hook for the operator's separate `eligibility-engine` backend project. Add 1989 cutoff-line warning for Italian Jure Sanguinis. | 1.5 | All 7 CBD tracks exist; this adds the eligibility structured layer. Rides Bill C-3 / Italian DL 36/2025 news cycle — surface that volatility in Real Journey. |
| T1e | **AI conversational entry point**: "I don't know where to start" CTA from Home. Calls Claude API with tool-use to invoke `VisaRecommender`, `CostDatabase.cities(for:)`, and `WizardRepository.tracksForCountry`. Streaming response. Paywall after first 5 messages for non-Pro users. | 2.0 | Net new. Needs `Services/AIService.swift` + API key in app config (Codemagic env). Use `claude-sonnet-4-6` or whatever is current at the time of build. |

**Wave 2 risk flags:**
- *API key handling*: do not embed the key in the binary. Recommend a thin Cloud Function or backend proxy. Cost: ~0.5 dev day for the proxy.
- *AI tool-use guardrails*: must not give legal advice. System prompt enforces "informational, verify with official sources" framing.

## Wave 3 — session N+2 (~5 dev days)

**Goal:** the document-heavy layer + the verified-content layer that turns GoThere into a planning tool people refer to weekly, not once.

| ID | Feature | Effort | Notes |
| --- | --- | --- | --- |
| T1h | **Apostille / sworn-translation tracker**: surface the new slot fields (`apostilleRequired`, `swornTranslationRequired`) as status sub-steps inside each Document slot. Status enum extension: `pending` → `obtained` → `apostilled` → `translated` → `submitted`. | 2.0 | Depends on Wave 1 foundation. |
| T1d | **Decision Tree → Wizard handoff (deepen)**: currently `VisaRecommender` routes via `wizardTrackId`. Add an interstitial "Here's why we recommended X" explanation card pulling from the structured rules introduced in Wave 2. | 1.0 | Lighter than briefing assumed — handoff exists; this is the explanation layer. |
| T1k | **Verified-as-of-date on Resources**: new `verifiedAt: Date?` field on `Resource`. Surface a "Verified MMM YYYY" pill or "Verify with official source" warning if > 90 days old. Job to refresh canonical resources (manual quarterly process; document it). | 2.0 | New model field + UI + a `_marketing/resources_audit_log.md` cadence doc. |

## Wave 4 — session N+3 (~5–7 dev days)

**Goal:** revenue-adjacent + the differentiation layer (comparison engine deepening, tax foundation, marketplace).

| ID | Feature | Effort | Notes |
| --- | --- | --- | --- |
| T1j | **Country comparison engine (deepen)**: `VisaCompareView` exists but is single-country. Add cross-country side-by-side compare (Spain DNV vs. Portugal D8 vs. Mexico Remote Work, etc.) with weighted scoring against user's `CountrySelection`-style preference profile. | 2.0 | Schema for preference profile + UI table. |
| T1l | **Attorney / genealogist referral marketplace**: directory model, FTC affiliate disclosure copy, paid-placement vs. organic distinction. Initial population: 5-10 vetted entries per country. **App Store risk**: medium — affiliate marketplaces can trigger reviews around "advisor recommendations" if framed as advice. Frame as directory only. | 2.5 | New `Referral` model, `ReferralsView`, `_marketing/referrals_vetting.md` policy doc. Revenue model decision needed first (subscription vs. per-lead vs. flat-fee partnerships). |
| T1i | **Tax pre-move planner (foundational)**: US-side checklist module — residency exit date (last day in US state), FEIE eligibility check, FBAR threshold awareness ($10K aggregate), FATCA threshold, state-exit (CA/NY) caveats. Defer foreign-side tax planning to Wave 5+ because rules vary too widely. | 2.5 | Net new module. **Risk**: tax framing. Must say "informational" hundreds of times; lawyer-reviewed copy if budget allows. |

## Wave 5+ — Tier 2 (sequence by user-feedback signal)

After Tier 1 ships, sequence Tier 2 by what users actually ask for in App Store reviews + support email. The proposed order if no signal exists:

| ID | Feature | Effort | Rationale for order |
| --- | --- | --- | --- |
| T2c | Banking pre-move (expat-friendly accounts, US address strategy) | 1.5 | Cheap, high-value, no regulatory risk. |
| T2g | Currency transfer cost calculator (Wise/Revolut/etc.) | 1.0 | Cheap, high-value, paid-affiliate revenue potential. |
| T2d | FBAR/FATCA compliance tracker | 2.0 | Stacks on T1i. |
| T2e | Voting from abroad | 1.0 | Cheap, civic, US election cycle visibility. |
| T2f | Social Security totalization | 1.5 | High-value for retirees; agreements matter to Spain/Portugal/Mexico subset. |
| T2b | International moving logistics (customs, pets, drivers license) | 2.5 | Wide scope; ship as separate modules per topic. |
| T2a | Healthcare planning (COBRA + destination + ACA reporting) | 2.5 | Complex; needs US-side + destination-side knowledge. |
| T2h | Real estate exploratory (Idealista, Imovirtual, realtor.ca) | 3.0 | API access concerns; web-link out is cheaper than API integration. |
| T2i | Community feed | 5.0+ | Highest cost. Only ship after Tier 1 + meaningful retention signal. Moderation, abuse reports, age-gating — App Store risk and ongoing ops cost. |

## Sequencing rationale — why this order

1. **Foundation must land first** because every wave after Wave 1 needs richer metadata. Skipping foundation forces every later wave to re-do schema work.
2. **Operator-credibility content (Wave 2) before AI** would be reasonable but AI rides the LLM-feature news cycle better, so they ship together.
3. **Document layer (Wave 3) before marketplace (Wave 4)** because document tracking is in the core promise; marketplace is monetization, which needs the core to be sticky first.
4. **Tax foundation (Wave 4) before tax detail (Wave 5+)** because the US side is universal and applies to all users; foreign side varies wildly and is high-risk to ship without lawyer review.
5. **Community feed last** because the moderation overhead is permanent — only ship after Tier 1 retention proves users want to stay.

## Things this plan deliberately doesn't promise

- Wave timing in calendar weeks. Throughput varies; the dev-day estimates above are the planning unit.
- "Wave 1 ships in this session." This session produces the PR. The operator ships when ready.
- Any backend / web app changes. Mission scope is iOS-only in this session.

## What needs operator sign-off before Phase 2

1. The wave sequencing above. If you want T1e (AI) bumped to Wave 1, say so now — it's a 2-day add but doable inside this session if foundation lands first.
2. The decision to ship `T1a-finish` / `T1b-finish` / `T1c-finish` as *deepening* rather than *new* in Wave 1, given the audit finding.
3. The "non-blocking on first 1-2 runs" approach for Codemagic test step.
