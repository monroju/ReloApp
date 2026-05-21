import Foundation

/// Registry of premium-only real-world visa journeys. Lookups are keyed by visa ID
/// (matches `VisaCatalog`) and by country ID (for fallback when a country has a
/// canonical journey but the user hasn't selected a specific visa yet).
enum RealJourneys {
    static let all: [RealJourney] = [spainDNV, spainAutonomo]

    static func forVisa(_ visaId: String) -> RealJourney? {
        all.first { $0.visaId == visaId }
    }

    static func forCountry(_ countryId: String) -> [RealJourney] {
        all.filter { $0.countryId == countryId }
    }

    // MARK: - Spain Digital Nomad Visa

    static let spainDNV = RealJourney(
        id: "spain_dnv",
        visaId: "spain_dnv",
        countryId: "spain",
        title: "Spain Digital Nomad Visa",
        subtitle: "Family of four · real 2023 case · 7-month journey",
        totalDuration: "~7 months from first consult to TIE card in hand",
        feeSummary: "Law firm retainer ≈ €4,500 for a family of four. Typical split: 60% on engagement, 40% on residence-permit pickup. Lease review and tax/Beckham Law consultations are billed separately as add-ons.",
        eligibilitySummary: [
            "Employer must have been operating for at least 12 months",
            "Employment relationship at least 3 months old at submission",
            "Documented remote-work capability (employer letter or contract clause)",
            "Income floor: roughly €2,000/month base + ~€750 for first family member + ~€250 per additional dependant",
            "Clean criminal record (apostilled background check from country of origin)"
        ],
        phases: [intakePhase, submissionPhase, correctionsPhase, arrivalPhase, empadronamientoPhase, tiePhase, healthcarePhase, taxPhase],
        crossPhaseGotchas: [
            JourneyGotcha(
                id: "g_appointments",
                title: "Appointment volume scales by family size",
                detail: "A family of four needs 8 total in-person appointments at the police station (4 fingerprint slots + 4 card-pickup slots). Book consecutive same-day slots wherever possible — gestores often handle this."
            ),
            JourneyGotcha(
                id: "g_30day",
                title: "The '30-day TIE deadline' refers to booking, not attending",
                detail: "Spanish admin accepts a confirmed appointment receipt dated within 30 days of the resolution, even if the actual fingerprint date is months later. This relieves the pressure if local police slots are scarce."
            ),
            JourneyGotcha(
                id: "g_tasa",
                title: "Tasa 790-012 is paid in cash, day-of, before 11 AM",
                detail: "Not online. Not the day before. Walk into any Spanish bank the morning of your appointment with the printed form, pay in cash, get it stamped, then go to the police station. Miss the window and you reschedule."
            ),
            JourneyGotcha(
                id: "g_padron",
                title: "Empadronamiento generally won't accept Airbnb addresses",
                detail: "Most town halls require a signed long-term lease already in force. Align your arrival timing so your lease has started before you attempt Padrón registration."
            ),
            JourneyGotcha(
                id: "g_disclaimer",
                title: "Province-specific variation is real",
                detail: "Wait times and document requirements differ by province. The timing in this journey reflects Málaga/Andalucía — Barcelona, Madrid, and Valencia can be longer."
            )
        ],
        disclaimer: "Illustrative content based on a real 2023 family case (US → Málaga). Not legal advice. Visa rules, fees, and processing times change — verify with a licensed Spanish immigration lawyer before acting."
    )

    // MARK: Phases

    private static let intakePhase = JourneyPhase(
        id: "p_intake",
        order: 1,
        title: "1. Intake & Engagement",
        timeframe: "Week 1",
        summary: "Initial consultation with a Spanish immigration law firm. The firm assesses eligibility, sends a fee quote, and (on payment) introduces the assigned case handler. Expect a 30-minute video call before any paperwork.",
        documents: [
            "Passport bio-page scans for all family members",
            "Recent payslips (3 months) or proof of self-employment income",
            "Employer letter confirming remote-work allowance and tenure",
            "Marriage certificate (if applying as family)",
            "Birth certificates for dependants",
            "Background check from country of origin (apostilled, recent)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_intake_1", situation: "Initial pitch", phrasing: "We recap your eligibility against the income, tenure, and remote-work tests."),
            LawyerPattern(id: "lp_intake_2", situation: "Fee proposal", phrasing: "Quote arrives by email with itemized scope and a split-payment option."),
            LawyerPattern(id: "lp_intake_3", situation: "Case handler intro", phrasing: "Originating advisor CCs the assigned lawyer and remains available as backup contact.")
        ],
        gotchas: [
            "Tax-advisor referrals are inside the same firm but separately billed — quote arrives via a Tax Questionnaire link",
            "The intake advisor often isn't your case handler — expect a deliberate, named handover within a few days"
        ]
    )

    private static let submissionPhase = JourneyPhase(
        id: "p_submission",
        order: 2,
        title: "2. Document Gathering & Submission",
        timeframe: "Weeks 2–6",
        summary: "The law firm commissions sworn translations of every non-Spanish document, prepares the dossier, and submits to the Unidad de Grandes Empresas y Colectivos Estratégicos (UGE-CE). You ship apostilles, payslips, and bank statements to the firm as you collect them.",
        documents: [
            "Apostilled background check (recent, country of origin)",
            "Sworn Spanish translations of: payslips, employer letter, contracts, civil status docs",
            "Bank statements showing financial means (last 3–6 months)",
            "Private Spanish health insurance policy proof",
            "Application forms (firm prepares — you sign)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_sub_1", situation: "Translation hand-off", phrasing: "Firm forwards docs to their sworn translator and bills the translation through."),
            LawyerPattern(id: "lp_sub_2", situation: "Pre-submission checklist", phrasing: "Final email enumerates every dossier component and asks for confirmation."),
            LawyerPattern(id: "lp_sub_3", situation: "Submission proof", phrasing: "After filing, the firm sends a PDF receipt as evidence of the submission date.")
        ],
        gotchas: [
            "Sworn translations are billed at per-page rates — expect €30–€60/page, paid via the firm",
            "Health insurance must be private + co-pay-free for residency purposes — generic travel policies are rejected"
        ]
    )

    private static let correctionsPhase = JourneyPhase(
        id: "p_corrections",
        order: 3,
        title: "3. Subsanación (Admin Corrections)",
        timeframe: "Variable, 0–4 weeks after submission",
        summary: "Spain's UGE-CE may raise a requerimiento de subsanación — a formal request for additional or corrected documents. The window to respond is short: typically 5 business days. The lawyer drafts the response and resubmits.",
        documents: [
            "Whatever the admin specifically flagged (commonly: re-translated payslips, updated financial means proof)",
            "Translator's amended sworn declaration if a prior translation was deficient"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_corr_1", situation: "Subsanación notification", phrasing: "Firm forwards the admin's notice and proposes a fix plan that same day."),
            LawyerPattern(id: "lp_corr_2", situation: "Vacation handover", phrasing: "Outgoing lawyer names the covering colleague before any deadline lands.")
        ],
        gotchas: [
            "The 5-business-day clock can include a weekend — read the notice's exact date carefully",
            "Re-translation costs are not always included in the original retainer — confirm before paying"
        ]
    )

    private static let arrivalPhase = JourneyPhase(
        id: "p_arrival",
        order: 4,
        title: "4. Resolution & Arrival in Spain",
        timeframe: "1–6 weeks after submission",
        summary: "The admin issues a resolution granting the residence permit. The lawyer emails the resolution PDF. You now have 30 days to book the TIE fingerprint appointment (booking-not-attending — see gotcha above). Time your flights to land after your lease is signed.",
        documents: [
            "Resolution letter (PDF from the firm)",
            "Signed long-term lease (originals, both parties)",
            "Flight itinerary to align with lease start date"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_arr_1", situation: "Approval notification", phrasing: "Often delivered with all-caps celebration line and an emoji."),
            LawyerPattern(id: "lp_arr_2", situation: "Next-steps brief", phrasing: "Firm attaches a step-by-step PDF for Padrón, TIE, and arrival logistics.")
        ],
        gotchas: [
            "Some firms include arrival logistics in the retainer; others charge it as 'final-step assistance'",
            "Resolution validity has a ticking 30-day clock for the TIE booking — don't wait past week 3"
        ]
    )

    private static let empadronamientoPhase = JourneyPhase(
        id: "p_padron",
        order: 5,
        title: "5. Empadronamiento (Padrón)",
        timeframe: "Within first 2 weeks of arrival",
        summary: "Register your address at the local town hall. The Padrón certificate is required for the TIE appointment and for nearly every subsequent administrative step (school enrolment, healthcare card, driver's licence exchange).",
        documents: [
            "Municipal Padrón form (city-specific — download from town hall site)",
            "Original passports for every family member",
            "Signed rental contract, currently in force",
            "Recent utility bill or rent-payment proof (often required, not always)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_pad_1", situation: "City-specific guidance", phrasing: "Firm sends the exact PDF form for your municipality and the booking link.")
        ],
        gotchas: [
            "Some cities require an appointment booked online weeks in advance — check first",
            "Padrón certificate must be issued within the last 3 months for the TIE appointment"
        ]
    )

    private static let tiePhase = JourneyPhase(
        id: "p_tie",
        order: 6,
        title: "6. TIE Card Issuance",
        timeframe: "4–10 weeks after fingerprints",
        summary: "Two appointments at the National Police (CNP): a fingerprint appointment, then a card-pickup appointment ~4–6 weeks later (the card is printed in Madrid). Each family member needs their own slot for each step.",
        documents: [
            "Form EX-17 (firm provides)",
            "Tasa 790-012 fee form, paid in cash at a Spanish bank the morning of the appointment",
            "Recent passport photo on white background",
            "Passport + photocopy",
            "Resolution letter granting the permit",
            "Empadronamiento certificate (within last 3 months) + photocopy",
            "Appointment receipt printout"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_tie_1", situation: "Slot scarcity update", phrasing: "Firm polls for cancellations weekly and re-books earlier if one opens."),
            LawyerPattern(id: "lp_tie_2", situation: "Pickup confirmation", phrasing: "Admin assistant emails when the card is printed and ready for pickup.")
        ],
        gotchas: [
            "High-demand cities (Barcelona, Madrid) may have a 6–8 week wait for the first available slot",
            "Bring physical photocopies — many police stations don't have working copiers",
            "Children get a slightly shorter validity period than parents on the first card — this is normal"
        ]
    )

    private static let healthcarePhase = JourneyPhase(
        id: "p_health",
        order: 7,
        title: "7. Private Health Insurance Certificate",
        timeframe: "Renewed annually",
        summary: "Non-EU residents not enrolled in Seguridad Social must show continuous private coverage with no co-pays and no coverage gaps. The 'Conditions Certificate' + payment receipt from your Spanish private insurer is what immigration accepts as proof.",
        documents: [
            "Active policy with a Spain-based insurer (e.g. Sanitas, ASSSA, DKV, Adeslas)",
            "Conditions Certificate naming every insured family member and the policy year",
            "Payment receipt showing premiums paid for the current year",
            "Copies of every family member's NIE/TIE (insurer needs these before issuing the certificate)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_hc_1", situation: "Insurer request", phrasing: "Email your assigned commercial agent — generic info@ inboxes take longer."),
            LawyerPattern(id: "lp_hc_2", situation: "Turnaround", phrasing: "Local branch typically quotes 24 hours from head office, then postal delivery.")
        ],
        gotchas: [
            "Insurer may default to postal mail — confirm your current Spanish address explicitly",
            "Multi-policy households (adults + kids on separate plans) need to list every policy number"
        ]
    )

    private static let taxPhase = JourneyPhase(
        id: "p_tax",
        order: 8,
        title: "8. Tax & Beckham Law (Optional Parallel)",
        timeframe: "Within first 6 months of residency",
        summary: "DNV holders can apply for the Beckham Law regime — a special tax status that caps non-Spanish income at a flat ~24% rate for the first 6 years. The window to apply is narrow. Most immigration firms have an internal tax department that handles this; you complete a separate tax questionnaire and get a separate quote.",
        documents: [
            "Modelo 149 (Beckham application form — firm prepares)",
            "Proof of employment relationship and start date",
            "DNV resolution + TIE",
            "Padrón certificate"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_tax_1", situation: "Cross-referral", phrasing: "Immigration lawyer forwards a tax questionnaire link from the tax team."),
            LawyerPattern(id: "lp_tax_2", situation: "Capacity disclosure", phrasing: "Firm may flag department-level delays in advance so you can plan timing.")
        ],
        gotchas: [
            "Beckham must be applied for within 6 months of starting Spanish residency — miss it and you wait years",
            "Beckham is rarely the right choice if most income is from Spanish sources — model both scenarios first"
        ]
    )

    // MARK: - Spain Autónomo (Self-Employed)
    //
    // Wave 2 — Autónomo deepening. Walks an arrival-week registration with Hacienda
    // and the Tesorería General de la Seguridad Social, the first-year tarifa plana
    // window, and the trimestral filing cadence. Anonymised composite from two
    // gestoría engagements observed in 2024–2025.

    static let spainAutonomo = RealJourney(
        id: "spain_autonomo",
        visaId: "es_autonomo",
        countryId: "spain",
        title: "Spain Self-Employed (Autónomo)",
        subtitle: "Solo founder · 2024 case · alta to first IVA filing",
        totalDuration: "~5 months from arrival to first clean trimestral",
        feeSummary: "Gestoría retainer ≈ €80–€120/month for ongoing IRPF + IVA filings. Initial alta package (Modelo 037 + RETA registration) is typically a one-off €150–€250. Optional Beckham application via an in-firm tax department is billed separately.",
        eligibilitySummary: [
            "Already hold a Spanish residence permit allowing self-employed work (Autónomo, DNV, family-reunified with work rights)",
            "Plan to invoice from Spain — autónomo registration is mandatory before issuing the first Spanish-resident invoice",
            "NIE/TIE issued before alta — Hacienda and the TGSS will not register an alta without it",
            "Spanish bank account ready to receive direct-debit IRPF and IVA payments"
        ],
        phases: [autonomoPreparePhase, autonomoHaciendaPhase, autonomoSocialSecurityPhase, autonomoFirstQuarterPhase, autonomoYearEndPhase],
        crossPhaseGotchas: [
            JourneyGotcha(
                id: "g_aut_calendar",
                title: "The trimestral calendar runs on a Spanish, not a foreign, fiscal year",
                detail: "IRPF Modelo 130 and IVA Modelo 303 are due by the 20th of January, April, July, and October. There is no quarterly extension and the AEAT direct-debit window closes on the 15th — set your gestoría a working buffer."
            ),
            JourneyGotcha(
                id: "g_aut_tarifa_plana",
                title: "Tarifa Plana stacks with the autónomo cuota — choose the right alta date",
                detail: "The flat €80/mo first-12-month cuota applies from your alta date forward, not from the calendar year. Time your alta so it lands on a month boundary; mid-month altas truncate the first month."
            ),
            JourneyGotcha(
                id: "g_aut_epigrafe",
                title: "The IAE epígrafe is sticky once filed",
                detail: "The activity code (epígrafe) on Modelo 037 drives which IRPF section applies and whether IVA is exempt. Changing it later is a Modelo 037 update — not a manual edit on the next return."
            ),
            JourneyGotcha(
                id: "g_aut_invoices_before_alta",
                title: "Invoices dated before alta are not deductible",
                detail: "Pre-alta expenses (laptop, lawyer fees, gestoría intake) only deduct against IRPF when invoiced after the alta date. Hold expense receipts until alta is confirmed."
            ),
            JourneyGotcha(
                id: "g_aut_disclaimer",
                title: "Tax position depends on your full picture",
                detail: "Beckham Law, autónomo Tarifa Plana, and a separate sociedad limitada (SL) can all be the right answer — or the wrong one — depending on revenue and client mix. Have a tax advisor model both an autónomo and SL scenario before you elect."
            )
        ],
        disclaimer: "Illustrative content based on anonymised 2024 cases (US founders setting up in Spain). Not legal or tax advice. Spanish tax law and social-security thresholds change every fiscal year — verify with a licensed gestor or tax advisor before acting."
    )

    private static let autonomoPreparePhase = JourneyPhase(
        id: "p_aut_prepare",
        order: 1,
        title: "1. Pre-alta Preparation",
        timeframe: "Week 0 (before arrival or in week of arrival)",
        summary: "Engage a gestoría, decide your activity epígrafe(s), and confirm NIE/TIE. The gestoría drafts Modelo 037 and the TGSS alta forms so they can be filed the same day you walk in.",
        documents: [
            "Valid NIE or TIE",
            "Spanish bank account IBAN (or non-resident account during transition)",
            "Description of intended business activity (used to pick the IAE epígrafe)",
            "Identity document of the gestor you are appointing"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_aut_intake", situation: "Initial scoping", phrasing: "Gestor confirms the right autónomo route after a 20-minute video call."),
            LawyerPattern(id: "lp_aut_epigrafe", situation: "Epígrafe selection", phrasing: "Gestor proposes one primary plus one optional secondary IAE code."),
            LawyerPattern(id: "lp_aut_power", situation: "Power of attorney", phrasing: "You sign an apoderamiento so the gestor can file Modelos 037 and TA.0521 on your behalf.")
        ],
        gotchas: [
            "Without a NIE you cannot proceed — finish that step before booking a gestoría engagement",
            "Pick the gestor before signing any apartment lease — they will need the address on Modelo 037"
        ]
    )

    private static let autonomoHaciendaPhase = JourneyPhase(
        id: "p_aut_hacienda",
        order: 2,
        title: "2. Hacienda — Modelo 037 (or 036)",
        timeframe: "Week 1",
        summary: "Register as an empresario individual with the Agencia Tributaria via Modelo 037 (simplified) or 036 (full). Filing assigns your IAE activity code, declares IRPF and IVA obligations, and opens the door to the trimestral filing calendar.",
        documents: [
            "Modelo 037 or 036 (gestoría prepares from the apoderamiento)",
            "DNI/NIE and proof of address",
            "IAE epígrafe documentation (gestoría supplies)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_aut_037", situation: "Form submission", phrasing: "Gestoría submits Modelo 037 electronically and emails a stamped PDF receipt."),
            LawyerPattern(id: "lp_aut_iae", situation: "Activity confirmation", phrasing: "Gestoría confirms the assigned epígrafe in writing for your records.")
        ],
        gotchas: [
            "Use Modelo 036 (not 037) if you will collect intra-EU VAT or charge IVA-exempt services",
            "The alta date you pick on Modelo 037 is the date your trimestral calendar starts — pick the 1st of a month"
        ]
    )

    private static let autonomoSocialSecurityPhase = JourneyPhase(
        id: "p_aut_ss",
        order: 3,
        title: "3. Seguridad Social — RETA Alta",
        timeframe: "Week 1 (same week as Hacienda)",
        summary: "Register with the Régimen Especial de Trabajadores Autónomos via Modelo TA.0521 at the Tesorería General de la Seguridad Social. Elect a contribution base and — if eligible — opt into Tarifa Plana to lock in the €80/mo first-year cuota.",
        documents: [
            "Modelo TA.0521 (gestoría prepares)",
            "Modelo 037 receipt from Hacienda (TGSS will not accept the alta without it)",
            "Spanish bank IBAN for the direct-debit cuota",
            "Tarifa Plana election form (if applicable)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_aut_reta", situation: "TGSS submission", phrasing: "Gestoría submits TA.0521 with effective date matching the Hacienda alta."),
            LawyerPattern(id: "lp_aut_base", situation: "Contribution base selection", phrasing: "Gestor recommends the minimum base for year one unless pension contributions matter to you."),
            LawyerPattern(id: "lp_aut_tarifa", situation: "Tarifa Plana opt-in", phrasing: "Gestor flags whether your prior autónomo history disqualifies the flat rate.")
        ],
        gotchas: [
            "Once you miss Tarifa Plana at alta you cannot retro-apply — confirm eligibility before the form is submitted",
            "Choosing too high a contribution base costs real money for years — the minimum base is the right default unless you have a specific reason"
        ]
    )

    private static let autonomoFirstQuarterPhase = JourneyPhase(
        id: "p_aut_q1",
        order: 4,
        title: "4. First Trimestral Cycle",
        timeframe: "Months 1–4 after alta",
        summary: "File your first IRPF (Modelo 130) and IVA (Modelo 303) returns by the 20th of the first month after the quarter ends. The gestoría typically takes invoices monthly and files quarterly; you confirm the totals before they submit.",
        documents: [
            "Invoices issued during the quarter (gestoría intake)",
            "Deductible expense receipts (gestoría intake)",
            "Modelo 130 + Modelo 303 (gestoría prepares from the intake)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_aut_intake_monthly", situation: "Monthly intake", phrasing: "Gestoría requests the prior month's invoices and receipts by the 5th."),
            LawyerPattern(id: "lp_aut_review", situation: "Pre-submission review", phrasing: "Gestoría emails draft returns 3 working days before the AEAT deadline.")
        ],
        gotchas: [
            "AEAT direct debit closes on the 15th — late confirmations push you to a manual transfer with a 5% surcharge",
            "First-quarter IVA is sometimes a zero filing — file it anyway, omissions trigger an automatic SII alert"
        ]
    )

    private static let autonomoYearEndPhase = JourneyPhase(
        id: "p_aut_year_end",
        order: 5,
        title: "5. Year-End: Modelos 390 & Renta",
        timeframe: "January–June after first calendar year",
        summary: "Modelo 390 (annual IVA summary) is due 30 January and Modelo 100 (declaración de la renta — personal income tax) opens in April and closes 30 June. The gestoría typically prepares both; Beckham elects out via Modelo 151 instead of 100.",
        documents: [
            "Modelo 390 (annual IVA summary)",
            "Modelo 100 — declaración de la renta (or Modelo 151 if on Beckham)",
            "Annual summary of issued invoices and deductible expenses",
            "Modelo 347 (third-party transactions) if any single counterparty exceeds €3,005.06"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_aut_390", situation: "Modelo 390", phrasing: "Gestoría reconciles Modelos 303 with 390 and flags discrepancies before filing."),
            LawyerPattern(id: "lp_aut_renta", situation: "Renta", phrasing: "Gestoría drafts Modelo 100 with full deductions and asks for sign-off before AEAT submission.")
        ],
        gotchas: [
            "Modelo 347 sneaks up — third-party threshold triggers easily for SaaS suppliers and landlord rents",
            "Renta deadline is non-negotiable — missing 30 June triggers automatic recargos plus interest"
        ]
    )
}
