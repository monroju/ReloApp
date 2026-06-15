import Foundation

/// Curated resource lists for users with active PersonalConsiderations.
/// Surfaced as a "For You" section in ResourcesView when the wizard collected
/// at least one persona. Lists are intentionally short (3–5 entries per persona ×
/// country) — quality over breadth.
///
/// Audit cadence: refresh URLs annually; if a link 404s, prefer the org's umbrella
/// page over the dead deep-link.
enum InclusivityResources {

    /// Build the "For You" categories for a user with the given personas and country.
    /// Returns at most one category per persona, ordered by display priority.
    static func categories(
        considerations: Set<PersonalConsideration>,
        isSingleParent: Bool,
        countryId: String
    ) -> [WebResourceCategory] {
        var out: [WebResourceCategory] = []

        // Display order: most safety-critical first.
        let displayOrder: [PersonalConsideration] = [
            .lgbtq, .trans, .disabled, .veteran, .pregnant, .neurodivergent, .senior, .poc
        ]
        for c in displayOrder where considerations.contains(c) {
            if let cat = category(for: c, countryId: countryId) {
                out.append(cat)
            }
        }
        if isSingleParent, let cat = singleParentCategory(countryId: countryId) {
            out.append(cat)
        }
        return out
    }

    // MARK: - LGBTQ+

    private static func lgbtqCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "heart.text.square"
        let title = "LGBTQ+ Resources"
        let common = [
            WebResource(id: "ilga-rainbow", title: "ILGA-Europe Rainbow Map",
                        description: "Country ranking by legal & social rights",
                        url: "https://www.rainbow-europe.org/", type: "official"),
        ]
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [
                WebResource(id: "felgtb", title: "FELGTBI+",
                            description: "Federación Estatal LGTBI+ — national federation",
                            url: "https://felgtbi.org/", type: "community"),
                WebResource(id: "cogam", title: "COGAM (Madrid)",
                            description: "Madrid LGBT+ collective, advisory & social",
                            url: "https://cogam.es/", type: "community"),
                WebResource(id: "casal-lambda", title: "Casal Lambda (Barcelona)",
                            description: "Barcelona LGBTI+ centre and library",
                            url: "https://lambda.cat/", type: "community"),
            ]
        case "portugal":
            countrySpecific = [
                WebResource(id: "ilga-pt", title: "ILGA Portugal",
                            description: "Legal advice + community helpline",
                            url: "https://ilga-portugal.pt/", type: "service"),
                WebResource(id: "rea-lisbon", title: "rede ex aequo",
                            description: "Youth LGBTI+ network",
                            url: "https://www.rea.pt/", type: "community"),
            ]
        case "germany":
            countrySpecific = [
                WebResource(id: "lsvd", title: "LSVD",
                            description: "Lesben- und Schwulenverband — national advocacy",
                            url: "https://www.lsvd.de/en/", type: "community"),
                WebResource(id: "mann-o-meter", title: "Mann-O-Meter (Berlin)",
                            description: "Berlin gay men's information centre",
                            url: "https://mann-o-meter.de/", type: "community"),
            ]
        case "ireland":
            countrySpecific = [
                WebResource(id: "belongto", title: "BeLonG To",
                            description: "LGBTQ+ youth support, all-island",
                            url: "https://www.belongto.org/", type: "community"),
                WebResource(id: "lgbt-ie", title: "LGBT Ireland",
                            description: "Helpline, peer support, training",
                            url: "https://lgbt.ie/", type: "service"),
            ]
        case "uk_ancestry":
            countrySpecific = [
                WebResource(id: "stonewall", title: "Stonewall UK",
                            description: "Workplace + legal info; Diversity Champion lists",
                            url: "https://www.stonewall.org.uk/", type: "community"),
                WebResource(id: "switchboard", title: "Switchboard LGBT+",
                            description: "Confidential helpline + chat",
                            url: "https://switchboard.lgbt/", type: "service"),
            ]
        case "canada":
            countrySpecific = [
                WebResource(id: "egale", title: "Egale Canada",
                            description: "National LGBTQI2S advocacy + resources",
                            url: "https://egale.ca/", type: "community"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "arcigay", title: "Arcigay",
                            description: "Italy's largest LGBT+ association",
                            url: "https://www.arcigay.it/", type: "community"),
            ]
        case "argentina":
            countrySpecific = [
                WebResource(id: "100x100-diversidad", title: "100% Diversidad y Derechos",
                            description: "LGBT+ rights organisation",
                            url: "https://100porciento.com.ar/", type: "community"),
            ]
        case "mexico":
            countrySpecific = [
                WebResource(id: "yaaj", title: "Yaaj México",
                            description: "Mental health + community programs",
                            url: "https://yaajmexico.org/", type: "community"),
            ]
        case "poland":
            countrySpecific = [
                WebResource(id: "kph", title: "Kampania Przeciw Homofobii",
                            description: "Anti-homophobia campaign, legal aid",
                            url: "https://kph.org.pl/en/", type: "community"),
                WebResource(id: "lambda-warsaw", title: "Lambda Warszawa",
                            description: "Warsaw LGBT+ centre, helpline",
                            url: "https://lambdawarszawa.org/en/", type: "service"),
            ]
        case "hungary":
            countrySpecific = [
                WebResource(id: "hatter", title: "Háttér Society",
                            description: "Hungary's largest LGBTQ+ org; legal helpline",
                            url: "https://en.hatter.hu/", type: "community"),
            ]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_lgbtq", title: title, icon: icon,
                                    resources: countrySpecific + common)
    }

    // MARK: - Transgender

    private static func transCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "person.text.rectangle"
        let title = "Trans Resources"
        let common = [
            WebResource(id: "tgeu-map", title: "TGEU Trans Rights Map",
                        description: "Legal gender recognition + care access by country",
                        url: "https://transrightsmap.tgeu.org/", type: "official"),
        ]
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [
                WebResource(id: "plataforma-trans", title: "Federación Plataforma Trans",
                            description: "National trans federation; 2023 trans-law guidance",
                            url: "https://plataformatrans.org/", type: "community"),
            ]
        case "germany":
            countrySpecific = [
                WebResource(id: "dgti", title: "dgti e.V.",
                            description: "Trans association; supplementary ID (Ergänzungsausweis)",
                            url: "https://dgti.org/", type: "community"),
            ]
        case "ireland":
            countrySpecific = [
                WebResource(id: "teni", title: "TENI",
                            description: "Transgender Equality Network Ireland — legal + peer support",
                            url: "https://teni.ie/", type: "community"),
            ]
        case "uk_ancestry":
            countrySpecific = [
                WebResource(id: "gendered-intelligence", title: "Gendered Intelligence",
                            description: "UK trans charity; care-pathway navigation",
                            url: "https://genderedintelligence.co.uk/", type: "community"),
            ]
        case "canada":
            countrySpecific = [
                WebResource(id: "egale-trans", title: "Egale Canada — Trans resources",
                            description: "Documents, provincial care coverage guides",
                            url: "https://egale.ca/", type: "community"),
            ]
        case "argentina":
            countrySpecific = [
                WebResource(id: "ley-identidad", title: "Ley de Identidad de Género",
                            description: "Official guide to document change + guaranteed care",
                            url: "https://www.argentina.gob.ar/justicia/derechofacil/leysimple/identidad-de-genero",
                            type: "official"),
            ]
        case "mexico":
            countrySpecific = [
                WebResource(id: "condesa", title: "Clínica Especializada Condesa",
                            description: "Mexico City public HRT + trans health clinic",
                            url: "https://condesadf.mx/", type: "service"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "mit-italia", title: "MIT — Movimento Identità Trans",
                            description: "Bologna-based trans org; legal + health desk",
                            url: "https://mit-italia.it/", type: "community"),
            ]
        case "poland":
            countrySpecific = [
                WebResource(id: "trans-fuzja", title: "Fundacja Trans-Fuzja",
                            description: "Polish trans foundation; court-process guidance",
                            url: "https://transfuzja.org/", type: "community"),
            ]
        case "hungary":
            countrySpecific = [
                WebResource(id: "transvanilla", title: "Transvanilla",
                            description: "Hungarian trans association; recognition-ban updates",
                            url: "https://transvanilla.hu/", type: "community"),
            ]
        case "portugal":
            countrySpecific = [
                WebResource(id: "ilga-pt-trans", title: "ILGA Portugal",
                            description: "Self-ID law guidance + trans peer support",
                            url: "https://ilga-portugal.pt/", type: "service"),
            ]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_trans", title: title, icon: icon,
                                    resources: countrySpecific + common)
    }

    // MARK: - Disabled / Accessibility

    private static func disabledCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "figure.roll"
        let title = "Disability & Accessibility"
        let common = [
            WebResource(id: "eu-disab-card", title: "EU Disability Card",
                        description: "Mutual recognition across EU member states",
                        url: "https://employment-social-affairs.ec.europa.eu/policies-and-activities/social-protection-social-inclusion/persons-disabilities/european-disability-card_en",
                        type: "official"),
        ]
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [
                WebResource(id: "imserso", title: "IMSERSO",
                            description: "National institute for elderly & disability services",
                            url: "https://www.imserso.es/", type: "official"),
                WebResource(id: "once", title: "ONCE",
                            description: "Blind & low-vision services + employment",
                            url: "https://www.once.es/", type: "service"),
            ]
        case "portugal":
            countrySpecific = [
                WebResource(id: "inr-pt", title: "INR (Instituto Nacional para a Reabilitação)",
                            description: "National disability authority",
                            url: "https://www.inr.pt/", type: "official"),
            ]
        case "germany":
            countrySpecific = [
                WebResource(id: "schwerbehindertenausweis", title: "Schwerbehindertenausweis Info",
                            description: "Severe disability ID — tax breaks, free transit",
                            url: "https://www.einfach-teilhaben.de/", type: "official"),
                WebResource(id: "integrationsamt", title: "Integrationsamt",
                            description: "Workplace accommodation + sign-language funding",
                            url: "https://www.integrationsaemter.de/", type: "service"),
            ]
        case "ireland":
            countrySpecific = [
                WebResource(id: "disability-fed-ie", title: "Disability Federation of Ireland",
                            description: "Umbrella org + advocacy",
                            url: "https://www.disability-federation.ie/", type: "community"),
                WebResource(id: "ihrec", title: "Irish Human Rights & Equality Commission",
                            description: "Disability-discrimination complaints",
                            url: "https://www.ihrec.ie/", type: "official"),
            ]
        case "uk_ancestry":
            countrySpecific = [
                WebResource(id: "scope-uk", title: "Scope",
                            description: "UK's largest disability equality charity",
                            url: "https://www.scope.org.uk/", type: "community"),
                WebResource(id: "pip", title: "Personal Independence Payment",
                            description: "Disability benefit info (post-Brexit residency rules apply)",
                            url: "https://www.gov.uk/pip", type: "official"),
            ]
        case "canada":
            countrySpecific = [
                WebResource(id: "rdsp", title: "Registered Disability Savings Plan",
                            description: "Federal disability savings + grants",
                            url: "https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/registered-disability-savings-plan-rdsp.html",
                            type: "official"),
                WebResource(id: "aoda", title: "AODA (Ontario)",
                            description: "Accessibility for Ontarians with Disabilities Act",
                            url: "https://www.aoda.ca/", type: "official"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "law-104", title: "Legge 104/1992",
                            description: "Italy's disability framework + caregiver leave",
                            url: "https://www.inps.it/", type: "official"),
            ]
        case "mexico":
            countrySpecific = [
                WebResource(id: "conadis", title: "CONADIS",
                            description: "Consejo Nacional para el Desarrollo y la Inclusión",
                            url: "https://www.gob.mx/conadis", type: "official"),
            ]
        case "argentina":
            countrySpecific = [
                WebResource(id: "andis", title: "ANDIS",
                            description: "Agencia Nacional de Discapacidad — CUD certificate",
                            url: "https://www.argentina.gob.ar/andis", type: "official"),
            ]
        case "poland":
            countrySpecific = [
                WebResource(id: "pfron", title: "PFRON",
                            description: "State fund for disabled rehabilitation & employment",
                            url: "https://www.pfron.org.pl/", type: "official"),
            ]
        case "hungary":
            countrySpecific = [
                WebResource(id: "meosz", title: "MEOSZ",
                            description: "National Federation of Disabled Persons",
                            url: "https://meosz.hu/", type: "community"),
            ]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_disabled", title: title, icon: icon,
                                    resources: countrySpecific + common)
    }

    // MARK: - Veteran

    private static func veteranCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "shield.lefthalf.filled"
        let title = "Veteran Resources"
        let common = [
            WebResource(id: "va-fmp", title: "VA Foreign Medical Program",
                        description: "Service-connected care reimbursement abroad",
                        url: "https://www.va.gov/communitycare/programs/veterans/fmp/",
                        type: "official"),
            WebResource(id: "ssa-totalization", title: "SSA Totalization Agreements",
                        description: "How US credits transfer to host-country pensions",
                        url: "https://www.ssa.gov/international/agreements_overview.html",
                        type: "official"),
        ]
        let countrySpecific: [WebResource]
        switch countryId {
        case "germany":
            countrySpecific = [
                WebResource(id: "ramstein-va", title: "Ramstein VA Outreach",
                            description: "USAF Ramstein veteran services",
                            url: "https://www.benefits.va.gov/persona/veteran-livingabroad.asp",
                            type: "official"),
            ]
        case "mexico":
            countrySpecific = [
                WebResource(id: "ajijic-vets", title: "American Legion Post 7 Ajijic",
                            description: "Largest US-veteran post outside the US",
                            url: "https://www.legion.org/", type: "community"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "aviano-vets", title: "Aviano AB Veteran Services",
                            description: "US military community Italy",
                            url: "https://www.aviano.af.mil/", type: "official"),
            ]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_veteran", title: title, icon: icon,
                                    resources: countrySpecific + common)
    }

    // MARK: - Pregnant

    private static func pregnantCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "figure.and.child.holdinghands"
        let title = "Pregnancy & Maternity Care"
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [
                WebResource(id: "sespa-mat", title: "Maternity in the SNS",
                            description: "Public maternity care + Tarjeta Sanitaria registration",
                            url: "https://www.sanidad.gob.es/", type: "official"),
                WebResource(id: "elparto-es", title: "El Parto es Nuestro",
                            description: "Respectful-birth advocacy + birth-plan templates",
                            url: "https://www.elpartoesnuestro.es/", type: "community"),
            ]
        case "portugal":
            countrySpecific = [
                WebResource(id: "sns-mat", title: "SNS Saúde Materna",
                            description: "Maternal health entry-point",
                            url: "https://www.sns24.gov.pt/", type: "official"),
            ]
        case "germany":
            countrySpecific = [
                WebResource(id: "mutterschutz", title: "Mutterschutzgesetz",
                            description: "14-week paid maternity protection law",
                            url: "https://www.bmfsfj.de/", type: "official"),
                WebResource(id: "elterngeld", title: "Elterngeld portal",
                            description: "Parental allowance application",
                            url: "https://www.elterngeld-digital.de/", type: "official"),
            ]
        case "ireland":
            countrySpecific = [
                WebResource(id: "hse-mat", title: "HSE Maternity Service",
                            description: "Public maternity, choose-your-midwife",
                            url: "https://www2.hse.ie/services/maternity-services/",
                            type: "official"),
                WebResource(id: "cuidiu", title: "Cuidiú",
                            description: "Parent support, antenatal classes",
                            url: "https://www.cuidiu.ie/", type: "community"),
            ]
        case "uk_ancestry":
            countrySpecific = [
                WebResource(id: "nhs-pregnancy", title: "NHS Pregnancy",
                            description: "Free maternity care for residents",
                            url: "https://www.nhs.uk/pregnancy/", type: "official"),
                WebResource(id: "nct", title: "NCT",
                            description: "Antenatal classes + parent network",
                            url: "https://www.nct.org.uk/", type: "community"),
            ]
        case "canada":
            countrySpecific = [
                WebResource(id: "ei-maternity", title: "EI Maternity & Parental Benefits",
                            description: "Federal maternity/parental leave",
                            url: "https://www.canada.ca/en/services/benefits/ei/ei-maternity-parental.html",
                            type: "official"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "ssn-maternita", title: "SSN Maternità",
                            description: "Public maternity protection + INPS allowance",
                            url: "https://www.inps.it/", type: "official"),
            ]
        case "mexico":
            countrySpecific = [
                WebResource(id: "imss-mat", title: "IMSS Maternidad",
                            description: "Public maternity care",
                            url: "https://www.imss.gob.mx/", type: "official"),
            ]
        case "argentina":
            countrySpecific = [
                WebResource(id: "msal-mat", title: "Ministerio de Salud Maternidad",
                            description: "Maternal & child health programs",
                            url: "https://www.argentina.gob.ar/salud", type: "official"),
            ]
        case "poland":
            countrySpecific = [
                WebResource(id: "nfz-mat", title: "NFZ — Opieka okołoporodowa",
                            description: "Public perinatal care",
                            url: "https://www.nfz.gov.pl/", type: "official"),
                WebResource(id: "rodzic-po-ludzku", title: "Rodzić po Ludzku",
                            description: "'Birth as a Human' advocacy + hospital ratings",
                            url: "https://www.rodzicpoludzku.pl/", type: "community"),
            ]
        case "hungary":
            countrySpecific = [
                WebResource(id: "neak-csed", title: "NEAK CSED",
                            description: "Maternity allowance + CSED/GYED info",
                            url: "https://www.neak.gov.hu/", type: "official"),
            ]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_pregnant", title: title, icon: icon,
                                    resources: countrySpecific)
    }

    // MARK: - Neurodivergent

    private static func neurodivergentCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "brain.head.profile"
        let title = "Neurodivergent Support"
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [
                WebResource(id: "autismo-espana", title: "Confederación Autismo España",
                            description: "Diagnostic referrals + adult support",
                            url: "https://autismo.org.es/", type: "community"),
                WebResource(id: "tdah-espana", title: "Federación Española TDAH",
                            description: "ADHD federation — adult resources",
                            url: "https://feaadah.org/", type: "community"),
            ]
        case "portugal":
            countrySpecific = [
                WebResource(id: "fpda", title: "Federação Portuguesa de Autismo (FPDA)",
                            description: "National autism federation",
                            url: "https://www.fpda.pt/", type: "community"),
            ]
        case "germany":
            countrySpecific = [
                WebResource(id: "autismus-de", title: "autismus Deutschland",
                            description: "National autism federation; SPZ referrals",
                            url: "https://www.autismus.de/", type: "community"),
                WebResource(id: "adhs-de", title: "ADHS Deutschland",
                            description: "Adult ADHD support and clinicians directory",
                            url: "https://www.adhs-deutschland.de/", type: "community"),
            ]
        case "ireland":
            countrySpecific = [
                WebResource(id: "asiam", title: "AsIAm",
                            description: "Ireland's autism advocacy + adult community",
                            url: "https://asiam.ie/", type: "community"),
                WebResource(id: "adhd-ie", title: "ADHD Ireland",
                            description: "Adult ADHD support, Right to Choose info",
                            url: "https://adhdireland.ie/", type: "community"),
            ]
        case "uk_ancestry":
            countrySpecific = [
                WebResource(id: "nas-uk", title: "National Autistic Society",
                            description: "UK's main autism charity; adult diagnostic guide",
                            url: "https://www.autism.org.uk/", type: "community"),
                WebResource(id: "adhd-uk", title: "ADHD UK",
                            description: "Right-to-Choose NHS clinics list",
                            url: "https://adhduk.co.uk/", type: "community"),
            ]
        case "canada":
            countrySpecific = [
                WebResource(id: "autism-canada", title: "Autism Canada",
                            description: "Province-by-province service navigation",
                            url: "https://autismcanada.org/", type: "community"),
                WebResource(id: "caddra", title: "CADDRA",
                            description: "Canadian ADHD Resource Alliance — clinicians",
                            url: "https://www.caddra.ca/", type: "community"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "angsa", title: "ANGSA",
                            description: "Italy's parent + adult autism association",
                            url: "https://www.angsa.it/", type: "community"),
            ]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_neurodivergent", title: title, icon: icon,
                                    resources: countrySpecific)
    }

    // MARK: - Senior

    private static func seniorCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "figure.walk.motion"
        let title = "Senior Living Resources"
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [
                WebResource(id: "imserso-senior", title: "IMSERSO Programs",
                            description: "Senior travel, day care, social services",
                            url: "https://www.imserso.es/", type: "official"),
                WebResource(id: "expat-coast", title: "Expat senior hubs",
                            description: "Dénia, Estepona, Alicante walkable senior towns",
                            url: "https://www.idealista.com/", type: "marketplace"),
            ]
        case "portugal":
            countrySpecific = [
                WebResource(id: "seg-social-idosos", title: "Segurança Social — Idosos",
                            description: "Pension reciprocity + senior services",
                            url: "https://www.seg-social.pt/", type: "official"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "inps-pensioni", title: "INPS Pensioni",
                            description: "Italian pension + international totalization",
                            url: "https://www.inps.it/", type: "official"),
            ]
        case "mexico":
            countrySpecific = [
                WebResource(id: "inapam", title: "INAPAM",
                            description: "Senior discount card (60+) — services, transit",
                            url: "https://www.gob.mx/inapam", type: "official"),
            ]
        case "argentina":
            countrySpecific = [
                WebResource(id: "pami", title: "PAMI",
                            description: "Public senior healthcare insurance",
                            url: "https://www.pami.org.ar/", type: "official"),
            ]
        case "germany":
            countrySpecific = [
                WebResource(id: "deutsche-rentenversicherung", title: "Deutsche Rentenversicherung",
                            description: "Pension + international agreements",
                            url: "https://www.deutsche-rentenversicherung.de/", type: "official"),
            ]
        case "ireland":
            countrySpecific = [
                WebResource(id: "age-action", title: "Age Action Ireland",
                            description: "Senior advocacy + benefit navigation",
                            url: "https://www.ageaction.ie/", type: "community"),
            ]
        case "uk_ancestry":
            countrySpecific = [
                WebResource(id: "age-uk", title: "Age UK",
                            description: "UK senior charity; pension + care navigation",
                            url: "https://www.ageuk.org.uk/", type: "community"),
            ]
        case "canada":
            countrySpecific = [
                WebResource(id: "oas-cpp", title: "OAS / CPP",
                            description: "Old Age Security + Canada Pension Plan",
                            url: "https://www.canada.ca/en/services/benefits/publicpensions.html",
                            type: "official"),
            ]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_senior", title: title, icon: icon,
                                    resources: countrySpecific)
    }

    // MARK: - Single Parent (driven by Household, not PersonalConsideration)

    private static func singleParentCategory(countryId: String) -> WebResourceCategory? {
        let icon = "figure.and.child.holdinghands"
        let title = "Single Parent Support"
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [
                WebResource(id: "es-monoparental", title: "Familia Monoparental status",
                            description: "Tax credits + reduced-fee daycare (Ley 18/2022)",
                            url: "https://www.boe.es/", type: "official"),
                WebResource(id: "fnumf", title: "FNUMF",
                            description: "Federación Nacional de Familias Monoparentales",
                            url: "https://familiasmonoparentales.es/", type: "community"),
            ]
        case "portugal":
            countrySpecific = [
                WebResource(id: "iss-monoparental", title: "ISS Família Monoparental",
                            description: "Single-parent allowances",
                            url: "https://www.seg-social.pt/", type: "official"),
            ]
        case "germany":
            countrySpecific = [
                WebResource(id: "unterhaltsvorschuss", title: "Unterhaltsvorschuss",
                            description: "State child-support advance",
                            url: "https://familienportal.de/", type: "official"),
                WebResource(id: "vamv", title: "VAMV — Single parents association",
                            description: "Alleinerziehende advocacy + advice",
                            url: "https://www.vamv.de/", type: "community"),
            ]
        case "ireland":
            countrySpecific = [
                WebResource(id: "ofp-ie", title: "One-Parent Family Payment",
                            description: "Until youngest child turns 7",
                            url: "https://www.gov.ie/", type: "official"),
                WebResource(id: "treoir", title: "Treoir",
                            description: "Federation for unmarried parents",
                            url: "https://www.treoir.ie/", type: "community"),
            ]
        case "uk_ancestry":
            countrySpecific = [
                WebResource(id: "gingerbread", title: "Gingerbread",
                            description: "UK single parents — advice + community",
                            url: "https://www.gingerbread.org.uk/", type: "community"),
                WebResource(id: "uc-uk", title: "Universal Credit",
                            description: "Replaces older single-parent benefits",
                            url: "https://www.gov.uk/universal-credit", type: "official"),
            ]
        case "canada":
            countrySpecific = [
                WebResource(id: "ccb", title: "Canada Child Benefit",
                            description: "Tax-free monthly per-child payment",
                            url: "https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit-overview.html",
                            type: "official"),
            ]
        case "italy":
            countrySpecific = [
                WebResource(id: "assegno-unico", title: "Assegno Unico Universale",
                            description: "INPS universal child allowance",
                            url: "https://www.inps.it/", type: "official"),
            ]
        case "poland":
            countrySpecific = [
                WebResource(id: "rodzina-800", title: "Rodzina 800+",
                            description: "PLN 800/mo per child",
                            url: "https://www.zus.pl/", type: "official"),
            ]
        case "hungary":
            countrySpecific = [
                WebResource(id: "csaladi-tamogatas", title: "Családi adókedvezmény",
                            description: "Family tax credit (doubled for single parents)",
                            url: "https://nav.gov.hu/", type: "official"),
            ]
        default:
            countrySpecific = []
        }
        guard !countrySpecific.isEmpty else { return nil }
        return WebResourceCategory(id: "incl_single_parent", title: title, icon: icon,
                                    resources: countrySpecific)
    }

    // ⚠️ VERIFY URLs before release — official/established equality bodies; confirm live.
    private static func pocCategory(_ countryId: String) -> WebResourceCategory {
        let icon = "person.3.fill"
        let title = "Anti-Racism & Equality"
        let common: [WebResource] = []
        let countrySpecific: [WebResource]
        switch countryId {
        case "spain":
            countrySpecific = [WebResource(id: "sos-racismo-es", title: "SOS Racismo",
                description: "Federation of anti-racism associations; reporting + support",
                url: "https://sosracismo.eu/", type: "community")]
        case "italy":
            countrySpecific = [WebResource(id: "unar-it", title: "UNAR",
                description: "National Office Against Racial Discrimination (gov)",
                url: "https://www.unar.it/", type: "official")]
        case "germany":
            countrySpecific = [WebResource(id: "ads-de", title: "Antidiskriminierungsstelle",
                description: "Federal Anti-Discrimination Agency — advice + complaints",
                url: "https://www.antidiskriminierungsstelle.de/", type: "official")]
        case "ireland":
            countrySpecific = [WebResource(id: "ihrec-ie", title: "IHREC",
                description: "Irish Human Rights & Equality Commission",
                url: "https://www.ihrec.ie/", type: "official")]
        case "uk_ancestry":
            countrySpecific = [WebResource(id: "ehrc-uk", title: "EHRC",
                description: "Equality & Human Rights Commission (Equality Act 2010)",
                url: "https://www.equalityhumanrights.com/", type: "official")]
        case "canada":
            countrySpecific = [WebResource(id: "crrf-ca", title: "Canadian Race Relations Foundation",
                description: "Federal foundation; resources + reporting",
                url: "https://www.crrf-fcrr.ca/", type: "official")]
        case "mexico":
            countrySpecific = [WebResource(id: "conapred-mx", title: "CONAPRED",
                description: "National Council to Prevent Discrimination (gov)",
                url: "https://www.conapred.org.mx/", type: "official")]
        default:
            countrySpecific = []
        }
        return WebResourceCategory(id: "incl_poc", title: title, icon: icon,
                                    resources: common + countrySpecific)
    }

    // MARK: - Dispatcher

    private static func category(for consideration: PersonalConsideration,
                                  countryId: String) -> WebResourceCategory? {
        let cat: WebResourceCategory
        switch consideration {
        case .lgbtq:          cat = lgbtqCategory(countryId)
        case .trans:          cat = transCategory(countryId)
        case .disabled:       cat = disabledCategory(countryId)
        case .veteran:        cat = veteranCategory(countryId)
        case .pregnant:       cat = pregnantCategory(countryId)
        case .neurodivergent: cat = neurodivergentCategory(countryId)
        case .senior:         cat = seniorCategory(countryId)
        case .poc:            cat = pocCategory(countryId)
        }
        return cat.resources.isEmpty ? nil : cat
    }
}
