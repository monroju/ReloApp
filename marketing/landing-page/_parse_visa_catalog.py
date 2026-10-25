#!/usr/bin/env python3
"""Parse ios/GoThere/Data/VisaCatalog.swift into _visa_catalog.json.

The Swift is very regular (one VisaInfo(...) literal per visa, key: value lines),
so we split on VisaInfo( at paren depth and pull fields with light regex.
Comparison-page generation reads the JSON, never the Swift.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).parent
SWIFT = ROOT.parent.parent.parent / "ios" / "GoThere" / "Data" / "VisaCatalog.swift"

text = SWIFT.read_text(encoding="utf-8")

# Isolate each VisaInfo( ... ) block by walking parens from each "VisaInfo(".
blocks = []
i = 0
needle = "VisaInfo("
while True:
    start = text.find(needle, i)
    if start == -1:
        break
    j = start + len(needle)
    depth = 1
    while j < len(text) and depth:
        ch = text[j]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        j += 1
    blocks.append(text[start + len(needle):j - 1])
    i = j

STR = lambda key, b: (re.search(rf'\b{key}:\s*"((?:[^"\\]|\\.)*)"', b) or [None, None])[1]
INT = lambda key, b: (lambda m: int(m[1]) if m else None)(re.search(rf'\b{key}:\s*(\d+)', b))


def str_array(key, b):
    m = re.search(rf'\b{key}:\s*\[(.*?)\]', b, re.S)
    if not m:
        return []
    return [s for s in re.findall(r'"((?:[^"\\]|\\.)*)"', m[1])]


visas = []
for b in blocks:
    vid = STR("id", b)
    if not vid:
        continue
    visas.append({
        "id": vid,
        "countryId": STR("countryId", b),
        "countryFlag": STR("countryFlag", b),
        "countryName": STR("countryName", b),
        "name": STR("name", b),
        "shortName": STR("shortName", b),
        "category": (re.search(r'\bcategory:\s*\.(\w+)', b) or [None, None])[1],
        "income": STR("income", b),
        "monthlyIncomeEUR": INT("monthlyIncomeEUR", b),
        "processingTime": STR("processingTime", b),
        "duration": STR("duration", b),
        "workAllowed": STR("workAllowed", b),
        "pathToPR": STR("pathToPR", b),
        "pathToCitizenship": STR("pathToCitizenship", b),
        "costEstimate": STR("costEstimate", b),
        "pros": str_array("pros", b),
        "cons": str_array("cons", b),
        "officialUrl": STR("officialUrl", b),
    })

out = ROOT / "_visa_catalog.json"
out.write_text(json.dumps(visas, indent=2, ensure_ascii=False), encoding="utf-8")

from collections import Counter
cats = Counter(v["category"] for v in visas)
countries = Counter(v["countryName"] for v in visas)
print(f"parsed {len(visas)} visas -> {out.name}")
print("by category:", dict(cats))
print("by country:", dict(countries))
missing = [v["id"] for v in visas if not v["name"] or not v["category"]]
if missing:
    print("WARN incomplete:", missing)
