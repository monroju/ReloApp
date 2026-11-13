#!/usr/bin/env python3
"""Put the partner box + expert-intro form into the hand-written blog posts. Idempotent.

Content sits between <!-- partners:start --> and <!-- partners:end -->, placed just
before the post's first CTA block. Rerun after editing _partners.json:
    python _inject_partners.py
"""
import re
from pathlib import Path

from _partners import partner_box, expert_lead_box

ROOT = Path(__file__).parent
START, END = "<!-- partners:start -->", "<!-- partners:end -->"
BLOCK_RE = re.compile(re.escape(START) + r".*?" + re.escape(END) + r"\r?\n?", re.S)
ANCHORS = ['<div class="cta-box">', '<div class="cta-banner">']

# slug -> (partner categories, country for country-only partners, expert topic or None)
POSTS = {
    "argentina-rentista-visa-2026": (["health_insurance", "money"], "argentina", "general"),
    "canada-citizenship-by-descent-2026": (["money"], "canada", "descent"),
    "canada-express-entry-visa-2026": (["money"], "canada", "general"),
    "germany-eu-blue-card-2026": (["money"], "germany", "general"),
    "how-to-move-abroad-from-the-us": (["health_insurance", "money"], "", "general"),
    "hungary-simplified-naturalization-2026": (["money"], "hungary", "descent"),
    "hungary-white-card-visa-2026": (["health_insurance", "money"], "hungary", "general"),
    "ireland-foreign-births-register-2026": (["money"], "ireland", "ireland_descent"),
    "ireland-stamp-0-retiree-visa-2026": (["health_insurance", "money"], "ireland", "general"),
    "italy-elective-residency-visa-2026": (["health_insurance", "money"], "italy", "general"),
    "italy-jure-sanguinis-citizenship-2026": (["money"], "italy", "italy_descent"),
    "mexico-temporary-resident-visa-2026": (["health_insurance", "money"], "mexico", "general"),
    "poland-citizenship-confirmation-2026": (["money"], "poland", "descent"),
    "portugal-d7-d8-visa-2026": (["health_insurance", "money"], "portugal", "portugal_visa"),
    "spain-non-lucrative-visa-2026": (["health_insurance", "car", "money"], "spain", "spain_visa"),
    "uk-ancestry-visa-2026": (["money"], "uk", "general"),
    "uk-skilled-worker-visa-2026": (["money"], "uk", "general"),
}


def main():
    for slug, (cats, country, topic) in POSTS.items():
        f = ROOT / "blog" / f"{slug}.html"
        raw = f.read_bytes().decode("utf-8")
        nl = "\r\n" if "\r\n" in raw else "\n"
        text = BLOCK_RE.sub("", raw)
        campaign = f"blog-{slug}"[:60]
        inner = partner_box(cats, country, campaign) + (expert_lead_box(topic, campaign) if topic else "")
        if inner:
            pos = min((text.find(a) for a in ANCHORS if a in text), default=-1)
            if pos < 0:
                print(f"  no CTA anchor: {slug}")
                continue
            line_start = text.rfind("\n", 0, pos) + 1
            block = (START + "\n" + inner + END + "\n").replace("\n", nl)
            text = text[:line_start] + block + text[line_start:]
        if text != raw:
            f.write_bytes(text.encode("utf-8"))
            print(f"  updated: {slug}")


if __name__ == "__main__":
    main()
