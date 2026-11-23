"""Checks _help.py: the feed only exposes agreed orgs, partner pages carry attribution.

Run: cd ios/marketing && PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests -q
"""
import copy
import json
import sys
from datetime import date
from pathlib import Path

import pytest

SITE = Path(__file__).resolve().parents[1] / "landing-page"
sys.path.insert(0, str(SITE))
import _help  # noqa: E402

ORG = {"id": "test-org", "name": "Test Org", "blurb": "Helps people.", "url": "https://test.org",
       "audiences": ["veterans"], "apps": ["gothere", "localista"], "countries": ["*"],
       "partner_page": True, "members_word": "members", "_note": "private", "enabled": True}


def cfg(*orgs):
    return {"orgs": [copy.deepcopy(o) for o in orgs]}


def test_disabled_orgs_never_reach_the_feed():
    off = dict(ORG, id="off-org", enabled=False)
    assert _help.feed(cfg(off), today=date(2026, 11, 12)) == {"version": 1, "updated": "2026-11-12", "orgs": []}


def test_feed_has_only_public_fields():
    f = _help.feed(cfg(ORG))
    assert f["orgs"] == [{k: ORG[k] for k in _help.PUBLIC}]
    assert "_note" not in json.dumps(f) and "enabled" not in f["orgs"][0]


@pytest.mark.parametrize("bad", [{"url": "http://x.org"}, {"apps": ["other"]},
                                 {"audiences": ["nope"]}, {"id": "Bad Id!"}, {"blurb": ""}])
def test_validation_rejects_bad_entries(bad):
    with pytest.raises(ValueError):
        _help.feed(cfg(dict(ORG, **bad)))


def test_partner_page_attribution_and_noindex():
    page = _help.page(ORG)
    assert '<meta name="robots" content="noindex">' in page
    assert "ct=partner_test-org" in page and "pt=128632140" in page
    assert "utm_source%3Dtest-org" in page
    assert "id6760248690" in page and "id6760856341" in page and "com.localista.spain" in page
    assert "Free access for Test Org members" in page


def test_checked_in_source_builds():
    f = _help.feed()
    assert f["version"] == 1
    assert all(set(o) <= set(_help.PUBLIC) for o in f["orgs"])
