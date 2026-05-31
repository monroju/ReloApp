import Foundation

/// "Bring your job abroad" kit — middle-class remote-worker core. Pairs with the
/// digital-nomad visa tracks: the two things remote workers get wrong are (1) proving
/// remote employment to a consulate, and (2) tax residency. This supplies copy-paste
/// letter templates and the tax-residency warnings nobody tells you about.
/// Informational only — not legal or tax advice.
enum RemoteWorkKit {

    struct LetterTemplate: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let body: String
    }

    static let templates: [LetterTemplate] = [
        LetterTemplate(
            id: "employer_verification",
            title: "Employer Remote-Work Verification Letter",
            subtitle: "For digital-nomad visa applications (Spain DNV, Portugal D8, etc.)",
            body: """
[Company Letterhead]

[Date]

To Whom It May Concern,

This letter confirms that [Employee Full Name] (passport no. [______]) has been \
employed by [Company Legal Name], registered in [Country], since [Start Date], \
in the position of [Job Title].

[Employee Name] is employed on a [full-time / contract] basis with gross annual \
compensation of [USD/EUR amount], paid [monthly/bi-weekly]. Their role is performed \
entirely remotely and can be carried out from any location. The company authorizes \
[Employee Name] to perform their duties remotely from [Destination Country] and has \
no objection to their relocation.

[Company Name] is a registered entity (registration no. [______]) and has been \
operating for more than [X] years. This employment relationship is ongoing with no \
planned end date.

For any verification, please contact [HR Name, title, email, phone].

Sincerely,
[Authorized Signatory Name]
[Title]
[Company Name]
"""
        ),
        LetterTemplate(
            id: "freelance_income",
            title: "Self-Employed / Freelance Income Statement",
            subtitle: "For DNV / self-employment tracks when you have multiple clients",
            body: """
[Your Name]
[Address]
[Date]

Statement of Self-Employment and Income

I, [Your Full Name], certify that I operate as an independent contractor / freelancer \
providing [type of services] to clients located outside of [Destination Country].

My business has been active since [Start Date]. Over the past 12 months my gross \
income from this activity has averaged [USD/EUR amount] per month, evidenced by the \
attached:
  • Client contracts / service agreements
  • Invoices for the last [6–12] months
  • Bank statements showing corresponding deposits
  • [Most recent US tax return / Schedule C]

Less than [20]% of my income derives from clients in [Destination Country], in \
compliance with the visa's local-client limit where applicable.

[Signature]
[Your Name]
"""
        ),
    ]

    struct TaxWarning: Identifiable {
        let id: String
        let title: String
        let detail: String
    }

    /// The cross-border tax facts remote workers most often miss. Surfaced as warnings,
    /// not advice — every one ends in "talk to a cross-border accountant."
    static let taxWarnings: [TaxWarning] = [
        TaxWarning(id: "183_day",
            title: "The 183-day rule makes you a tax resident",
            detail: "Spend more than ~183 days in a calendar year in most countries and you become a tax resident there — owing tax on (often) worldwide income, regardless of where your employer is. Plan your move date around the tax year."),
        TaxWarning(id: "us_worldwide",
            title: "The US taxes you no matter where you live",
            detail: "US citizens and green-card holders file US returns on worldwide income forever. The Foreign Earned Income Exclusion (~$126k for 2024) and Foreign Tax Credit usually prevent double taxation — but you must file to claim them."),
        TaxWarning(id: "double_tax_treaty",
            title: "Check the US tax treaty + totalization agreement",
            detail: "Most GoThere destinations have a US tax treaty (avoids double income tax) and a Social Security totalization agreement (avoids paying into two systems). Mexico and Argentina have weaker coverage — verify before you rely on it."),
        TaxWarning(id: "preferential_regimes",
            title: "You may qualify for a flat-tax regime — but the window is tight",
            detail: "Spain's Beckham Law (24% flat) and Portugal's NHR-successor (IFICI) can slash your rate, but you must elect in within months of becoming resident. Italy and Hungary offer flat regimes too. Don't miss the election deadline."),
        TaxWarning(id: "employer_risk",
            title: "Your employer may create a 'permanent establishment' risk",
            detail: "If you work for a US employer from abroad, your presence can trigger local payroll/corporate obligations for them. Many companies say no to relocation for this reason — get written authorization (see the template) and warn your HR early."),
    ]

    static let disclaimer = "Templates are starting points — adapt to your situation and the specific consulate's requirements. Tax notes are informational, not advice. Engage a cross-border accountant before you move."
}
