#!/usr/bin/env python3
"""Generate high-intent visa comparison pages under /compare/ from _visa_catalog.json.

Builds:
    /compare/index.html                     hub
    /compare/passive-income-visas/          retiree / passive-income roundup (8)
    /compare/digital-nomad-visas/           digital nomad roundup (5)
    /compare/citizenship-by-descent/        ancestry roundup (9)
    /compare/investment-visas/              golden-visa roundup (4)
    /compare/work-visas/                    skilled-work roundup (16)
    /compare/spain-nlv-vs-portugal-d7/      head-to-head (top retiree query)
    /compare/spain-dnv-vs-portugal-d8/      head-to-head (top nomad query)

Data source is the parsed JSON, so refreshing = re-run _parse_visa_catalog.py.
"""
import json
from pathlib import Path

ROOT = Path(__file__).parent
VISAS = {v["id"]: v for v in json.load(open(ROOT / "_visa_catalog.json", encoding="utf-8"))}

UMAMI = '''<!-- Cloudflare Web Analytics --><script type='module' src='https://static.cloudflareinsights.com/beacon.min.js' data-cf-beacon='{"token": "64a77b8c518846cd99a83b9c13466ac3"}'></script><!-- End Cloudflare Web Analytics -->'''
APP_URL = "https://apps.apple.com/app/gothere-relocation-guide/id6760248690"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.gothere.app"

# Visa id -> existing deep-dive blog post (cross-link where one exists).
GUIDE = {
    "es_nlv": "spain-non-lucrative-visa-2026",
    "es_dnv": "spain-non-lucrative-visa-2026",
    "pt_d7": "portugal-d7-d8-visa-2026",
    "pt_d8": "portugal-d7-d8-visa-2026",
    "mx_temp_econ": "mexico-temporary-resident-visa-2026",
    "mx_temp_remote": "mexico-temporary-resident-visa-2026",
    "mx_perm": "mexico-temporary-resident-visa-2026",
    "it_elective": "italy-elective-residency-visa-2026",
    "it_jure_sanguinis": "italy-jure-sanguinis-citizenship-2026",
    "ie_stamp_0": "ireland-stamp-0-retiree-visa-2026",
    "ie_fbr": "ireland-foreign-births-register-2026",
    "de_blue_card": "germany-eu-blue-card-2026",
    "uk_skilled_worker": "uk-skilled-worker-visa-2026",
    "uk_ancestry": "uk-ancestry-visa-2026",
    "ca_express_entry": "canada-express-entry-visa-2026",
    "ca_descent": "canada-citizenship-by-descent-2026",
    "pl_confirmation": "poland-citizenship-confirmation-2026",
    "hu_white_card": "hungary-white-card-visa-2026",
    "hu_simplified": "hungary-simplified-naturalization-2026",
    "ar_rentista": "argentina-rentista-visa-2026",
}

# Country id -> our city/country hub (only the three with city packs).
COUNTRY_HUB = {"spain": "/spain/", "portugal": "/portugal/", "mexico": "/mexico/"}

CSS = """
    :root { --teal:#15B8A6; --teal-dark:#0F8F82; --bg:#0B0F14; --bg-card:#1A2332; --border:#1E293B; --text:#F1F5F9; --text-mute:#94A3B8; }
    *,*:before,*:after { box-sizing:border-box; margin:0; padding:0; }
    body { font-family:Inter,-apple-system,sans-serif; background:var(--bg); color:var(--text); line-height:1.7; -webkit-font-smoothing:antialiased; }
    a { color:var(--teal); text-decoration:none; } a:hover { text-decoration:underline; }
    .container { max-width:900px; margin:0 auto; padding:32px 24px; }
    nav { padding:20px 24px; border-bottom:1px solid var(--border); }
    nav .container { padding:0; display:flex; justify-content:space-between; align-items:center; }
    nav a.logo { font-family:'DM Sans'; font-weight:700; font-size:22px; color:var(--text); }
    h1 { font-family:'DM Sans'; font-size:38px; line-height:1.2; font-weight:700; margin:24px 0 16px; letter-spacing:-0.02em; }
    h2 { font-family:'DM Sans'; font-size:25px; margin:48px 0 8px; font-weight:700; letter-spacing:-0.01em; }
    h3 { font-size:19px; margin:28px 0 6px; font-weight:600; }
    p { margin:16px 0; }
    .lede { font-size:18px; color:var(--text-mute); margin:0 0 24px; }
    .breadcrumb { font-size:14px; color:var(--text-mute); margin-bottom:12px; }
    .breadcrumb a { color:var(--text-mute); }
    .table-wrap { overflow-x:auto; margin:20px 0; }
    table { width:100%; border-collapse:collapse; font-size:14px; min-width:640px; }
    th,td { padding:10px 12px; text-align:left; border-bottom:1px solid var(--border); vertical-align:top; }
    th { color:var(--teal); font-weight:600; background:rgba(21,184,166,0.05); position:sticky; top:0; }
    td.visa { font-weight:600; color:var(--text); white-space:nowrap; }
    .grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(250px,1fr)); gap:16px; margin:20px 0; }
    .tile { background:var(--bg-card); border:1px solid var(--border); border-radius:12px; padding:18px 20px; display:block; }
    .tile:hover { border-color:var(--teal); text-decoration:none; }
    .tile h3 { font-size:17px; font-weight:600; color:var(--text); margin:0 0 6px; }
    .tile p { font-size:14px; color:var(--text-mute); margin:0; }
    .card { background:var(--bg-card); border:1px solid var(--border); border-radius:12px; padding:20px 22px; margin:16px 0; }
    .card h3 { margin-top:0; }
    .pros-cons { display:grid; grid-template-columns:1fr 1fr; gap:16px; margin:12px 0; }
    .pros-cons ul { margin:6px 0 0 18px; font-size:14px; color:var(--text-mute); }
    .pros h4,.cons h4 { font-size:12px; text-transform:uppercase; letter-spacing:0.04em; }
    .pros h4 { color:var(--teal); } .cons h4 { color:#f87171; }
    .cta-box { background:linear-gradient(135deg,var(--teal-dark),var(--teal)); border-radius:16px; padding:32px; text-align:center; margin:48px 0; }
    .cta-box h3 { color:#fff; font-size:24px; margin-bottom:8px; } .cta-box p { color:rgba(255,255,255,0.9); margin-bottom:20px; }
    .cta-buttons { display:flex; gap:12px; justify-content:center; flex-wrap:wrap; }
    .cta-buttons a { background:#000; color:#fff; padding:12px 20px; border-radius:8px; font-weight:500; }
    .cta-buttons a:hover { background:#1a1a1a; text-decoration:none; }
    .callout { background:var(--bg-card); border:1px solid var(--border); border-left:3px solid var(--teal); border-radius:8px; padding:16px 20px; margin:24px 0; font-size:15px; }
    footer { border-top:1px solid var(--border); padding:32px 24px; margin-top:64px; color:var(--text-mute); font-size:14px; }
    footer .container { padding:0; }
    @media (max-width:600px){ h1{font-size:30px;} .pros-cons{grid-template-columns:1fr;} }
"""

HEAD = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  {umami}
  <title>{title}</title>
  <meta name="description" content="{desc}">
  <link rel="canonical" href="{canonical}">
  <meta property="og:title" content="{og_title}">
  <meta property="og:description" content="{desc}">
  <meta property="og:url" content="{canonical}">
  <meta property="og:type" content="article">
  <meta property="og:image" content="https://getgothere.app/og-image.png">
  <meta name="twitter:card" content="summary_large_image">
  {schema}
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=DM+Sans:wght@500;700&display=swap" rel="stylesheet">
  <style>{css}</style>
</head>
<body>
  <nav><div class="container"><a href="/" class="logo">GoThere</a><a href="{app}?utm_source=blog&utm_medium=organic&utm_campaign=compare">Get the app &rarr;</a></div></nav>
  <main class="container">
"""

FOOTER = """  </main>
  <footer><div class="container"><p>&copy; 2026 GoThere &middot; <a href="/">Home</a> &middot; <a href="/blog/">Blog</a> &middot; <a href="/compare/">Compare visas</a> &middot; <a href="/safe-harbor/">Safe Harbor Index</a></p></div></footer>
</body>
</html>
"""


def cta(campaign, heading, sub):
    return (f'    <div class="cta-box"><h3>{heading}</h3><p>{sub}</p><div class="cta-buttons">'
            f'<a href="{APP_URL}?utm_source=blog&utm_medium=organic&utm_campaign={campaign}">Download for iOS</a>'
            f'<a href="{PLAY_URL}&referrer=utm_source%3Dblog%26utm_medium%3Dorganic%26utm_campaign%3D{campaign}">Get on Google Play</a>'
            "</div></div>\n")


def visa_label(v):
    return f'{v["countryFlag"]} {v["countryName"].replace(" (Ancestry)","")} {v["shortName"]}'


def compare_table(ids, cols):
    """cols: list of (header, visa-key)."""
    h = '    <div class="table-wrap"><table>\n      <tr><th>Visa</th>'
    h += "".join(f"<th>{c[0]}</th>" for c in cols) + "</tr>\n"
    for vid in ids:
        v = VISAS[vid]
        row = f'      <tr><td class="visa">{visa_label(v)}</td>'
        for _, key in cols:
            row += f"<td>{v.get(key) or '&mdash;'}</td>"
        h += row + "</tr>\n"
    h += "    </table></div>\n"
    return h


def visa_detail(vid):
    v = VISAS[vid]
    guide = GUIDE.get(vid)
    hub = COUNTRY_HUB.get(v["countryId"])
    links = []
    if guide:
        links.append(f'<a href="/blog/{guide}.html">Full {v["countryName"].replace(" (Ancestry)","")} guide</a>')
    if hub:
        links.append(f'<a href="{hub}">City guides</a>')
    links.append(f'<a href="{v["officialUrl"]}" rel="nofollow" target="_blank">Official source</a>')
    pros = "".join(f"<li>{p}</li>" for p in v["pros"])
    cons = "".join(f"<li>{c}</li>" for c in v["cons"])
    return (
        f'    <div class="card" id="{vid}">\n'
        f'      <h3>{v["countryFlag"]} {v["name"]} &mdash; {v["countryName"].replace(" (Ancestry)","")}</h3>\n'
        f'      <p style="color:var(--text-mute);font-size:15px;margin:4px 0 12px;">'
        f'<strong>Income:</strong> {v["income"]} &middot; <strong>Processing:</strong> {v["processingTime"]} '
        f'&middot; <strong>Cost:</strong> {v["costEstimate"]}<br>'
        f'<strong>Path to PR:</strong> {v["pathToPR"]} &middot; <strong>Citizenship:</strong> {v["pathToCitizenship"]}</p>\n'
        f'      <div class="pros-cons"><div class="pros"><h4>Pros</h4><ul>{pros}</ul></div>'
        f'<div class="cons"><h4>Trade-offs</h4><ul>{cons}</ul></div></div>\n'
        f'      <p style="font-size:14px;">{" &middot; ".join(links)}</p>\n'
        f'    </div>\n'
    )


def page(path, title, desc, og_title, body, schema=""):
    html = HEAD.format(umami=UMAMI, css=CSS, app=APP_URL, title=title, desc=desc,
                       og_title=og_title, canonical=f"https://getgothere.app{path}", schema=schema)
    html += body + FOOTER
    out = ROOT / path.strip("/")
    out.mkdir(parents=True, exist_ok=True)
    (out / "index.html").write_text(html, encoding="utf-8")
    print(f"  -> {path}")


# ---- Category roundup config ---------------------------------------------
ROUNDUPS = [
    {
        "path": "/compare/passive-income-visas/", "campaign": "cmp-passive",
        "ids": ["es_nlv", "pt_d7", "it_elective", "ie_stamp_0", "mx_temp_econ", "mx_perm", "ar_rentista", "ar_pensionado"],
        "h1": "Best Passive-Income &amp; Retiree Visas for Americans (2026)",
        "title": "Best Passive-Income &amp; Retiree Visas for Americans 2026 | GoThere",
        "desc": "Compare the passive-income and retiree visas Americans actually use in 2026: Spain NLV, Portugal D7, Italy Elective, Ireland Stamp 0, Mexico, Argentina. Income bars, costs, and paths to residency side by side.",
        "intro": "If you can prove steady income without working locally, these are the visas that let you settle abroad. Portugal's D7 has the lowest income bar in the EU; Spain's NLV forbids all local work; Italy's Elective Residency is the cheapest passive route in Western Europe. Here they are side by side.",
        "cols": [("Income bar", "income"), ("Processing", "processingTime"), ("Path to PR", "pathToPR"), ("Cost", "costEstimate")],
    },
    {
        "path": "/compare/digital-nomad-visas/", "campaign": "cmp-nomad",
        "ids": ["es_dnv", "pt_d8", "it_dnv", "mx_temp_remote", "hu_white_card"],
        "h1": "Best Digital Nomad Visas for Americans (2026)",
        "title": "Best Digital Nomad Visas for Americans 2026 | GoThere",
        "desc": "Spain DNV vs Portugal D8 vs Italy DNV vs Mexico vs Hungary White Card. Real income requirements, tax regimes, and the length each visa actually lasts, compared for US remote workers in 2026.",
        "intro": "These visas are built for people earning from a foreign employer or their own clients. The differences that matter: the monthly income bar, whether there's a favorable tax regime, and how long you can actually stay. Spain's Beckham Law and Hungary's hard two-year cap sit at opposite ends of that spectrum.",
        "cols": [("Income bar", "income"), ("Work allowed", "workAllowed"), ("Duration", "duration"), ("Path to PR", "pathToPR")],
    },
    {
        "path": "/compare/citizenship-by-descent/", "campaign": "cmp-ancestry",
        "ids": ["it_jure_sanguinis", "ie_fbr", "pl_confirmation", "hu_simplified", "de_stag_15", "ca_descent", "uk_ancestry", "ar_by_option", "pl_karta_polaka"],
        "h1": "Get a Second Passport by Ancestry: 2026 Comparison",
        "title": "Citizenship by Descent for Americans 2026: Ireland, Italy, Poland &amp; More | GoThere",
        "desc": "If a parent or grandparent was born abroad, you may already qualify for a second passport. Compare citizenship-by-descent routes for Italy, Ireland, Poland, Hungary, Germany, Canada and the UK for Americans in 2026.",
        "intro": "A second passport by ancestry is the cheapest and most durable way abroad, because it's recognition of citizenship you may already hold, not a visa you can lose. The catch is proving the paper trail. Eligibility rules differ sharply, and some (Italy, UK) changed recently, so verify current rules before assuming you qualify.",
        "cols": [("Qualifying ancestor", "income"), ("Processing", "processingTime"), ("Cost", "costEstimate")],
    },
    {
        "path": "/compare/investment-visas/", "campaign": "cmp-invest",
        "ids": ["pt_golden", "it_investor", "hu_investor", "ar_investor"],
        "h1": "Golden &amp; Investment Visas for Americans (2026)",
        "title": "Golden &amp; Investment Visas for Americans 2026 | GoThere",
        "desc": "Portugal Golden Visa, Italy Investor Visa, Hungary and Argentina investment routes compared for Americans in 2026: minimum investment, processing time, and path to residency.",
        "intro": "Investment routes trade money for time and flexibility: higher upfront cost, but low physical-presence requirements and fast processing. Portugal's Golden Visa dropped real estate in 2023, so the qualifying routes now run through funds and other approved options. Compare the real minimums below.",
        "cols": [("Minimum / criteria", "income"), ("Processing", "processingTime"), ("Path to PR", "pathToPR"), ("Cost", "costEstimate")],
    },
    {
        "path": "/compare/work-visas/", "campaign": "cmp-work",
        "ids": ["de_blue_card", "uk_skilled_worker", "uk_global_talent", "ca_express_entry", "ca_pnp", "ie_critical_skills", "es_work", "pt_d2", "de_chancenkarte", "hu_d_visa", "pl_temp_residence"],
        "h1": "Skilled-Work Visas for Americans (2026)",
        "title": "Best Skilled-Work Visas for Americans 2026: Germany, UK, Canada &amp; More | GoThere",
        "desc": "Compare skilled-work and job-seeker visas for Americans in 2026: Germany EU Blue Card, UK Skilled Worker, Canada Express Entry, Ireland Critical Skills and more. Salary thresholds and PR timelines side by side.",
        "intro": "If you have a job offer or an in-demand skill, work visas are often the fastest route to permanent residency, sometimes faster than passive income. The levers that matter are the salary threshold, whether you need an employer sponsor, and how quickly the visa converts to PR. Germany's Blue Card and Canada's Express Entry are the two most-searched for good reason.",
        "cols": [("Salary / criteria", "income"), ("Work allowed", "workAllowed"), ("Path to PR", "pathToPR"), ("Processing", "processingTime")],
    },
]


def build_roundup(cfg):
    schema = ('<script type="application/ld+json">{"@context":"https://schema.org","@type":"Article",'
              '"headline":"' + cfg["h1"].replace("&amp;", "and") + '","author":{"@type":"Organization","name":"GoThere"},'
              '"publisher":{"@type":"Organization","name":"GoThere"},"datePublished":"2026-07-17",'
              '"mainEntityOfPage":"https://getgothere.app' + cfg["path"] + '"}</script>')
    body = f'    <div class="breadcrumb"><a href="/">Home</a> / <a href="/compare/">Compare</a> / {cfg["h1"].split("(")[0].strip()}</div>\n'
    body += f'    <h1>{cfg["h1"]}</h1>\n    <p class="lede">{cfg["intro"]}</p>\n'
    body += "    <h2>At a glance</h2>\n"
    body += compare_table(cfg["ids"], cfg["cols"])
    body += '    <p style="font-size:13px;color:var(--text-mute);">Thresholds reflect 2025&ndash;2026 rules and change often. Verify current figures at each official source before applying.</p>\n'
    body += "    <h2>Each visa in detail</h2>\n"
    for vid in cfg["ids"]:
        body += visa_detail(vid)
    body += cta(cfg["campaign"], "Not sure which one fits?",
                "GoThere's visa matcher takes your income, timeline, and goals and ranks every route for you, then tracks the checklist for the one you pick.")
    # related roundups
    others = [r for r in ROUNDUPS if r["path"] != cfg["path"]]
    links = " &middot; ".join(f'<a href="{r["path"]}">{r["h1"].split("(")[0].strip().replace("&amp;","&")}</a>' for r in others)
    body += f'    <h2>Other comparisons</h2>\n    <p>{links}</p>\n'
    page(cfg["path"], cfg["title"], cfg["desc"], cfg["h1"].replace("&amp;", "&"), body, schema)


# ---- Head-to-head config -------------------------------------------------
HEADTOHEAD = [
    {
        "path": "/compare/spain-nlv-vs-portugal-d7/", "campaign": "cmp-nlv-d7",
        "a": "es_nlv", "b": "pt_d7",
        "h1": "Spain NLV vs Portugal D7: Which Is Right for You? (2026)",
        "title": "Spain NLV vs Portugal D7 2026: Retiree Visa Comparison | GoThere",
        "desc": "Spain's Non-Lucrative Visa vs Portugal's D7, compared for Americans in 2026. Income requirements, work rules, tax, and path to citizenship, so you can pick the right passive-income visa.",
        "intro": "This is the single most-asked question among Americans retiring or living passively in Iberia. Both give you a path to an EU passport. The real differences: Portugal's D7 needs far less income and lets you work, while Spain's NLV forbids all local work but offers a more established expat infrastructure. Here's the honest side-by-side.",
        "cols": [("Income bar", "income"), ("Work allowed", "workAllowed"), ("Processing", "processingTime"), ("Path to PR", "pathToPR"), ("Citizenship", "pathToCitizenship"), ("Cost", "costEstimate")],
    },
    {
        "path": "/compare/spain-dnv-vs-portugal-d8/", "campaign": "cmp-dnv-d8",
        "a": "es_dnv", "b": "pt_d8",
        "h1": "Spain DNV vs Portugal D8: Digital Nomad Visa Comparison (2026)",
        "title": "Spain DNV vs Portugal D8 2026: Digital Nomad Visa Comparison | GoThere",
        "desc": "Spain's Digital Nomad Visa vs Portugal's D8, compared for American remote workers in 2026. Income bars, tax regimes (Beckham vs IFICI), duration, and residency paths side by side.",
        "intro": "Both let a remote worker or freelancer live in Iberia on foreign income, and both lead to an EU passport. The decision usually comes down to tax: Spain's Beckham Law offers a flat 24% for new arrivals, while Portugal's post-NHR IFICI is narrower. Income bars and client rules differ too. Here's how they stack up.",
        "cols": [("Income bar", "income"), ("Work allowed", "workAllowed"), ("Duration", "duration"), ("Path to PR", "pathToPR"), ("Citizenship", "pathToCitizenship"), ("Cost", "costEstimate")],
    },
    {
        "path": "/compare/portugal-d7-vs-golden-visa/", "campaign": "cmp-d7-golden",
        "a": "pt_d7", "b": "pt_golden",
        "h1": "Portugal D7 vs Golden Visa: Which Route Fits You? (2026)",
        "title": "Portugal D7 vs Golden Visa 2026: Income vs Investment | GoThere",
        "desc": "Portugal's D7 vs the Golden Visa, compared for Americans in 2026. One asks for steady income and real residency; the other for capital and almost no stay requirement. Costs, timelines and paths to citizenship side by side.",
        "intro": "Two very different Portuguese routes to the same EU passport. The D7 is for people with steady passive income who will actually live in Portugal; the Golden Visa is for people with capital who want residency with almost no physical-presence requirement. One costs you time in-country, the other costs money. Here's the trade.",
        "cols": [("Income / investment", "income"), ("Cost", "costEstimate"), ("Work allowed", "workAllowed"), ("Processing", "processingTime"), ("Path to PR", "pathToPR"), ("Citizenship", "pathToCitizenship")],
    },
    {
        "path": "/compare/spain-nlv-vs-dnv/", "campaign": "cmp-nlv-dnv",
        "a": "es_nlv", "b": "es_dnv",
        "h1": "Spain Non-Lucrative vs Digital Nomad Visa (2026)",
        "title": "Spain NLV vs DNV 2026: Which Spanish Visa Is Right for You? | GoThere",
        "desc": "Spain's Non-Lucrative Visa vs the Digital Nomad Visa, compared for Americans in 2026. Work rules, income bars, the Beckham tax regime, and paths to residency and citizenship side by side.",
        "intro": "Both are Spanish residence permits for Americans living on non-Spanish income, and both lead to the same permanent residency and citizenship timeline. The split is work: the NLV forbids all professional activity and suits retirees or the financially independent, while the DNV is built for remote workers and freelancers and unlocks Spain's flat-rate Beckham tax regime. Here's the honest comparison.",
        "cols": [("Income bar", "income"), ("Work allowed", "workAllowed"), ("Processing", "processingTime"), ("Path to PR", "pathToPR"), ("Citizenship", "pathToCitizenship"), ("Cost", "costEstimate")],
    },
    {
        "path": "/compare/irish-vs-italian-citizenship-by-descent/", "campaign": "cmp-ie-it-descent",
        "a": "ie_fbr", "b": "it_jure_sanguinis",
        "h1": "Irish vs Italian Citizenship by Descent (2026)",
        "title": "Irish vs Italian Citizenship by Descent 2026: Which Do You Qualify For? | GoThere",
        "desc": "Ireland's Foreign Births Register vs Italy's jure sanguinis, compared for Americans in 2026. Which ancestor qualifies you, how long each takes, cost, and the 2025 Italian rule change explained.",
        "intro": "The two most popular ancestral-citizenship routes for Americans, and they work very differently. Ireland's Foreign Births Register generally requires an Irish-born grandparent and is a clean administrative process. Italy's jure sanguinis can reach further back, but a 2025 rule change tightened eligibility and the paper trail is famously demanding. Here's what actually qualifies you for each.",
        "cols": [("Qualifying ancestor", "income"), ("Processing", "processingTime"), ("Cost", "costEstimate"), ("Citizenship", "pathToCitizenship")],
    },
    {
        "path": "/compare/italy-elective-vs-portugal-d7/", "campaign": "cmp-it-elective-d7",
        "a": "it_elective", "b": "pt_d7",
        "h1": "Italy Elective Residency vs Portugal D7 (2026)",
        "title": "Italy Elective Residency vs Portugal D7 2026: Retiree Visa Comparison | GoThere",
        "desc": "Italy's Elective Residency Visa vs Portugal's D7, compared for American retirees in 2026. Income expectations, work rules, processing, and paths to residency and an EU passport side by side.",
        "intro": "Two of the cheapest passive-income routes into Western Europe, constantly compared by retirees. Portugal's D7 has a low, published income bar and lets you work; Italy's Elective Residency expects substantial passive means and forbids work entirely. Portugal's path to citizenship is faster. Here's the side-by-side.",
        "cols": [("Income bar", "income"), ("Work allowed", "workAllowed"), ("Processing", "processingTime"), ("Path to PR", "pathToPR"), ("Citizenship", "pathToCitizenship"), ("Cost", "costEstimate")],
    },
    {
        "path": "/compare/germany-blue-card-vs-canada-express-entry/", "campaign": "cmp-de-ca-work",
        "a": "de_blue_card", "b": "ca_express_entry",
        "h1": "Germany Blue Card vs Canada Express Entry (2026)",
        "title": "Germany EU Blue Card vs Canada Express Entry 2026: Skilled Worker Comparison | GoThere",
        "desc": "Germany's EU Blue Card vs Canada's Express Entry, compared for skilled American workers in 2026. Salary thresholds, whether you need a job offer, processing speed, and paths to permanent residency.",
        "intro": "The two most-searched skilled-migration routes for Americans, one into the EU and one into Canada. Germany's EU Blue Card is employer-tied and needs a qualifying salary and a job offer; Canada's Express Entry is a points-based pool that doesn't require a job offer at all. The Blue Card can be faster if you already have an offer; Express Entry is more flexible if you don't. Here's how they compare.",
        "cols": [("Salary / criteria", "income"), ("Work allowed", "workAllowed"), ("Processing", "processingTime"), ("Path to PR", "pathToPR"), ("Citizenship", "pathToCitizenship")],
    },
]


def build_headtohead(cfg):
    a, b = VISAS[cfg["a"]], VISAS[cfg["b"]]
    schema = ('<script type="application/ld+json">{"@context":"https://schema.org","@type":"Article",'
              '"headline":"' + cfg["h1"].split("(")[0].strip() + '","author":{"@type":"Organization","name":"GoThere"},'
              '"publisher":{"@type":"Organization","name":"GoThere"},"datePublished":"2026-07-17",'
              '"mainEntityOfPage":"https://getgothere.app' + cfg["path"] + '"}</script>')
    body = f'    <div class="breadcrumb"><a href="/">Home</a> / <a href="/compare/">Compare</a> / {a["shortName"]} vs {b["shortName"]}</div>\n'
    body += f'    <h1>{cfg["h1"]}</h1>\n    <p class="lede">{cfg["intro"]}</p>\n'
    body += "    <h2>Side by side</h2>\n"
    body += compare_table([cfg["a"], cfg["b"]], cfg["cols"])
    body += "    <h2>The details</h2>\n"
    body += visa_detail(cfg["a"]) + visa_detail(cfg["b"])
    body += cta(cfg["campaign"], "Model both against your own numbers",
                "GoThere runs your real income and family size against every visa's threshold, then tracks the document checklist for the one you choose.")
    body += ('    <h2>Related</h2>\n    <p><a href="/compare/passive-income-visas/">All passive-income visas</a> '
             '&middot; <a href="/compare/digital-nomad-visas/">All digital nomad visas</a> '
             '&middot; <a href="/spain/">Moving to Spain</a> &middot; <a href="/portugal/">Moving to Portugal</a></p>\n')
    page(cfg["path"], cfg["title"], cfg["desc"], cfg["h1"].split("(")[0].strip(), body, schema)


def build_hub():
    schema = ('<script type="application/ld+json">{"@context":"https://schema.org","@type":"CollectionPage",'
              '"name":"Compare Visas","url":"https://getgothere.app/compare/","publisher":{"@type":"Organization","name":"GoThere"}}</script>')
    body = '    <div class="breadcrumb"><a href="/">Home</a> / Compare</div>\n'
    body += "    <h1>Compare Visas &amp; Second Passports for Americans</h1>\n"
    body += ('    <p class="lede">Every route abroad, grouped by what you have to offer: income, a skill, '
             "capital, or an ancestor. Pick a category to see the options side by side, with real thresholds and costs.</p>\n")
    body += "    <div class=\"grid\">\n"
    cards = [
        ("/compare/passive-income-visas/", "Passive-income &amp; retiree visas", "Live on savings or pension income. Spain NLV, Portugal D7, Italy Elective and more."),
        ("/compare/digital-nomad-visas/", "Digital nomad visas", "Work remotely from abroad. Spain DNV, Portugal D8, Hungary White Card and more."),
        ("/compare/citizenship-by-descent/", "Citizenship by ancestry", "A second passport through a parent or grandparent. Ireland, Italy, Poland and more."),
        ("/compare/work-visas/", "Skilled-work visas", "Move for a job or in-demand skill. Germany Blue Card, UK Skilled Worker, Canada Express Entry."),
        ("/compare/investment-visas/", "Golden &amp; investment visas", "Trade capital for residency. Portugal, Italy, Hungary and Argentina routes."),
    ]
    for href, t, d in cards:
        body += f'    <a class="tile" href="{href}"><h3>{t}</h3><p>{d}</p></a>\n'
    body += "    </div>\n"
    body += "    <h2>Popular head-to-heads</h2>\n    <div class=\"grid\">\n"
    for cfg in HEADTOHEAD:
        body += f'    <a class="tile" href="{cfg["path"]}"><h3>{cfg["h1"].split(":")[0]}</h3><p>{cfg["desc"][:90]}...</p></a>\n'
    body += "    </div>\n"
    body += ('    <div class="callout">These pages compare the rules. The '
             '<a href="' + APP_URL + '?utm_source=blog&utm_medium=organic&utm_campaign=cmp-hub">GoThere app</a> '
             "compares them against <em>your</em> income, timeline and family, then tracks the checklist for the one you pick.</div>\n")
    page("/compare/", "Compare Visas &amp; Second Passports for Americans 2026 | GoThere",
         "Compare every route abroad for Americans in 2026: passive-income, digital nomad, work, investment and citizenship-by-descent visas, side by side with real thresholds and costs.",
         "Compare Visas & Second Passports for Americans", body, schema)


def main():
    build_hub()
    for cfg in ROUNDUPS:
        build_roundup(cfg)
    for cfg in HEADTOHEAD:
        build_headtohead(cfg)
    print("\ndone")


if __name__ == "__main__":
    main()
