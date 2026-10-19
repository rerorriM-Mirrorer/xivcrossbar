"""Audit canonical dependencies and byte-preserving asset relocation."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--baseline', help='Optional local git checkpoint before the cleanup')
args = parser.parse_args()
external = {'actions', 'chat', 'config', 'files', 'images', 'io', 'lists', 'luau',
            'math', 'pack', 'resources', 'sets', 'socket', 'string', 'strings',
            'tables', 'texts', 'resources/crossbar_abilities', 'resources/crossbar_spells'}
sources = [root / 'xivcrossbar.lua', *root.joinpath('libs').rglob('*.lua'), *root.joinpath('ui').rglob('*.lua')]
for path in sources:
    for name in re.findall(r'''require\s*\(?['"]([^'"]+)''', path.read_text()):
        assert name in external or (root / (name + '.lua')).is_file(), (path, name)
assert {p.name for p in root.glob('*.lua')} == {'xivcrossbar.lua'}
manifest = json.loads(root.joinpath('tools/layout_legacy.json').read_text())
for entry in manifest:
    assert (root / entry['new']).is_file(), entry
    assert not (root / entry['old']).exists(), entry
assert "Replace('\\', '/')" in root.joinpath('tools/Finish-Cleanup.ps1').read_text()
assert 'Remove-Item -Recurse' not in root.joinpath('tools/Finish-Cleanup.ps1').read_text()
assert 'data/settings.xml' not in root.joinpath('tools/Finish-Cleanup.ps1').read_text()
if args.baseline:
    listing = subprocess.check_output(['git', 'ls-tree', '-rz', args.baseline], cwd=root)
    count = 0
    for record in listing.split(b'\0'):
        if not record:
            continue
        meta, raw_path = record.split(b'\t', 1)
        old = raw_path.decode()
        if not old.lower().endswith(('.png', '.jpg', '.jpeg')):
            continue
        new = re.sub(r'^themes/', 'images/themes/', old)
        new = new.replace('images/icons/iconpacks/', 'images/icons/')
        new = re.sub(r'^images/icons/(abilities|spells|weapons|elements|skillchain)/', r'images/icons/default/fallback/\1/', new)
        data = root.joinpath(new).read_bytes()
        sha = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
        assert sha == meta.decode().split()[2], (old, new)
        count += 1
    print(f'{count} shipped image files match the baseline byte-for-byte at their canonical paths.')
print('Canonical Lua dependencies, retired root modules, cleanup manifest and conservative helper structure passed.')
