#!/usr/bin/env python3
"""Get help feed + partner pages for getgothere.app.

Reads _help.json and writes:
  api/help.json      the feed the four apps read (enabled orgs only, public fields only)
  p/<id>/index.html  one co-branded "free access for <Org> members" page per enabled org
                     with partner_page=true. Store links carry the org id for attribution:
                     App Store ct=partner_<id> (App Analytics > Campaigns),
                     Play referrer utm_source=<id> (the Android apps store it on first launch).

Spec: Projects/growth-plan/08-get-help-spec.md
Run: python _help.py   (then deploy api/help.json and p/ to both surfaces)
"""
import html
import json
from datetime import date
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent
CFG = json.loads((ROOT / "_help.json").read_text(encoding="utf-8"))
PUBLIC = ("id", "name", "blurb", "url", "audiences", "apps", "countries")
AUDIENCES = {"lgbtq", "trans", "veterans", "neurodivergent", "disability", "families", "general"}
APPS = {"gothere", "localista"}
PT = "128632140"
STORE = {
    "gothere": {
        "name": "GoThere",
        "what": "Turns visa and citizenship paperwork into small, clear steps with deadlines.",
        "ios": "https://apps.apple.com/app/gothere-relocation-guide/id6760248690",
        "play": "com.gothere.app",
    },
    "localista": {
        "name": "Localista",
        "what": "Explains Spanish government letters and local news in plain English.",
        "ios": "https://apps.apple.com/app/localista-spain-expat-news/id6760856341",
        "play": "com.localista.spain",
    },
}


def e(s):
    return html.escape(str(s), quote=True)


def validate(org):
    missing = [k for k in ("id", "name", "blurb", "url", "apps") if not org.get(k)]
    if missing:
        raise ValueError(f"{org.get('id', '?')}: missing {missing}")
    if not org["url"].startswith("https://"):
        raise ValueError(f"{org['id']}: url must be https")
    if not set(org["apps"]) <= APPS:
        raise ValueError(f"{org['id']}: unknown app in {org['apps']}")
    if not set(org.get("audiences", ["general"])) <= AUDIENCES:
        raise ValueError(f"{org['id']}: unknown audience in {org.get('audiences')}")
    if not all(c.isalnum() or c == "-" for c in org["id"]) or org["id"].lower() != org["id"]:
        raise ValueError(f"{org['id']}: id must be lowercase letters, digits, hyphens")


def live_orgs(cfg=None):
    cfg = cfg or CFG
    out = []
    for org in cfg["orgs"]:
        if not org.get("enabled"):
            continue
        validate(org)
        out.append(org)
    return out


def feed(cfg=None, today=None):
    orgs = []
    for o in live_orgs(cfg):
        pub = {k: o[k] for k in PUBLIC if k in o}
        pub.setdefault("audiences", ["general"])
        pub.setdefault("countries", ["*"])
        orgs.append(pub)
    return {"version": 1, "updated": (today or date.today()).isoformat(), "orgs": orgs}


def ios_link(app, org_id):
    return f"{STORE[app]['ios']}?pt={PT}&ct=partner_{org_id}&mt=8"


def play_link(app, org_id):
    ref = quote(f"utm_source={org_id}&utm_medium=partner&utm_campaign=partner_{org_id}", safe="")
    return f"https://play.google.com/store/apps/details?id={STORE[app]['play']}&referrer={ref}"


def page(org):
    oid, name = org["id"], org["name"]
    who = org.get("members_word", "members")
    title = f"Free access for {name} {who}"
    canon = f"https://getgothere.app/p/{oid}/"
    apps = "".join(
        f'<section class="app"><h2>{e(STORE[a]["name"])}</h2><p>{e(STORE[a]["what"])}</p>'
        f'<div class="badges"><a href="{e(ios_link(a, oid))}">Download on the App Store</a>'
        f'<a href="{e(play_link(a, oid))}">Get it on Google Play</a></div></section>'
        for a in org["apps"])
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="robots" content="noindex">
  <script src="/assets/gt.js" defer></script>
  <title>{e(title)}</title>
  <meta name="description" content="{e(title)}. Step by step help moving abroad, free.">
  <link rel="canonical" href="{canon}">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=DM+Sans:wght@700&display=swap" rel="stylesheet">
  <style>
    :root {{ --teal:#15B8A6; --bg:#0B0F14; --bg-card:#1A2332; --border:#1E293B; --text:#F1F5F9; --mute:#94A3B8; }}
    *,*:before,*:after {{ box-sizing:border-box; margin:0; padding:0; }}
    body {{ font-family:Inter,-apple-system,sans-serif; background:var(--bg); color:var(--text); line-height:1.7; }}
    a {{ color:var(--teal); }}
    .container {{ max-width:720px; margin:0 auto; padding:32px 16px; }}
    nav {{ padding:20px 16px; border-bottom:1px solid var(--border); font-family:'DM Sans'; font-weight:700; font-size:22px; }}
    h1 {{ font-family:'DM Sans'; font-size:34px; line-height:1.2; margin:16px 0; }}
    h2 {{ font-family:'DM Sans'; font-size:22px; margin:0 0 6px; }}
    p, ol {{ margin:12px 0; }} ol {{ padding-left:22px; }} li {{ margin:6px 0; }}
    .lede {{ font-size:18px; color:var(--mute); }}
    .app, .steps {{ background:var(--bg-card); border:1px solid var(--border); border-radius:16px; padding:22px; margin:22px 0; }}
    .badges {{ display:flex; gap:12px; flex-wrap:wrap; margin-top:12px; }}
    .badges a {{ background:#000; color:#fff; border:1px solid var(--border); padding:12px 18px; border-radius:10px; font-weight:600; text-decoration:none; }}
    .note {{ font-size:14px; color:var(--mute); }}
    @media (max-width:600px) {{ h1 {{ font-size:28px; }} }}
  </style>
</head>
<body>
  <nav><div class="container" style="padding:0">GoThere</div></nav>
  <main class="container">
    <h1>{e(title)}</h1>
    <p class="lede">We partner with <a href="{e(org['url'])}">{e(name)}</a> to give their {e(who)} free access to our apps.</p>
    {apps}
    <div class="steps">
      <h2>How to get your free access</h2>
      <ol>
        <li>Get your free access code from {e(name)}.</li>
        <li>Install the app with the button above.</li>
        <li>On iPhone: open the app, go to Settings, tap Redeem a code, and enter your code.</li>
        <li>On Android: open the app, go to Settings, tap Redeem a code, and enter your code in Google Play.</li>
      </ol>
      <p class="note">Each code works once. If yours doesn't work, write to gabriel@getgothere.app and we'll sort it out.</p>
    </div>
    <p class="note">We never ask for your gender identity, disability or military status. GoThere gives general information, not legal advice.</p>
  </main>
</body>
</html>
"""


def write(cfg=None):
    api = ROOT / "api" / "help.json"
    api.write_text(json.dumps(feed(cfg), ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    pages = []
    for org in live_orgs(cfg):
        if org.get("partner_page"):
            out = ROOT / "p" / org["id"] / "index.html"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(page(org), encoding="utf-8", newline="\n")
            pages.append(out)
    return api, pages


if __name__ == "__main__":
    api, pages = write()
    print(f"api/help.json written, {len(feed()['orgs'])} live org(s); {len(pages)} partner page(s)")
    for p in pages:
        print(" ", p.relative_to(ROOT))
