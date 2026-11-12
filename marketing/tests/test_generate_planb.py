"""Checks /plan-b/ (landing-page/_generate_planb.py) and the Plan B box on the descent checker.

Run the generators first, then: cd ios/marketing && PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests -q
"""
import json
import re
from pathlib import Path

SITE_DIR = Path(__file__).resolve().parents[1] / "landing-page"
DATA = Path(__file__).resolve().parents[3] / "shared" / "data"
CHAINS = json.loads((DATA / "descent_chains.json").read_text(encoding="utf-8"))["chains"]
HTML = (SITE_DIR / "plan-b" / "index.html").read_text(encoding="utf-8")
BODY = re.sub(r"<script.*?</script>", "", HTML, flags=re.S).split("<body>", 1)[1]
TOOL = (SITE_DIR / "tools" / "citizenship-by-descent" / "index.html").read_text(encoding="utf-8")


def schema_types(html):
    return {json.loads(b)["@type"] for b in re.findall(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)}


def test_canonical_schema_and_no_template_leaks():
    assert '<link rel="canonical" href="https://getgothere.app/plan-b/">' in HTML
    assert {"Article", "BreadcrumbList", "FAQPage"} <= schema_types(HTML)
    assert not re.findall(r"\bNone\b|\bnan\b|\{[A-Za-z_\[\]'\"]+\}", BODY)


def test_store_links_attributed():
    apple = re.findall(r"https://apps\.apple\.com/[^\"']+", HTML)
    assert apple and all("pt=128632140" in u and "utm_" not in u for u in apple)
    assert any("ct=planb_plan-b" in u for u in apple)
    assert all("referrer=" in u for u in re.findall(r"https://play\.google\.com/[^\"']+", HTML))


def test_every_country_has_a_section_and_official_source():
    for chain in CHAINS.values():
        cc = chain["countryCode"]
        assert f'id="{cc}"' in BODY, cc
        official = next(s["url"] for s in chain["sources"] if s["type"] == "official")
        assert official.replace("&", "&amp;") in BODY, cc


def test_review_times_only_from_sourced_stages():
    """A wait shown on the page must exist, with a source, in the data; the rest say Not yet verified."""
    for chain in CHAINS.values():
        wait = next(s for s in chain["stages"] if s["id"] == "wait")
        if wait["typicalMonths"]:
            assert wait["sourceUrl"].replace("&", "&amp;") in BODY
    assert "Not yet verified" in BODY  # IT, PL, HU publish no review time today


def test_no_political_framing():
    lowered = BODY.lower()
    for word in ("election", "trump", "biden", "midterm", "flee", "escape", "regime"):
        assert word not in lowered, word


def test_unaudited_blog_posts_not_linked():
    assert "/blog/hungary-simplified-naturalization-2026.html" not in BODY
    assert "/blog/poland-citizenship-confirmation-2026.html" not in BODY


def test_checker_track_box_hidden_until_result():
    box = re.search(r'<div class="cta-box" id="track-in-app" hidden>(.*?)</div></div>', TOOL, re.S)
    assert box, "track box missing or not hidden by default"
    assert "ct=tools_descent-track" in box.group(1)
    assert 'track.hidden = d.confidence === "red"' in TOOL
    assert 'trackBox.hidden = true' in TOOL  # reset before every check
