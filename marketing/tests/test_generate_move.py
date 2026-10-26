"""Checks the output of landing-page/_generate_move.py (run the generator first).

Run: cd ios/marketing && PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests -q
"""
import json
import re
from pathlib import Path

import pytest

SITE_DIR = Path(__file__).resolve().parents[1] / "landing-page"
DATA = Path(__file__).resolve().parents[3] / "shared" / "data"
VISAS = json.loads((DATA / "visas.json").read_text(encoding="utf-8"))
SLUGS = ["es", "pt", "ie", "it", "mx"]


def page(slug):
    return (SITE_DIR / "move" / f"us-to-{slug}" / "index.html").read_text(encoding="utf-8")


@pytest.mark.parametrize("slug", SLUGS)
def test_no_placeholder_leaks(slug):
    body = re.sub(r"<script.*?</script>", "", page(slug), flags=re.S).split("<body>", 1)[1]
    leaks = re.findall(r"\bNone\b|\bnan\b|\{[A-Za-z_\[\]'\"]+\}", body)
    assert not leaks, f"{leaks} leaked into /move/us-to-{slug}/"


@pytest.mark.parametrize("slug", SLUGS)
def test_every_fact_source_is_linked(slug):
    html = page(slug)
    for v in (v for v in VISAS if v["country"].lower() == slug):
        for field in ("income", "processingTimeDays", "workAllowed", "pathToPR", "pathToCitizenship"):
            url = v[field].get("sourceUrl")
            if url:
                assert url.replace("&", "&amp;") in html, f"{v['id']}.{field} source missing"


@pytest.mark.parametrize("slug", SLUGS)
def test_schema_blocks_parse_and_canonical(slug):
    html = page(slug)
    blocks = [json.loads(b) for b in re.findall(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)]
    types = {b["@type"] for b in blocks}
    assert {"Article", "BreadcrumbList", "FAQPage"} <= types
    faq = next(b for b in blocks if b["@type"] == "FAQPage")
    assert len(faq["mainEntity"]) >= 3
    assert f'<link rel="canonical" href="https://getgothere.app/move/us-to-{slug}/">' in html
    assert (SITE_DIR / "move" / "og" / f"us-to-{slug}.png").exists()


@pytest.mark.parametrize("slug", SLUGS)
def test_store_links_are_attributable(slug):
    html = page(slug)
    apple = re.findall(r"https://apps\.apple\.com/[^\"']+", html)
    play = re.findall(r"https://play\.google\.com/[^\"']+", html)
    assert apple and play
    assert all("pt=128632140" in u and "ct=" in u and "utm_" not in u for u in apple)
    assert all("referrer=" in u for u in play)


def test_null_facts_render_as_not_verified():
    # ie_stamp_0 citizenship is deliberately null (disputed)
    assert "Not yet verified" in page("ie")


def test_api_matches_data():
    api = json.loads((SITE_DIR / "api" / "visas.json").read_text(encoding="utf-8"))
    assert len(api["visas"]) == len(VISAS)
    index = json.loads((SITE_DIR / "api" / "index.json").read_text(encoding="utf-8"))
    for c in index["countries"]:
        slug = c["url"].rsplit("/", 1)[1]
        doc = json.loads((SITE_DIR / "api" / "countries" / slug).read_text(encoding="utf-8"))
        assert doc["visas"] and all(v["country"] == c["country"] for v in doc["visas"])


def test_llms_txt_and_updates():
    llms = (SITE_DIR / "llms.txt").read_text(encoding="utf-8")
    for slug in SLUGS:
        assert f"/move/us-to-{slug}/" in llms
    feed = json.loads((SITE_DIR / "updates" / "feed.json").read_text(encoding="utf-8"))
    assert feed["items"] and all(i["external_url"].startswith("https://") for i in feed["items"])
