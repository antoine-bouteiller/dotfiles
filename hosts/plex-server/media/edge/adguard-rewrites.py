"""Keep AdGuard Home's local DNS rewrites pointed at the Tailscale IP.

check YAML DESIRED IP DOMAIN...
    Root-side, from the reconcile timer. Reads YAML only. Exit 0 when the
    rewrites already match, 1 after publishing DESIRED (the restart handoff),
    2 on read/parse/validation error.
apply DESIRED YAML
    From AdGuard's pre-start hook, after upstream settings generation and while
    the daemon is stopped. Rewrites YAML atomically; a missing DESIRED is a no-op.
"""

import ipaddress
import json
import os
import sys
import tempfile

import yaml

REWRITE_KEYS = ("rewrites", "rewrites_enabled")


def managed_rewrites(ip, domains):
    return [{"domain": d, "answer": ip, "enabled": True} for d in domains]


def validate(ip, domains):
    ipaddress.IPv4Address(ip)
    if not isinstance(domains, list) or not all(isinstance(d, str) and d for d in domains):
        raise ValueError("domains must be a list of non-empty strings")


def load_yaml(path):
    with open(path) as f:
        config = yaml.safe_load(f)
    if config is None:
        config = {}
    if not isinstance(config, dict):
        raise ValueError(f"{path}: top level is not a mapping")
    return config


def up_to_date(config, ip, domains):
    filtering = config.get("filtering") or {}
    return filtering.get("rewrites") == managed_rewrites(ip, domains) and filtering.get(
        "rewrites_enabled", True
    )


def write_atomic(path, mode, render):
    """Write via a same-directory temp file so a failure leaves `path` intact."""
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or ".", prefix=".rewrites-")
    try:
        with os.fdopen(fd, "w") as f:
            render(f)
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        os.unlink(tmp)
        raise


def check(yaml_path, desired_path, ip, *domains):
    domains = list(domains)
    try:
        validate(ip, domains)
        if not os.path.exists(yaml_path):
            print(f"{yaml_path} does not exist yet; nothing to reconcile")
            return 0
        if up_to_date(load_yaml(yaml_path), ip, domains):
            return 0
        write_atomic(
            desired_path, 0o644, lambda f: json.dump({"ip": ip, "domains": domains}, f)
        )
    except Exception as e:  # noqa: BLE001 - any failure is "retry next tick"
        print(f"check failed: {e}", file=sys.stderr)
        return 2
    print(f"rewrites differ; published {desired_path} for {ip}")
    return 1


def apply(desired_path, yaml_path):
    if not os.path.exists(desired_path):
        return 0
    with open(desired_path) as f:
        desired = json.load(f)
    ip, domains = desired["ip"], desired["domains"]
    validate(ip, domains)
    config = load_yaml(yaml_path)
    if up_to_date(config, ip, domains):
        return 0
    filtering = config.setdefault("filtering", {})
    filtering["rewrites_enabled"] = True
    filtering["rewrites"] = managed_rewrites(ip, domains)
    write_atomic(yaml_path, 0o600, lambda f: yaml.safe_dump(config, f, sort_keys=False))
    print(f"applied {len(domains)} rewrites -> {ip}")
    return 0


if __name__ == "__main__":
    commands = {"check": check, "apply": apply}
    if len(sys.argv) < 2 or sys.argv[1] not in commands:
        sys.exit(__doc__)
    sys.exit(commands[sys.argv[1]](*sys.argv[2:]))
