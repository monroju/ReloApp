# GoThere v1.7.0 — Foundation + Wave 1

## App Store "What's New" copy (operator-facing draft)

Short form (60-char ASC limit):
> Wizard now schedules milestones + apostille tracking

Long form (≤ 4000 chars):
> Big plumbing release for visa planners.
>
> Visa Wizard now schedules milestone reminders on your Calendar, anchored to the date you pick. Each milestone is color-coded by type — red for hard deadlines (TIE 30-day post-arrival), orange for document expirations (FBI background check 90 days), teal for consulate appointments, green for milestones reached.
>
> Documents tab now surfaces where each document comes from, how long it stays valid, and whether you need an apostille or sworn translation. Required-document slots map directly to your visa's checklist.
>
> Cost Calculator gained a dependents stepper so the affordable-visas section computes the correct family-adjusted income threshold (Spain NLV scales +25% per dependent, for example — and Spain DNV adds +75% for spouse, +25% per child).
>
> Visa Wizard summary now shows the dependent-adjusted income requirement before you tap "Add to my checklist."
>
> Behind the scenes: typed milestones, anchored scheduling, a Combine event bus, and a new test harness running on every CI build.

## Privacy nutrition label changes
None. No new data categories collected. The new Schema additions
(documentSlot enrichment, milestone metadata, dependent count) all live
in the same `users/{uid}/...` subcollections that were already disclosed:
- Health & Fitness: still none
- Financial Info: still none (no income/account data collected; user enters
  monthly figures locally for the Cost Calculator, never transmitted)
- Identifiers: still User ID (Firebase Auth uid)

## QA checklist before TestFlight push

- [ ] Build green on Codemagic (`ios-simulator-build`)
- [ ] XCTest step green (`ignore_failure: true` for first 1-2 runs; promote after)
- [ ] Smoke: run Spain NLV wizard end-to-end, confirm milestones appear on Calendar with correct colors
- [ ] Smoke: FBI slot in Documents shows "FBI website", "90 days", Apostille + Sworn translation badges
- [ ] Smoke: Cost Calculator dependents=2 changes the affordability bucket for Spain NLV
- [ ] Smoke: re-run wizard — slot statuses persist, milestone events upsert (no duplicates)
- [ ] Smoke: dark mode still uses brand teal accent
- [ ] Push permission prompt appears on first wizard completion (delete & reinstall to retest)

## Known limitations carried into Wave 2

- Only Spain NLV carries milestone metadata in the bundled config. Other tracks (Spain DNV/Work/Student/Family/Autónomo, Portugal D7/D8/D2, Mexico, CBD countries) need their milestone arrays populated. Backlog item for Wave 2.
- Push permission is requested AFTER scheduling on first wizard completion — first-run reminders for that wizard run are lost. Fix in Wave 2: prompt for permission on the wizard intro step.
- Documents tab "Verified" status is intentionally absent in v1; will land in Wave 3 with the apostille tracker (T1h).
