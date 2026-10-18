"""Build an audited, self-contained DirectLink test ZIP from a published tree.

The local commit hash may differ from GitHub's API-created commit hash. Require
the *tree* SHA to match the independently inspected published branch exactly.
Never archive installed personal state, test fixtures, or illustrative XML.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
PUBLISHED_RE = re.compile(r"[0-9a-f]{40}\Z")
EXCLUDED_DIRS = {"data", "tests", "packaging", "examples", "upload"}
ALLOWED_SUFFIXES = {".lua", ".ahk", ".bat", ".png", ".jpg", ".jpeg", ".md", ".txt", ".json"}
ALLOWED_BARE = {"LICENSE", "NOTICE"}
REQUIRED = {
    "xivcrossbar.lua", "ffxi_directinput.ahk", "personal_controls.ahk",
    "controller_messages.ahk", "controller_clients.ahk", "movement_signal.ahk",
    "controller_messages.lua", "personal_controls.lua", "l1_bank.lua",
    "companion_banks.lua", "companion_keys.lua", "companion_output.lua",
    "l1_transport.lua", "l1_view.lua", "ui/text_measure.lua",
    "images/setup/gamepad-directinput.jpg", "themes/ffxiv/frame.png",
    "README.md", "WORKFLOW.md", "TESTING.md", "AGENTS.md",
    "docs/LIVE-TEST-DIRECTLINK.md", "LICENSE", "NOTICE",
}


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT).decode().strip()


def should_include(name):
    p = Path(name)
    return (
        bool(p.parts)
        and p.parts[0] not in EXCLUDED_DIRS
        and not any(part.startswith(".") for part in p.parts)
        and (p.suffix.lower() in ALLOWED_SUFFIXES or name in ALLOWED_BARE)
    )


def build():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--published", required=True, help="Verified GitHub branch commit SHA")
    parser.add_argument("--published-tree", required=True, help="Verified GitHub commit tree SHA")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    assert PUBLISHED_RE.fullmatch(args.published), "Expected published commit SHA"
    assert PUBLISHED_RE.fullmatch(args.published_tree), "Expected published tree SHA"
    assert git("branch", "--show-current") == "development/directlink", "Wrong branch"
    assert not git("status", "--porcelain"), "Commit all changes before packaging"
    local_tree = git("rev-parse", "HEAD^{tree}")
    assert local_tree == args.published_tree, "Local tree differs from published source"
    output = args.output.resolve()
    assert not output.exists(), "Refuse to replace a previously delivered ZIP"

    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    files = sorted(name.decode() for name in tracked.split(b"\0") if name and should_include(name.decode()))
    assert REQUIRED.issubset(files), sorted(REQUIRED.difference(files))
    assert not any(name.lower().endswith((".xml", ".ini", ".log", ".bak", ".lease", ".buttons", ".l1")) for name in files)
    contents = {"xivcrossbar/" + name: (ROOT / name).read_bytes() for name in files}

    wrapper = (ROOT / "ffxi_directinput.ahk").read_text()
    for dependency in re.findall(r"^#Include %A_ScriptDir%\\(.+)$", wrapper, re.M):
        assert "xivcrossbar/" + dependency in contents, f"Missing AHK include {dependency}"

    version = re.search(r"_addon.version = '([^']+)'", (ROOT / "xivcrossbar.lua").read_text())
    assert version and version.group(1) == "0.4.0-a.20261018.directlink1-banks2"
    contents["xivcrossbar/PACKAGE-INFO.txt"] = (
        "XIVCrossbar DirectLink companion banks test 2 complete installation\n"
        "Branch: development/directlink\n"
        f"Published source commit: {args.published}\n"
        f"Verified source tree: {local_tree}\n"
        f"Runtime: {version.group(1)}\n"
        "AHK wrapper: Controls=9.9-banks\n"
        "Read docs/LIVE-TEST-DIRECTLINK.md before updating.\n"
        "No character data, custom bindings/settings or companion Trust addon included.\n"
        "Windows/FFXI live acceptance remains pending.\n"
    ).encode()

    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, content in sorted(contents.items()):
            entry = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            entry.external_attr = 0o644 << 16
            archive.writestr(entry, content, compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(output) as archive:
        assert archive.testzip() is None
        assert set(archive.namelist()) == set(contents)
        for name, content in contents.items():
            assert archive.read(name) == content, name

    audit = {
        "published_commit": args.published,
        "published_tree": args.published_tree,
        "runtime": version.group(1),
        "entry_count": len(contents),
        "archive_bytes": output.stat().st_size,
        "archive_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "entries": {name: hashlib.sha256(data).hexdigest() for name, data in sorted(contents.items())},
    }
    audit_path = output.with_suffix(".audit.json")
    assert not audit_path.exists(), "Refuse to overwrite audit"
    audit_path.write_text(json.dumps(audit, indent=2) + "\n")
    print(f"{output} | {len(contents)} entries | {output.stat().st_size} bytes | published {args.published}")


if __name__ == "__main__":
    build()
