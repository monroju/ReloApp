import Foundation

/// Registry of premium-only real-world visa journeys. Lookups are keyed by visa ID
/// (matches `VisaCatalog`) and by country ID (for fallback when a country has a
/// canonical journey but the user hasn't selected a specific visa yet).
enum RealJourneys {
    static let all: [RealJourney] = [spainDNV, spainAutonomo, italyJureSanguinis, irelandFBR]

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

    // MARK: - Italy Jure Sanguinis
    //
    // Wave 2 — Ancestry deepening. Post-Decree-Law 36/2025 (converted by Law
    // 74/2025) the consulate path collapsed for great-grandparent lines. This
    // journey walks the post-reform document chain and the Court of Rome
    // fallback for 1948 maternal-line cases. Anonymised composite from two
    // observed 2024-2025 engagements with Italian citizenship lawyers.

    static let italyJureSanguinis = RealJourney(
        id: "italy_jure_sanguinis",
        visaId: "it_jure_sanguinis",
        countryId: "italy",
        title: "Italy Citizenship by Descent (Jure Sanguinis)",
        subtitle: "Grandparent line · 2025 case · 14-month journey",
        totalDuration: "~14 months from comune request to Italian passport in hand",
        feeSummary: "Italian citizenship lawyer retainer ≈ €3,500-€6,000 for a clean consulate case; €8,000-€15,000+ for a 1948 Court of Rome filing. Document costs (apostilles, sworn translations, GRO-equivalent civil records) add another €800-€2,000.",
        eligibilitySummary: [
            "Italian-born parent or grandparent in your line (post-DL 36/2025 cap)",
            "Citizenship chain not broken by ancestor's naturalisation before the next generation in line was born",
            "1948 case (maternal line where child was born before 1 January 1948) requires Court of Rome action — no consulate route",
            "Application filed before 23:59 Rome time on 27 March 2025 falls under the pre-reform rules"
        ],
        phases: [italyEligibilityPhase, italyDocumentChainPhase, italyApostillePhase, italyTranslationPhase, italyFilingPhase, italyRegistrationPhase],
        crossPhaseGotchas: [
            JourneyGotcha(
                id: "g_it_dl36",
                title: "DL 36/2025 closed the great-grandparent consulate path",
                detail: "If your line runs through a great-grandparent or further back, the consulate will not process you under the post-March-2025 rules. A specialist lawyer can advise whether a Court of Rome filing or a different track remains open."
            ),
            JourneyGotcha(
                id: "g_it_chain_break",
                title: "Naturalisation timing is the single most common chain-break",
                detail: "Your Italian-born ancestor must NOT have naturalised as a US citizen before the next generation in the line was born. Verify the exact naturalisation date via the USCIS Genealogy Program before paying for document apostilles."
            ),
            JourneyGotcha(
                id: "g_it_1948",
                title: "1948 maternal-line cases route to the Court of Rome",
                detail: "A line passing through a female ancestor whose child was born before 1 January 1948 cannot be processed at a consulate. A 1948 case is filed in the Court of Rome through an Italian lawyer."
            ),
            JourneyGotcha(
                id: "g_it_comune_speed",
                title: "Italian comune turnaround varies widely",
                detail: "Some comune offices respond to mailed certified-mail requests within 6 weeks; others take 6+ months. A lawyer with on-the-ground contacts (or a relative in Italy) can shave months off the chain."
            ),
            JourneyGotcha(
                id: "g_it_disclaimer",
                title: "Verify with a lawyer before relying on this",
                detail: "Italian citizenship-by-descent rules are still in active change after DL 36/2025 and the Constitutional Court's 12 March 2026 ruling. Do not rely on this journey as authoritative — confirm your specific eligibility with a licensed Italian citizenship lawyer."
            )
        ],
        disclaimer: "Illustrative content based on anonymised 2024-2025 grandparent-line cases. Not legal advice. Italian citizenship law is in active change — verify the current statutory framework with a licensed Italian lawyer before paying any fees."
    )

    private static let italyEligibilityPhase = JourneyPhase(
        id: "p_it_eligibility",
        order: 1,
        title: "1. Eligibility Verification",
        timeframe: "Weeks 1-4",
        summary: "Pull the Italian-born ancestor's USCIS naturalisation history (or a Certificate of Non-Existence). Confirm the post-DL 36/2025 generation cap applies to your line and identify whether the line is paternal, maternal post-1948, or a 1948 case.",
        documents: [
            "USCIS Genealogy Program request for naturalisation records (Index Search + Record Request)",
            "Family tree mapping every birth, marriage, and death in the line",
            "Approximate dates of: Italian ancestor's birth, emigration from Italy, US naturalisation (if any), and birth of next generation in line"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_it_intake", situation: "Initial scoping call", phrasing: "Lawyer re-tests your eligibility against the two-generation cap before quoting."),
            LawyerPattern(id: "lp_it_chain", situation: "Chain risk assessment", phrasing: "Lawyer drafts the naturalisation-timing test and flags which records to pull first.")
        ],
        gotchas: [
            "USCIS Index Search confirms whether a naturalisation record exists; Record Request retrieves it — order both",
            "Lawyer typically asks for a flat fee plus per-record costs; clarify which is which before signing"
        ]
    )

    private static let italyDocumentChainPhase = JourneyPhase(
        id: "p_it_chain",
        order: 2,
        title: "2. Civil Records Chain",
        timeframe: "Months 2-6",
        summary: "Order long-form birth, marriage, and death certificates for every person in the line — both Italian (from the comune) and US-side. Italian comune requests typically go by certified mail with a self-addressed return envelope and a small reimbursement for postage.",
        documents: [
            "Italian ancestor's atto di nascita (birth) from the comune of birth",
            "Italian ancestor's atto di matrimonio (marriage) if applicable",
            "Italian ancestor's atto di morte (death) if deceased",
            "Long-form US birth, marriage, and death certificates for every generation in the line",
            "Translation of any non-English source documents into English (for the US side)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_it_comune", situation: "Comune outreach", phrasing: "Lawyer drafts certified-mail requests in Italian for each comune."),
            LawyerPattern(id: "lp_it_us_records", situation: "US vital records", phrasing: "Lawyer routes you to the issuing US jurisdiction's preferred ordering channel.")
        ],
        gotchas: [
            "Long-form (full) certificates required — short-form is rejected",
            "Some comune offices charge €0 but insist on a self-addressed return envelope; others charge €30+",
            "US vital records can be slow during peak summer order season — start early"
        ]
    )

    private static let italyApostillePhase = JourneyPhase(
        id: "p_it_apostille",
        order: 3,
        title: "3. Apostille Every US Document",
        timeframe: "Month 6-8",
        summary: "Every US-issued document in the chain needs an Apostille of the Hague from the issuing US state's Secretary of State (federal documents get the US Department of State). Italian documents do not need apostilles — they are accepted natively.",
        documents: [
            "Apostille on each US birth certificate",
            "Apostille on each US marriage certificate",
            "Apostille on each US death certificate",
            "Apostille on USCIS naturalisation record or Certificate of Non-Existence"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_it_apostille", situation: "Apostille routing", phrasing: "Lawyer routes each document to the correct issuing-state apostille office."),
            LawyerPattern(id: "lp_it_apostille_speed", situation: "Speed options", phrasing: "Lawyer flags which states accept expedited service and which don't.")
        ],
        gotchas: [
            "Apostille must be issued by the state that issued the underlying record — out-of-state apostilles are rejected",
            "Some states require an intermediate county clerk certification before the Secretary of State apostille",
            "USCIS records get federal apostilles from the US Department of State — different process and timeline"
        ]
    )

    private static let italyTranslationPhase = JourneyPhase(
        id: "p_it_translation",
        order: 4,
        title: "4. Sworn Translation into Italian",
        timeframe: "Month 8-10",
        summary: "Every US document — original, apostille, and any annotations — needs a sworn Italian translation by a traduttore giurato or a translator registered with the relevant Italian court. Translations are then bound to the original and apostille as a single notarised package.",
        documents: [
            "Sworn Italian translation of every US document in the chain",
            "Translator's giuramento (sworn affidavit) attached to each translation",
            "Bound packets: each original + apostille + translation as a single bundle"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_it_translator", situation: "Translator selection", phrasing: "Lawyer routes documents to a court-registered traduttore giurato."),
            LawyerPattern(id: "lp_it_bundle", situation: "Bundle preparation", phrasing: "Lawyer confirms each packet is bound and ribboned per consular standard.")
        ],
        gotchas: [
            "DIY or non-sworn translations are rejected — even if perfectly accurate",
            "Translation fees scale with page count, not document count — long marriage certificates can cost more than birth certificates",
            "Bind originals BEFORE the consular submission — loose translations can be lost in handling"
        ]
    )

    private static let italyFilingPhase = JourneyPhase(
        id: "p_it_filing",
        order: 5,
        title: "5. File at the Consulate or in Court",
        timeframe: "Month 10-12",
        summary: "Book a Prenot@Mi appointment at the Italian consulate covering your jurisdiction. For 1948 maternal-line cases (child born before 1948), skip the consulate and file in the Court of Rome through your Italian lawyer.",
        documents: [
            "Complete bound packets for every person in the line",
            "Application form (modulo) per consulate; lawyer prepares",
            "Consulate appointment confirmation from Prenot@Mi",
            "Court filing dossier (1948 cases only)"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_it_prenotami", situation: "Prenot@Mi booking", phrasing: "Lawyer monitors the consulate calendar and books the first available slot."),
            LawyerPattern(id: "lp_it_court", situation: "Court of Rome filing", phrasing: "Italian lawyer files the 1948 dossier in Rome and updates you on hearing dates.")
        ],
        gotchas: [
            "Prenot@Mi appointments at high-demand consulates (NY, LA) can be booked 12+ months out",
            "1948 court cases run 12-36 months; budget accordingly",
            "Consulate may request re-issued certificates if your originals are more than 6 months old at filing"
        ]
    )

    private static let italyRegistrationPhase = JourneyPhase(
        id: "p_it_registration",
        order: 6,
        title: "6. Trascrizione, Passport, and AIRE",
        timeframe: "Month 12-14",
        summary: "Once the consulate or court confirms recognition, your records are transcribed (trascrizione) into the Italian civil registry of your ancestor's comune. You can then apply for an Italian passport. AIRE registration (Anagrafe Italiani Residenti all'Estero) follows.",
        documents: [
            "Consulate or court recognition decree",
            "Italian passport application (online via Prenot@Mi for some consulates)",
            "AIRE registration form"
        ],
        lawyerPatterns: [
            LawyerPattern(id: "lp_it_trascrizione", situation: "Comune transcription", phrasing: "Lawyer pings the comune to confirm transcription is recorded."),
            LawyerPattern(id: "lp_it_passport", situation: "Passport booking", phrasing: "Consulate schedules passport biometrics 4-8 weeks after transcription is confirmed.")
        ],
        gotchas: [
            "Transcription is asynchronous — book your passport appointment as soon as recognition is confirmed",
            "AIRE registration triggers Italian tax-residency conversations — model your tax position before registering",
            "Children born after recognition inherit citizenship automatically but still need their own transcriptions to obtain a passport"
        ]
    )

    // MARK: - Ireland FBR
    //
    // Wave 2 — Ancestry deepening. Walks the standard grandparent-on-the-island
    // path through the DFA's FBR portal. The 12-month standard backlog and the
    // "register before having children" trap are the two highest-signal facts
    // for this audience.

    static let irelandFBR = RealJourney(
        id: "ireland_fbr",
        visaId: "ie_fbr",
        countryId: "ireland",
        title: "Ireland Foreign Births Register (FBR)",
        subtitle: "Grandparent path · 2024 case · 13-month journey",
        totalDuration: "~13 months from first GRO request to FBR certificate in hand",
        feeSummary: "FBR fee: €278 (adults), €153 (under 18), payable at submission. GRO-issued certificates ≈ €20 each; US-side vital records ≈ $25-$45 each. Optional genealogist for archive work ≈ €60-€120/hour.",
        eligibilitySummary: [
            "Ancestor born on the island of Ireland (any of the 32 counties — Northern Ireland counts)",
            "Grandparent path is automatic; great-grandparent paths require the intermediate parent to have been on the FBR before your birth",
            "Your FBR registration must be COMPLETE before any future child's birth for them to inherit Irish citizenship",
            "No language test, no income test, no residence requirement"
        ],
        phases: [irelandPlanningPhase, irelandGROOrderPhase, irelandUSRecordsPhase, irelandApplicationPhase, irelandWaitPhase, irelandPassportPhase],
        crossPhaseGotchas: [
            JourneyGotcha(
                id: "g_ie_gro",
                title: "GRO-issued certified copies are required",
                detail: "Free historical scans from IrishGenealogy.ie are useful for research but the DFA will only accept GRO-issued certified copies for the FBR application. Order from the GRO directly or through a third-party service."
            ),
            JourneyGotcha(
                id: "g_ie_long_form",
                title: "Long-form birth certificates only",
                detail: "Short-form / wallet-size US birth certificates are rejected. Order long-form certified copies showing both parents' names from the issuing US vital records office."
            ),
            JourneyGotcha(
                id: "g_ie_children",
                title: "Children must wait until your FBR is complete",
                detail: "A child born to a non-resident Irish citizen does NOT inherit Irish citizenship unless the parent was already on the FBR at the child's birth. Time your applications carefully."
            ),
            JourneyGotcha(
                id: "g_ie_backlog",
                title: "DFA standard processing is ~12 months",
                detail: "The DFA does not offer paid expedited processing for routine FBR applications. Plan for 12 months as a floor. The clock starts when the DFA receives your complete application by post, not when you submit electronically."
            ),
            JourneyGotcha(
                id: "g_ie_disclaimer",
                title: "Verify with the DFA before relying on this",
                detail: "Irish citizenship rules are stable but processing times and document requirements occasionally change. Verify with the current DFA FBR guidance before paying any fees."
            )
        ],
        disclaimer: "Illustrative content based on an anonymised 2024 grandparent-line case (US → Irish citizenship). Not legal advice. Irish citizenship law is stable but processing times change — verify with the current DFA FBR guidance before relying on this."
    )

    private static let irelandPlanningPhase = JourneyPhase(
        id: "p_ie_planning",
        order: 1,
        title: "1. Plan Your Documentary Chain",
        timeframe: "Weeks 1-2",
        summary: "Map the line from you up to your Irish-born ancestor and list every document you need. Confirm the grandparent (or earlier eligible ancestor) was born on the island of Ireland and identify which county. If you have a parent on the FBR already, your path is simpler.",
        documents: [
            "Family tree mapping every person in the line, with approximate dates",
            "Confirmation of the Irish ancestor's county of birth",
            "FBR application portal account (DFA)"
        ],
        lawyerPatterns: [],
        gotchas: [
            "Northern Ireland counts — Belfast and Derry births are fine for FBR via the grandparent rule",
            "If your path is via a great-grandparent, the intermediate parent must already be on the FBR before your birth — check that first"
        ]
    )

    private static let irelandGROOrderPhase = JourneyPhase(
        id: "p_ie_gro",
        order: 2,
        title: "2. Order GRO Certificates from Ireland",
        timeframe: "Month 1-3",
        summary: "Order GRO-issued certified copies of your Irish-born ancestor's birth, marriage (if applicable), and death (if deceased) certificates. Order any other Irish-side certificates needed to link the chain (parent's birth cert if they were also born in Ireland, etc.).",
        documents: [
            "GRO-issued ancestor's birth certificate",
            "GRO-issued ancestor's marriage certificate (if applicable)",
            "GRO-issued ancestor's death certificate (if deceased)"
        ],
        lawyerPatterns: [],
        gotchas: [
            "GRO turnaround is typically 4-8 weeks by post",
            "Online GRO orders ship to the address on file — confirm your shipping address before submitting",
            "Free historical scans from IrishGenealogy.ie can confirm an ancestor exists in the records, but won't substitute for a GRO-issued certificate"
        ]
    )

    private static let irelandUSRecordsPhase = JourneyPhase(
        id: "p_ie_us_records",
        order: 3,
        title: "3. Order US Vital Records",
        timeframe: "Month 2-4",
        summary: "Order long-form birth, marriage, and death certificates for every generation in the chain on the US side. Marriage certificates link generations where surnames change.",
        documents: [
            "Your own long-form birth certificate",
            "Linking parent's long-form birth certificate",
            "Marriage certificates for every generation where a surname changed",
            "Current government photo ID + recent proof of address (utility bill or bank statement)"
        ],
        lawyerPatterns: [],
        gotchas: [
            "Short-form / wallet-size birth certificates are rejected — order long-form",
            "Vital Records turnaround varies wildly by US state and county; budget extra time for Texas, New York, and California",
            "Marriage certificates can be county-issued or state-issued — confirm which your state requires"
        ]
    )

    private static let irelandApplicationPhase = JourneyPhase(
        id: "p_ie_application",
        order: 4,
        title: "4. Complete and Post the FBR Application",
        timeframe: "Month 4-5",
        summary: "Submit the online FBR application via fbr.dfa.ie. Pay the fee online. Print the form, sign by hand, and post the signed copy with all supporting documents (originals or GRO-issued certified copies) to the address shown on the application.",
        documents: [
            "Signed printed FBR application form",
            "All supporting documents listed in the application (originals or GRO-issued)",
            "FBR fee payment receipt (€278 adult / €153 under 18)"
        ],
        lawyerPatterns: [],
        gotchas: [
            "Use a tracked or registered postal service — the DFA does not confirm receipt of incomplete applications",
            "The DFA returns originals after processing but expects you to be without them for 12+ months",
            "Include a cover letter listing every enclosed document — saves processing time"
        ]
    )

    private static let irelandWaitPhase = JourneyPhase(
        id: "p_ie_wait",
        order: 5,
        title: "5. Wait (~12 Months)",
        timeframe: "Month 5-17",
        summary: "DFA standard processing is approximately 12 months. Incomplete applications wait longer — the DFA will write to you to request clarifying documents, with a deadline to respond. Set a calendar reminder so you don't miss it.",
        documents: [
            "Any DFA requests for further information (respond within the stated deadline)",
            "Optional: nothing else — the DFA processes asynchronously"
        ],
        lawyerPatterns: [],
        gotchas: [
            "The DFA does not provide live status updates — emails go to a general queue",
            "RFIs (request for further information) typically have a 4-week response window — missing it pushes you back to the end of the queue"
        ]
    )

    private static let irelandPassportPhase = JourneyPhase(
        id: "p_ie_passport",
        order: 6,
        title: "6. Receive FBR Certificate and Apply for Passport",
        timeframe: "Month 17 onwards",
        summary: "Once you receive your FBR certificate, you are an Irish citizen with the same rights as anyone born in Ireland. Apply for an Irish passport via the Department of Foreign Affairs passport service.",
        documents: [
            "FBR certificate (your proof of Irish citizenship)",
            "Irish passport application (online via DFA passport service)",
            "Recent passport photo + identity documents"
        ],
        lawyerPatterns: [],
        gotchas: [
            "Online passport applications via DFA typically take 4-6 weeks once submitted",
            "Register children's births on the FBR before any future grandchildren — the chain closes if the parent was not on the FBR at the child's birth",
            "Dual citizenship is allowed — you retain all US rights"
        ]
    )
}
