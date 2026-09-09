"""AdGuard rewrite lifecycle regressions (AC-005).

Run with the pinned PyYAML interpreter:
  nix shell --impure --expr 'let f = builtins.getFlake (toString ./.);
    p = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
    in p.python3.withPackages (ps: [ps.pyyaml])' -c python3 tests/review-fixes-adguard.py

Covers the actual helper in temp dirs, the evaluated plex-server unit options, and
(on Linux only) the actual evaluated reconciler script with mocked tailscale/systemctl.
"""

import json
import os
import platform
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
HELPER = ROOT / "hosts/plex-server/media/edge/adguard-rewrites.py"
IP, DOMAINS = "100.64.0.7", ["a.example", "b.example"]
EVAL_EXPR = """
let
  s = (builtins.getFlake (toString ./.)).nixosConfigurations.plex-server.config.systemd;
  r = s.services.adguardhome-tailscale-rewrites;
in {
  timer = { inherit (s.timers.adguardhome-tailscale-rewrites) wantedBy timerConfig; };
  reconciler = { inherit (r) before after wants requires wantedBy script serviceConfig environment; };
  adguard = {
    inherit (s.services.adguardhome) preStart;
    inherit (s.services.adguardhome.serviceConfig) DynamicUser RestrictAddressFamilies;
  };
  tmpfiles = s.tmpfiles.rules;
}
"""


def rewrites(ip, domains):
    return [{"domain": d, "answer": ip, "enabled": True} for d in domains]


def helper(*args):
    return subprocess.run(
        [sys.executable, str(HELPER), *map(str, args)], capture_output=True, text=True
    )


class HelperTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.yaml = self.tmp / "AdGuardHome.yaml"
        self.desired = self.tmp / "desired.json"
        self.base = {"bind_host": "127.0.0.1", "users": [{"name": "x"}], "filtering": {"blocked_services": ["y"]}}

    def tearDown(self):
        os.chmod(self.tmp, 0o700)
        subprocess.run(["rm", "-rf", self.tmp])

    def write_yaml(self, config):
        self.yaml.write_text(yaml.safe_dump(config, sort_keys=False))
        return self.yaml.read_bytes()

    def check(self, ip=IP, domains=DOMAINS):
        return helper("check", self.yaml, self.desired, ip, *domains)

    def assertNoStray(self):
        self.assertEqual([p.name for p in self.tmp.iterdir() if p.name.startswith(".")], [])

    def test_check_missing_yaml_does_nothing(self):
        self.assertEqual(self.check().returncode, 0)
        self.assertFalse(self.desired.exists())

    def test_check_fresh_yaml_publishes(self):
        before = self.write_yaml(self.base)
        r = self.check()
        self.assertEqual(r.returncode, 1, r.stderr)
        self.assertEqual(json.loads(self.desired.read_text()), {"ip": IP, "domains": DOMAINS})
        self.assertEqual(stat.S_IMODE(self.desired.stat().st_mode), 0o644)
        self.assertEqual(self.yaml.read_bytes(), before, "check must not write YAML")
        self.assertNoStray()

    def test_check_identical_is_noop(self):
        cfg = dict(self.base, filtering={"blocked_services": ["y"], "rewrites_enabled": True, "rewrites": rewrites(IP, DOMAINS)})
        self.write_yaml(cfg)
        self.assertEqual(self.check().returncode, 0)
        self.assertFalse(self.desired.exists())

    def test_check_changed_ip_or_domains(self):
        cfg = dict(self.base, filtering={"rewrites": rewrites("100.64.0.9", DOMAINS)})
        self.write_yaml(cfg)
        self.assertEqual(self.check().returncode, 1)
        self.write_yaml(dict(self.base, filtering={"rewrites": rewrites(IP, DOMAINS[:1])}))
        self.assertEqual(self.check().returncode, 1)
        self.write_yaml(dict(self.base, filtering={"rewrites": rewrites(IP, DOMAINS), "rewrites_enabled": False}))
        self.assertEqual(self.check().returncode, 1)

    def test_check_errors(self):
        self.yaml.write_text("filtering: [unclosed")
        self.assertEqual(self.check().returncode, 2)
        self.write_yaml(self.base)
        self.assertEqual(self.check(ip="not-an-ip").returncode, 2)
        self.assertEqual(self.check(domains=[]).returncode, 1, "no domains is a valid empty list")
        self.assertFalse((self.tmp / "nope").exists())

    def test_apply_missing_desired_is_noop(self):
        before = self.write_yaml(self.base)
        self.assertEqual(helper("apply", self.desired, self.yaml).returncode, 0)
        self.assertEqual(self.yaml.read_bytes(), before)

    def test_apply_updates_then_check_is_quiet(self):
        self.write_yaml(self.base)
        self.assertEqual(self.check().returncode, 1)
        r = helper("apply", self.desired, self.yaml)
        self.assertEqual(r.returncode, 0, r.stderr)
        cfg = yaml.safe_load(self.yaml.read_text())
        self.assertEqual(cfg["users"], [{"name": "x"}])
        self.assertEqual(cfg["filtering"]["blocked_services"], ["y"])
        self.assertEqual(cfg["filtering"]["rewrites"], rewrites(IP, DOMAINS))
        self.assertTrue(cfg["filtering"]["rewrites_enabled"])
        self.assertEqual(stat.S_IMODE(self.yaml.stat().st_mode), 0o600)
        self.assertNoStray()
        self.assertEqual(self.check().returncode, 0, "converged: no further restart")
        # Idempotent re-apply on the next pre-start leaves the file untouched.
        before = self.yaml.read_bytes()
        self.assertEqual(helper("apply", self.desired, self.yaml).returncode, 0)
        self.assertEqual(self.yaml.read_bytes(), before)

    def test_apply_malformed_payload_preserves_yaml(self):
        before = self.write_yaml(self.base)
        for payload in ["{not json", json.dumps({"ip": "999.1.1.1", "domains": DOMAINS}), json.dumps({"ip": IP, "domains": "a"})]:
            self.desired.write_text(payload)
            self.assertNotEqual(helper("apply", self.desired, self.yaml).returncode, 0)
            self.assertEqual(self.yaml.read_bytes(), before)
        self.assertNoStray()

    @unittest.skipIf(os.geteuid() == 0, "root bypasses directory permissions")
    def test_apply_failed_replace_preserves_yaml(self):
        before = self.write_yaml(self.base)
        self.desired.write_text(json.dumps({"ip": IP, "domains": DOMAINS}))
        os.chmod(self.tmp, 0o500)
        try:
            self.assertNotEqual(helper("apply", self.desired, self.yaml).returncode, 0)
            self.assertEqual(self.yaml.read_bytes(), before)
        finally:
            os.chmod(self.tmp, 0o700)
        self.assertNoStray()


class EvaluatedConfigTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        out = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", EVAL_EXPR], cwd=ROOT, capture_output=True, text=True
        )
        assert out.returncode == 0, out.stderr
        cls.cfg = json.loads(out.stdout)

    def test_timer_is_bounded_and_independent_of_adguard(self):
        t = self.cfg["timer"]
        self.assertEqual(t["wantedBy"], ["timers.target"])
        self.assertEqual(t["timerConfig"], {"OnBootSec": "30s", "OnUnitInactiveSec": "1min"})
        r = self.cfg["reconciler"]
        self.assertEqual(r["wantedBy"], [])
        for rel in ("before", "after", "wants", "requires"):
            self.assertNotIn("adguardhome.service", r[rel])
        self.assertEqual(r["serviceConfig"]["Type"], "oneshot")
        self.assertEqual(r["serviceConfig"]["TimeoutStartSec"], "10s")
        self.assertNotIn("RemainAfterExit", r["serviceConfig"])

    def test_adguard_prestart_applies_after_upstream_generation_with_sandbox_intact(self):
        pre = self.cfg["adguard"]["preStart"]
        self.assertLess(pre.index("yaml-merge"), pre.index("adguard-rewrites.py apply"))
        self.assertIn("retaining working DNS configuration", pre)
        self.assertTrue(self.cfg["adguard"]["DynamicUser"])
        self.assertEqual(self.cfg["adguard"]["RestrictAddressFamilies"], ["AF_NETLINK", "AF_INET", "AF_INET6"])
        self.assertIn("d /run/adguardhome-tailscale-rewrites 0755 root root - -", self.cfg["tmpfiles"])

    def test_evaluated_reconciler_script(self):
        """Run the actual evaluated script with mocked tailscale/systemctl (Linux only)."""
        r = self.cfg["reconciler"]
        if platform.system() != "Linux" or not os.path.exists(r["environment"]["PATH"].split(":")[0]):
            print("\nUNVERIFIED: evaluated reconciler script needs Linux with the plex-server closure", file=sys.stderr)
            return
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            (tmp / "bin").mkdir()
            (tmp / "bin/tailscale").write_text('#!/bin/sh\n[ -n "$MOCK_IP" ] || exit 1\necho "$MOCK_IP"\n')
            (tmp / "bin/systemctl").write_text('#!/bin/sh\necho "$*" >> "$MOCK_LOG"\nexit "${MOCK_SYSTEMCTL_STATUS:-0}"\n')
            for b in (tmp / "bin").iterdir():
                b.chmod(0o755)
            log, yaml_path, desired = tmp / "systemctl.log", tmp / "AdGuardHome.yaml", tmp / "desired.json"
            env = dict(r["environment"], PATH=f"{tmp}/bin:{r['environment']['PATH']}", MOCK_LOG=str(log),
                       ADGUARD_YAML=str(yaml_path), REWRITES_DESIRED=str(desired), LOCAL_DNS_DOMAINS=" ".join(DOMAINS))

            def run(**extra):
                log.write_text("")
                return subprocess.run(["bash", "-c", r["script"]], env={**env, **extra}, capture_output=True, text=True)

            yaml_path.write_text("bind_host: 127.0.0.1\n")
            self.assertEqual(run(MOCK_IP="").returncode, 0)  # no Tailscale IP: no restart
            self.assertEqual(log.read_text(), "")
            self.assertEqual(run(MOCK_IP=IP).returncode, 0)  # changed: handoff + queued restart
            self.assertEqual(log.read_text(), "--no-block try-restart adguardhome.service\n")
            self.assertEqual(json.loads(desired.read_text()), {"ip": IP, "domains": DOMAINS})
            self.assertNotEqual(run(MOCK_IP=IP, MOCK_SYSTEMCTL_STATUS="1").returncode, 0)  # queue failure surfaces
            self.assertEqual(helper("apply", desired, yaml_path).returncode, 0)  # pre-start applies
            self.assertEqual(run(MOCK_IP=IP).returncode, 0)  # converged: no restart
            self.assertEqual(log.read_text(), "")
            yaml_path.write_text("filtering: [oops")
            self.assertEqual(run(MOCK_IP=IP).returncode, 2)  # error: logged, retried next tick
            self.assertEqual(log.read_text(), "")


if __name__ == "__main__":
    unittest.main()
