#!/usr/bin/env python3
"""Generate /plan-b/ (growth/PLAN_B_SPEC.md section 8).

What a second citizenship by descent involves, which countries pass it down, how far
back the line goes, documents, fees and verified waits. "Options, not exits": no
political framing.

Single source of truth: shared/data/descent_chains.json (built by
shared/data/descent_chains.py from sourced research) plus the checker copy in
shared/ancestry_paths.json. Every fact on the page carries its source link and
last-verified date; anything unverified says "Not yet verified".

Deploy with the app release that ships the Plan B tab (Apple 4.2: the page points at it).
"""
import json

from _generate_move import DATA, PROJECT, SITE, apple_link, esc, page, play_link

CHAINS = json.loads((DATA / "descent_chains.json").read_text(encoding="utf-8"))
ANCESTRY = {p["id"]: p for p in json.loads(
    (PROJECT / "shared" / "ancestry_paths.json").read_text(encoding="utf-8"))["paths"]}

PATH = "/plan-b/"
CAMPAIGN = "plan-b"
ROLE = {"parent": "a parent", "grandparent": "a grandparent", "ggp": "a great-grandparent or further"}
# Guides re-verified against official sources; others link straight to the official page.
GUIDES = {
    "ie": "/blog/ireland-foreign-births-register-2026.html",
    "it": "/blog/italy-jure-sanguinis-citizenship-2026.html",
}
CHECKER = {"ie": "/tools/citizenship-by-descent/"}
ORDER = ["ie", "it", "de", "pl", "hu"]


def store_links():
    return (apple_link("gothere", "planb", CAMPAIGN),
            play_link("gothere", "planb", CAMPAIGN, medium="organic"))


def src_link(url, checked, label="source"):
    if not url:
        return '<span class="muted">Not yet verified</span>'
    when = f", checked {esc(checked)}" if checked else ""
    return f'<a class="src" href="{esc(url)}" rel="nofollow noopener" target="_blank">{label}</a><span class="muted">{when}</span>'


def months(stage):
    m = stage.get("typicalMonths")
    if not m:
        return None
    f = lambda x: str(int(x)) if float(x).is_integer() else f"{x:.1f}"
    return f"about {f(m['low'])} months" if m["low"] == m["high"] else f"{f(m['low'])} to {f(m['high'])} months"


def chains():
    by_cc = {c["countryCode"]: c for c in CHAINS["chains"].values()}
    return [by_cc[cc] for cc in ORDER if cc in by_cc]


def country_name(chain):
    return ANCESTRY[chain["ancestryPathId"]]["countryName"]


def wait_stage(chain):
    return next(s for s in chain["stages"] if s["id"] == "wait")


def official(chain):
    return next(s for s in chain["sources"] if s["type"] == "official")


def table():
    rows = ""
    for c in chains():
        w = wait_stage(c)
        wait = months(w)
        wait_html = (f'{esc(wait)} {src_link(w["sourceUrl"], w["lastVerified"])}' if wait
                     else '<span class="muted">Not yet verified</span>')
        o = official(c)
        rows += (f'<tr><td><a href="#{c["countryCode"]}">{esc(country_name(c))}</a></td>'
                 f'<td>{esc(ROLE[c["lineage"]["maxRole"]])}</td>'
                 f'<td>{len(c["documents"])}</td>'
                 f'<td>{wait_html}</td>'
                 f'<td>{src_link(o["url"], c["lastVerified"], "official")}</td></tr>')
    return ('    <table class="calc"><thead><tr><th>Country</th><th>Line usually runs through</th>'
            '<th>Document types</th><th>Typical review time</th><th>Rules</th></tr></thead>'
            f'<tbody>{rows}</tbody></table>\n')


def country_section(c):
    cc = c["countryCode"]
    a = ANCESTRY[c["ancestryPathId"]]
    lin = c["lineage"]
    fees = [h for h in c.get("orderHints", []) if h.get("fee")]
    fee_html = "".join(f'<li><strong>{esc(h["label"])}:</strong> {esc(h["fee"])} '
                       f'{src_link(h["sourceUrl"], h["lastVerified"])}</li>' for h in fees)
    docs = "".join(f"<li>{esc(d['label'])}</li>" for d in c["documents"][:8])
    more = len(c["documents"]) - 8
    links = []
    if cc in CHECKER:
        links.append(f'<a href="{CHECKER[cc]}">check your line for free</a>')
    if cc in GUIDES:
        links.append(f'<a href="{GUIDES[cc]}">read the full guide</a>')
    o = official(c)
    links.append(f'<a class="src" href="{esc(o["url"])}" rel="nofollow noopener" target="_blank">{esc(o["title"])}</a>')
    return (f'    <h2 id="{cc}">{esc(a["fullName"])}</h2>\n'
            f'    <p>{esc(lin["note"] or "")} {src_link(lin["sourceUrl"], lin["lastVerified"])}</p>\n'
            f'    <p><strong>What you get:</strong> {esc(a["outcome"])}</p>\n'
            f'    <p><strong>Main documents</strong> (the app builds the full list for each person in your line):</p>'
            f'<ul>{docs}</ul>'
            + (f'<p class="muted">Plus {more} more.</p>' if more > 0 else "") + "\n"
            + (f'    <p><strong>Fees</strong></p><ul>{fee_html}</ul>\n' if fees else
               '    <p><strong>Fees:</strong> <span class="muted">Not yet verified</span></p>\n')
            + f'    <p>Next: {" &middot; ".join(links)}</p>\n')


def join_and(items):
    items = list(items)
    return items[0] if len(items) == 1 else ", ".join(items[:-1]) + " and " + items[-1]


def faqs():
    cs = chains()
    names = join_and([country_name(c) for c in cs])
    verified_waits = [(country_name(c), months(wait_stage(c))) for c in cs if months(wait_stage(c))]
    wait_line = "; ".join(f"{n}: {m}" for n, m in verified_waits)
    far = [country_name(c) for c in cs if c["lineage"]["maxRole"] == "ggp"]
    return [
        ("Which countries pass citizenship down to Americans?",
         f"GoThere covers {names}. Each has its own rules on how far back the line can go, "
         "and the details on this page come from each country's official pages."),
        ("Do I have to move to get a second citizenship by descent?",
         "No move is needed to apply through these routes. Most of the work is collecting birth, marriage and "
         "naturalization records for each person in your line, which is why it is worth starting early."),
        ("How long does it take?",
         f"Official review times where they are published: {wait_line}. Gathering records adds months on top, "
         "depending on how fast each records office answers." if wait_line else
         "Review times vary and are not published for most routes."),
        ("Can a great-grandparent count?",
         (f"In {join_and(far)}, the line can run through a great-grandparent or further. " if far else "")
         + "In Ireland it works only if your parent was registered on the Foreign Births Register before you were born, "
         "and in Italy the 2025 law usually stops the line at a grandparent."),
        ("Is this legal advice?",
         "No. It is information from official sources, dated. Rules and fees change, so check the linked "
         "official page before you apply."),
    ]


def build():
    apple, play = store_links()
    title = "Plan B Passport: Second Citizenship by Descent for Americans (2026)"
    desc = ("Which countries pass citizenship down to children and grandchildren of emigrants, how far back the "
            "line goes, the documents, fees and official review times. Sourced and dated.")
    qa = faqs()
    schema = [
        {"@context": "https://schema.org", "@type": "Article", "headline": title, "description": desc,
         "url": SITE + PATH, "dateModified": CHAINS["generatedAt"],
         "publisher": {"@type": "Organization", "name": "GoThere", "url": SITE}},
        {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "Home", "item": SITE + "/"},
            {"@type": "ListItem", "position": 2, "name": "Plan B", "item": SITE + PATH}]},
        {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in qa]},
    ]
    faq_html = "    <h2>Questions</h2>\n" + "".join(f"    <h3>{esc(q)}</h3>\n    <p>{esc(a)}</p>\n" for q, a in qa)
    body = (
        '    <p class="breadcrumb"><a href="/">Home</a> / Plan B</p>\n'
        '    <h1>Plan B: a second citizenship you may already have a claim to</h1>\n'
        '    <div class="answer"><p>If a parent or grandparent came from Ireland, Italy, Germany, Poland or Hungary, '
        'you may be able to claim that citizenship by descent. It is paperwork, not a move: you can start '
        'collecting records now and decide later whether to use it.</p>'
        '<p>Options, not exits. Applications often take one to three years or more, so the slow part is worth starting early.</p></div>\n'
        f'    <p class="verified">Data verified {esc(CHAINS["generatedAt"])} &middot; Information, not legal advice</p>\n'
        '    <h2>Who passes citizenship down</h2>\n'
        + table()
        + "".join(country_section(c) for c in chains())
        + '    <h2>Track it in GoThere</h2>\n'
        '    <p>The Plan B tab turns a likely result into a checklist for each person in your line: ordered, '
        'received, apostilled, translated, done. It shows where to order every record and keeps a readiness '
        'score. Tracking descent paths is free.</p>\n'
        f'    <div class="cta-box"><h3>Start your Plan B</h3><p>Names and dates stay on your phone.</p>'
        f'<div class="cta-buttons"><a href="{apple}">Download for iOS</a><a href="{play}">Get on Google Play</a></div></div>\n'
        + faq_html
        + f'    <p class="muted">{esc(CHAINS["disclaimer"])}</p>\n')
    page(PATH, title, desc, body, schema, campaign=CAMPAIGN)
    return PATH


if __name__ == "__main__":
    build()
    print("\ndone")
