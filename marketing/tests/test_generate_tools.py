"""Checks the output of landing-page/_generate_tools.py (run the generator first).

Run: cd ios/marketing && PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests -q
"""
import json
import re
from pathlib import Path

import pytest

SITE_DIR = Path(__file__).resolve().parents[1] / "landing-page"
DATA = Path(__file__).resolve().parents[3] / "shared" / "data"
VISAS = json.loads((DATA / "visas.json").read_text(encoding="utf-8"))
FX = json.loads((DATA / "fx_cache.json").read_text(encoding="utf-8"))
PAGES = ["tools", "tools/citizenship-by-descent", "tools/visa-income-calculator"]


def page(path):
    return (SITE_DIR / path / "index.html").read_text(encoding="utf-8")


def schema_types(html):
    return {json.loads(b)["@type"] for b in re.findall(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)}


@pytest.mark.parametrize("path", PAGES)
def test_canonical_store_links_and_no_leaks(path):
    html = page(path)
    assert f'<link rel="canonical" href="https://getgothere.app/{path}/">' in html
    apple = re.findall(r"https://apps\.apple\.com/[^\"']+", html)
    assert apple and all("pt=128632140" in u and "ct=tools_" in u and "utm_" not in u for u in apple)
    assert all("referrer=" in u for u in re.findall(r"https://play\.google\.com/[^\"']+", html))
    body = re.sub(r"<script.*?</script>", "", html, flags=re.S).split("<body>", 1)[1]
    assert not re.findall(r"\bNone\b|\bnan\b|\{[A-Za-z_\[\]'\"]+\}", body)


@pytest.mark.parametrize("path", PAGES[1:])
def test_tool_schema(path):
    assert {"WebApplication", "BreadcrumbList", "FAQPage"} <= schema_types(page(path))


def test_descent_checker_uses_the_engine_and_asks_no_names():
    html = page("tools/citizenship-by-descent")
    assert 'var MCP = "/mcp/"' in html and '"check_descent_eligibility"' in html
    assert not re.search(r'name="[^"]*name[^"]*"', html), "never ask for names"
    for cc in ("ie", "ca"):
        assert f'id="requirements-{cc}"' in html
        assert f'value="{cc}"' in html
    assert "Rules verified 20" in html
    assert "textContent" in html and "innerHTML" not in html, "engine text must not be parsed as HTML"


def test_income_calculator_matches_visa_data():
    html = page("tools/visa-income-calculator")
    data = json.loads(re.search(r'<script type="application/json" id="income-data">(.*?)</script>', html, re.S).group(1))
    assert data["date"] == FX["date"] and data["rates"] == FX["rates"]
    by_id = {v["id"]: v for v in data["visas"]}
    for v in VISAS:
        inc = v["income"]
        if v["category"] == "work":
            assert v["id"] not in by_id, "job-offer salary floors are not personal-income tests"
            assert inc["sourceUrl"].replace("&", "&amp;") in html
            continue
        if inc.get("monthly") is None and inc.get("annual") is None:
            continue
        want = inc["monthly"] if inc.get("monthly") is not None else inc["annual"] / 12
        assert by_id[v["id"]]["monthly"] == pytest.approx(want, abs=0.01)
        assert by_id[v["id"]]["currency"] == inc["currency"]
        assert inc["sourceUrl"].replace("&", "&amp;") in html, f"{v['id']} source missing"
    usd = [r["monthly"] / FX["rates"].get(r["currency"], 1) for r in data["visas"]]
    assert usd == sorted(usd)


def test_tools_are_linked_and_tracked():
    assert "/tools/" in (SITE_DIR / "index.html").read_text(encoding="utf-8")
    assert "/tools/citizenship-by-descent/" in (SITE_DIR / "llms.txt").read_text(encoding="utf-8")
    sitemap = (SITE_DIR / "sitemap.xml").read_text(encoding="utf-8")
    for path in PAGES:
        assert f"https://getgothere.app/{path}/" in sitemap
    assert "window.gtTrack = send" in (SITE_DIR / "assets" / "gt.js").read_text(encoding="utf-8")
