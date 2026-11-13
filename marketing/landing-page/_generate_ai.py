#!/usr/bin/env python3
"""Generate /ai/: how to use GoThere's MCP server from Claude, ChatGPT, Cursor, VS Code.

The server itself lives at https://getgothere.app/mcp (eligibility-engine). This page is
the human-readable front door, linked from llms.txt. Tool list mirrors app/mcp/server.py.
"""
from _generate_move import SITE, esc, page

MCP = f"{SITE}/mcp"

TOOLS = [
    ("get_visa_options", "Residence visas for Americans moving to Spain, Portugal, Ireland, Italy or Mexico: income needed, fees, processing time, years to residency and citizenship."),
    ("get_move_checklist", "Step by step checklist for one visa, with fees and any recent rule changes."),
    ("get_rule_changes", "Verified changes to visa rules, newest first, each with the old and new value."),
    ("check_descent_eligibility", "Whether a parent or grandparent gives you Irish or Canadian citizenship by descent."),
    ("get_pathway_requirements", "Documents, cost and timing for the Irish and Canadian descent routes."),
    ("list_pathways", "Which citizenship by descent routes are covered, and which are planned."),
]

PROMPTS = [
    "How much income do I need for Portugal's D7 visa?",
    "Walk me through applying for Spain's digital nomad visa.",
    "What changed recently in Portugal's visa rules?",
    "My grandmother was born in Cork. Can I get an Irish passport?",
]

CLIENTS = [
    ("Claude", "<ol><li>In Claude (web or desktop), open <strong>Settings</strong>, then <strong>Connectors</strong>.</li>"
               "<li>Choose <strong>Add custom connector</strong>, name it GoThere, and paste the server address.</li>"
               "<li>No sign in needed. Custom connectors depend on your Claude plan.</li></ol>"),
    ("Claude Code", f"<pre><code>claude mcp add --transport http gothere {MCP}</code></pre>"),
    ("Cursor", "<p>Add to <code>~/.cursor/mcp.json</code>:</p>"
               f'<pre><code>{esc(chr(123))}\n  "mcpServers": {{\n    "gothere": {{ "url": "{MCP}" }}\n  }}\n}}</code></pre>'),
    ("VS Code", "<p>Add to <code>.vscode/mcp.json</code>:</p>"
                f'<pre><code>{esc(chr(123))}\n  "servers": {{\n    "gothere": {{ "type": "http", "url": "{MCP}" }}\n  }}\n}}</code></pre>'),
    ("ChatGPT", "<p>A listing in the ChatGPT app directory is on the way. If your ChatGPT plan includes developer mode, "
                "you can already add the server address as a custom connector there.</p>"),
]

CSS_EXTRA = """
    <style>
    .mcp-url { display:flex; gap:8px; align-items:center; flex-wrap:wrap; background:var(--bg-card); border:1px solid var(--border); border-left:3px solid var(--teal); border-radius:8px; padding:14px 18px; margin:12px 0 24px; }
    .mcp-url code { font-size:16px; word-break:break-all; }
    .mcp-url button { padding:8px 14px; border-radius:8px; border:0; background:var(--teal); color:#0B0F14; font-weight:600; cursor:pointer; }
    pre { background:var(--bg-card); border:1px solid var(--border); border-radius:8px; padding:12px 14px; overflow-x:auto; font-size:13px; }
    .client { margin:18px 0; } .client h3 { margin:0 0 6px; }
    ul.tools li { margin:8px 0; } ul.tools code { color:var(--teal); }
    </style>
"""


def build():
    body = '    <div class="breadcrumb"><a href="/">Home</a> &rsaquo; Use GoThere in AI assistants</div>\n'
    body += CSS_EXTRA
    body += "    <h1>Use GoThere in Claude, ChatGPT and other AI assistants</h1>\n"
    body += ('    <p class="lede">GoThere runs an MCP server, so your AI assistant can look up visa '
             "requirements, move checklists, recent rule changes and citizenship by descent answers "
             "from the same verified data as this site. Every figure comes with its official source "
             "and the date it was checked.</p>\n")
    body += (f'    <div class="mcp-url"><span>Server address:</span> <code id="mcp">{MCP}</code> '
             '<button type="button" onclick="navigator.clipboard.writeText(document.getElementById(\'mcp\').textContent);'
             'this.textContent=\'Copied\'">Copy</button></div>\n')
    body += "    <h2>Set it up</h2>\n"
    for name, html in CLIENTS:
        body += f'    <div class="client"><h3>{esc(name)}</h3>{html}</div>\n'
    body += "    <h2>What it can answer</h2>\n    <ul class=\"tools\">\n"
    body += "".join(f"      <li><code>{esc(t)}</code>: {esc(d)}</li>\n" for t, d in TOOLS)
    body += "    </ul>\n    <h2>Try asking</h2>\n    <ul>\n"
    body += "".join(f"      <li>&ldquo;{esc(p)}&rdquo;</li>\n" for p in PROMPTS)
    body += "    </ul>\n"
    body += ("    <h2>Privacy and limits</h2>\n    <ul>\n"
             "      <li>No account or sign in. Nothing you ask is stored.</li>\n"
             "      <li>Answers come from fixed rules and sourced data, not from a model guessing, and the server says so plainly when a country is not covered.</li>\n"
             "      <li>Research, not legal advice. Confirm with the consulate or a qualified lawyer before you file.</li>\n"
             f'      <li>Also listed in the <a href="https://registry.modelcontextprotocol.io/v0/servers?search=app.getgothere" rel="nofollow noopener">official MCP Registry</a> as <code>app.getgothere/citizenship</code>.</li>\n'
             "    </ul>\n")
    schema = [{"@context": "https://schema.org", "@type": "WebPage",
               "name": "Use GoThere in Claude, ChatGPT and other AI assistants",
               "url": SITE + "/ai/", "about": "GoThere MCP server for visa and citizenship by descent answers"}]
    page("/ai/", "Use GoThere in Claude, ChatGPT & AI Assistants (MCP)",
         "Add GoThere's MCP server to Claude, ChatGPT, Cursor or VS Code for sourced visa requirements, "
         "move checklists, rule changes and citizenship by descent checks.",
         body, schema, campaign="ai_setup")


if __name__ == "__main__":
    build()
