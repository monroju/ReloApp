#!/usr/bin/env python3
"""Generate pSEO city pages for getgothere.app from shared/poi/ + _pseo_data.json.

Output: /spain/madrid/index.html, /portugal/lisbon/index.html, etc.
Each page is self-contained (no shared CSS) so deployment = scp the dir.

Usage:
    python _generate_pseo.py            # generate all
    python _generate_pseo.py madrid     # one city only
"""
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).parent
DATA = json.load(open(ROOT / "_pseo_data.json"))
POI_DIR = ROOT.parent.parent.parent / "shared" / "poi"

UMAMI_SCRIPT = '''<!-- Cloudflare Web Analytics --><script type='module' src='https://static.cloudflareinsights.com/beacon.min.js' data-cf-beacon='{"token": "64a77b8c518846cd99a83b9c13466ac3"}'></script><!-- End Cloudflare Web Analytics -->'''
APP_URL = "https://apps.apple.com/app/gothere-relocation-guide/id6760248690"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.gothere.app"

# Reciprocal cross-promo to our Spain-expat app Localista (mylocalista.com already
# links back to GoThere). Rendered only on Spain city pages, where it's relevant.
CROSS_PROMO_SPAIN = """
    <div class="cross-promo">
      <div>
        <strong>Already landing in Spain?</strong>
        <p>Localista is our sister app for life once you're on the ground — local news, visa &amp; law changes, and town-by-town guides in plain English.</p>
      </div>
      <a href="https://mylocalista.com/?utm_source=gothere&amp;utm_medium=pseo&amp;utm_campaign=cross_promo">Meet Localista &rarr;</a>
    </div>
"""

# Map our city slugs to POI file names
POI_FILE_MAP = {
    "madrid": "poi_madrid.json",
    "barcelona": "poi_barcelona.json",
    "valencia": "poi_valencia.json",
    "granada": "poi_granada.json",
    "bilbao": "poi_bilbao.json",
    "sansebastian": "poi_sansebastian.json",
    "lisbon": "poi_lisbon.json",
    "porto": "poi_porto.json",
    "faro": "poi_faro.json",
    "cascais": "poi_cascais.json",
    "mexico_city": "poi_mexico_city.json",
    "playa_del_carmen": "poi_playa_del_carmen.json",
    "san_miguel": "poi_san_miguel.json",
    "oaxaca": "poi_oaxaca.json",
    "tulum": "poi_tulum.json",
}


def load_pois(slug: str) -> dict:
    f = POI_DIR / POI_FILE_MAP.get(slug, f"poi_{slug}.json")
    if not f.exists():
        return {"pois": [], "categories": {}}
    data = json.load(open(f, encoding="utf-8"))
    cats = Counter(p["category"] for p in data["pois"])
    by_cat = {}
    for cat in cats:
        by_cat[cat] = [p for p in data["pois"] if p["category"] == cat][:5]
    return {"total": len(data["pois"]), "categories": cats, "samples": by_cat}


PAGE_TPL = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  {umami}
  <title>{city} for Americans 2026: Cost, Visa, Neighborhoods</title>
  <meta name="description" content="{meta_desc}">
  <meta name="keywords" content="move to {city}, {city} expat, {city} cost of living, {city} visa, americans in {city}, {city} relocation, {city} neighborhoods">
  <link rel="canonical" href="https://getgothere.app/{country_slug}/{city_slug}/">

  <meta property="og:title" content="Moving to {city}? The 2026 American Relocation Guide">
  <meta property="og:description" content="{meta_desc}">
  <meta property="og:url" content="https://getgothere.app/{country_slug}/{city_slug}/">
  <meta property="og:type" content="article">
  <meta property="og:image" content="https://getgothere.app/og-image.png">
  <meta name="twitter:card" content="summary_large_image">

  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "Article",
    "headline": "Moving to {city}: 2026 American Relocation Guide",
    "description": "{meta_desc}",
    "author": {{"@type": "Organization", "name": "GoThere"}},
    "publisher": {{"@type": "Organization", "name": "GoThere"}},
    "datePublished": "2026-05-06",
    "mainEntityOfPage": "https://getgothere.app/{country_slug}/{city_slug}/"
  }}
  </script>

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=DM+Sans:wght@500;700&display=swap" rel="stylesheet">

  <style>
    :root {{
      --teal: #15B8A6; --teal-dark: #0F8F82;
      --bg: #0B0F14; --bg-card: #1A2332; --border: #1E293B;
      --text: #F1F5F9; --text-mute: #94A3B8;
    }}
    *,*:before,*:after {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: Inter, -apple-system, sans-serif;
      background: var(--bg); color: var(--text); line-height: 1.7;
      -webkit-font-smoothing: antialiased;
    }}
    a {{ color: var(--teal); text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    .container {{ max-width: 800px; margin: 0 auto; padding: 32px 24px; }}
    nav {{ padding: 20px 24px; border-bottom: 1px solid var(--border); }}
    nav .container {{ padding: 0; display: flex; justify-content: space-between; align-items: center; }}
    nav a.logo {{ font-family: 'DM Sans'; font-weight: 700; font-size: 22px; color: var(--text); }}
    h1 {{
      font-family: 'DM Sans'; font-size: 40px; line-height: 1.2; font-weight: 700;
      margin: 32px 0 16px; letter-spacing: -0.02em;
    }}
    h2 {{
      font-family: 'DM Sans'; font-size: 28px; margin: 48px 0 16px; font-weight: 700;
      letter-spacing: -0.01em;
    }}
    h3 {{ font-size: 20px; margin: 24px 0 8px; font-weight: 600; }}
    p {{ margin: 16px 0; color: var(--text); }}
    .lede {{ font-size: 18px; color: var(--text-mute); margin: 0 0 32px; }}
    .breadcrumb {{ font-size: 14px; color: var(--text-mute); margin-bottom: 16px; }}
    .breadcrumb a {{ color: var(--text-mute); }}
    table {{ width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 15px; }}
    th, td {{ padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }}
    th {{ color: var(--teal); font-weight: 600; background: rgba(21,184,166,0.05); }}
    .card {{
      background: var(--bg-card); border: 1px solid var(--border);
      border-radius: 12px; padding: 20px; margin: 16px 0;
    }}
    .pros-cons {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin: 16px 0; }}
    .pros-cons > div {{ background: var(--bg-card); border-radius: 8px; padding: 16px; }}
    .pros-cons h4 {{ margin-bottom: 8px; font-size: 14px; text-transform: uppercase; }}
    .pros h4 {{ color: var(--teal); }}
    .cons h4 {{ color: #f87171; }}
    .cta-box {{
      background: linear-gradient(135deg, var(--teal-dark), var(--teal));
      border-radius: 16px; padding: 32px; text-align: center; margin: 48px 0;
    }}
    .cta-box h3 {{ color: #fff; font-size: 24px; margin-bottom: 8px; }}
    .cta-box p {{ color: rgba(255,255,255,0.9); margin-bottom: 20px; }}
    .cta-buttons {{ display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; }}
    .cta-buttons a {{
      background: #000; color: #fff; padding: 12px 20px; border-radius: 8px;
      font-weight: 500; display: inline-block;
    }}
    .cta-buttons a:hover {{ background: #1a1a1a; text-decoration: none; }}
    .poi-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 16px 0; }}
    .poi-pill {{ background: var(--bg-card); border-radius: 8px; padding: 12px; font-size: 14px; }}
    .poi-pill strong {{ display: block; color: var(--teal); margin-bottom: 4px; font-size: 12px; text-transform: uppercase; }}
    .cross-promo {{ display: flex; align-items: center; justify-content: space-between; gap: 16px;
      flex-wrap: wrap; background: var(--bg-card); border: 1px solid var(--border);
      border-left: 3px solid #E8B931; border-radius: 12px; padding: 20px 24px; margin: 32px 0; }}
    .cross-promo strong {{ font-family: 'DM Sans'; font-size: 16px; }}
    .cross-promo p {{ margin: 6px 0 0; color: var(--text-mute); font-size: 14px; max-width: 52ch; }}
    .cross-promo a {{ white-space: nowrap; font-weight: 600; }}
    footer {{ border-top: 1px solid var(--border); padding: 32px 24px; margin-top: 64px; color: var(--text-mute); font-size: 14px; }}
    footer .container {{ padding: 0; }}
    @media (max-width: 600px) {{
      h1 {{ font-size: 32px; }}
      .pros-cons {{ grid-template-columns: 1fr; }}
    }}
  </style>
</head>
<body>
  <nav>
    <div class="container">
      <a href="/" class="logo">GoThere</a>
      <a href="{app_url}?utm_source=blog&utm_medium=organic&utm_campaign=pseo-{city_slug}">Get the app →</a>
    </div>
  </nav>

  <main class="container">
    <div class="breadcrumb"><a href="/">Home</a> / <a href="/{country_slug}/">{country}</a> / {city}</div>

    <h1>Moving to {city}? The 2026 American's Honest Relocation Guide</h1>
    <p class="lede">{lede}</p>

    <p>{intro_para}</p>

    <h2>Cost of living in {city} (2026)</h2>
    <table>
      <tr><th>Category</th><th>Monthly cost</th></tr>
      <tr><td>1BR apartment (decent area)</td><td>{cost_1br}</td></tr>
      <tr><td>2BR apartment</td><td>{cost_2br}</td></tr>
      <tr><td>Groceries (single person, cooking 80%)</td><td>{groceries_solo}</td></tr>
      <tr><td>Public transport monthly pass</td><td>{transport_pass}</td></tr>
      <tr><td>Fiber internet (300+ Mbps)</td><td>{internet}</td></tr>
      <tr><td>Coworking (hot desk)</td><td>{coworking_starting}</td></tr>
    </table>
    <p>Numbers are 2026 ranges, varying by neighborhood. The realistic monthly total for a single person renting solo lands roughly between {realistic_low} and {realistic_high} after rent + utilities + groceries + insurance + transport. Couples save substantially because rent is the largest single line.</p>

    <h2>Visa path for Americans</h2>
    <p>The two main paths into {country} for US citizens are the <strong>{primary_visa}</strong> (income-based, work prohibited) and the <strong>{secondary_visa}</strong> (remote workers).</p>
    <div class="card">
      <h3>What you'll actually need</h3>
      <ul style="margin: 12px 0 12px 20px; color: var(--text-mute);">
        {fbi_line}
        <li>Valid US passport with 12+ months validity</li>
        <li>Proof of income or savings (consulate-specific thresholds)</li>
        <li>Private health insurance valid in {country} (no copays, no deductibles)</li>
        <li>Apostilled birth certificate, marriage certificate (if applicable)</li>
        <li>Medical certificate (consulate-specific format)</li>
      </ul>
      <p style="color: var(--text-mute); font-size: 14px;">{tax_perk_line}</p>
    </div>

    <h2>Best neighborhoods in {city}</h2>
    <p>{best_neighborhoods}</p>

    <h2>Weather and climate</h2>
    <p>{weather}.</p>

    <h2>Should you actually move to {city}?</h2>
    <div class="pros-cons">
      <div class="pros"><h4>Pros</h4><p>{pros}</p></div>
      <div class="cons"><h4>Trade-offs</h4><p>{cons}</p></div>
    </div>

    {poi_section}

    <div class="cta-box">
      <h3>Skip the 47-tab browser session</h3>
      <p>GoThere has visa checklists, cost calculators, and document tracking for {country}, ready to use today.</p>
      <div class="cta-buttons">
        <a href="{app_url}?utm_source=blog&utm_medium=organic&utm_campaign=pseo-{city_slug}">Download for iOS</a>
        <a href="{play_url}&referrer=utm_source%3Dblog%26utm_medium%3Dorganic%26utm_campaign%3Dpseo-{city_slug}">Get on Google Play</a>
      </div>
    </div>

    {cross_promo}

    <h2>Related guides</h2>
    <p>{related_links}</p>
  </main>

  <footer>
    <div class="container">
      <p>&copy; 2026 GoThere · <a href="/">Home</a> · <a href="/blog/how-to-move-abroad-from-the-us.html">Blog</a></p>
    </div>
  </footer>
</body>
</html>
"""


def render_poi_section(slug: str, city_name: str) -> str:
    pois = load_pois(slug)
    if not pois.get("samples"):
        return ""
    cat_titles = {
        "bank": "Banks",
        "hospital": "Hospitals",
        "clinic": "Clinics",
        "supermarket": "Supermarkets",
    }
    blocks = []
    for cat, samples in pois["samples"].items():
        if not samples:
            continue
        names = ", ".join(s["name"] for s in samples[:5] if s.get("name"))
        if names:
            blocks.append(f'<div class="poi-pill"><strong>{cat_titles.get(cat, cat).upper()}</strong>{names}</div>')
    if not blocks:
        return ""
    return f"""
    <h2>On the ground in {city_name}</h2>
    <p>Practical things you'll need within the first month — banks, hospitals, clinics, and supermarkets near the central neighborhoods.</p>
    <div class="poi-grid">{"".join(blocks)}</div>
    <p style="font-size:14px;color:var(--text-mute);">Full POI list with addresses and maps available in the GoThere app.</p>
    """


def parse_range(s: str) -> tuple[int, int]:
    import re
    nums = re.findall(r"[\d,]+", s)
    nums = [int(n.replace(",", "")) for n in nums]
    if len(nums) >= 2:
        return nums[0], nums[1]
    return nums[0], nums[0] if nums else (0, 0)


def render_city(country_slug: str, city_slug: str, country: dict, city: dict, related: list) -> str:
    low_1br, _ = parse_range(city["cost_1br"])
    _, high_2br = parse_range(city["cost_2br"])
    realistic_low_eur = low_1br + 600
    realistic_high_eur = high_2br + 800

    if "USD" in (country.get("currency") or ""):
        realistic_low = f"${realistic_low_eur} USD"
        realistic_high = f"${realistic_high_eur} USD"
    else:
        realistic_low = f"{realistic_low_eur} EUR"
        realistic_high = f"{realistic_high_eur} EUR"

    fbi_line = "<li><strong>FBI background check, federally apostilled</strong> (12–18 weeks by mail; 2 weeks via approved channeler)</li>" if country["fbi_check_required"] else "<li>Federal background check (Mexico does not require an FBI check for the Temporary Resident Visa, only the consulate-issued affidavit)</li>"

    tax_perk_line = f"Tax angle: {country['tax_perk']}." if country.get("tax_perk") else ""

    related_html = " · ".join(f'<a href="/{r["country_slug"]}/{r["city_slug"]}/">{r["name"]}</a>' for r in related)

    meta_desc = f"Real costs, neighborhoods, visa options, and trade-offs for Americans considering a move to {city['name']}, {country['name']} in 2026. Written by people who actually did it."

    lede = f"{city['blurb'][:180]}..."

    poi_section = render_poi_section(city_slug, city["name"])

    cross_promo = CROSS_PROMO_SPAIN if country_slug == "spain" else ""

    return PAGE_TPL.format(
        umami=UMAMI_SCRIPT,
        city=city["name"],
        country=country["name"],
        country_slug=country_slug,
        city_slug=city_slug,
        meta_desc=meta_desc,
        lede=lede,
        intro_para=city["blurb"],
        cost_1br=city["cost_1br"],
        cost_2br=city["cost_2br"],
        groceries_solo=city["groceries_solo"],
        transport_pass=city["transport_pass"],
        internet=city["internet"],
        coworking_starting=city["coworking_starting"],
        realistic_low=realistic_low,
        realistic_high=realistic_high,
        primary_visa=country["primary_visa"],
        secondary_visa=country["secondary_visa"],
        fbi_line=fbi_line,
        tax_perk_line=tax_perk_line,
        best_neighborhoods=city["best_neighborhoods"],
        weather=city["weather"],
        pros=city["pros"],
        cons=city["cons"],
        poi_section=poi_section,
        related_links=related_html,
        cross_promo=cross_promo,
        app_url=APP_URL,
        play_url=PLAY_URL,
    )


def main() -> None:
    target = sys.argv[1] if len(sys.argv) > 1 else None
    generated = []

    all_cities = []
    for country_slug, country in DATA.items():
        for city_slug in country["cities"]:
            all_cities.append((country_slug, city_slug, country["cities"][city_slug]["name"]))

    for country_slug, country in DATA.items():
        for city_slug, city in country["cities"].items():
            if target and city_slug != target:
                continue
            related = [
                {"country_slug": cs, "city_slug": cit_slug, "name": name}
                for cs, cit_slug, name in all_cities
                if cit_slug != city_slug
            ][:4]
            html = render_city(country_slug, city_slug, country, city, related)
            out = ROOT / country_slug / city_slug / "index.html"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(html, encoding="utf-8")
            generated.append(str(out.relative_to(ROOT)))
            print(f"  -> {out.relative_to(ROOT)}")

    print(f"\ngenerated {len(generated)} pages")


if __name__ == "__main__":
    main()
