"""Build a complete test installation from an exact player-supplied snapshot.

Contributing author: A. Preserve all runtime settings, profiles and controller
files; replace only the explicitly consolidated Lua modules and README.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OVERLAY = (
    'action_binder.lua', 'ui/selectablelist.lua', 'defaults.lua', 'player.lua',
    'ui.lua', 'xivcrossbar.lua', 'ui_drag.lua', 'ui_visibility.lua', 'README.md',
)
EXPECTED_SNAPSHOT = 'd55bc5922c9ae82fd6c865dacf528bd8c04cfb408c2c33e00269dee9ef32b94d'


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def build(snapshot: Path, output: Path) -> dict:
    # The hash identifies the October 4 baseline; don't silently package a
    # different PC installation under this test's name/provenance.
    assert digest(snapshot.read_bytes()) == EXPECTED_SNAPSHOT, 'Wrong snapshot for this build'
    assert snapshot.resolve() != output.resolve(), 'Keep the original archive intact'
    original: dict[str, bytes] = {}
    metadata = {}
    directories = {}
    with zipfile.ZipFile(snapshot) as archive:
        for entry in archive.infolist():
            path = PurePosixPath(entry.filename)
            assert not path.is_absolute() and '..' not in path.parts, 'Unsafe archive path'
            assert path.parts and path.parts[0] == 'xivcrossbar', 'Unexpected archive root'
            assert (entry.external_attr >> 16) & 0o170000 != 0o120000, 'Archive symlink'
            if entry.is_dir():
                directories[entry.filename] = entry
                continue
            assert entry.filename not in original, 'Duplicate archive entry'
            original[entry.filename] = archive.read(entry)
            metadata[entry.filename] = entry
    files = dict(original)
    for relative in OVERLAY:
        files['xivcrossbar/' + relative] = (ROOT / relative).read_bytes()
    # These additions are documentation/development files, never inputs to the
    # automatic controller launch. Keep personal data out of the public repo.
    for folder in ('docs', 'tests', 'experiments', 'tools'):
        for path in sorted((ROOT / folder).rglob('*')):
            if path.is_file() and '__pycache__' not in path.parts:
                files['xivcrossbar/' + path.relative_to(ROOT).as_posix()] = path.read_bytes()
    for name in ('CHANGELOG.md',):
        files['xivcrossbar/' + name] = (ROOT / name).read_bytes()
    files['TEST-NOTES.md'] = (ROOT / 'docs/TESTING-2026-10-04.md').read_bytes()
    # This is the regression that matters for the capture: every untouched
    # byte, including each XML/INI/AHK/cache/image and backup, must survive.
    changed = [name for name in original if files[name] != original[name]]
    assert set(changed) <= {'xivcrossbar/' + p for p in OVERLAY}
    preserved = len(original) - len(changed)
    manifest = {
        'captured_date': '2026-10-04', 'timezone': 'America/Chicago',
        'build': '0.4.0-a.20261004.1', 'snapshot_sha256': EXPECTED_SNAPSHOT,
        'snapshot_files': len(original), 'preserved_snapshot_files': preserved,
        'changed_snapshot_files': changed,
        'files': [{'path': name, 'size': len(data), 'sha256': digest(data),
                   'snapshot_sha256': digest(original[name]) if name in original else None}
                  for name, data in sorted(files.items())],
    }
    files['PACKAGE-MANIFEST.json'] = (json.dumps(manifest, indent=2) + '\n').encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        for name, entry in sorted(directories.items()):
            archive.writestr(entry, b'')
        for name, data in sorted(files.items()):
            if name in metadata:
                archive.writestr(metadata[name], data)
            else:
                info = zipfile.ZipInfo(name, date_time=(2026, 10, 4, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o100644 << 16
                archive.writestr(info, data)
    # Read back the finished artifact, not a second staging tree: this catches
    # errors in archive construction rather than merely rechecking inputs.
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None, 'Corrupt output archive'
        assert set(archive.namelist()) == set(files) | set(directories)
        for name, data in files.items():
            assert archive.read(name) == data, name
    return {'output': str(output.resolve()), 'files': len(files),
            'preserved_snapshot_files': preserved, 'changed_snapshot_files': changed,
            'sha256': digest(output.read_bytes())}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(build(args.snapshot, args.output), indent=2))
