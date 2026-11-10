#!/usr/bin/env python3
"""Shared partner (affiliate) box + expert-intro lead form for getgothere.app generators.

    from _partners import partner_box, expert_lead_box, write_api
    partner_box(["health_insurance", "money"], country="spain", campaign="pseo-madrid")
    expert_lead_box(topic="italy_descent", campaign="move-us-to-it")

partner_box returns "" when no partner in those categories is enabled with an
affiliate_url, so pages never show dead or commission-free links.

Run directly to write /api/partners.json (the apps fetch it) and print status:
    python _partners.py
"""
import html
import json
from pathlib import Path
from urllib.parse import urlencode, urlparse, parse_qsl, urlunparse

ROOT = Path(__file__).parent
CFG = json.loads((ROOT / "_partners.json").read_text(encoding="utf-8"))

CSS = """
.gt-partners{border:1px solid rgba(127,127,127,.25);border-radius:14px;padding:20px 22px;margin:28px 0;background:rgba(127,127,127,.06)}
.gt-partners h3{margin:0 0 6px;font-size:19px}
.gt-partners>p{margin:0 0 14px;opacity:.85;font-size:15px}
.gt-partners ul{list-style:none;margin:0;padding:0;display:grid;gap:12px}
.gt-partners li{display:flex;gap:14px;align-items:flex-start;justify-content:space-between;flex-wrap:wrap}
.gt-partners li div{flex:1 1 260px}
.gt-partners li strong{display:block}
.gt-partners li span{font-size:14px;opacity:.8}
.gt-partners a.gt-p-btn{white-space:nowrap;padding:8px 14px;border-radius:999px;border:1px solid currentColor;text-decoration:none;font-weight:600;font-size:14px}
.gt-partners small{display:block;margin-top:14px;font-size:12px;opacity:.7}
.gt-lead form{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}
.gt-lead input[type=email]{flex:1 1 220px;padding:10px 12px;border-radius:10px;border:1px solid rgba(127,127,127,.4);font:inherit;min-width:0}
.gt-lead button{padding:10px 16px;border-radius:10px;border:0;font:inherit;font-weight:600;cursor:pointer;background:#0f766e;color:#fff}
.gt-lead .gt-lead-ok{display:none;font-weight:600}
.gt-lead .gt-lead-err{font-size:14px;color:#b91c1c}
"""

HEADINGS = {
    "health_insurance": ("Health insurance for your move", "Long-stay visas usually need private health cover, and some consulates require no copays or deductibles. Check what yours asks for, then compare:"),
    "money": ("Moving your money", "Banks charge 3 to 5% on currency conversion. A cheaper way to move savings and proof of funds:"),
}

TOPIC_COPY = {
    "italy_descent": "Italian citizenship by descent: want an intro to a vetted lawyer or document service?",
    "ireland_descent": "Irish Foreign Births Register: want an intro to someone who handles the paperwork?",
    "spain_visa": "Applying for a Spanish visa: want an intro to a vetted immigration lawyer?",
    "portugal_visa": "Applying for a Portuguese visa: want an intro to a vetted immigration lawyer?",
    "descent": "Claiming citizenship by descent: want an intro to a vetted lawyer or document service?",
    "general": "Want an intro to a vetted immigration lawyer for your move?",
}


def _e(s):
    return html.escape(str(s), quote=True)


def _active(categories, country):
    out = []
    for p in CFG["partners"]:
        if not (p.get("enabled") and p.get("affiliate_url")):
            continue
        if p["category"] not in categories:
            continue
        if "*" not in p["countries"] and country not in p["countries"]:
            continue
        if country and country in p.get("exclude_countries", []):
            continue
        out.append(p)
    return out


def _tag(url, campaign):
    """Append our sub-id so the partner dashboard shows which page converted."""
    u = urlparse(url)
    q = dict(parse_qsl(u.query))
    q.setdefault("utm_source", "gothere")
    q.setdefault("utm_medium", "partner")
    q["utm_campaign"] = campaign
    return urlunparse(u._replace(query=urlencode(q)))


def partner_box(categories, country="", campaign="site"):
    blocks = []
    for cat in categories:
        ps = _active([cat], country)
        if not ps:
            continue
        h, sub = HEADINGS[cat]
        items = "".join(
            f'<li><div><strong>{_e(p["name"])}</strong><span>{_e(p["blurb"])}</span></div>'
            f'<a class="gt-p-btn" rel="sponsored nofollow noopener" target="_blank" '
            f'data-partner="{_e(p["id"])}" href="{_e(_tag(p["affiliate_url"], campaign))}">See options &rarr;</a></li>'
            for p in ps)
        blocks.append(f'<h3>{_e(h)}</h3><p>{_e(sub)}</p><ul>{items}</ul>')
    if not blocks:
        return ""
    return (f'<style>{CSS}</style><aside class="gt-partners" aria-label="Partner services">'
            + "".join(blocks) + f'<small>{_e(CFG["disclosure"])}</small></aside>\n')


LEAD_JS = """<script>
(function(){document.querySelectorAll('.gt-lead form').forEach(function(f){
 f.addEventListener('submit',async function(ev){ev.preventDefault();
  var box=f.parentNode,err=box.querySelector('.gt-lead-err'),ok=box.querySelector('.gt-lead-ok'),b=f.querySelector('button'),em=f.email.value.trim();
  err.textContent='';if(!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(em)){err.textContent='Please enter a valid email address.';return;}
  b.disabled=true;var q=new URLSearchParams(location.search);
  try{var r=await fetch('https://api.mylocalista.com/marketing/capture',{method:'POST',headers:{'Content-Type':'application/json'},
   body:JSON.stringify({app:'gothere',email:em,source:'expert_lead_'+f.dataset.topic,language:document.documentElement.lang||'en',
   utm_source:q.get('utm_source')||'site',utm_medium:q.get('utm_medium')||'organic',utm_campaign:f.dataset.campaign,utm_content:location.pathname})});
   if(!r.ok)throw 0;f.style.display='none';ok.style.display='block';
   if(window.gtTrack)try{gtTrack('expert_lead',{topic:f.dataset.topic})}catch(e){}
  }catch(e){err.textContent="Couldn't reach the server. Try again in a minute.";b.disabled=false;}
 });});})();
</script>"""


def expert_lead_box(topic="general", campaign="site"):
    if not CFG["expert_lead"].get("enabled"):
        return ""
    q = TOPIC_COPY.get(topic, TOPIC_COPY["general"])
    return (f'<style>{CSS}</style><aside class="gt-partners gt-lead" aria-label="Expert introduction">'
            f'<h3>{_e(q)}</h3>'
            '<p>We are lining up a small list of lawyers and services we have checked. Leave your email and we will '
            'write once, to offer an introduction. We share your details with a partner only if you reply yes.</p>'
            f'<form data-topic="{_e(topic)}" data-campaign="{_e(campaign)}" novalidate>'
            '<input type="email" name="email" autocomplete="email" placeholder="you@example.com" aria-label="Email" required>'
            '<button type="submit">Request an intro</button></form>'
            '<p class="gt-lead-ok">Thanks. We will be in touch when a vetted partner is ready.</p>'
            '<p class="gt-lead-err" role="alert"></p>'
            '<small>GoThere is research, not legal advice. See our <a href="/privacy.html">privacy policy</a>.</small>'
            f'</aside>{LEAD_JS}\n')


def write_api():
    """Public feed for the apps: only live partners, no internal notes."""
    live = [{k: p[k] for k in ("id", "name", "category", "countries", "blurb")} | {"url": p["affiliate_url"]}
            for p in CFG["partners"] if p.get("enabled") and p.get("affiliate_url") and not p.get("web_only")]
    out = {"version": 1, "disclosure": CFG["disclosure"], "partners": live}
    (ROOT / "api").mkdir(exist_ok=True)
    (ROOT / "api" / "partners.json").write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return live


if __name__ == "__main__":
    live = write_api()
    for p in CFG["partners"]:
        state = ("LIVE web only" if p.get("web_only") else "LIVE") if (p.get("enabled") and p.get("affiliate_url")) else "off (needs affiliate_url + enabled)"
        print(f"{p['id']:20} {state}")
    print(f"api/partners.json written, {len(live)} live")
