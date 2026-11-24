"""Partner placement rules and the Spain NLV insurance page.

Run: cd marketing && python -m pytest tests -q
"""
import json
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parents[1] / "landing-page"
sys.path.insert(0, str(SITE))
from _partners import _active, partner_box  # noqa: E402

SPAIN_PAGES = [*(f"spain/{c}/index.html" for c in ("barcelona", "bilbao", "granada", "madrid", "sansebastian", "valencia")),
               "move/us-to-es/index.html", "blog/spain-non-lucrative-visa-2026.html",
               "blog/spain-nlv-health-insurance-2026.html", "compare/spain-nlv-vs-dnv/index.html"]
NEW = SITE / "blog" / "spain-nlv-health-insurance-2026.html"


def ids(country):
    return {p["id"] for p in _active(["health_insurance"], country)}


def partners_on(rel):
    return set(re.findall(r'data-partner="([a-z_]+)"', (SITE / rel).read_text(encoding="utf-8")))


def test_spain_gets_only_spain_compliant_insurers():
    got = ids("spain")
    assert "feather_es" in got
    assert not {"genki", "safetywing", "safetywing_complete"} & got


def test_genki_still_offered_outside_spain():
    assert "genki" in ids("portugal")
    assert "genki" in ids("")


def test_spain_box_html_has_feather_and_no_genki():
    html = partner_box(["health_insurance"], "spain", "t")
    assert 'data-partner="feather_es"' in html and "genki" not in html


def test_generated_spain_pages_follow_the_rule():
    for rel in SPAIN_PAGES:
        got = partners_on(rel)
        assert "feather_es" in got, rel
        assert "genki" not in got and "safetywing" not in got, rel


def test_new_page_partner_box_and_expert_form():
    html = NEW.read_text(encoding="utf-8")
    assert html.count("<!-- partners:start -->") == 1
    assert 'class="gt-partners gt-lead"' in html
    assert "utm_campaign=blog-spain-nlv-health-insurance-2026" in html


def test_new_page_json_ld_parses_and_faq_present():
    html = NEW.read_text(encoding="utf-8")
    blocks = [json.loads(b) for b in re.findall(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)]
    types = {b["@type"] for b in blocks}
    assert {"Article", "FAQPage"} <= types
    faq = next(b for b in blocks if b["@type"] == "FAQPage")
    assert len(faq["mainEntity"]) >= 4


def test_new_page_cites_official_sources_only_for_rules():
    html = NEW.read_text(encoding="utf-8")
    srcs = re.findall(r'<a class="src"[^>]*href="([^"]+)"', html)
    assert len(srcs) >= 4
    assert all(re.match(r"https://(www\.)?(exteriores\.gob\.es|dgsfp\.mineco\.gob\.es)/", s) for s in srcs), srcs


def test_new_page_linked_and_in_sitemap():
    assert "/blog/spain-nlv-health-insurance-2026.html" in (SITE / "blog" / "index.html").read_text(encoding="utf-8")
    assert "/blog/spain-nlv-health-insurance-2026.html" in (SITE / "blog" / "spain-non-lucrative-visa-2026.html").read_text(encoding="utf-8")
    assert "https://getgothere.app/blog/spain-nlv-health-insurance-2026.html" in (SITE / "sitemap.xml").read_text(encoding="utf-8")


def test_api_feed_keeps_genki_for_apps():
    feed = json.loads((SITE / "api" / "partners.json").read_text(encoding="utf-8"))
    assert {p["id"] for p in feed["partners"]} == {"genki", "feather_es", "feather_de"}


# --- Expatsi (impact.com, approved 2026-11-23) ---
from _partners import _tag  # noqa: E402

PASSIVE_POSTS = ["argentina-rentista-visa-2026", "ireland-stamp-0-retiree-visa-2026", "italy-elective-residency-visa-2026",
                 "mexico-temporary-resident-visa-2026", "portugal-d7-d8-visa-2026", "spain-non-lucrative-visa-2026"]
PLANNING_PAGES = ["blog/how-to-move-abroad-from-the-us.html", "tools/visa-income-calculator/index.html",
                  *(f"move/us-to-{c}/index.html" for c in ("es", "ie", "it", "mx", "pt"))]


def test_impact_links_get_subid_not_utm():
    url = _tag("https://expatsiinc.sjv.io/c/8250997/4027765/54613", "us-to-pt", "subId1")
    assert url == "https://expatsiinc.sjv.io/c/8250997/4027765/54613?subId1=us-to-pt"


def test_other_partners_keep_utm_tags():
    url = _tag("https://genki.world/products/native?with=gothere", "x")
    assert "with=gothere" in url and "utm_source=gothere" in url and "utm_campaign=x" in url and "subId1" not in url


def test_planning_box_has_expatsi_and_disclosure():
    html = partner_box(["planning"], "portugal", "t")
    assert 'data-partner="expatsi_test"' in html and "subId1=t" in html
    assert 'rel="sponsored nofollow noopener"' in html and "partner links" in html


def test_expatsi_not_in_app_feed():
    feed = json.loads((SITE / "api" / "partners.json").read_text(encoding="utf-8"))
    assert not [p for p in feed["partners"] if p["id"].startswith("expatsi")]


def test_planning_pages_carry_expatsi_test():
    for rel in PLANNING_PAGES:
        assert "expatsi_test" in partners_on(rel), rel


def test_passive_posts_carry_expatsi_passive_only_there():
    for slug in PASSIVE_POSTS:
        assert "expatsi_passive" in partners_on(f"blog/{slug}.html"), slug
    for other in ("uk-skilled-worker-visa-2026", "germany-eu-blue-card-2026", "spain-nlv-health-insurance-2026"):
        assert not {"expatsi_passive", "expatsi_test"} & partners_on(f"blog/{other}.html"), other


# --- Grupo Abrazo (Spain consultants, operator approved 2026-11-24) ---
from _partners import expert_lead_box  # noqa: E402

ABRAZO_PAGES = [*(f"spain/{c}/index.html" for c in ("barcelona", "bilbao", "granada", "madrid", "sansebastian", "valencia")),
                "spain/index.html", "move/us-to-es/index.html", "blog/spain-non-lucrative-visa-2026.html",
                "blog/spain-nlv-health-insurance-2026.html",
                *(f"compare/{c}/index.html" for c in ("spain-nlv-vs-dnv", "spain-nlv-vs-portugal-d7", "spain-dnv-vs-portugal-d8"))]
NOT_ABRAZO = ["portugal/lisbon/index.html", "move/us-to-pt/index.html", "blog/portugal-d7-d8-visa-2026.html",
              "compare/passive-income-visas/index.html", "mexico/tulum/index.html"]
DASHES = ("—", "–", " - ")


def test_spain_lead_box_is_grupo_abrazo():
    html = expert_lead_box("spain_visa", "t")
    assert 'data-partner="grupo_abrazo"' in html
    assert 'href="https://dashboard.grupoabrazo.com/go-there?' in html and "gabriel-go-there" not in html
    assert 'rel="sponsored nofollow noopener"' in html and "partner links" in html
    assert "10% off for GoThere readers" in html
    assert 'data-topic="spain_visa"' in html  # email intro form kept
    assert "147" not in html and "€" not in html and "EUR" not in html  # no price until currency confirmed
    text = html.split("<aside", 1)[1].split("<script>", 1)[0]
    assert not any(d in text for d in DASHES)


def test_other_topics_unchanged():
    for topic in ("portugal_visa", "general", "italy_descent", "descent"):
        html = expert_lead_box(topic, "t")
        assert "grupo_abrazo" not in html and "vetted" in html, topic


def test_abrazo_on_every_spain_page_once():
    for rel in ABRAZO_PAGES:
        html = (SITE / rel).read_text(encoding="utf-8")
        assert html.count('data-partner="grupo_abrazo"') == 1, rel
        assert "dashboard.grupoabrazo.com/go-there" in html and "partner links" in html, rel


def test_abrazo_not_on_other_countries():
    for rel in NOT_ABRAZO:
        assert "grupo_abrazo" not in partners_on(rel), rel


def test_abrazo_not_in_app_feed():
    feed = json.loads((SITE / "api" / "partners.json").read_text(encoding="utf-8"))
    assert "grupo_abrazo" not in {p["id"] for p in feed["partners"]}
