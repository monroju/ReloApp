#!/usr/bin/env python3
"""Ping IndexNow (Bing, Yandex, Seznam, etc.) with the site's URLs so new / updated
pages get crawled within hours instead of waiting on the normal discovery cycle.

IndexNow ownership is proved by a public key file served at the site root:
    https://getgothere.app/<KEY>.txt   (contents = <KEY>)
That file lives beside this script and deploys with the rest of the static site.

Usage:
    python _indexnow.py            # DRY RUN — prints the payload, submits nothing
    python _indexnow.py --submit   # actually POST to IndexNow

Run it after _generate_sitemap.py (it reads sitemap.xml for the URL list).
"""
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).parent
HOST = "getgothere.app"
KEY = "9da24307a68613fbf4034bff7e7a5dea"
ENDPOINT = "https://api.indexnow.org/indexnow"


def sitemap_urls() -> list[str]:
    xml = (ROOT / "sitemap.xml").read_text(encoding="utf-8")
    return re.findall(r"<loc>([^<]+)</loc>", xml)


def main():
    submit = "--submit" in sys.argv

    key_file = ROOT / f"{KEY}.txt"
    if not key_file.exists():
        sys.exit(f"ERROR: key file {key_file.name} is missing — IndexNow can't verify ownership. "
                 f"Recreate it with contents '{KEY}'.")

    urls = sitemap_urls()
    if not urls:
        sys.exit("ERROR: no URLs found in sitemap.xml — run _generate_sitemap.py first.")

    payload = {
        "host": HOST,
        "key": KEY,
        "keyLocation": f"https://{HOST}/{KEY}.txt",
        "urlList": urls,
    }

    if not submit:
        print(f"DRY RUN — would POST {len(urls)} urls to {ENDPOINT}")
        print(f"  keyLocation: {payload['keyLocation']}")
        for u in urls[:5]:
            print(f"    {u}")
        print(f"    ... and {len(urls) - 5} more" if len(urls) > 5 else "")
        print("\nRe-run with --submit to actually notify IndexNow.")
        return

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(ENDPOINT, data=data,
                                 headers={"Content-Type": "application/json; charset=utf-8"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        print(f"IndexNow responded {resp.status} for {len(urls)} urls")


if __name__ == "__main__":
    main()
