# -*- coding: utf-8 -*-
"""Builds /leaving-the-us/index.html and /leaving-the-us/checklist.pdf.

Every threshold lives in PATHS below with its official source and the date it
was checked. Update the figure + `checked` together; never add a number without
a source. Checklist steps come from the app's task seeds (ios/GoThere/Seeds).

Run: python _generate_leaving.py   (then _generate_sitemap.py, then deploy)
"""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SEEDS = ROOT.parent.parent / "GoThere" / "Seeds"
OUT = ROOT / "leaving-the-us"
CT = "midterms26"
IOS = f"https://apps.apple.com/app/gothere-relocation-guide/id6760248690?pt=128632140&ct={CT}&mt=8"
PLAY = ("https://play.google.com/store/apps/details?id=com.gothere.app&referrer="
        f"utm_source%3Dsite%26utm_medium%3Dreferral%26utm_campaign%3D{CT}")
UPDATED = "2026-10-08"

# fig = the headline requirement; facts = (label, value) rows; src = (label, url)
PATHS = [
    {
        "id": "spain-nlv", "flag": "🇪🇸", "name": "Spain Non-Lucrative Visa",
        "fits": "Retirees and anyone living on savings, pensions or investments. You can't work in Spain on it.",
        "fig": '€2,400 a month in passive income (€28,800 a year), plus €600 a month for each family member.',
        "facts": [('Basis', '400% of IPREM (€600/month in 2026), +100% IPREM per dependent'), ('Work', 'Not allowed in Spain'), ('Path to permanent residency', '5 years'), ('Citizenship', '10 years of residence')],
        "src": [('Spain Ministry of Inclusion', 'https://www.inclusion.gob.es/web/migraciones/w/autorizacion-inicial-de-residencia-temporal-no-lucrativa')],
        "checked": UPDATED,
        "seed": [("spain", 6)], "guide": "/blog/spain-non-lucrative-visa-2026.html",
    },
    {
        "id": "spain-dnv", "flag": "🇪🇸", "name": "Spain Digital Nomad Visa",
        "fits": "Remote workers employed by (or freelancing for) companies outside Spain.",
        "fig": '€2,442 a month from employers or clients outside Spain. +€915.75 for the first family member, +€305.25 for each one after.',
        "facts": [('Basis', "200% of Spain's 2026 minimum wage (€1,221/month, 14 payments), per the official FAQ"), ('Work', 'Remote, for companies or clients outside Spain'), ('Path to permanent residency', '5 years'), ('Citizenship', '10 years')],
        "src": [('Spain digital nomad FAQ', 'https://www.inclusion.gob.es/documents/d/unidadgrandesempresas/digital-nomad-faqs-english'), ('BOE: 2026 minimum wage', 'https://www.boe.es/buscar/doc.php?id=BOE-A-2026-3815')],
        "checked": UPDATED,
        "seed": [], "steps": [("Use the Spain document steps above", "Passport, apostilles, sworn translations, consulate jurisdiction and health insurance work the same way."), ("Add proof of your remote work", "Your contract or client agreements and recent payslips or invoices showing the income threshold.")], "guide": "/compare/spain-nlv-vs-dnv/",
    },
    {
        "id": "portugal", "flag": "🇵🇹", "name": "Portugal D7 or D8",
        "fits": "D7 for passive income (pension, rentals, dividends). D8 for remote workers. The lowest income bar in Western Europe.",
        "fig": 'D7: €920 a month in passive income (+€460 per extra adult, +€276 per child). D8: €3,680 a month in remote-work income.',
        "facts": [('Basis', "Portugal's 2026 minimum wage is €920/month. D7 = 100% of it; D8 = 4 times it"), ('Work', 'Allowed (D7 includes local jobs)'), ('Path to permanent residency', '5 years')],
        "src": [('DGERT: 2026 minimum wage', 'https://www.dgert.gov.pt/retribuicao-minima-mensal-garantida-para-2026'), ('AIMA: means of subsistence', 'https://aima.gov.pt/pt/temas-transversais/meios-de-subsistencia')],
        "checked": UPDATED,
        "seed": [("portugal", 6)], "guide": "/blog/portugal-d7-d8-visa-2026.html",
    },
    {
        "id": "mexico", "flag": "🇲🇽", "name": "Mexico Temporary Residency",
        "fits": "The fastest, closest option. Proves income or savings; the exact amount depends on your consulate.",
        "fig": 'About $4,400 to $4,630 a month in income (last 6 months), or $73,000 to $78,000 in savings (last 12 months), depending on the consulate.',
        "facts": [('Basis', "680 days (income) or 11,460 days (savings) of Mexico's UMA, converted by each consulate"), ('Example', 'Las Vegas consulate, 2026: $4,630/month or $78,025'), ('Work', 'Needs a separate permission'), ('Path to permanent residency', 'After 4 years of temporary residency')],
        "src": [('Mexican Consulate Las Vegas (2026)', 'https://consulmex.sre.gob.mx/lasvegas/images/2026/VISAS2026/TemporaryResidenceVisa2026.pdf'), ('INEGI: UMA', 'https://www.inegi.org.mx/temas/uma/')],
        "checked": UPDATED,
        "seed": [("mexico", 6)], "guide": "/blog/mexico-temporary-resident-visa-2026.html",
    },
    {
        "id": "descent", "flag": "🇮🇪🇮🇹🇨🇦", "name": "Citizenship by descent",
        "fits": "If a parent or grandparent was born in Ireland or Italy, or you have Canadian ancestry, you may already have a second citizenship to claim. No income test.",
        "fig": 'No income test. Ireland: a grandparent born in Ireland (fee €278). Italy: since the 2025 reform, generally a parent or grandparent who held only Italian citizenship. Canada: Bill C-3 took effect December 15, 2025.',
        "facts": [('Ireland', 'Foreign Births Register, about 12 months, €270 + €8 postage for adults'), ('Italy', 'Law 74/2025: born abroad with another citizenship = Italian only if a parent or grandparent held exclusively Italian citizenship, or a parent lived in Italy 2 years before your birth (or you applied by March 27, 2025). An EU Court of Justice referral is pending.'), ('Canada', 'People born abroad beyond the first generation before Dec 15, 2025 became citizens. After that, the Canadian parent needs 1,095 days in Canada.')],
        "src": [('Ireland DFA', 'https://www.ireland.ie/en/dfa/citizenship/born-abroad/registering-a-foreign-birth/'), ('Italian Consulate New York', 'https://consnewyork.esteri.it/en/servizi-consolari-e-visti/servizi-per-il-cittadino-straniero/cittadinanza/'), ('IRCC: Bill C-3', 'https://www.canada.ca/en/immigration-refugees-citizenship/news/2025/12/bill-c-3-an-act-to-amend-the-citizenship-act-2025-comes-into-effect.html')],
        "checked": UPDATED,
        "seed": [("ireland", 3)], "steps_after": [("Italy: check the 2025 rule first", "You qualify only if a parent or grandparent held exclusively Italian citizenship, a parent lived in Italy 2 years before your birth, or you applied by March 27, 2025."), ("Canada: request a citizenship certificate", "If a parent or grandparent was Canadian, Bill C-3 may already make you a citizen. Apply for proof of citizenship with IRCC.")], "guide": "/compare/citizenship-by-descent/",
    },
    {
        "id": "germany", "flag": "🇩🇪", "name": "Germany EU Blue Card",
        "fits": "Degree holders with a job offer. The fastest route to EU permanent residency on this list.",
        "fig": 'A job offer paying at least €50,700 a year (lower in shortage fields such as IT, engineering and healthcare), plus a recognized degree.',
        "facts": [('Work', 'Yes, for the employer that sponsors you'), ('Path to permanent residency', '21 months with B1 German, 27 months with A1')],
        "src": [('Make it in Germany: EU Blue Card', 'https://www.make-it-in-germany.com/en/visa-residence/types/eu-blue-card')],
        "checked": UPDATED,
        "seed": [], "steps": [("Get a qualifying job offer in Germany", "The Blue Card needs a concrete offer that meets the salary threshold."), ("Check your degree is recognized", "Look up your university and degree in the anabin database, or apply for a ZAB statement of comparability."), ("Book a visa appointment at the German mission for your state", "Then apply with the offer, degree proof and passport.")], "guide": "/blog/germany-eu-blue-card-2026.html",
    },
]

# US-side steps that apply to almost every path (from the app seeds' document phase)
US_SIDE = [
    ("Check your passport", "Valid at least 6 months beyond your planned stay, with blank pages."),
    ("Order an FBI Identity History Summary", "Most residence visas want a recent federal background check."),
    ("Plan apostilles early", "State documents get apostilled by that state's Secretary of State; federal ones by the US Department of State. This can take weeks."),
    ("Order long-form birth and marriage certificates", "Certified copies, often with apostille and a sworn translation."),
    ("Find your consulate", "You apply at the consulate that covers the US state where you legally live, not the one with the shortest wait."),
    ("Price health insurance", "Most visas require private coverage with no co-pays for at least the first year."),
    ("Talk to a US tax professional", "You keep filing US taxes from abroad. Ask about FBAR and the Foreign Earned Income Exclusion before you move money."),
]


def seed_steps(p):
    """First plan/document steps from the app's seeds, or the path's own steps."""
    out = list(p.get("steps", []))
    for country, n in p["seed"]:
        items = json.load(open(SEEDS / f"{country}_tasks.json", encoding="utf-8"))
        items = [i for i in items if i.get("phaseId") in ("phase_1_plan", "phase_2_documents")]
        items.sort(key=lambda i: (i.get("phaseId"), i.get("order", 0)))
        out += [(i["title"], (i.get("description") or "").strip()) for i in items[:n]]
    return out + list(p.get("steps_after", []))


def e(s):
    return html.escape(s, quote=True)


def path_card(p, i):
    facts = "".join(f"<tr><th>{e(k)}</th><td>{e(v)}</td></tr>" for k, v in p["facts"])
    src = " · ".join(f'<a href="{e(u)}" rel="nofollow noopener" target="_blank">{e(l)}</a>' for l, u in p["src"])
    return f"""
    <section class="path" id="{p['id']}">
      <h2><span class="num">{i}</span> {p['flag']} {e(p['name'])}</h2>
      <p class="fits">{e(p['fits'])}</p>
      <p class="fig">{e(p['fig'])}</p>
      <table>{facts}</table>
      <p class="src">Official source: {src}. Checked {p['checked']}. Rules change; confirm with your consulate.</p>
      <p><a href="{p['guide']}">Read the full guide →</a></p>
    </section>"""


CAPTURE_JS = """
<script>
(function () {
  var form = document.getElementById('lt-form'); if (!form) return;
  var status = document.getElementById('lt-status');
  var dl = document.getElementById('lt-download');
  var params = new URLSearchParams(location.search);
  form.addEventListener('submit', async function (ev) {
    ev.preventDefault();
    var email = form.email.value.trim(); var btn = form.querySelector('button');
    status.textContent = '';
    if (!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)) { status.className = 'status err'; status.textContent = 'Please enter a valid email address.'; return; }
    btn.disabled = true;
    try {
      var res = await fetch('https://api.mylocalista.com/marketing/capture', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ app: 'gothere', email: email, source: 'leaving_the_us_checklist', language: 'en',
          utm_source: params.get('utm_source') || 'direct', utm_medium: params.get('utm_medium') || 'web',
          utm_campaign: params.get('utm_campaign') || 'midterms26', utm_content: params.get('utm_content') || '' })
      });
      if (!res.ok) throw new Error('bad_status');
      form.style.display = 'none'; dl.style.display = 'block';
    } catch (err) {
      status.className = 'status err'; status.textContent = "Couldn't reach the server. Try again in a minute."; btn.disabled = false;
    }
  });
})();
</script>"""


def page():
    title = "Leaving the US: 6 Realistic Paths Abroad (2026)"
    desc = ("Thinking about moving abroad? Six realistic visa and citizenship paths for Americans, "
            "with official income thresholds and a free checklist.")
    canon = "https://getgothere.app/leaving-the-us/"
    cards = "".join(path_card(p, i) for i, p in enumerate(PATHS, 1))
    toc = "".join(f'<li><a href="#{p["id"]}">{p["flag"]} {e(p["name"])}</a></li>' for p in PATHS)
    us = "".join(f"<li><strong>{e(t)}.</strong> {e(d)}</li>" for t, d in US_SIDE)
    schema = json.dumps({
        "@context": "https://schema.org", "@type": "Article", "headline": title, "description": desc,
        "author": {"@type": "Organization", "name": "GoThere"}, "publisher": {"@type": "Organization", "name": "GoThere"},
        "datePublished": UPDATED, "dateModified": UPDATED, "mainEntityOfPage": canon}, ensure_ascii=False)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <!-- Cloudflare Web Analytics --><script type='module' src='https://static.cloudflareinsights.com/beacon.min.js' data-cf-beacon='{{"token": "64a77b8c518846cd99a83b9c13466ac3"}}'></script><!-- End Cloudflare Web Analytics -->
  <title>{e(title)}</title>
  <meta name="description" content="{e(desc)}">
  <link rel="canonical" href="{canon}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="{e(title)}">
  <meta property="og:description" content="{e(desc)}">
  <meta property="og:url" content="{canon}">
  <meta property="og:image" content="https://getgothere.app/og-image.png">
  <meta name="twitter:card" content="summary_large_image">
  <script type="application/ld+json">{schema}</script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=DM+Sans:wght@500;700&display=swap" rel="stylesheet">
  <style>
    :root {{ --teal:#15B8A6; --teal-dark:#0F8F82; --bg:#0B0F14; --bg-card:#1A2332; --border:#1E293B; --text:#F1F5F9; --text-mute:#94A3B8; }}
    *,*:before,*:after {{ box-sizing:border-box; margin:0; padding:0; }}
    body {{ font-family:Inter,-apple-system,sans-serif; background:var(--bg); color:var(--text); line-height:1.7; -webkit-font-smoothing:antialiased; }}
    a {{ color:var(--teal); text-decoration:none; }} a:hover {{ text-decoration:underline; }}
    .container {{ max-width:760px; margin:0 auto; padding:32px 16px; }}
    nav {{ padding:20px 16px; border-bottom:1px solid var(--border); }}
    nav .container {{ padding:0; display:flex; justify-content:space-between; align-items:center; }}
    nav a.logo {{ font-family:'DM Sans'; font-weight:700; font-size:22px; color:var(--text); }}
    h1 {{ font-family:'DM Sans'; font-size:38px; line-height:1.2; font-weight:700; margin:24px 0 16px; letter-spacing:-0.02em; }}
    h2 {{ font-family:'DM Sans'; font-size:24px; margin:0 0 10px; font-weight:700; }}
    h3 {{ font-size:19px; margin:24px 0 8px; font-weight:600; color:var(--teal); }}
    p {{ margin:12px 0; }} ul, ol {{ margin:12px 0 12px 20px; }} li {{ margin:6px 0; }}
    .lede {{ font-size:18px; color:var(--text-mute); margin:16px 0 28px; }}
    .breadcrumb {{ font-size:14px; color:var(--text-mute); }} .breadcrumb a {{ color:var(--text-mute); }}
    .toc {{ background:var(--bg-card); border:1px solid var(--border); border-radius:12px; padding:16px 20px; }}
    .path {{ background:var(--bg-card); border:1px solid var(--border); border-radius:16px; padding:24px; margin:28px 0; }}
    .num {{ display:inline-block; width:30px; height:30px; line-height:30px; text-align:center; border-radius:50%; background:var(--teal); color:#00110F; font-size:16px; margin-right:6px; }}
    .fits {{ color:var(--text-mute); }} .fig {{ font-size:19px; font-weight:600; }}
    table {{ width:100%; border-collapse:collapse; margin:12px 0; font-size:15px; }}
    th, td {{ padding:8px 10px; text-align:left; border-bottom:1px solid var(--border); vertical-align:top; }}
    th {{ color:var(--teal); font-weight:600; width:38%; }}
    .src {{ font-size:13px; color:var(--text-mute); }}
    .capture {{ background:linear-gradient(135deg,var(--teal-dark),var(--teal)); border-radius:16px; padding:28px; margin:40px 0; color:#fff; }}
    .capture h3 {{ color:#fff; margin-top:0; font-size:22px; }}
    .capture form {{ display:flex; gap:8px; flex-wrap:wrap; margin-top:12px; }}
    .capture input {{ flex:1 1 220px; padding:12px 14px; border-radius:8px; border:0; font-size:16px; }}
    .capture button {{ padding:12px 20px; border-radius:8px; border:0; background:#000; color:#fff; font-weight:600; font-size:16px; cursor:pointer; }}
    .capture .fine {{ font-size:13px; color:rgba(255,255,255,0.85); }}
    .status.err {{ color:#FFE4E6; font-weight:600; }}
    #lt-download {{ display:none; }} #lt-download a {{ color:#fff; text-decoration:underline; font-weight:700; font-size:18px; }}
    .badges {{ display:flex; gap:12px; flex-wrap:wrap; margin:16px 0; }}
    .badges a {{ background:#000; color:#fff; border:1px solid var(--border); padding:12px 18px; border-radius:10px; font-weight:600; }}
    .note {{ font-size:14px; color:var(--text-mute); font-style:italic; }}
    footer {{ border-top:1px solid var(--border); padding:32px 16px; margin-top:48px; color:var(--text-mute); font-size:14px; }}
    @media (max-width:600px) {{ h1 {{ font-size:30px; }} .path {{ padding:18px; }} th {{ width:auto; }} }}
  </style>
</head>
<body>
  <nav><div class="container"><a href="/" class="logo">GoThere</a><a href="{IOS}">Get the app →</a></div></nav>
  <main class="container">
    <div class="breadcrumb"><a href="/">Home</a> / Leaving the US</div>
    <h1>Leaving the US: 6 realistic paths abroad</h1>
    <p class="lede">Whatever happens on November 3, a lot of Americans are quietly asking the same question: could I actually live somewhere else? Here are the six paths that most often work for US citizens, with the real numbers from official sources. No hype, no "move tomorrow" promises.</p>
    <p>I'm an American who moved to Málaga. Most people who look into this stop at "I don't know where to start." So start here: find the path that matches how you earn money, check the number, then work the checklist.</p>
    <div class="toc"><strong>The six paths</strong><ol>{toc}</ol></div>
    {cards}
    <div class="capture" id="checklist">
      <h3>Get the free checklist (PDF)</h3>
      <p>The US-side paperwork every path needs, plus the first steps for each of the six paths. Same steps we use in the app.</p>
      <form id="lt-form" novalidate>
        <input type="email" name="email" placeholder="you@example.com" autocomplete="email" required aria-label="Email address">
        <button type="submit">Get the checklist</button>
      </form>
      <p id="lt-status" class="status" role="status"></p>
      <div id="lt-download" role="status"><p>Here you go: <a href="/leaving-the-us/checklist.pdf" download>Download the checklist (PDF)</a></p></div>
      <p class="fine">One email address, no spam. Unsubscribe anytime.</p>
    </div>
    <h2>Before any of the six: the US-side paperwork</h2>
    <ol>{us}</ol>
    <h2>Track it in the app</h2>
    <p>GoThere turns your chosen path into a step-by-step checklist with deadlines, document tracking and cost estimates. On iPhone it's free to download, and Spain and Canada are free.</p>
    <div class="badges"><a href="{IOS}">Download on the App Store</a><a href="{PLAY}">Get it on Google Play</a></div>
    <p class="note">This page is general information, not legal or tax advice. Thresholds change, often every January. Always confirm with the consulate that covers your state, and talk to an immigration lawyer for anything complicated. Last updated {UPDATED}.</p>
  </main>
  <footer><div class="container" style="padding:0"><p>&copy; 2026 GoThere · <a href="/">Home</a> · <a href="/blog/">Blog</a> · <a href="/compare/">Compare visas</a> · <a href="/safe-harbor/">Safe Harbor Index</a></p></div></footer>
  {CAPTURE_JS}
</body>
</html>
"""


def pdf(path):
    from reportlab.lib.pagesizes import letter
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, ListFlowable, ListItem

    ss = getSampleStyleSheet()
    teal = colors.HexColor("#0F8F82")
    h1 = ParagraphStyle("h1", parent=ss["Title"], textColor=teal, fontSize=22, leading=26)
    h2 = ParagraphStyle("h2", parent=ss["Heading2"], textColor=teal, spaceBefore=14, keepWithNext=1)
    body = ParagraphStyle("b", parent=ss["BodyText"], fontSize=10, leading=13.5)
    small = ParagraphStyle("s", parent=body, fontSize=8.5, textColor=colors.HexColor("#555555"))

    def box(title, desc):
        t = f"<b>[ ]&nbsp;&nbsp;{e(title)}</b>"
        return ListItem(Paragraph(t + (f"<br/>{e(desc)}" if desc else ""), body), leftIndent=6)

    story = [Paragraph("Leaving the US: the checklist", h1),
             Paragraph(f"From GoThere (getgothere.app/leaving-the-us). Updated {UPDATED}. "
                       "General information, not legal or tax advice. Confirm every requirement with your consulate.", small),
             Spacer(1, 8),
             Paragraph("1. US-side paperwork (almost every path)", h2),
             ListFlowable([box(t, d) for t, d in US_SIDE], bulletType="bullet", start="")]
    for i, p in enumerate(PATHS, 2):
        story += [Paragraph(f"{i}. {e(p['name'])}", h2),
                  Paragraph(f"<b>Requirement:</b> {e(p['fig'])}", body),
                  Paragraph("Source: " + ", ".join(e(u) for _, u in p["src"]) + f" (checked {p['checked']})", small),
                  Spacer(1, 4),
                  ListFlowable([box(t, d) for t, d in seed_steps(p)], bulletType="bullet", start="")]
    story += [Spacer(1, 12), Paragraph(
        "Track every step, deadline and document in the GoThere app: getgothere.app", body)]
    SimpleDocTemplate(str(path), pagesize=letter, leftMargin=0.8 * inch, rightMargin=0.8 * inch,
                      topMargin=0.7 * inch, bottomMargin=0.7 * inch,
                      title="Leaving the US: the checklist", author="GoThere").build(story)


if __name__ == "__main__":
    for p in PATHS:
        assert p["fig"] != "PLACEHOLDER" and p["src"], f"unverified figures for {p['id']}"
    OUT.mkdir(exist_ok=True)
    (OUT / "index.html").write_text(page(), encoding="utf-8")
    pdf(OUT / "checklist.pdf")
    print("wrote", OUT / "index.html", OUT / "checklist.pdf")
