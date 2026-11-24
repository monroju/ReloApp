"""Runs landing-page/assets/gt.js in node with a stub DOM and checks which event a click sends.

Run: cd marketing && python -m pytest tests -q   (needs node on PATH)
"""
import json
import shutil
import subprocess
from pathlib import Path

import pytest

GT = Path(__file__).resolve().parents[1] / "landing-page" / "assets" / "gt.js"

HARNESS = r"""
const fs = require("fs");
const sent = [];
let handler = null;
globalThis.window = globalThis;
globalThis.location = new URL("https://getgothere.app/spain/madrid/");
window.posthog = { __loaded: true, capture: (n, p) => sent.push([n, p]) };
globalThis.document = {
  addEventListener: (t, fn) => { if (t === "click") handler = fn; },
  createElement: () => ({}),
  head: { appendChild: () => {} },
};
function link(href, attrs, boxClass) {
  const box = boxClass ? { className: boxClass, tagName: "ASIDE" } : null;
  const a = {
    href, rel: attrs.rel || "",
    classList: { contains: (c) => (attrs.class || "").split(" ").includes(c) },
    getAttribute: (k) => (k in attrs ? attrs[k] : null),
    closest: (sel) => (sel === "a[href]" ? a : box),
  };
  return a;
}
eval(fs.readFileSync(process.argv[2], "utf8"));
const clicks = JSON.parse(process.argv[3]);
for (const c of clicks) handler({ target: link(c.href, c.attrs, c.box) });
console.log(JSON.stringify(sent));
"""


def run(tmp_path, clicks):
    node = shutil.which("node")
    if not node:
        pytest.skip("node not on PATH")
    h = tmp_path / "harness.js"
    h.write_text(HARNESS, encoding="utf-8")
    out = subprocess.run([node, str(h), str(GT), json.dumps(clicks)], capture_output=True, text=True, timeout=30)
    assert out.returncode == 0, out.stderr
    return json.loads(out.stdout.strip().splitlines()[-1])


def test_partner_link_sends_partner_click(tmp_path):
    sent = run(tmp_path, [{
        "href": "https://feather-insurance.com/en-es/expat-health-insurance?utm_source=x&utm_campaign=pseo-madrid",
        "attrs": {"data-partner": "feather_es", "rel": "sponsored nofollow noopener", "class": "gt-p-btn"},
        "box": "gt-partners",
    }])
    assert sent == [["partner_click", {
        "partner": "feather_es", "campaign": "pseo-madrid", "placement": "gt-partners",
        "host": "feather-insurance.com", "page": "/spain/madrid/"}]]


def test_plain_source_link_still_sends_source_click(tmp_path):
    sent = run(tmp_path, [{
        "href": "https://www.exteriores.gob.es/Consulados/miami/",
        "attrs": {"rel": "nofollow", "class": "src"},
    }])
    assert sent == [["source_click", {"host": "www.exteriores.gob.es", "page": "/spain/madrid/"}]]


def test_internal_link_sends_nothing(tmp_path):
    assert run(tmp_path, [{"href": "https://getgothere.app/blog/", "attrs": {}}]) == []


def test_grupo_abrazo_link_sends_partner_click(tmp_path):
    sent = run(tmp_path, [{
        "href": "https://dashboard.grupoabrazo.com/go-there?utm_source=gothere&utm_medium=partner&utm_campaign=pseo-madrid",
        "attrs": {"data-partner": "grupo_abrazo", "rel": "sponsored nofollow noopener", "class": "gt-p-btn"},
        "box": "gt-partners gt-lead",
    }])
    assert sent == [["partner_click", {
        "partner": "grupo_abrazo", "campaign": "pseo-madrid", "placement": "gt-partners",
        "host": "dashboard.grupoabrazo.com", "page": "/spain/madrid/"}]]
