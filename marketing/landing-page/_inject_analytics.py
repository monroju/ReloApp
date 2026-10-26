#!/usr/bin/env python3
"""Make sure every page loads /assets/gt.js (cookieless PostHog events). Idempotent.

Generators already emit the tag; this covers hand-written pages. Run before deploy:
    python _inject_analytics.py          # report pages missing the tag
    python _inject_analytics.py --fix    # insert it before </head>
"""
import sys
from pathlib import Path

ROOT = Path(__file__).parent
TAG = '<script src="/assets/gt.js" defer></script>'
SKIP = {"googleade6ce484cc5585a.html"}


def main():
    fix = "--fix" in sys.argv
    missing = []
    for html in sorted(ROOT.rglob("*.html")):
        if html.name in SKIP or "_u" in html.parts:
            continue
        text = html.read_text(encoding="utf-8")
        if "/assets/gt.js" in text or "</head>" not in text:
            continue
        missing.append(html.relative_to(ROOT))
        if fix:
            html.write_text(text.replace("</head>", f"  {TAG}\n</head>", 1), encoding="utf-8", newline="")
    verb = "fixed" if fix else "missing"
    for m in missing:
        print(f"  {verb}: {m}")
    print(f"{len(missing)} pages {verb}")
    return 1 if (missing and not fix) else 0


if __name__ == "__main__":
    sys.exit(main())
