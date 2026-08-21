# Paid → Free-with-IAP flip: console checklist

Status as of 2026-08-21 (verified live):

| Store | Install price | Ratings |
|---|---|---|
| App Store `id6760248690`, v1.9.2 | $2.99 / 2,99 € | **0** |
| Google Play `com.gothere.app` | **$3.99 "Buy"** | no install band shown |

Both stores charge to install *and* charge again to unlock countries. This checklist
removes the first charge on iOS. Android is deliberately **not** included — see the
warning at the bottom.

---

## 0. Before anything: the one-way doors

- **Google Play paid → free is irreversible.** Once `com.gothere.app` is set to free it
  can never be paid again. Do iOS first, read the numbers, then decide on Play.
- **App Store paid → free is reversible.** You can flip back any time. This is the safe
  place to run the experiment.
- **No new binary is required on iOS**, and the change takes effect immediately.
  (`pricing_strategy.md` claims a binary submission is needed — that is wrong, per
  Apple's "Set a price" documentation. It is a Price Schedule edit, nothing more.)

### Sequencing: flip the price first, ship the grandfathering build second

This is safe, and it opens the funnel a full review cycle earlier. The reason it's safe:
a $2.99 paid install currently grants **Spain + Canada only** — every other country is a
separate IAP. So going free takes nothing away from existing buyers; the grandfathering
build only *adds* value (all-access) once it lands. There is no window in which a paying
customer is worse off.

---

## 1. Code (done — needs two constants filled in)

Grandfathering is implemented in `GoThere/Services/LegacyEntitlementService.swift` and
wired into `PurchaseManager.hasAllAccess`, which is the single gate every content check
already runs through (`isCountryUnlocked`, DocumentScan, RealJourney, AI chat quota,
Resources). No call sites changed.

**Both constants are set — no action needed:**

1. `freemiumGoLiveDate` = `2026-08-22 00:00 UTC`, end of the day the price was flipped.
2. `lastPaidBuild` = `0` (disabled, intentionally). Build 60 (v1.9.2) was live on both
   sides of the flip — last paid build *and* first free build, since going free needed
   no new binary. It therefore can't tell a payer from a free installer, and enabling it
   would hand permanent all-access to every free download until the next build ships.
   The date is the only signal that discriminates here.

Behaviour: grant-only. `AppTransaction` returning "unknown" (offline, no local
transaction) never revokes access. The flag mirrors to Firestore
`users/{uid}.legacyPaidInstall` so it follows the account to a second device, and to
UserDefaults so a cold offline launch is correct on first render.

To exercise the path in a DEBUG/TestFlight build (where `AppTransaction` values are
synthesized), set UserDefaults `debug_force_legacy_paid_install` = true.

---

## 2. App Store Connect

1. **Verify the subscription and bundle SKUs are Approved**, not "Missing Metadata".
   The code loads all four; missing ones silently don't appear, which would ship a
   paywall with nothing to buy:
   - `com.gothere.all_access_monthly`
   - `com.gothere.all_access_annual`
   - `com.gothere.europe_bundle`
   - `com.gothere.americas_bundle`
2. Keep the legacy per-country packs (`com.gothere.*_pack`, `com.gothere.all_countries`)
   **live, not removed**. Existing owners restore through them.
3. Every subscription description must keep the **EULA line** (this has bounced
   submissions before).
4. **Monetization → Pricing and Availability → Price Schedule → Free.** Immediate, no
   binary, reversible. Do this first.
5. Build and submit the grandfathering binary with the two constants set, where
   `freemiumGoLiveDate` = the date you did step 4.
6. App Privacy / listing: the subtitle and screenshots still imply a paid product in
   places. Check `ASO/` copy for "buy"/"purchase" language aimed at the install.
7. Promotional text: say the app is now free to try. Free-install is the single biggest
   ASO conversion lever you have and it should be stated.

## 3. Post-release watch (first 14 days)

The flip fixes install volume, not conversion. Instrument before you judge it:

- `purchaseInitiated` / `purchaseCompleted` are already emitted by `PurchaseManager`.
- PaywallView already logs `has_all_access` on appear — that's your paywall-view count.
- The number that decides whether this worked: **paywall views → purchase rate**.
  Revenue per install *will* drop hard. Total revenue depends entirely on whether the
  blurred `LockedCountryPreviewView` converts.
- Review prompts are already wired (`ReviewPromptService`, triggers on first task
  completed and visa-compare viewed). With install volume unblocked these should finally
  start producing ratings. Watch that the trigger isn't firing before the user has
  gotten value.
- `FirstWeekTrialService` gives every new install Portugal free for 7 days. Day 8 is the
  real conversion moment. Expect the paywall-view spike there.

---

## 4. Google Play — NOT part of this change

Play is $3.99 "Buy" today. Flipping it is the same call on the merits, but it is
**irreversible**, so it waits until the iOS numbers are in. When you do it:

- Play Console → Monetise → Products → set app to Free (one-way, confirms twice).
- Verify `ReviewHelper.kt` in-app review flow.
- Android has **no grandfathering patch yet** — the iOS `AppTransaction` mechanism has
  no direct Play equivalent. Play's answer is checking the purchase history via the
  Play Billing Library or granting entitlement server-side off the existing
  `users/{uid}` Firestore doc. That work is not done and must be done before the Play
  flip, or existing Android buyers lose access.
