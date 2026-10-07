#!/usr/bin/env python3
"""Auto-generate sitemap.xml by scanning the landing-page directory.

Replaces the previously hand-maintained sitemap so newly generated pSEO / compare /
safe-harbor pages are never silently left out of the index. Run it last, after the
other _generate_*.py scripts:

    python _generate_pseo.py && python _generate_compare.py && \
        python ../../../_marketing/gen_safe_harbor.py && python _generate_sitemap.py

URL rules:
  foo/index.html          -> https://getgothere.app/foo/
  foo/bar.html            -> https://getgothere.app/foo/bar.html
  index.html (root)       -> https://getgothere.app/

lastmod comes from each file's modification time.
"""
import time
from pathlib import Path

ROOT = Path(__file__).parent
BASE = "https://getgothere.app"

# Files/dirs to skip (source, tooling, error pages, verification stubs).
SKIP_DIRS = {"_u"}
SKIP_FILES = {"404.html", "google-verify.html"}


def priority_and_freq(url_path: str):
    """(priority, changefreq) by section. url_path is the path after the domain."""
    p = url_path.strip("/")
    if p == "":
        return "1.0", "weekly"
    seg = p.split("/")
    top = seg[0]
    is_hub = len(seg) == 1  # e.g. "spain", "blog", "compare", "safe-harbor"
    if top in ("spain", "portugal", "mexico"):
        return ("0.9", "weekly") if is_hub else ("0.9", "monthly")
    if top == "compare":
        return ("0.9", "weekly") if is_hub else ("0.8", "monthly")
    if top == "safe-harbor":
        return "0.9", "monthly"
    if top == "blog":
        return ("0.9", "weekly") if is_hub else ("0.8", "monthly")
    return "0.7", "monthly"


def url_for(html: Path) -> str | None:
    rel = html.relative_to(ROOT)
    parts = rel.parts
    if any(part in SKIP_DIRS for part in parts):
        return None
    if html.name in SKIP_FILES or html.name.startswith("_"):
        return None
    if html.name == "index.html":
        parent = "/".join(parts[:-1])
        return f"{BASE}/{parent}/".replace("//", "/").replace(":/", "://") if parent else f"{BASE}/"
    return f"{BASE}/{'/'.join(parts)}"


def main():
    entries = []
    for html in sorted(ROOT.rglob("*.html")):
        url = url_for(html)
        if not url:
            continue
        path = url[len(BASE):]
        prio, freq = priority_and_freq(path)
        lastmod = time.strftime("%Y-%m-%d", time.localtime(html.stat().st_mtime))
        entries.append((url, lastmod, freq, prio))

    # Root first, then by descending priority, then alphabetically — stable + readable.
    entries.sort(key=lambda e: (e[0] != f"{BASE}/", -float(e[3]), e[0]))

    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for url, lastmod, freq, prio in entries:
        lines.append(f'  <url><loc>{url}</loc><lastmod>{lastmod}</lastmod>'
                     f'<changefreq>{freq}</changefreq><priority>{prio}</priority></url>')
    lines.append('</urlset>')
    (ROOT / "sitemap.xml").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote sitemap.xml with {len(entries)} urls")


if __name__ == "__main__":
    main()
