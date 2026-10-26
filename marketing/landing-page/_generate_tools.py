#!/usr/bin/env python3
"""Generate the free tools (growth Phase 4).

Builds:
    /tools/index.html                          hub
    /tools/citizenship-by-descent/index.html   D9: descent checker (Ireland, Canada)
    /tools/visa-income-calculator/index.html   D10: income vs visa thresholds

Single source of truth:
  - The descent checker runs the deterministic rules in eligibility-engine. The page
    calls the live MCP endpoint (/mcp/, same origin) from the browser; pathways and
    requirements are pulled from the same endpoint at build time. No rules live here.
  - The income calculator reads shared/data/visas.json (via _generate_move) and the
    ECB reference rates cached by _generate_move.load_fx(). Rates are dated on the page.
"""
import json
import urllib.request

from _generate_move import (COUNTRIES, DISPLAY, EXTRA_CSS, FOOTER, FX, HEAD, SITE, UMAMI, VISAS,
                            apple_link, esc, money, play_link, src, write)
from _generate_compare import CSS

MCP_URL = f"{SITE}/mcp/"
PUBLISHED = "2026-10-26"

TOOLS_CSS = """
    [hidden] { display:none !important; }
    form.tool { background:var(--bg-card); border:1px solid var(--border); border-radius:8px; padding:20px 22px; margin:16px 0; }
    form.tool fieldset { border:0; padding:0; margin:0 0 16px; }
    form.tool legend { font-weight:600; margin-bottom:8px; }
    form.tool label { display:block; font-size:14px; color:var(--text-mute); margin:8px 0 4px; }
    form.tool input, form.tool select { background:var(--bg); color:var(--text); border:1px solid var(--border); border-radius:6px; padding:8px 10px; font:inherit; width:100%; max-width:260px; box-sizing:border-box; }
    form.tool .row { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:4px 16px; padding:12px 0; border-top:1px solid var(--border); }
    form.tool .row h3 { grid-column:1/-1; margin:0; font-size:16px; }
    form.tool .radios label { display:inline-flex; align-items:center; gap:6px; margin-right:18px; color:var(--text); font-size:15px; }
    form.tool .radios input { width:auto; }
    form.tool button { background:var(--teal); color:#0B0F14; border:0; border-radius:8px; padding:12px 22px; font:inherit; font-weight:600; cursor:pointer; margin-top:8px; }
    form.tool .check { display:flex; align-items:center; gap:8px; color:var(--text); font-size:15px; }
    form.tool .check input { width:auto; }
    .result { margin:20px 0; }
    .result .band { border-radius:8px; padding:16px 20px; border:1px solid var(--border); background:var(--bg-card); }
    .band.green { border-left:4px solid #22c55e; } .band.yellow { border-left:4px solid #fbbf24; } .band.red { border-left:4px solid #f87171; }
    .band h2 { margin:0 0 8px; font-size:20px; }
    .band ul { margin:8px 0 8px 20px; } .band li { margin:4px 0; }
    .muted { color:var(--text-mute); font-size:14px; }
    table.calc { width:100%; border-collapse:collapse; font-size:15px; margin:12px 0; }
    table.calc th, table.calc td { text-align:left; padding:10px 8px; border-bottom:1px solid var(--border); vertical-align:top; }
    table.calc th { color:var(--text-mute); font-weight:500; font-size:13px; }
    .ok { color:#22c55e; font-weight:600; } .short { color:#f87171; font-weight:600; } .close { color:#fbbf24; font-weight:600; }
    .tools-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); gap:16px; margin:20px 0; }
    .tools-grid a.card { display:block; background:var(--bg-card); border:1px solid var(--border); border-radius:8px; padding:20px; text-decoration:none; color:var(--text); }
    .tools-grid a.card h2 { font-size:19px; margin:0 0 8px; color:var(--teal); }
    @media (max-width:600px){ table.calc thead { display:none; } table.calc td { display:block; border:0; padding:4px 0; } table.calc tr { display:block; border-bottom:1px solid var(--border); padding:10px 0; } }
"""

TOOLS_FOOTER = FOOTER.replace('<a href="/updates/">Rule changes</a>',
                              '<a href="/updates/">Rule changes</a> &middot; <a href="/tools/">Free tools</a>')


def store_links(campaign):
    return apple_link("gothere", "tools", campaign), play_link("gothere", "tools", campaign, medium="organic")


def page(path, title, desc, body, schema, campaign):
    apple, _ = store_links(campaign)
    schema_html = "\n  ".join(
        f'<script type="application/ld+json">{json.dumps(s, ensure_ascii=False)}</script>' for s in schema)
    write(path, HEAD.format(umami=UMAMI, title=esc(title), desc=esc(desc), canonical=SITE + path,
                            og_image=f"{SITE}/og-image.png", schema=schema_html,
                            css=CSS + EXTRA_CSS + TOOLS_CSS, nav_app=apple)
          + body + TOOLS_FOOTER)


def cta(campaign, heading, sub):
    apple, play = store_links(campaign)
    return (f'    <div class="cta-box"><h3>{heading}</h3><p>{sub}</p><div class="cta-buttons">'
            f'<a href="{apple}">Download for iOS</a><a href="{play}">Get on Google Play</a></div></div>\n')


def breadcrumb(path, name):
    return {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": 1, "name": "Home", "item": SITE + "/"},
        {"@type": "ListItem", "position": 2, "name": "Free tools", "item": SITE + "/tools/"},
        {"@type": "ListItem", "position": 3, "name": name, "item": SITE + path}]}


def webapp(path, name, desc):
    return {"@context": "https://schema.org", "@type": "WebApplication", "name": name, "url": SITE + path,
            "description": desc, "applicationCategory": "UtilitiesApplication", "operatingSystem": "Any",
            "isAccessibleForFree": True, "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
            "publisher": {"@type": "Organization", "name": "GoThere", "url": SITE}}


def faq_schema(faqs):
    return {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
        {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in faqs]}


def faq_html(faqs):
    out = "    <h2>Questions</h2>\n"
    for q, a in faqs:
        out += f"    <h3>{esc(q)}</h3>\n    <p>{esc(a)}</p>\n"
    return out


# ---------- D9: descent checker ----------

def mcp_call(tool, arguments):
    """Call the live rules engine. Build fails loudly rather than shipping stale rules."""
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "tools/call",
                       "params": {"name": tool, "arguments": arguments}}).encode()
    req = urllib.request.Request(MCP_URL, data=body, method="POST", headers={
        "Content-Type": "application/json", "Accept": "application/json, text/event-stream",
        "Origin": SITE, "User-Agent": "gothere-site-build"})
    with urllib.request.urlopen(req, timeout=20) as r:
        res = json.load(r)["result"]
    if res.get("isError"):
        raise RuntimeError(f"{tool} failed: {res['content'][0]['text']}")
    sc = res["structuredContent"]
    return sc.get("result", sc)  # list-returning tools are wrapped as {"result": [...]}


DESCENT_JS = r"""
<script>
(function () {
  var MCP = "/mcp/";
  var form = document.getElementById("descent");
  var out = document.getElementById("descent-result");
  var REL = ["self", "parent", "grandparent", "great_grandparent"];

  function el(tag, text, cls) { var e = document.createElement(tag); if (text) e.textContent = text; if (cls) e.className = cls; return e; }
  function list(title, items) {
    var frag = document.createDocumentFragment();
    if (!items || !items.length) return frag;
    frag.appendChild(el("h3", title));
    var ul = el("ul"); items.forEach(function (t) { ul.appendChild(el("li", t)); }); frag.appendChild(ul);
    return frag;
  }
  function num(name) { var v = form.elements[name] && form.elements[name].value; return v === "" || v == null ? null : parseInt(v, 10); }

  function sync() {
    var country = form.elements.country.value;
    var ggp = form.elements.add_ggp.checked;
    document.querySelectorAll("[data-only]").forEach(function (n) { n.hidden = n.getAttribute("data-only") !== country; });
    document.getElementById("row-great_grandparent").hidden = !ggp;
  }
  form.addEventListener("change", sync); sync();

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var country = form.elements.country.value;
    var depth = form.elements.add_ggp.checked ? 4 : 3;
    var line = [];
    for (var i = 0; i < depth; i++) {
      var r = REL[i], m = { relation: r };
      var born = form.elements[r + "_born"].value; if (born) m.birth_country = born;
      var y = num(r + "_year"); if (y) m.birth_year = y;
      if (country === "ie") {
        var reg = num(r + "_fbr"); if (reg) { m.citizenship_registered_country = "IE"; m.citizenship_registered_year = reg; }
      } else {
        var nat = num(r + "_nat"); if (nat) { m.naturalized_country = "CA"; m.naturalized_year = nat; }
        var days = num(r + "_days"); if (days != null) m.days_in_country = days;
      }
      line.push(m);
    }
    out.textContent = "Checking…";
    fetch(MCP, { method: "POST", headers: { "Content-Type": "application/json", "Accept": "application/json, text/event-stream" },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "check_descent_eligibility", arguments: { country: country, line: line } } }) })
      .then(function (r) { if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); })
      .then(function (j) {
        out.textContent = "";
        if (j.error) throw new Error(j.error.message);
        var res = j.result;
        if (res.isError) {
          var box = el("div", null, "band yellow"); box.appendChild(el("h2", "Need a bit more"));
          box.appendChild(el("p", res.content[0].text)); out.appendChild(box);
          if (window.gtTrack) window.gtTrack("tool_descent_check", { country: country, confidence: "refused" });
          return;
        }
        var d = res.structuredContent;
        var band = el("div", null, "band " + d.confidence);
        band.appendChild(el("h2", d.verdict));
        band.appendChild(el("p", d.rationale));
        band.appendChild(list("What supports it", d.supporting_facts));
        band.appendChild(list("Blocking", d.blockers));
        band.appendChild(list("Still to prove", d.missing));
        if (d.next_action) { band.appendChild(el("h3", "Next step")); band.appendChild(el("p", d.next_action)); }
        band.appendChild(list("Assumptions in this answer", d.caveats));
        band.appendChild(el("p", d.disclaimer, "muted"));
        if (d.confidence !== "red") {
          var a = el("a", "Documents, cost and processing time for this pathway →"); a.href = "#requirements-" + country;
          band.appendChild(a);
        }
        out.appendChild(band);
        out.scrollIntoView({ behavior: "smooth", block: "start" });
        if (window.gtTrack) window.gtTrack("tool_descent_check", { country: country, confidence: d.confidence, generations: depth });
      })
      .catch(function (err) {
        out.textContent = "";
        var box = el("div", null, "band red"); box.appendChild(el("h2", "The checker is unavailable right now"));
        box.appendChild(el("p", "Please try again in a minute. (" + err.message + ")")); out.appendChild(box);
      });
  });
})();
</script>
"""

BORN = [("US", "United States"), ("IE", "Ireland (including Northern Ireland)"), ("CA", "Canada"),
        ("GB", "United Kingdom (outside Northern Ireland)"), ("ZZ", "Somewhere else")]
EXAMPLE_YEAR = {"self": 1990, "parent": 1962, "grandparent": 1935, "great_grandparent": 1905}
REL_LABEL = {"self": "You", "parent": "Your parent (on this side of the family)",
             "grandparent": "Their parent (your grandparent)",
             "great_grandparent": "Their parent (your great-grandparent)"}


def gen_row(rel, default_born):
    opts = "".join(f'<option value="{c}"{" selected" if c == default_born else ""}>{esc(n)}</option>'
                   for c, n in BORN)
    hidden = ' hidden' if rel == "great_grandparent" else ""
    row = (f'      <div class="row" id="row-{rel}"{hidden}><h3>{REL_LABEL[rel]}</h3>\n'
           f'        <div><label for="{rel}_born">Born in</label><select id="{rel}_born" name="{rel}_born">{opts}</select></div>\n'
           f'        <div><label for="{rel}_year">Birth year</label><input id="{rel}_year" name="{rel}_year" type="number" min="1850" max="2026" inputmode="numeric" placeholder="e.g. {EXAMPLE_YEAR[rel]}"></div>\n')
    if rel == "parent":
        # Ireland: only the parent's own FBR registration date decides (1956 Act s.7(3)).
        row += (f'        <div data-only="ie"><label for="{rel}_fbr">Year added to Irish Foreign Births Register</label>'
                f'<input id="{rel}_fbr" name="{rel}_fbr" type="number" min="1900" max="2026" inputmode="numeric" placeholder="blank if never"></div>\n')
    if rel != "self":
        row += (f'        <div data-only="ca"><label for="{rel}_nat">Year naturalized as Canadian</label>'
                f'<input id="{rel}_nat" name="{rel}_nat" type="number" min="1850" max="2026" inputmode="numeric" placeholder="blank if not"></div>\n')
    if rel == "parent":
        row += (f'        <div data-only="ca"><label for="{rel}_days">Days they lived in Canada before your birth</label>'
                f'<input id="{rel}_days" name="{rel}_days" type="number" min="0" max="40000" inputmode="numeric" placeholder="only if known"></div>\n')
    return row + "      </div>\n"


def requirements_html(req):
    docs = "".join(f"<li>{esc(d)}</li>" for d in req["documents"])
    return (f'    <h3 id="requirements-{req["country_code"]}">{esc(req["country_name"])}</h3>\n'
            f'    <dl class="facts"><dt>Cost</dt><dd>{esc(req["cost"])}</dd>'
            f'<dt>Processing time</dt><dd>{esc(req["processing_time"])}</dd>'
            f'<dt>Official site</dt><dd><a class="src" href="{esc(req["official_url"])}" rel="nofollow noopener" target="_blank">{esc(req["official_url"])}</a></dd></dl>\n'
            f'    <p><strong>Documents:</strong></p><ul>{docs}</ul>\n'
            f'    <p><strong>Watch out:</strong> {esc(req["gotcha"])}</p>\n')


def build_descent():
    path = "/tools/citizenship-by-descent/"
    pathways = mcp_call("list_pathways", {})
    supported = [p for p in pathways if p["status"] == "supported"]
    planned = [p for p in pathways if p["status"] != "supported"]
    reqs = [mcp_call("get_pathway_requirements", {"country": p["country_code"]}) for p in supported]
    verified = reqs[0]["rules_verified_as_of"]
    names = " and ".join(p["country_name"] for p in supported)

    title = f"Citizenship by Descent Checker: {names} (Free, 2026)"
    desc = (f"Check in a minute whether a parent, grandparent or great-grandparent gives you "
            f"{names.replace(' and ', ' or ')} citizenship by descent. Free, no names asked, nothing stored.")
    faqs = [
        ("Can I get Irish citizenship through my grandparent?",
         "Yes, if your grandparent was born on the island of Ireland, including Northern Ireland. You apply through "
         "the Foreign Births Register. A great-grandparent only works if your parent was registered on the "
         "Foreign Births Register before you were born."),
        ("Can I get Canadian citizenship through my grandparent?",
         "Since Bill C-3 took effect on 15 December 2025, the first-generation limit is gone, so many grandchildren "
         "of Canadians are now citizens. For people born after that date in the second or later generation, the "
         "Canadian parent must have spent 1,095 days in Canada before the birth."),
        ("Does this checker store my family details?",
         "No. It asks for countries and years only, never names. The answer is computed and nothing is saved."),
        ("Which countries does it cover?",
         f"{names} today. " + ", ".join(p["country_name"] for p in planned)
         + " are in progress, and the checker says so rather than guessing."),
    ]
    schema = [webapp(path, "Citizenship by descent checker", desc), breadcrumb(path, "Citizenship by descent checker"),
              faq_schema(faqs)]

    radios = "".join(
        f'<label><input type="radio" name="country" value="{p["country_code"]}"{" checked" if i == 0 else ""}> {esc(p["country_name"])}</label>'
        for i, p in enumerate(supported))
    body = (f'    <p class="breadcrumb"><a href="/">Home</a> / <a href="/tools/">Free tools</a> / Citizenship by descent</p>\n'
            f'    <h1>Citizenship by descent checker</h1>\n'
            f'    <div class="answer"><p>Answer a few questions about your direct family line and get a verdict on '
            f'<strong>{esc(names)}</strong> citizenship by descent, with the reasoning, what is missing, and the next step.</p>'
            f'<p>No names asked and nothing stored. The answer comes from fixed, tested rules, not from AI, so the same answers give the same result.</p></div>\n'
            f'    <p class="verified">Rules verified {esc(verified)} &middot; Informational only, not legal advice</p>\n'
            f'    <form class="tool" id="descent" novalidate>\n'
            f'      <fieldset><legend>Which citizenship?</legend><div class="radios">{radios}</div></fieldset>\n'
            + gen_row("self", "US") + gen_row("parent", "US") + gen_row("grandparent", "IE") + gen_row("great_grandparent", "IE")
            + f'      <label class="check"><input type="checkbox" name="add_ggp"> My ancestor is a great-grandparent</label>\n'
            f'      <p class="muted">Only years are needed. Leave a year blank if you do not know it; the answer will say what is missing.</p>\n'
            f'      <button type="submit">Check eligibility</button>\n'
            f'    </form>\n'
            f'    <div class="result" id="descent-result" aria-live="polite"></div>\n'
            f'    <h2>What you need for each pathway</h2>\n'
            + "".join(requirements_html(r) for r in reqs)
            + f'    <h2>Not covered yet</h2>\n'
            f'    <p>{esc(", ".join(p["country_name"] for p in planned))}. For Italy, read the '
            f'<a href="/blog/italy-jure-sanguinis-citizenship-2026.html">Italian citizenship by descent guide</a>, and compare it with Ireland '
            f'<a href="/compare/irish-vs-italian-citizenship-by-descent/">here</a>.</p>\n'
            f'    <p>Going further on Ireland: <a href="/blog/ireland-foreign-births-register-2026.html">the Foreign Births Register guide</a>.</p>\n'
            + faq_html(faqs)
            + cta("citizenship-by-descent", "Track the whole claim in GoThere",
                  "Build your family tree, store the certificates, and follow each step of the application.")
            + DESCENT_JS)
    page(path, title, desc, body, schema, "citizenship-by-descent")
    return {"path": path, "name": "Citizenship by descent checker", "desc": desc}


# ---------- D10: income calculator ----------

def income_rows():
    """Personal-income thresholds only. Job-offer salary floors (category 'work') are not
    a test of the income you already have, so they are listed separately."""
    rows, salary = [], []
    for v in VISAS:
        inc = v["income"]
        c = COUNTRIES[v["country"]]
        name = f'{c["name"]} {DISPLAY[v["id"]][0]}'
        link = f'/move/us-to-{c["slug"]}/#{v["id"]}'
        if v["category"] == "work":
            salary.append((v, name, link))
            continue
        if inc.get("monthly") is not None:
            monthly = inc["monthly"]
        elif inc.get("annual") is not None:
            monthly = inc["annual"] / 12
        else:
            continue
        rows.append({"id": v["id"], "name": name, "link": link, "monthly": round(monthly, 2),
                     "currency": inc["currency"], "family": inc.get("perDependent") or "",
                     "audience": DISPLAY[v["id"]][1], "basis": inc.get("basis") or "",
                     "source": inc.get("sourceUrl"), "sourceType": inc.get("sourceType"),
                     "verified": inc.get("lastVerified")})
    rows.sort(key=lambda r: r["monthly"] / FX["rates"].get(r["currency"], 1))
    return rows, salary


INCOME_JS = r"""
<script>
(function () {
  var DATA = JSON.parse(document.getElementById("income-data").textContent);
  var form = document.getElementById("income");
  var out = document.getElementById("income-result");
  var SYM = { EUR: "€", USD: "$", MXN: "MX$" };
  function usd(amount, cur) { return cur === "USD" ? amount : amount / DATA.rates[cur]; }
  function fmt(n, cur) { return (SYM[cur] || cur + " ") + Math.round(n).toLocaleString("en-US"); }
  function el(tag, text, cls) { var e = document.createElement(tag); if (text) e.textContent = text; if (cls) e.className = cls; return e; }

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var amount = parseFloat(form.elements.amount.value);
    if (!(amount > 0)) { out.textContent = "Enter your income to compare."; return; }
    var cur = form.elements.currency.value;
    var monthlyUsd = usd(form.elements.period.value === "year" ? amount / 12 : amount, cur);
    var table = el("table", null, "calc"), head = el("tr");
    ["Visa", "Needs (applicant)", "You", "Family members"].forEach(function (h) { head.appendChild(el("th", h)); });
    var thead = el("thead"); thead.appendChild(head); table.appendChild(thead);
    var tbody = el("tbody"), meets = 0;
    DATA.visas.forEach(function (v) {
      var needUsd = usd(v.monthly, v.currency), tr = el("tr");
      var name = el("td"), a = el("a", v.name); a.href = v.link; name.appendChild(a);
      name.appendChild(el("div", "For " + v.audience, "muted")); tr.appendChild(name);
      tr.appendChild(el("td", fmt(v.monthly, v.currency) + "/mo" + (v.currency !== "USD" ? " (≈ " + fmt(needUsd, "USD") + ")" : "")));
      var gap = monthlyUsd - needUsd, cell;
      if (gap >= needUsd * 0.1) { cell = el("td", "Meets it", "ok"); meets++; }
      else if (gap >= 0) { cell = el("td", "Just meets it, within 10%", "close"); meets++; }
      else { cell = el("td", "Short by " + fmt(-gap, "USD") + "/mo", "short"); }
      tr.appendChild(cell);
      tr.appendChild(el("td", v.family || "No family figure published", "muted"));
      tbody.appendChild(tr);
    });
    table.appendChild(tbody);
    out.textContent = "";
    out.appendChild(el("p", "Your income: about " + fmt(monthlyUsd, "USD") + " a month. You meet " + meets + " of " + DATA.visas.length + " income thresholds for the applicant alone."));
    out.appendChild(table);
    out.appendChild(el("p", "Thresholds are for the main applicant. Each visa adds an amount for a spouse or children, shown in the last column. Close to the line? Exchange rates move, and consulates judge borderline cases, so give yourself a margin.", "muted"));
    if (window.gtTrack) window.gtTrack("tool_income_calc", { currency: cur, period: form.elements.period.value, meets: meets });
  });
})();
</script>
"""


def build_income():
    path = "/tools/visa-income-calculator/"
    rows, salary = income_rows()
    fx_date = FX["date"]
    eur = FX["rates"]["EUR"]
    title = "Visa Income Calculator: Do You Earn Enough to Move Abroad? (2026)"
    desc = (f"Enter your income and see which of {len(rows)} retiree, passive-income and digital nomad visas in Spain, "
            "Portugal, Ireland, Italy and Mexico you qualify for. Every threshold sourced and dated.")
    cheapest = rows[0]
    faqs = [
        ("How much income do I need to move abroad from the US?",
         f"Of the visas here, the lowest bar is the {cheapest['name']} at "
         f"{money(cheapest['monthly'], cheapest['currency'], usd=False)} a month for the applicant. "
         f"The highest personal-income bar is the {rows[-1]['name']}."),
        ("Do these thresholds include my spouse and children?",
         "No. They are for the main applicant. Each visa adds an amount per family member, listed next to it."),
        ("Which exchange rate does the calculator use?",
         f"The European Central Bank reference rate published on {fx_date}: 1 US dollar = {eur:.4f} euros. "
         "Rates move every day, so leave yourself a margin if you are close to a threshold."),
        ("Does any income count?",
         "No. Retiree and passive-income visas usually exclude salary, and digital nomad visas need income from "
         "remote work. Check the basis line under each visa."),
    ]
    schema = [webapp(path, "Visa income calculator", desc), breadcrumb(path, "Visa income calculator"),
              faq_schema(faqs)]

    data = {"rates": FX["rates"], "date": fx_date,
            "visas": [{k: r[k] for k in ("id", "name", "link", "monthly", "currency", "family", "audience")}
                      for r in rows]}
    static_rows = "".join(
        f'<tr><td><a href="{r["link"]}">{esc(r["name"])}</a><div class="muted">{esc(r["basis"])}</div></td>'
        f'<td>{money(r["monthly"], r["currency"])}/mo {src({"sourceUrl": r["source"], "sourceType": r["sourceType"]})}'
        f'<div class="muted">Verified {esc(r["verified"])}</div></td>'
        f'<td class="muted">{esc(r["family"]) or "No family figure published"}</td></tr>'
        for r in rows)
    salary_html = "".join(
        f'<li><a href="{link}">{esc(name)}</a>: salary of at least {money(v["income"]["annual"], v["income"]["currency"])}/year '
        f'from an Irish employer {src(v["income"])}. {esc(v["income"]["basis"])}</li>'
        for v, name, link in salary)

    body = (f'    <p class="breadcrumb"><a href="/">Home</a> / <a href="/tools/">Free tools</a> / Visa income calculator</p>\n'
            f'    <h1>Visa income calculator</h1>\n'
            f'    <div class="answer"><p>Enter what you earn and see which of <strong>{len(rows)} residence visas</strong> in Spain, '
            f'Portugal, Ireland, Italy and Mexico your income clears, and by how much.</p>'
            f'<p>Every threshold comes from an official source with the date we checked it. Nothing you type leaves your browser.</p></div>\n'
            f'    <p class="verified">Exchange rates: ECB reference rates of {esc(fx_date)} (1 USD = €{eur:.4f}) via '
            f'<a class="src" href="https://frankfurter.dev/" rel="nofollow noopener" target="_blank">Frankfurter</a></p>\n'
            f'    <form class="tool" id="income" novalidate>\n'
            f'      <div class="row" style="border-top:0">\n'
            f'        <div><label for="amount">Your income</label><input id="amount" name="amount" type="number" min="0" step="any" inputmode="decimal" placeholder="e.g. 3500" required></div>\n'
            f'        <div><label for="currency">Currency</label><select id="currency" name="currency"><option value="USD">US dollars</option><option value="EUR">Euros</option></select></div>\n'
            f'        <div><label for="period">Per</label><select id="period" name="period"><option value="month">month</option><option value="year">year</option></select></div>\n'
            f'      </div>\n'
            f'      <button type="submit">Compare</button>\n'
            f'    </form>\n'
            f'    <div class="result" id="income-result" aria-live="polite"></div>\n'
            f'    <h2>All thresholds, lowest first</h2>\n'
            f'    <table class="calc"><thead><tr><th>Visa</th><th>Applicant needs</th><th>Family members</th></tr></thead><tbody>{static_rows}</tbody></table>\n'
            f'    <h2>Job-offer visas</h2>\n'
            f'    <p>These test the salary of a job you have been offered in the country, not the income you have now:</p>\n'
            f'    <ul>{salary_html}</ul>\n'
            + faq_html(faqs)
            + cta("visa-income-calculator", "Found a visa that fits?",
                  "GoThere turns it into a step-by-step checklist, with the documents and deadlines for your situation.")
            + f'    <script type="application/json" id="income-data">{json.dumps(data, ensure_ascii=False)}</script>\n'
            + INCOME_JS)
    page(path, title, desc, body, schema, "visa-income-calculator")
    return {"path": path, "name": "Visa income calculator", "desc": desc}


def build_hub(tools):
    path = "/tools/"
    title = "Free Move-Abroad Tools: Citizenship by Descent Checker and Visa Income Calculator"
    desc = "Free tools for Americans planning a move abroad. No sign-up, nothing stored."
    cards = "".join(f'<a class="card" href="{t["path"]}"><h2>{esc(t["name"])}</h2><p class="muted">{esc(t["desc"])}</p></a>'
                    for t in tools)
    body = (f'    <h1>Free tools for moving abroad</h1>\n'
            f'    <p>No sign-up, nothing stored. Every rule and threshold is sourced and dated.</p>\n'
            f'    <div class="tools-grid">{cards}</div>\n'
            f'    <p>For the full requirements by country, see <a href="/move/">Move abroad guides</a>.</p>\n'
            + cta("hub", "Plan the whole move in GoThere", "Visa steps, documents and deadlines in one checklist."))
    schema = [{"@context": "https://schema.org", "@type": "CollectionPage", "name": title, "url": SITE + path,
               "hasPart": [{"@type": "WebApplication", "name": t["name"], "url": SITE + t["path"]} for t in tools]}]
    page(path, title, desc, body, schema, "hub")


def main():
    tools = [build_descent(), build_income()]
    build_hub(tools)
    print("\ndone")


if __name__ == "__main__":
    main()
