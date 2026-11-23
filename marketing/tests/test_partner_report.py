"""partner_report.py builds valid-looking HogQL and never needs the key in --dry-run."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import partner_report  # noqa: E402


def test_queries_scope_site_and_window():
    qs = partner_report.queries(7)
    assert len(qs) == 5
    for _, sql in qs.values():
        assert "INTERVAL 7 DAY" in sql and "'getgothere.app'" in sql


def test_partner_hosts_come_from_config():
    hosts = partner_report.partner_hosts()
    assert "genki.world" in hosts and "feather-insurance.com" in hosts


def test_dry_run_needs_no_key(monkeypatch, capsys):
    monkeypatch.delenv("POSTHOG_KEY", raising=False)
    monkeypatch.setattr(partner_report, "KEY_FILE", Path("does-not-exist"))
    assert partner_report.main(["--dry-run", "--days", "7"]) == 0
    out = capsys.readouterr().out
    assert "partner_click" in out and "phx_" not in out
