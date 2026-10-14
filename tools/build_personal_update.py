"""Build a cumulative code/docs overlay; exclude installed state and images."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED

root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]).resolve()
out.mkdir(parents=True,exist_ok=True)
base='personal2-complete-20261013'
rollback='personal4-pulse-test-20261013'
def git(*args):
    return subprocess.check_output(['git',*args],cwd=root)

changed=git('diff','--name-only',base,'HEAD').decode().splitlines()
docs={'README.md','PERSONAL.md','COLOR-SETTINGS.md','tools/keyprobe/README.md'}
files=[p for p in changed if not p.startswith('tests/') and
       (p in docs or (p.endswith(('.lua','.ahk')) and not p.startswith('tools/'))
        or p.startswith('tools/keyprobe/') and p.endswith(('.lua','.ahk')))]
assert 'ui/rounded_bar.lua' in files
assert not any(p.startswith(('data/','images/','themes/')) or p.endswith('.ini') for p in files)
name='XIVCrossbar-Personal5-Update.zip'
audit={'source_commit':git('rev-parse','HEAD').decode().strip(),
       'base':base,'rollback':rollback,'files':{},'rollback_files':[]}
with ZipFile(out/name,'w',ZIP_DEFLATED) as archive:
    for p in ('WORKFLOW.md','TESTING.md'):
        archive.writestr(p,(root/p).read_bytes())
    for p in files:
        data=(root/p).read_bytes()
        archive.writestr('xivcrossbar/'+p,data)
        audit['files'][p]=hashlib.sha256(data).hexdigest()
        previous=subprocess.run(['git','show',rollback+':'+p],cwd=root,
                                stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        if previous.returncode==0:
            archive.writestr('rollback/xivcrossbar/'+p,previous.stdout)
            audit['rollback_files'].append(p)
with ZipFile(out/name) as archive:
    assert archive.testzip() is None
    for p in files:
        assert archive.read('xivcrossbar/'+p)==(root/p).read_bytes()
    assert 'README.md' not in archive.namelist()
    audit['entries']=len(archive.namelist())
audit['size_bytes']=(out/name).stat().st_size
audit['sha256']=hashlib.sha256((out/name).read_bytes()).hexdigest()
(out/'PACKAGE-AUDIT.json').write_text(json.dumps(audit,indent=2)+'\n')
print(json.dumps({'path':str(out/name),'entries':audit['entries'],
                  'size_bytes':audit['size_bytes'],'runtime_files':len(files)}))
