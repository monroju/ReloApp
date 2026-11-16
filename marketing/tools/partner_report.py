#!/usr/bin/env python3
"""Weekly partner report for getgothere.app: which partner links get clicked, on which pages.

Reads the PostHog read-only key itself (POSTHOG_KEY env var, else the key file below) and prints
only counts, never the key. Run it weekly and compare with the partner dashboards (Feather, Genki,
SafetyWing): clicks here vs sign-ups there tells you which pages earn.

    python marketing/tools/partner_report.py            # last 7 and 28 days
    python marketing/tools/partner_report.py --days 14  # one window
    python marketing/tools/partner_report.py --dry-run  # print the queries, no network, no key
"""
import argparse
import json
import os
import sys
import urllib.request
from pathlib import Path

PROJECT = 173722
API = f"https://eu.posthog.com/api/projects/{PROJECT}/query/"
KEY_FILE = Path(r"C:\Users\JGM\Documents\_backups\credentials-20260817\projects_credentials\posthog-readonly.txt")
SITE = "getgothere.app"
PARTNERS = Path(__file__).resolve().parents[1] / "landing-page" / "_partners.json"


def partner_hosts():
    from urllib.parse import urlparse
    cfg = json.loads(PARTNERS.read_text(encoding="utf-8"))
    hosts = {urlparse(p["affiliate_url"]).hostname for p in cfg["partners"] if p.get("affiliate_url")}
    return sorted(h for h in hosts if h)


def _q(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def queries(days):
    win = f"timestamp > now() - INTERVAL {int(days)} DAY AND properties.$host = {_q(SITE)}"
    hosts = ", ".join(_q(h) for h in partner_hosts())
    return {
        "Partner clicks by partner": (
            ["partner", "clicks"],
            f"SELECT properties.partner, count() AS c FROM events WHERE event = 'partner_click' AND {win} "
            "GROUP BY properties.partner ORDER BY c DESC LIMIT 50"),
        "Partner clicks by page": (
            ["page", "partner", "clicks"],
            f"SELECT properties.page, properties.partner, count() AS c FROM events WHERE event = 'partner_click' AND {win} "
            "GROUP BY properties.page, properties.partner ORDER BY c DESC LIMIT 50"),
        "Older-style clicks to partner sites (source_click, before partner_click shipped)": (
            ["host", "page", "clicks"],
            f"SELECT properties.host, properties.page, count() AS c FROM events WHERE event = 'source_click' "
            f"AND properties.host IN ({hosts}) AND {win} "
            "GROUP BY properties.host, properties.page ORDER BY c DESC LIMIT 50"),
        "Top pages (pageviews)": (
            ["page", "views"],
            f"SELECT properties.$pathname, count() AS c FROM events WHERE event = '$pageview' AND {win} "
            "GROUP BY properties.$pathname ORDER BY c DESC LIMIT 25"),
        "Expert intro requests": (
            ["topic", "requests"],
            f"SELECT properties.topic, count() AS c FROM events WHERE event = 'expert_lead' AND {win} "
            "GROUP BY properties.topic ORDER BY c DESC LIMIT 20"),
    }


def key():
    k = os.environ.get("POSTHOG_KEY", "").strip()
    if not k and KEY_FILE.exists():
        k = KEY_FILE.read_text(encoding="utf-8").strip().split()[0]
    if not k:
        sys.exit("No PostHog key: set POSTHOG_KEY or create the key file.")
    return k


def run(sql, k):
    req = urllib.request.Request(API, data=json.dumps({"query": {"kind": "HogQLQuery", "query": sql}}).encode(),
                                 headers={"Authorization": f"Bearer {k}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r).get("results", [])


def table(cols, rows):
    if not rows:
        return "  (none)"
    rows = [[("" if v is None else str(v)) for v in r] for r in rows]
    w = [max(len(c), *(len(r[i]) for r in rows)) for i, c in enumerate(cols)]
    line = lambda r: "  " + "  ".join(v.ljust(w[i]) for i, v in enumerate(r))  # noqa: E731
    return "\n".join([line(cols), line(["-" * x for x in w])] + [line(r) for r in rows])


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, action="append")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args(argv)
    windows = a.days or [7, 28]
    k = None if a.dry_run else key()
    for d in windows:
        print(f"\n=== getgothere.app, last {d} days ===")
        for title, (cols, sql) in queries(d).items():
            print(f"\n{title}")
            if a.dry_run:
                print("  " + sql)
                continue
            try:
                print(table(cols, run(sql, k)))
            except Exception as e:  # keep going, one bad query should not hide the rest
                print(f"  query failed: {type(e).__name__}: {getattr(e, 'code', '')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
