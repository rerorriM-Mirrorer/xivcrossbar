"""Build a complete, committed runtime and conversation handoff; never ship data."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
stem, published = sys.argv[2:4]
assert re.fullmatch(r'[A-Za-z0-9_-]+', stem)
assert re.fullmatch(r'[0-9a-f]{40}', published)

def git(*args):
    return subprocess.check_output(['git', *args], cwd=root)

assert not git('status', '--porcelain').strip(), 'Commit before packaging'
commit = git('rev-parse', 'HEAD').decode().strip()
tree = git('rev-parse', 'HEAD^{tree}').decode().strip()
branch = git('branch', '--show-current').decode().strip()
handoff = 'HANDOFF-PERSONAL-RC3.md' if branch == 'personal/ps5extended' else 'HANDOFF-PUBLIC-RC3.md'
assert branch in ('personal/ps5extended', 'public/rc3-maintenance')
header = ('Complete installation; branch: ' + branch + '\nLocal source commit: ' + commit +
          '\nPublished source commit: ' + published + '\nGit tree: ' + tree + '\n\n').encode()

def include(path):
    if path.startswith(('.', 'data/', 'tests/', 'packaging/')):
        return False
    if path in ('TESTING.md', 'WORKFLOW.md'):
        return False
    if path.startswith(('images/', 'themes/')):
        return True
    if path.startswith('docs/'):
        return path in ('docs/' + handoff, 'docs/BRANCH-MAP.md')
    if path.startswith('tools/'):
        return branch == 'personal/ps5extended' and path.startswith('tools/keyprobe/')
    return path.endswith(('.lua', '.ahk', '.bat')) or path in (
        'README.md', 'PERSONAL.md', 'COLOR-SETTINGS.md', 'LICENSE', 'NOTICE')

entries = {
    'TESTING.md': header + (root / 'TESTING.md').read_bytes(),
    'WORKFLOW.md': (root / 'WORKFLOW.md').read_bytes(),
}
for path in git('ls-files').decode().splitlines():
    if include(path):
        entries['xivcrossbar/' + path] = (root / path).read_bytes()

# User state is always absent, including generated controller launch/lease files.
assert not any('/data/' in path or path.lower().endswith(('.xml', '.ini', '.log', '.bak', '.active'))
               for path in entries)
assert not any('/tests/' in path or '/packaging/' in path for path in entries)
required = ['xivcrossbar.lua', 'ffxi_directinput.ahk', 'ui/resources.lua',
            'images/icons/iconpacks/default/icon_list.txt', 'images/assets/menu/L2.png',
            'images/assets/menu/R2.png', 'images/setup/gamepad-directinput.jpg',
            'images/setup/ffxi-ijkl-targeting.png', 'themes/ffxiv/notice.png',
            'LICENSE', 'NOTICE', 'docs/' + handoff, 'docs/BRANCH-MAP.md']
wrapper = (root / 'ffxi_directinput.ahk').read_text()
for name in re.findall(r'^#Include %A_ScriptDir%\\(.+)$', wrapper, re.M):
    required.append(name.replace('\\', '/'))
for path in required:
    assert 'xivcrossbar/' + path in entries, 'Missing required runtime/asset: ' + path

if branch == 'public/rc3-maintenance':
    assert not any('personal_controls' in path or 'movement_signal' in path or '/tools/' in path
                   for path in entries)
    assert 'ps5-extended' not in (root / 'libs/controller/profiles.lua').read_text()
else:
    assert 'xivcrossbar/movement_signal.ahk' in entries

out.mkdir(parents=True, exist_ok=True)
archive = out / (stem + '-Complete.zip')
assert not archive.exists(), 'Refuse to overwrite a delivered package'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for path, raw in entries.items():
        z.writestr(path, raw)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len(z.namelist()) == len(entries)
    for path, raw in entries.items():
        assert z.read(path) == raw, path

standalone = out / (stem + '-Handoff.md')
standalone.write_bytes(header + (root / 'docs' / handoff).read_bytes())
map_copy = out / (stem + '-Branch-Map.md')
map_copy.write_bytes(header + (root / 'docs/BRANCH-MAP.md').read_bytes())
audit = {'branch': branch, 'local_commit': commit, 'published_commit': published,
         'tree': tree, 'archive': archive.name, 'files':
         {path: hashlib.sha256(raw).hexdigest() for path, raw in entries.items()}}
(out / (stem + '-audit.json')).write_text(json.dumps(audit, indent=2))
print(json.dumps({'archive': str(archive), 'bytes': archive.stat().st_size,
                  'entries': len(entries), 'handoff': str(standalone),
                  'branch_map': str(map_copy), 'commit': commit}))
