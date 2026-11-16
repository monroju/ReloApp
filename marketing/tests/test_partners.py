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
