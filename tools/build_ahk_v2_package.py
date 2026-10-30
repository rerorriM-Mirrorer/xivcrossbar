"""Reproducible personal v2 code/docs overlay plus separate v1 rollback.

No userdata/config/images. Each payload is bound to committed git bytes.
"""
from pathlib import Path
import hashlib, json, subprocess, sys
from zipfile import ZipFile, ZIP_DEFLATED
root = Path(__file__).resolve().parents[1]
base = 'ed86e5f36c435273b62332278ed08fcb82c2f27f'
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=True)
def git(*args):
    return subprocess.check_output(['git', *args], cwd=root)
head = git('rev-parse','HEAD').decode().strip()
assert not git('status','--porcelain').strip(), 'Commit all source changes first'
def payload(ref, modern):
    names = git('ls-tree','-r','--name-only',ref).decode().splitlines()
    picked = []
    for p in names:
        runtime = p == 'xivcrossbar.lua' or p.startswith(('libs/','ui/')) and p.endswith('.lua')
        ahk = '/' not in p and p.endswith('.ahk')
        docs = p in ('README.md','WORKFLOW.md','TESTING.md','PERSONAL.md','COLOR-SETTINGS.md','LICENSE','LICENSE.md','LICENSE.txt')
        current = modern and (p.startswith('docs/AHK-V2-') or p.startswith('tests/') and p.endswith(('.ahk','.ps1','.js','.py','.lua')) or p in ('launch-controller.cmd','launch-controller.ps1','tools/keyprobe/keyboard_probe.ahk','tools/keyprobe/README.md'))
        if runtime or ahk or docs or current:
            assert not p.startswith(('data/','images/','themes/')) and not p.endswith('.ini')
            picked.append(p)
    return {p:git('show', ref+':'+p) for p in picked}
def archive(name, ref, files):
    path=out/name
    manifest={'source_commit':ref,'base_checkpoint':base,'files':{p:hashlib.sha256(b).hexdigest() for p,b in files.items()}}
    with ZipFile(path,'w',ZIP_DEFLATED) as z:
        for p,b in files.items():z.writestr('xivcrossbar/'+p,b)
        z.writestr('xivcrossbar/PACKAGE-MANIFEST.json',json.dumps(manifest,indent=2)+'\n')
    with ZipFile(path) as z:
        assert z.testzip() is None
        for p,b in files.items(): assert z.read('xivcrossbar/'+p)==b
        for p in ('README.md','WORKFLOW.md','TESTING.md'): assert 'xivcrossbar/'+p in z.namelist()
    return path
v2=archive('XIVCrossbar-AHKv2-Test1.zip',head,payload(head,True))
v1=archive('XIVCrossbar-v1-Rollback-ed86e5f.zip',base,payload(base,False))
bundle=out/'XIVCrossbar-AHKv2-Test1-WithRollback.zip'
with ZipFile(bundle,'w',ZIP_DEFLATED) as z:
    z.write(v2,v2.name)
    z.write(v1,v1.name)
    z.writestr('INSTALL-FIRST.txt','Extract the AHKv2 Test1 ZIP and overlay its xivcrossbar folder only after stopping the wrapper and unloading all clients. Read xivcrossbar/docs/AHK-V2-MIGRATION.md first. The v1 ZIP is a separate rollback, never an additional active runtime. Preserve your complete currently working installation before testing.\nSource: '+head+'\n')
print(json.dumps({'bundle':str(bundle),'source_commit':head,'sha256':hashlib.sha256(bundle.read_bytes()).hexdigest(),'bytes':bundle.stat().st_size}))
