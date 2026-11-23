#!/usr/bin/env python3
"""Bring each formula in Formula/ to its tool's latest published version.

Usage: python3 scripts/bump.py [--check]
Prints one line per formula and, last, "CHANGED: <names>" (space separated, may be empty).
--check changes nothing and exits 1 when a formula is behind.

Safety rules, because a formula is code that runs on other people's Macs:
- A version is accepted only when it is plain digits and dots, and only when it is newer than the one in the file.
- A download address is built here from a fixed pattern, or checked against one. Nothing a registry returns is
  written into a formula except that version and a SHA-256 this script computed from the bytes it downloaded.
- A Python tool that gains dependencies stops the run: its formula would need a resource block per dependency.
"""
import hashlib
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSION = re.compile(r"^\d+(\.\d+){1,3}$")
MAX_BYTES = 100 * 1024 * 1024

# name -> (kind, source name). kind decides where the latest version and the archive come from.
FORMULAE = {
    "onionskin": ("npm", "onionskin-cli"),
    "hotin": ("pypi", "hotin"),
    "realstop": ("pypi", "realstop"),
    "nhc-pp-cli": ("github-tag", "abe238/nhc-pp-cli"),
    "shelters-pp-cli": ("github-tag", "abe238/shelters-pp-cli"),
}


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "homebrew-tap-bump", "Accept": "application/json, */*"})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise SystemExit(f"FAILED: {url} is larger than {MAX_BYTES} bytes")
    return data


def key(v):
    return tuple(int(p) for p in v.split("."))


def checked(v, where):
    if not isinstance(v, str) or not VERSION.match(v):
        raise SystemExit(f"FAILED: {where} gave a version this script does not accept: {v!r}")
    return v


def latest(kind, src):
    """-> (version, archive url)"""
    if kind == "npm":
        v = checked(json.loads(get(f"https://registry.npmjs.org/{src}/latest"))["version"], f"npm {src}")
        return v, f"https://registry.npmjs.org/{src}/-/{src}-{v}.tgz"
    if kind == "pypi":
        d = json.loads(get(f"https://pypi.org/pypi/{src}/json"))
        v = checked(d["info"]["version"], f"PyPI {src}")
        if d["info"].get("requires_dist"):
            raise SystemExit(f"FAILED: {src} {v} now has dependencies ({d['info']['requires_dist']}); its formula needs resource blocks, written by hand")
        want = re.compile(r"^https://files\.pythonhosted\.org/packages/[0-9a-f]{2}/[0-9a-f]{2}/[0-9a-f]{60}/" + re.escape(f"{src}-{v}.tar.gz") + "$")
        urls = [u["url"] for u in d["urls"] if u.get("packagetype") == "sdist" and want.match(u.get("url", ""))]
        if len(urls) != 1:
            raise SystemExit(f"FAILED: PyPI {src} {v} does not have exactly one source archive at the expected address")
        return v, urls[0]
    if kind == "github-tag":
        tags = json.loads(get(f"https://api.github.com/repos/{src}/tags?per_page=100"))
        versions = [t["name"][1:] for t in tags if isinstance(t.get("name"), str) and re.match(r"^v\d+\.\d+\.\d+$", t["name"])]
        if not versions:
            raise SystemExit(f"FAILED: {src} has no vX.Y.Z tag")
        v = checked(max(versions, key=key), f"GitHub {src}")
        return v, f"https://github.com/{src}/archive/refs/tags/v{v}.tar.gz"
    raise SystemExit(f"FAILED: unknown kind {kind}")


def current(text, name):
    m = re.search(r'^  url "([^"]+)"$', text, re.M)
    s = re.search(r'^  sha256 "([0-9a-f]{64})"$', text, re.M)
    if not m or not s:
        raise SystemExit(f"FAILED: Formula/{name}.rb has no plain url and sha256 lines")
    v = re.search(r"(\d+(?:\.\d+){1,3})(?:\.tgz|\.tar\.gz)$", m.group(1))
    if not v:
        raise SystemExit(f"FAILED: cannot read the version from the url in Formula/{name}.rb")
    return v.group(1), m.group(1), s.group(1)


def main():
    check = "--check" in sys.argv[1:]
    changed = []
    for name, (kind, src) in FORMULAE.items():
        path = ROOT / "Formula" / f"{name}.rb"
        text = path.read_text()
        have, have_url, have_sha = current(text, name)
        new, url = latest(kind, src)
        if key(new) <= key(have):
            print(f"{name}: {have} is current (latest published: {new})")
            continue
        sha = hashlib.sha256(get(url)).hexdigest()
        print(f"{name}: {have} -> {new}")
        changed.append(name)
        if check:
            continue
        text = text.replace(f'  url "{have_url}"', f'  url "{url}"', 1).replace(f'  sha256 "{have_sha}"', f'  sha256 "{sha}"', 1)
        path.write_text(text)
    print("CHANGED: " + " ".join(changed))
    return 1 if (check and changed) else 0


if __name__ == "__main__":
    sys.exit(main())
