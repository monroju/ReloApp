# GoThere — App Store Update Package (Chatbot-Proof Differentiation Wave)

**Branch:** `chatbot-proof-differentiation`
**Date:** 2026-06-05
**Marketing version in repo:** 1.8.0 (operator bumps for submission)

This wave makes GoThere operational where a chatbot is only informational:
holding the user's documents and pushing before they expire, a one-tap +
reminder path into Spain's cita previa system, and a single dashboard that
cross-references visa, income, documents, tasks, and target date.

> **Framing note (important for the copy):** the Documents tab already shipped a
> document vault with apostille / sworn-translation flags and badges. This update
> *adds expiration tracking + alerts* to it — the copy below says "now alerts you"
> rather than presenting the vault as brand-new. Cita Monitor and the Co-Pilot
> dashboard are genuinely new.

---

## What's New — two variants (operator picks one)

### Variant A — bold
> GoThere now does things no AI chatbot can. Your Document Vault tracks
> expiration dates and pushes you before your FBI check, medical certificate, or
> bank statements go stale — so you never reach a consulate with an expired file.
> The new Cita Monitor gives you one-tap access to Spain's notoriously backlogged
> cita previa portals plus reminders to check when slots are released. And the new
> Co-Pilot dashboard reads your whole move at once — visa, income, documents,
> timeline, and tasks — into a single readiness score with the alerts that matter
> today. GoThere is now your move co-pilot, not just a guide.

### Variant B — understated
> • Document Vault now tracks expiration dates and alerts you 30/14/3 days before
>   anything expires.
> • New Cita Monitor: one-tap access to Spain's cita previa portals + reminders to
>   check during release windows.
> • New Co-Pilot dashboard: visa, income, documents, timeline, and tasks combined
>   into one readiness score.
> All guidance is informational — verify with official sources.

### Variant C — continuity-honest (recommended if reviewers compare against prior build)
> GoThere has always held your relocation documents — now it watches their clocks.
> Document Vault adds automatic expiration tracking with push alerts before your
> background check, medical certificate, or financials expire. New this release:
> a Cita Monitor for Spain's appointment system (one-tap portal access + check
> reminders) and a Co-Pilot dashboard that turns everything GoThere knows about
> your move into a single readiness score.

---

## Feature → store-listing mapping

| Store-facing feature | Status this wave | Notes for listing |
|---|---|---|
| Document Vault | **Existing, extended** | Vault + apostille/sworn badges already shipped; expiration tracking + push alerts are new. |
| Document expiration push alerts | **New** | Local notifications at 30/14/3 days + day-of. On-device; no server. |
| Cita Monitor | **New** | User-guided: opens the official portal + reminds you to check. GoThere does **not** book or scrape the government system — keep marketing claims to "fast access + reminders," never "we get you a slot." |
| Co-Pilot dashboard | **New** | Readiness score + compound insight cards. |

---

## Screenshot refresh (recommend updating ≥2)

1. **Document Vault with the status bar** — show the vault header pills
   ("2 complete · 1 expiring soon · 1 missing") and a row with a red/amber expiry
   chip ("Expires in 14 days"). This is the single most differentiating frame.
2. **Co-Pilot dashboard with populated cards** — readiness ring (e.g. 68 / "A few
   things need attention") plus a red document-expiry card, an amber income card,
   and a green cita card. Use realistic seed data.
3. *(Optional)* **Cita Monitor** — a saved NIE — Madrid target with "Reminders on ·
   Mon–Fri 8:30" and the "Open booking portal" button.

Suggested caption set (App Store Connect):
- "Never miss an expiry — alerts before your documents go stale."
- "Spain's cita previa, one tap away — plus reminders to check."
- "Your whole move in one readiness score."

---

## Privacy nutrition label — review

No new **transmitted** data types are introduced:

- **Documents** and their expiration metadata: already covered by the existing
  Firebase Storage/Firestore document handling (user content the user uploads).
  Expiration dates/flags are additional fields on the same already-declared data.
- **Cita monitors** (appointment type + province + reminder prefs): stored
  **locally only** (UserDefaults) — not transmitted, so no new collection
  category.
- **Calculator monthly cost** persisted for the dashboard: stored **locally**
  (UserDefaults). Not transmitted.
- **Local notifications**: on-device scheduling; not a data-collection type.

**Action:** no label change is expected, but confirm the existing "User Content"
declaration covers stored documents, and that nothing here flips a "Data Used to
Track You" toggle (it does not — all new state is local or already-declared).

---

## Review notes (App Store Connect "Notes for Reviewer")

- All validity periods, income thresholds, and document rules are **informational**
  and shown with a "verify with official sources" caveat — no legal/financial
  advice is given.
- **Cita Monitor does not automate or access** the Spanish government booking
  system. It deep-links the user to the official public portal and schedules local
  reminders to check manually. No scraping, no credentials, no automated booking.
- Document expiration alerts are **local notifications** scheduled on-device;
  push permission is requested in-context on first document upload and the app
  degrades gracefully if denied (in-app chips/header replace the push).

---

## Pre-submission checklist (operator)

- [ ] Run `xcodegen` (folder-glob target auto-registers the new Swift files) and
      build in Xcode 26.
- [ ] Run the test suite (`GoThereTests`) — new pure-logic tests:
      `DocumentVaultTests`, `CitaMonitorTests`, `CoPilotEngineTests`.
- [ ] Verify notification permission prompt copy on first upload on device.
- [ ] Confirm `aps-environment = production` entitlement unchanged (it is).
- [ ] Capture refreshed screenshots (above) on a seeded account.
- [ ] If subscriptions remain enabled, keep the EULA link in the Description
      (3.1.2 — see `gothere-v170-subscriptions`).
- [ ] Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml`.
