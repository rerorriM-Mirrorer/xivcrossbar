"""Build one non-nested kit from committed source; no user data or runtime bundled."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

p = argparse.ArgumentParser()
p.add_argument('--revision', default='HEAD')
p.add_argument('--published', required=True)
p.add_argument('--output', required=True)
a = p.parse_args()
repo = Path(__file__).resolve().parents[1]

def git(*args):
    return subprocess.check_output(['git', *args], cwd=repo)

def source(path):
    return git('show', a.revision + ':' + path)

baseline = '28304f405e7824e1b7dbc5f9e20378985007ea84'
assert not git('diff', '--name-only', '--diff-filter=D', baseline, a.revision).strip()
changed = git('diff', '--name-only', baseline, a.revision).decode().splitlines()
paths = sorted({name for name in changed if not name.startswith(
    ('tests/', 'packaging/', 'examples/', 'data/', 'images/', 'tools/windower_patch/'))
    and Path(name).suffix in ('.lua', '.ahk', '.md')} | {'README.md', 'WORKFLOW.md', 'TESTING.md'})
paths.remove('TESTING.md'); paths.insert(0, 'TESTING.md')
payload = {name: source(name) for name in paths}
version = re.search(rb"_addon.version = '([^']+)'", payload['xivcrossbar.lua'])[1].decode()
tree = git('rev-parse', a.revision + '^{tree}').decode().strip()
payload['PATCH-INFO.txt'] = f'''XIVcrossbar Installer 1 cumulative bootstrap — A — October 24, 2026
Runtime: {version} / Controls 9.19-lifecycle1
Published development/directlink source: {a.published}
Tree: {tree}
Baseline: {baseline} (Cleanup 1)
Code/docs only; no userdata/artwork. Includes earlier cumulative fixes.
Apply through WindowerPatch.cmd in the Windower root. First use requires manual
XB unload; subsequent installs can coordinate it. Reload clients yourself.
Core PowerShell integration exercised under PowerShell 7.4.6/Linux, 71 Lua
suites / 160 parsed sources and 8 JS controller suites passed. Native Windows
PowerShell 5.1, CMD/file picker and Windower handoff acceptance pending.
See docs/INSTALLER-TEST.md and TESTING.md.
'''.encode()
manifest = {'schema': 1, 'addon': 'xivcrossbar', 'version': version,
            'source_commit': a.published, 'tree': tree,
            'files': [{'path': name, 'sha256': hashlib.sha256(raw).hexdigest()}
                      for name, raw in payload.items()]}
members = {name: source('tools/windower_patch/' + name)
           for name in ('WindowerPatch.cmd', 'WindowerPatch.ps1')}
members['INSTALLER-README.md'] = source('tools/windower_patch/README.md')
prefix = 'WindowerPatchSupport/bootstrap/'
members[prefix + 'windower-patch.json'] = json.dumps(manifest, indent=2).encode()
members.update({prefix + 'xivcrossbar/' + name: raw for name, raw in payload.items()})
artifact = Path(a.output).resolve()
artifact.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(artifact, 'w', zipfile.ZIP_DEFLATED) as z:
    for name, raw in members.items():
        z.writestr(name, raw)
with zipfile.ZipFile(artifact) as z:
    assert z.testzip() is None
    assert len(z.namelist()) == len(members)
    for name, raw in members.items():
        assert z.read(name) == raw
    assert not any(name.lower().endswith('.zip') for name in z.namelist())
    assert not any('/xivcrossbar/data/' in name or '/xivcrossbar/images/' in name for name in z.namelist())
print(json.dumps({'path': str(artifact), 'bytes': artifact.stat().st_size,
                  'payload_files': len(payload), 'sha256': hashlib.sha256(artifact.read_bytes()).hexdigest(),
                  'published': a.published, 'tree': tree}))
