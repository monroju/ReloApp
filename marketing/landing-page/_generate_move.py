#!/usr/bin/env python3
"""Generate data-driven pages from the canonical visa data (Projects/GoThere/shared/data).

Builds:
    /move/index.html                hub
    /move/us-to-{es,pt,ie,it,mx}/   answer-first country-pair pages (canonical deep pages)
    /move/og/us-to-*.png            per-page OG images
    /updates/index.html             rule-change log, from changelog.json
    /updates/feed.json              JSON Feed 1.1 of the same
    /api/visas.json                 all verified records
    /api/countries/{cc}.json        records per destination
    /llms.txt                       map of the site for LLMs

Every fact on these pages comes from visas.json with its sourceUrl + lastVerified.
Null facts render as "Not yet verified". Never hand-edit the output, edit the data.

USD equivalents use ECB reference rates via Frankfurter (cached in shared/data/fx_cache.json).
"""
import html
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).parent
PROJECT = ROOT.parent.parent.parent
DATA = PROJECT / "shared" / "data"
SITE = "https://getgothere.app"

sys.path.insert(0, str(PROJECT / "_marketing" / "paid"))
from link_builder import apple_link, play_link  # noqa: E402

from _generate_compare import CSS, UMAMI  # noqa: E402

VISAS = json.loads((DATA / "visas.json").read_text(encoding="utf-8"))
CHANGELOG = sorted(json.loads((DATA / "changelog.json").read_text(encoding="utf-8")),
                   key=lambda e: e["date"], reverse=True)
PUBLISHED = "2026-10-26"

COUNTRIES = {
    "ES": {"slug": "es", "name": "Spain", "flag": "🇪🇸", "demonym": "Spanish", "hub": "/spain/",
           "guides": [("/blog/spain-non-lucrative-visa-2026.html", "Spain Non-Lucrative Visa guide")],
           "compare": [("/compare/spain-nlv-vs-dnv/", "Spain NLV vs DNV"),
                       ("/compare/spain-nlv-vs-portugal-d7/", "Spain NLV vs Portugal D7")]},
    "PT": {"slug": "pt", "name": "Portugal", "flag": "🇵🇹", "demonym": "Portuguese", "hub": "/portugal/",
           "guides": [("/blog/portugal-d7-d8-visa-2026.html", "Portugal D7 vs D8 guide")],
           "compare": [("/compare/spain-nlv-vs-portugal-d7/", "Spain NLV vs Portugal D7"),
                       ("/compare/spain-dnv-vs-portugal-d8/", "Spain DNV vs Portugal D8"),
                       ("/compare/portugal-d7-vs-golden-visa/", "Portugal D7 vs Golden Visa")]},
    "IE": {"slug": "ie", "name": "Ireland", "flag": "🇮🇪", "demonym": "Irish", "hub": None,
           "guides": [("/blog/ireland-stamp-0-retiree-visa-2026.html", "Ireland Stamp 0 guide"),
                      ("/blog/ireland-foreign-births-register-2026.html", "Irish citizenship by descent (FBR)")],
           "compare": [("/compare/irish-vs-italian-citizenship-by-descent/", "Irish vs Italian citizenship by descent")]},
    "IT": {"slug": "it", "name": "Italy", "flag": "🇮🇹", "demonym": "Italian", "hub": None,
           "guides": [("/blog/italy-elective-residency-visa-2026.html", "Italy Elective Residence guide"),
                      ("/blog/italy-jure-sanguinis-citizenship-2026.html", "Italian citizenship by descent")],
           "compare": [("/compare/italy-elective-vs-portugal-d7/", "Italy Elective vs Portugal D7")]},
    "MX": {"slug": "mx", "name": "Mexico", "flag": "🇲🇽", "demonym": "Mexican", "hub": "/mexico/",
           "guides": [("/blog/mexico-temporary-resident-visa-2026.html", "Mexico Temporary Resident guide")],
           "compare": [("/compare/passive-income-visas/", "Passive-income visas compared")]},
}

# Presentation only: friendly names and who each route suits. Facts stay in visas.json.
DISPLAY = {
    "es_nlv": ("Non-Lucrative Visa", "retirees and people living on passive income"),
    "es_dnv": ("Digital Nomad Visa", "remote workers for employers or clients outside Spain"),
    "pt_d7": ("D7 Visa", "retirees and people living on passive income"),
    "pt_d8": ("D8 Digital Nomad Visa", "remote workers for employers or clients outside Portugal"),
    "ie_stamp_0": ("Stamp 0 (independent means)", "financially independent retirees"),
    "ie_critical_skills": ("Critical Skills Employment Permit", "skilled workers with an Irish job offer"),
    "it_elective": ("Elective Residence Visa", "retirees and people living on passive income"),
    "it_dnv": ("Digital Nomad Visa", "highly skilled remote workers"),
    "mx_temp_econ": ("Temporary Resident Visa", "people with steady income or savings"),
    "mx_perm": ("Permanent Resident Visa", "retirees with a pension"),
}

WORK = {"no": "No", "foreignOnly": "Foreign employer or clients only", "yes": "Yes",
        "restricted": "Restricted"}
SYMBOL = {"EUR": "€", "USD": "$", "MXN": "MX$"}
NUM = {2: "two", 3: "three", 4: "four"}

EXTRA_CSS = """
    .answer { background:var(--bg-card); border:1px solid var(--border); border-left:3px solid var(--teal); border-radius:8px; padding:18px 22px; margin:8px 0 20px; font-size:17px; }
    .answer p { margin:8px 0; }
    .verified { font-size:13px; color:var(--text-mute); margin:0 0 24px; }
    .src { font-size:12px; margin-left:4px; white-space:nowrap; }
    .nv { color:#fbbf24; font-size:13px; }
    .usd { color:var(--text-mute); font-size:13px; }
    dl.facts { display:grid; grid-template-columns:200px 1fr; gap:8px 16px; margin:16px 0; font-size:15px; }
    dl.facts dt { color:var(--text-mute); } dl.facts dd { margin:0; }
    ol.steps { margin:12px 0 12px 22px; } ol.steps li { margin:6px 0; }
    details { margin:12px 0; font-size:14px; color:var(--text-mute); }
    details summary { cursor:pointer; color:var(--teal); }
    details li { margin:6px 0 6px 18px; }
    .tag { display:inline-block; font-size:12px; padding:2px 8px; border-radius:999px; border:1px solid var(--border); color:var(--text-mute); margin-right:6px; }
    .change { border-bottom:1px solid var(--border); padding:18px 0; }
    .change h2 { font-size:20px; margin:8px 0; }
    .diff { font-size:14px; } .diff del { color:#f87171; } .diff ins { color:var(--teal); text-decoration:none; }
    @media (max-width:600px){ dl.facts{grid-template-columns:1fr;} dl.facts dt{margin-top:8px;} }
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
  <meta property="og:title" content="{title}">
  <meta property="og:description" content="{desc}">
  <meta property="og:url" content="{canonical}">
  <meta property="og:type" content="article">
  <meta property="og:image" content="{og_image}">
  <meta name="twitter:card" content="summary_large_image">
  {schema}
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=DM+Sans:wght@500;700&display=swap" rel="stylesheet">
  <style>{css}</style>
</head>
<body>
  <nav><div class="container"><a href="/" class="logo">GoThere</a><a href="{nav_app}">Get the app &rarr;</a></div></nav>
  <main class="container">
"""

FOOTER = """  </main>
  <footer><div class="container"><p>&copy; 2026 GoThere &middot; <a href="/">Home</a> &middot; <a href="/move/">Move abroad</a> &middot; <a href="/compare/">Compare visas</a> &middot; <a href="/updates/">Rule changes</a> &middot; <a href="/blog/">Blog</a></p>
  <p>GoThere is research, not legal advice. Rules change; confirm with the consulate or a qualified immigration lawyer before you file.</p></div></footer>
</body>
</html>
"""


# ---------- helpers ----------

def esc(s):
    return html.escape(str(s), quote=True)


def load_fx():
    """USD per unit of EUR/MXN from Frankfurter (ECB). Falls back to the cached copy."""
    cache = DATA / "fx_cache.json"
    try:
        with urllib.request.urlopen("https://api.frankfurter.dev/v1/latest?base=USD&symbols=EUR,MXN",
                                    timeout=15) as r:
            fx = json.load(r)
        cache.write_text(json.dumps(fx, indent=2) + "\n", encoding="utf-8")
    except Exception as e:  # offline build: use last good rates
        print(f"  FX fetch failed ({e}), using cache")
        fx = json.loads(cache.read_text(encoding="utf-8"))
    return fx


FX = load_fx()


def money(amount, cur, usd=True):
    s = f"{amount:,.0f}" if amount >= 100 else f"{amount:,.2f}"
    out = f"{SYMBOL.get(cur, cur + ' ')}{s}"
    if usd and cur != "USD" and cur in FX["rates"]:
        out += f' <span class="usd">(≈ ${amount / FX["rates"][cur]:,.0f})</span>'
    return out


def src(obj):
    if not obj or not obj.get("sourceUrl"):
        return ""
    label = "official source" if obj.get("sourceType") == "official" else "source"
    return f'<a class="src" href="{esc(obj["sourceUrl"])}" rel="nofollow noopener" target="_blank">[{label}]</a>'


NV = '<span class="nv">Not yet verified</span>'


def years(n):
    if n == 0:
        return "immediately"
    if n != int(n):
        return f"{round(n * 12)} months"
    return f"{n:g} year" + ("" if n == 1 else "s")


def income_text(v, usd=True):
    inc = v["income"]
    if inc.get("monthly") is not None:
        return f'{money(inc["monthly"], inc["currency"], usd)}/month'
    if inc.get("annual") is not None:
        return f'{money(inc["annual"], inc["currency"], usd)}/year'
    return None


def processing_text(v):
    p = v["processingTimeDays"]
    if p.get("max") is None:
        return None
    if not p.get("min"):
        return f'up to {p["max"]} days'
    return f'about {p["max"]} days' if p["min"] == p["max"] else f'{p["min"]}–{p["max"]} days'


def fees_text(v, usd=True):
    if not v["fees"]:
        return None
    return "; ".join(f'{esc(f["label"])}: {money(f["amount"], f["currency"], usd)}' for f in v["fees"])


def plain(s):
    """Strip tags for JSON-LD answers."""
    import re
    return re.sub(r"<[^>]+>", "", s).replace("≈", "about ")


def store_links(campaign):
    return apple_link("gothere", "move", campaign), play_link("gothere", "move", campaign, medium="organic")


def write(path, text):
    out = ROOT / path.lstrip("/")
    if out.suffix == "":
        out = out / "index.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8", newline="\n")
    print(f"  -> {path}")


def page(path, title, desc, body, schema, og_image=f"{SITE}/og-image.png", campaign="hub"):
    apple, _ = store_links(campaign)
    schema_html = "\n  ".join(
        f'<script type="application/ld+json">{json.dumps(s, ensure_ascii=False)}</script>' for s in schema)
    write(path, HEAD.format(umami=UMAMI, title=esc(title), desc=esc(desc), canonical=SITE + path,
                            og_image=og_image, schema=schema_html, css=CSS + EXTRA_CSS, nav_app=apple)
          + body + FOOTER)


def cta(campaign, heading, sub):
    apple, play = store_links(campaign)
    return (f'    <div class="cta-box"><h3>{heading}</h3><p>{sub}</p><div class="cta-buttons">'
            f'<a href="{apple}">Download for iOS</a><a href="{play}">Get on Google Play</a></div></div>\n')


def og_image(slug, country):
    from PIL import Image, ImageDraw, ImageFont
    w, h = 1200, 630
    im = Image.new("RGB", (w, h), "#0B0F14")
    d = ImageDraw.Draw(im)
    d.rectangle([0, h - 10, w, h], fill="#15B8A6")
    icon = Image.open(ROOT / "app-icon.png").convert("RGBA").resize((120, 120))
    im.paste(icon, (80, 70), icon)
    bold = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 92)
    semi = ImageFont.truetype("C:/Windows/Fonts/seguisb.ttf", 40)
    d.text((225, 95), "GoThere", font=ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 56), fill="#F1F5F9")
    d.text((80, 260), "US to " + country, font=bold, fill="#F1F5F9")
    d.text((80, 370), "Visas, income and steps in 2026", font=semi, fill="#15B8A6")
    d.text((80, 530), "Every figure sourced and dated  ·  getgothere.app", font=semi, fill="#94A3B8")
    out = ROOT / "move" / "og" / f"us-to-{slug}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out, optimize=True)
    return f"{SITE}/move/og/us-to-{slug}.png"


# ---------- /move/us-to-xx/ ----------

def visa_section(v, c):
    name, who = DISPLAY[v["id"]]
    inc, sav, dur = v["income"], v["savings"], v["duration"]
    rows = []
    it = income_text(v)
    rows.append(("Income required", (it + (f' <span class="usd">({esc(inc["basis"])})</span>' if inc.get("basis") else "") + src(inc)) if it else NV))
    if inc.get("perDependent"):
        rows.append(("Per dependent", esc(inc["perDependent"]) + src(inc)))
    if sav.get("amount") is not None:
        rows.append(("Savings alternative", money(sav["amount"], sav["currency"]) + src(sav)))
    elif sav.get("basis"):
        rows.append(("Savings", esc(sav["basis"]) + src(sav)))
    pt = processing_text(v)
    rows.append(("Decision time", (pt + src(v["processingTimeDays"])) if pt else NV))
    ft = fees_text(v)
    rows.append(("Government fees", (ft + " " + "".join(src(f) for f in v["fees"][:1])) if ft else NV))
    if dur.get("initialMonths"):
        rows.append(("First permit", f'{dur["initialMonths"]} months' + (f'; {esc(dur["renewal"][:1].lower() + dur["renewal"][1:])}' if dur.get("renewal") else "") + src(dur)))
    wa = v["workAllowed"].get("value")
    rows.append(("Can you work?", (WORK[wa] + src(v["workAllowed"])) if wa else NV))
    pr = v["pathToPR"].get("years")
    rows.append(("Permanent residence", ((years(pr) if pr == 0 else f"after {years(pr)}") + src(v["pathToPR"])) if pr is not None else NV))
    cz = v["pathToCitizenship"].get("years")
    rows.append(("Citizenship", (f"after {years(cz)} of residence" + src(v["pathToCitizenship"])) if cz is not None else NV))

    out = f'    <h2 id="{v["id"]}">{c["name"]} {esc(name)}: who it suits and what it takes</h2>\n'
    out += f"    <p>For {who}. Official name: <em>{esc(v['name'])}</em>.</p>\n"
    out += '    <dl class="facts">\n' + "".join(f"      <dt>{k}</dt><dd>{val}</dd>\n" for k, val in rows) + "    </dl>\n"
    if v["steps"]:
        out += f"    <h3>How to apply for the {esc(name)} from the US</h3>\n    <ol class=\"steps\">\n"
        for s in v["steps"]:
            detail = f" {esc(s['detail'])}" if s.get("detail") else ""
            out += f'      <li><strong>{esc(s["title"])}.</strong>{detail}{src(s)}</li>\n'
        out += "    </ol>\n"
    notes = [(label, v[f].get("note")) for label, f in [
        ("Income", "income"), ("Savings", "savings"), ("Decision time", "processingTimeDays"),
        ("Duration", "duration"), ("Work", "workAllowed"), ("Permanent residence", "pathToPR"),
        ("Citizenship", "pathToCitizenship")] if v[f].get("note")]
    if notes:
        out += "    <details><summary>Legal basis and notes</summary><ul>\n"
        out += "".join(f"      <li><strong>{k}:</strong> {esc(n)}</li>\n" for k, n in notes)
        out += "    </ul></details>\n"
    if v.get("verificationNotes"):
        out += f"    <details><summary>What we could not verify</summary><p>{esc(v['verificationNotes'])}</p></details>\n"
    return out


def faqs_for(c, visas):
    qa = []
    for v in visas:
        name = DISPLAY[v["id"]][0]
        it = income_text(v)
        if it:
            basis = f' ({v["income"]["basis"]})' if v["income"].get("basis") else ""
            qa.append((f"How much income do I need for the {c['name']} {name}?",
                       f"{it}{esc(basis)}, according to the official source, last checked {v['income']['lastVerified']}."))
        pt = processing_text(v)
        if pt:
            qa.append((f"How long does the {c['name']} {name} take?",
                       f"The official decision period is {pt}. Real-world timelines are often longer once you add document gathering and appointments."))
        wa = v["workAllowed"].get("value")
        if wa:
            qa.append((f"Can I work in {c['name']} on the {name}?", WORK[wa] + "."))
    cit = [(DISPLAY[v["id"]][0], v["pathToCitizenship"].get("years")) for v in visas]
    known = [f"{years(y)} on the {n}" for n, y in cit if y is not None]
    if known:
        qa.append((f"How long until I can become a {c['demonym']} citizen?",
                   f"Counting legal residence: {'; '.join(known)}. Citizenship by descent, if you qualify, can be much faster."))
    return qa


def build_country(cc, c):
    order = list(DISPLAY)
    visas = sorted((v for v in VISAS if v["country"] == cc and "US" in v["from"]), key=lambda v: order.index(v["id"]))
    if not visas:
        return None
    slug = f"us-to-{c['slug']}"
    path = f"/move/{slug}/"
    verified = max(v["lastVerified"] for v in visas)

    parts = []
    for v in visas:
        name, who = DISPLAY[v["id"]]
        it = income_text(v, usd=True)
        need = f", which needs {it}" if it else ""
        parts.append(f"the <a href=\"#{v['id']}\">{esc(name)}</a> for {who}{need}")
    answer = (f"<p>Most Americans move to {c['name']} on one of {NUM.get(len(visas), len(visas))} routes: "
              + "; or ".join(parts) + ".</p>")
    cz = [(DISPLAY[v["id"]][0], v["pathToCitizenship"].get("years")) for v in visas]
    if all(y is not None for _, y in cz) and len({y for _, y in cz}) == 1:
        answer += f"<p>Either way, {c['demonym']} citizenship takes {years(cz[0][1])} of legal residence.</p>"

    title = f"Moving from the US to {c['name']} in 2026: Visas, Income & Steps"
    desc = (f"How Americans move to {c['name']} in 2026: " + ", ".join(DISPLAY[v['id']][0] for v in visas)
            + f". Income thresholds, fees, timelines and steps, each linked to the official source. Verified {verified}.")

    body = f'    <div class="breadcrumb"><a href="/">Home</a> &rsaquo; <a href="/move/">Move abroad</a> &rsaquo; US to {c["name"]}</div>\n'
    body += f"    <h1>Moving from the US to {c['name']} in 2026</h1>\n"
    body += f'    <div class="answer">{answer}</div>\n'
    body += (f'    <p class="verified">Last verified {verified} against official {c["name"]} government and consulate pages. '
             'Every figure links to its source. USD amounts are approximate, at the ECB reference rate of '
             f'{FX["date"]}.</p>\n')

    body += f"    <h2>{c['name']} visas for Americans at a glance</h2>\n    <div class=\"table-wrap\"><table>\n"
    body += "      <tr><th>Route</th><th>Income</th><th>Decision time</th><th>Work</th><th>Permanent residence</th><th>Citizenship</th></tr>\n"
    for v in visas:
        it = income_text(v, usd=False)
        pt = processing_text(v)
        wa = v["workAllowed"].get("value")
        pr, cz2 = v["pathToPR"].get("years"), v["pathToCitizenship"].get("years")
        body += (f'      <tr><td class="visa"><a href="#{v["id"]}">{esc(DISPLAY[v["id"]][0])}</a></td>'
                 f"<td>{it or NV}</td><td>{pt or NV}</td><td>{WORK[wa] if wa else NV}</td>"
                 f"<td>{years(pr).capitalize() if pr is not None else NV}</td><td>{years(cz2) if cz2 is not None else NV}</td></tr>\n")
    body += "    </table></div>\n"

    for v in visas:
        body += visa_section(v, c)

    qa = faqs_for(c, visas)
    body += f"    <h2>Questions Americans ask about moving to {c['name']}</h2>\n"
    for q, a in qa:
        body += f"    <h3>{esc(q)}</h3>\n    <p>{a}</p>\n"

    body += "    <h2>Go deeper</h2>\n    <ul>\n"
    if c["hub"]:
        body += f'      <li><a href="{c["hub"]}">{c["name"]} city guides</a></li>\n'
    for href, label in c["guides"] + c["compare"]:
        body += f'      <li><a href="{href}">{label}</a></li>\n'
    body += '      <li><a href="/updates/">Recent rule changes</a></li>\n'
    body += f'      <li><a href="/api/countries/{c["slug"]}.json">This data as JSON</a></li>\n    </ul>\n'
    body += cta(slug, f"Plan your move to {c['name']}",
                "GoThere checks your income and family against each route, then tracks every document and deadline for the one you pick.")

    url = SITE + path
    schema = [
        {"@context": "https://schema.org", "@type": "Article", "headline": title, "description": desc,
         "datePublished": PUBLISHED, "dateModified": verified, "mainEntityOfPage": url,
         "author": {"@type": "Organization", "name": "GoThere", "url": SITE},
         "publisher": {"@type": "Organization", "name": "GoThere", "url": SITE},
         "citation": sorted({v["officialUrl"] for v in visas})},
        {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "Home", "item": SITE + "/"},
            {"@type": "ListItem", "position": 2, "name": "Move abroad", "item": SITE + "/move/"},
            {"@type": "ListItem", "position": 3, "name": f"US to {c['name']}", "item": url}]},
        {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": plain(a)}} for q, a in qa]},
    ]
    page(path, title, desc, body, schema, og_image=og_image(c["slug"], c["name"]), campaign=slug)
    return {"cc": cc, "path": path, "c": c, "visas": visas, "verified": verified}


def build_hub(built):
    body = '    <div class="breadcrumb"><a href="/">Home</a> &rsaquo; Move abroad</div>\n'
    body += "    <h1>Move abroad from the US: country guides for 2026</h1>\n"
    body += ('    <p class="lede">One page per destination with the visas Americans actually use, the income '
             "each one needs, how long it takes and the steps, every figure linked to the official source.</p>\n")
    body += '    <div class="grid">\n'
    for b in built:
        names = ", ".join(DISPLAY[v["id"]][0] for v in b["visas"])
        body += (f'    <a class="tile" href="{b["path"]}"><h3>{b["c"]["flag"]} US to {b["c"]["name"]}</h3>'
                 f"<p>{esc(names)}. Verified {b['verified']}.</p></a>\n")
    body += "    </div>\n"
    body += ('    <div class="callout">Do you earn enough? Try the <a href="/tools/visa-income-calculator/">visa income calculator</a>. '
             'Rules change: see <a href="/updates/">what changed recently</a>, or <a href="/compare/">compare visas side by side</a>.</div>\n')
    body += cta("hub", "Not sure which country fits?", "GoThere matches your income, timeline and family to the routes you qualify for.")
    schema = [{"@context": "https://schema.org", "@type": "CollectionPage", "name": "Move abroad from the US",
               "url": SITE + "/move/", "hasPart": [SITE + b["path"] for b in built]}]
    page("/move/", "Move Abroad From the US in 2026: Country Guides", "Country-by-country guides for Americans moving abroad in 2026: Spain, Portugal, Ireland, Italy and Mexico. Visas, income, fees and steps with official sources.",
         body, schema)


# ---------- /updates/ ----------

def build_updates():
    body = '    <div class="breadcrumb"><a href="/">Home</a> &rsaquo; Rule changes</div>\n'
    body += "    <h1>Visa and residency rule changes</h1>\n"
    body += ('    <p class="lede">Changes we have verified in the rules Americans use to move abroad. '
             'Each entry links to the official source. Also as a <a href="/updates/feed.json">JSON feed</a>.</p>\n')
    names = {cc: c["name"] for cc, c in COUNTRIES.items()}
    for e in CHANGELOG:
        country = names.get(e["country"], e["country"])
        move = f'/move/us-to-{e["country"].lower()}/' if e["country"] in COUNTRIES else None
        body += f'    <div class="change" id="{e["date"]}-{e["country"].lower()}-{e["visaIds"][0]}">\n'
        body += f'      <span class="tag">{e["date"]}</span><span class="tag">{country}</span><span class="tag">{e["kind"]}</span>\n'
        body += f'      <h2>{esc(e["title"])}</h2>\n      <p>{esc(e["summary"])}</p>\n'
        body += f'      <p class="diff">Was: <del>{esc(e["old"])}</del> &rarr; Now: <ins>{esc(e["new"])}</ins> '
        body += f'<a class="src" href="{esc(e["sourceUrl"])}" rel="nofollow noopener" target="_blank">[official source]</a>'
        if move:
            body += f' &middot; <a href="{move}">US to {country} guide</a>'
        body += "</p>\n    </div>\n"
    schema = [{"@context": "https://schema.org", "@type": "CollectionPage", "name": "Visa and residency rule changes",
               "url": SITE + "/updates/", "dateModified": CHANGELOG[0]["date"] if CHANGELOG else PUBLISHED}]
    page("/updates/", "Visa Rule Changes for Americans Moving Abroad (2026)",
         "Verified changes to visa, residency and citizenship rules for Americans moving abroad: income thresholds, fees and citizenship timelines, with official sources.",
         body, schema)

    feed = {"version": "https://jsonfeed.org/version/1.1", "title": "GoThere: visa rule changes",
            "home_page_url": SITE + "/updates/", "feed_url": SITE + "/updates/feed.json",
            "items": [{"id": f'{e["date"]}-{e["country"]}-{"-".join(e["visaIds"])}',
                       "url": f'{SITE}/updates/#{e["date"]}-{e["country"].lower()}-{e["visaIds"][0]}',
                       "title": e["title"], "content_text": e["summary"], "date_published": e["date"] + "T00:00:00Z",
                       "external_url": e["sourceUrl"], "tags": [e["country"], e["kind"]]} for e in CHANGELOG]}
    (ROOT / "updates" / "feed.json").write_text(json.dumps(feed, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("  -> /updates/feed.json")


# ---------- /api/ + /llms.txt ----------

API_META = {
    "publisher": "GoThere (https://getgothere.app)",
    "disclaimer": "Research, not legal advice. Each fact carries sourceUrl and lastVerified; null means not yet verified. Confirm with the consulate before filing.",
    "schema": SITE + "/api/visa.schema.json",
}


def build_api(built):
    api = ROOT / "api"
    (api / "countries").mkdir(parents=True, exist_ok=True)
    (api / "visa.schema.json").write_text((DATA / "schema" / "visa.schema.json").read_text(encoding="utf-8"), encoding="utf-8")
    (api / "visas.json").write_text(json.dumps({**API_META, "visas": VISAS}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    index = {**API_META, "countries": []}
    for b in built:
        c = b["c"]
        doc = {**API_META, "country": b["cc"], "name": c["name"], "guide": SITE + b["path"],
               "lastVerified": b["verified"], "visas": b["visas"]}
        (api / "countries" / f'{c["slug"]}.json').write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        index["countries"].append({"country": b["cc"], "name": c["name"], "url": f'{SITE}/api/countries/{c["slug"]}.json',
                                   "lastVerified": b["verified"]})
    (api / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"  -> /api/ ({len(built)} countries)")


def build_llms(built):
    lines = ["# GoThere", "",
             "> GoThere helps Americans move abroad: which visa fits, how much income it needs, how long it takes, "
             "and the steps. Facts on the pages below link to official government sources and carry a last-verified date.", "",
             "## Country guides (US to X)", ""]
    for b in built:
        names = ", ".join(DISPLAY[v["id"]][0] for v in b["visas"])
        lines.append(f'- [US to {b["c"]["name"]}]({SITE}{b["path"]}): {names}. Verified {b["verified"]}.')
    lines += ["", "## Data", "",
              f"- [Visa data index]({SITE}/api/index.json): JSON, one file per country, every fact with sourceUrl + lastVerified",
              f"- [All visas]({SITE}/api/visas.json): every verified record",
              f"- [Rule changes]({SITE}/updates/): verified changes, also as [JSON Feed]({SITE}/updates/feed.json)",
              "", "## Compare", "",
              f"- [Compare visas]({SITE}/compare/): passive income, digital nomad, work, investment and citizenship-by-descent routes side by side",
              "", "## Tools", "",
              f"- [Citizenship by descent checker]({SITE}/tools/citizenship-by-descent/): web form over the same rules, Ireland and Canada",
              f"- [Visa income calculator]({SITE}/tools/visa-income-calculator/): your income against every verified visa threshold, ECB exchange rates",
              f"- [Citizenship by descent MCP server]({SITE}/mcp): deterministic eligibility checks for Ireland and Canada (MCP Registry: app.getgothere/citizenship)",
              "", "## Optional", "",
              f"- [Blog]({SITE}/blog/): long-form visa guides",
              f"- [Safe Harbor Index]({SITE}/safe-harbor/): destination safety for specific groups", ""]
    (ROOT / "llms.txt").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print("  -> /llms.txt")


def main():
    built = [b for cc, c in COUNTRIES.items() if (b := build_country(cc, c))]
    build_hub(built)
    build_updates()
    build_api(built)
    build_llms(built)
    print("\ndone")


if __name__ == "__main__":
    main()
