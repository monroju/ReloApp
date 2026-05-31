import Foundation

/// Family-with-kids relocation guide. Middle-class core: the #1 unanswered question
/// for parents moving abroad is "what happens to my kids' schooling, healthcare, and
/// visa status?" Built from the founders' own move to Málaga with 3 children under 7.
/// Content is informational, refreshed 2025-2026 — verify school fees locally.
struct FamilyMoveProfile {
    let countryId: String
    let flag: String
    let name: String
    /// Public-school access + language reality for expat children.
    let publicSchooling: String
    /// International / bilingual school availability + rough annual fee band (USD).
    let internationalSchooling: String
    /// Legality + practicality of homeschooling.
    let homeschooling: String
    /// How children are covered for healthcare.
    let childHealthcare: String
    /// How dependent children are added to the primary applicant's visa/residency.
    let childVisaNote: String
    /// 2-3 practical, parent-to-parent tips specific to this country.
    let tips: [String]
}

enum FamilyMoveData {
    static let profiles: [FamilyMoveProfile] = [
        FamilyMoveProfile(countryId: "spain", flag: "🇪🇸", name: "Spain",
            publicSchooling: "Free public schools, strong quality. Under-7s adapt to Spanish fast; immersion is the norm. Concertado (semi-private) schools are low-cost and popular.",
            internationalSchooling: "Many British/American/IB schools in Madrid, Barcelona, Málaga, Valencia. ~$6,000–$15,000/yr.",
            homeschooling: "Legally grey — tolerated but not formally recognized. Most families enroll locally.",
            childHealthcare: "Children covered under the family's private policy (visa requirement) or public system once registered (empadronamiento + Seguridad Social).",
            childVisaNote: "Children included as dependents on NLV/DNV. NLV adds +25% IPREM income per child; DNV +25% per child.",
            tips: [
                "Empadronar (register) the whole family at the town hall ASAP — it's the gateway to school placement and healthcare.",
                "Public school spots are assigned by catchment; secure housing before the spring enrollment window.",
                "Kids under 6 often skip the language barrier entirely within a term."
            ]),
        FamilyMoveProfile(countryId: "portugal", flag: "🇵🇹", name: "Portugal",
            publicSchooling: "Free public schools; quality varies by region. Lisbon/Porto have waitlists. Portuguese immersion for young kids works well.",
            internationalSchooling: "Strong international-school scene (Lisbon, Cascais, Algarve). ~$8,000–$20,000/yr.",
            homeschooling: "Legal and recognized (ensino doméstico) with registration and annual exams.",
            childHealthcare: "SNS public health covers registered residents including children; private insurance common as a top-up.",
            childVisaNote: "Children included as dependents on D7/D8/D2. Citizenship after 5 years applies to the whole family.",
            tips: [
                "Get each child a NIF (tax number) early — needed for school and health registration.",
                "Algarve and Cascais have the densest English-speaking family communities.",
                "AIMA appointment backlogs are real — book the family's biometrics the moment you can."
            ]),
        FamilyMoveProfile(countryId: "mexico", flag: "🇲🇽", name: "Mexico",
            publicSchooling: "Free public schools but variable; most expat families choose private/bilingual, which is affordable by US standards.",
            internationalSchooling: "Abundant bilingual + American/IB schools (CDMX, Guadalajara, Mérida, San Miguel). ~$3,000–$12,000/yr.",
            homeschooling: "Legal; many expat families homeschool, especially in coastal/SMA communities.",
            childHealthcare: "Private care is inexpensive and high-quality in cities; IMSS voluntary enrollment covers children cheaply.",
            childVisaNote: "Children included on Temporary/Permanent Resident family unity. Spouse of Mexican-born has a 2-yr citizenship fast-track for the family.",
            tips: [
                "Private bilingual school often costs less than US daycare — a major draw for families.",
                "Apostille US birth certificates before you go; you'll need them for school and CURP.",
                "San Miguel de Allende and Mérida have established American family scenes."
            ]),
        FamilyMoveProfile(countryId: "canada", flag: "🇨🇦", name: "Canada",
            publicSchooling: "Excellent free public schools in English (or French). No language barrier for US kids.",
            internationalSchooling: "Available in major cities but rarely needed given strong public system. ~$15,000–$30,000/yr.",
            homeschooling: "Legal and well-supported, regulated by province.",
            childHealthcare: "Provincial health plans cover children (waiting period varies by province; bridge with private insurance).",
            childVisaNote: "Children included on PR (Express Entry/PNP/family sponsorship) or via citizenship-by-descent (Bill C-3) — instant for eligible kids.",
            tips: [
                "If you qualify for citizenship by descent, your children likely do too — claim together.",
                "Check the provincial health waiting period (e.g. BC/Ontario ~3 months) and insure the gap.",
                "Public schools are genuinely strong — international school is usually unnecessary."
            ]),
        FamilyMoveProfile(countryId: "ireland", flag: "🇮🇪", name: "Ireland",
            publicSchooling: "Free English-language public schools. Many are state-funded but church-affiliated; multidenominational (Educate Together) growing.",
            internationalSchooling: "Limited — public system is the norm. A few international schools in Dublin.",
            homeschooling: "Constitutionally protected; register with Tusla.",
            childHealthcare: "Public system covers residents; under-8s get free GP care. Private insurance common.",
            childVisaNote: "Children included on Critical Skills/General permits and Stamp 0. Citizenship by descent (FBR) covers eligible children — but register before they're born to pass it on.",
            tips: [
                "Under-8s qualify for a free GP visit card — register once you have a PPS number.",
                "School places are tight in Dublin; apply early and widely.",
                "Housing shortage is the real constraint — secure it before enrolling kids."
            ]),
        FamilyMoveProfile(countryId: "italy", flag: "🇮🇹", name: "Italy",
            publicSchooling: "Free public schools; young children immerse in Italian quickly. Quality strong in the north.",
            internationalSchooling: "International/IB schools in Rome, Milan, Florence. ~$8,000–$18,000/yr.",
            homeschooling: "Legal (istruzione parentale) with annual exams.",
            childHealthcare: "SSN public health covers registered residents including children.",
            childVisaNote: "Children included on Elective Residency/DNV. Jure sanguinis (citizenship by descent) covers eligible children automatically.",
            tips: [
                "If claiming jure sanguinis, minor children are recognized alongside the parent.",
                "Enroll kids by presenting your codice fiscale + residency to the local school.",
                "Northern regions (Lombardy, Emilia-Romagna) have stronger public schools."
            ]),
        FamilyMoveProfile(countryId: "germany", flag: "🇩🇪", name: "Germany",
            publicSchooling: "Free, high-quality public schools. Kids stream into German quickly; Willkommensklassen ease the transition.",
            internationalSchooling: "Strong international scene (Berlin, Munich, Frankfurt). ~$12,000–$25,000/yr.",
            homeschooling: "Effectively illegal — compulsory school attendance is strictly enforced.",
            childHealthcare: "Statutory health insurance (GKV) covers children of insured parents at no extra premium.",
            childVisaNote: "Children included on Blue Card/Freelancer family reunification. StAG §15 restoration covers eligible descendants.",
            tips: [
                "Homeschooling is not an option — plan on local or international enrollment.",
                "GKV family coverage adds children free of charge — a big saving vs the US.",
                "Anmeldung (address registration) for the whole family unlocks school + health."
            ]),
        FamilyMoveProfile(countryId: "poland", flag: "🇵🇱", name: "Poland",
            publicSchooling: "Free public schools; quality solid. Younger kids pick up Polish fast.",
            internationalSchooling: "International/American schools in Warsaw, Kraków, Wrocław. ~$8,000–$18,000/yr.",
            homeschooling: "Legal (edukacja domowa) with registration and exams.",
            childHealthcare: "NFZ public health covers children of insured residents.",
            childVisaNote: "Children included on Visa D/Temp Residence. Confirmation of citizenship covers eligible descendants — no language test.",
            tips: [
                "If confirming Polish citizenship, eligible children gain EU citizenship too.",
                "Warsaw and Kraków have the most established international family communities.",
                "Low cost of living makes private/international school more attainable than in the West."
            ]),
        FamilyMoveProfile(countryId: "argentina", flag: "🇦🇷", name: "Argentina",
            publicSchooling: "Free public schools; private bilingual schools are affordable and popular with expats.",
            internationalSchooling: "British/American/IB schools in Buenos Aires. Affordable vs US/Europe.",
            homeschooling: "Legally grey; most families enroll in private bilingual schools.",
            childHealthcare: "Universal public healthcare is free even for residents-in-process; private obras sociales/prepagas are inexpensive.",
            childVisaNote: "Children included on Rentista/Pensionado. Kids of native-born Argentines qualify for citizenship by option — fast 2-yr family path.",
            tips: [
                "Healthcare is free and open even while your residency is processing — a rare safety net.",
                "Buenos Aires has excellent, affordable bilingual schools.",
                "Peso volatility means USD income stretches very far on school + living costs."
            ]),
        FamilyMoveProfile(countryId: "hungary", flag: "🇭🇺", name: "Hungary",
            publicSchooling: "Free public schools; Hungarian is hard, so young kids adapt better than teens.",
            internationalSchooling: "International/American/British schools in Budapest. ~$8,000–$20,000/yr.",
            homeschooling: "Legal (magántanuló / private-student status) with registration.",
            childHealthcare: "Public health (TAJ) covers insured residents' children; private clinics inexpensive.",
            childVisaNote: "Children included on D-Visa/residence. Simplified naturalization covers eligible descendants (basic Hungarian needed for adults).",
            tips: [
                "Budapest's international schools are the practical choice given the language barrier.",
                "Get each child a TAJ card for public healthcare access.",
                "Central location makes weekend travel across Europe easy for families."
            ]),
        FamilyMoveProfile(countryId: "uk_ancestry", flag: "🇬🇧", name: "UK (Ancestry)",
            publicSchooling: "Free state schools in English — no language barrier. Quality varies by catchment.",
            internationalSchooling: "Private/independent schools widely available but pricey. ~$20,000–$45,000/yr.",
            homeschooling: "Legal (elective home education); minimal regulation.",
            childHealthcare: "NHS covers residents including children (visa holders pay the IHS up front).",
            childVisaNote: "Children included on the Ancestry visa as dependents. The IHS health surcharge is per-person, including children — budget for it.",
            tips: [
                "Budget the Immigration Health Surcharge for every family member — it adds up fast over 5 years.",
                "State school admission is catchment-based; housing location drives school options.",
                "No language barrier makes the UK one of the smoothest moves for US kids."
            ]),
    ]

    static func profile(for countryId: String) -> FamilyMoveProfile? {
        profiles.first { $0.countryId == countryId }
    }

    /// Universal, country-agnostic guidance for moving with young children.
    static let universalTips: [String] = [
        "Apostille every child's birth certificate (and adoption/custody papers) before you leave the US — you'll need them for school, visas, and healthcare.",
        "Single parents: carry notarized consent from the other parent for international relocation — many consulates require it.",
        "Keep a digital + paper folder of each child's vaccination records; most school systems require proof.",
        "Children under ~7 typically absorb the local language within a few months — earlier moves are easier on kids.",
        "Budget a 1–3 month healthcare gap on arrival and bridge it with travel/expat insurance until residency registration completes."
    ]
}
