"""Package committed runtime only. Never distribute installed data/templates."""
from pathlib import Path
import subprocess,sys,zipfile,json,hashlib
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=True)
name,base,published=sys.argv[2:5]
def git(*args):return subprocess.check_output(['git',*args],cwd=root)
assert not git('status','--porcelain').strip(),'Commit before packaging'
revision=git('rev-parse','HEAD').decode().strip()
complete=base=='complete'
paths=git('ls-files' if complete else 'diff',*(() if complete else ('--name-only',base,'HEAD'))).decode().splitlines()
def include(p):
    if p.startswith(('data/','tests/','packaging/','.','tools/build_')):return False
    if p in ('TESTING.md','WORKFLOW.md'):return False
    if p.startswith(('images/','themes/')):return complete
    return p.endswith(('.lua','.ahk','.bat')) or p in ('README.md','PERSONAL.md','COLOR-SETTINGS.md','LICENSE','NOTICE','tools/keyprobe/README.md')
entries={}
for p in paths:
    if include(p) and (root/p).is_file():entries['xivcrossbar/'+p]=(root/p).read_bytes()
entries['WORKFLOW.md']=(root/'WORKFLOW.md').read_bytes()
entries['TESTING.md']=('Package source commit: '+revision+'\nGitHub checkpoint: '+published+'\n\n').encode()+(root/'TESTING.md').read_bytes()
if not complete:
    for p in list(entries):
        if not p.startswith('xivcrossbar/'):continue
        prior=subprocess.run(['git','show',base+':'+p[12:]],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        if prior.returncode==0:entries['rollback/'+p]=prior.stdout
assert not any('/data/' in p or p.lower().endswith(('.xml','.ini')) for p in entries)
archive=out/name
assert not archive.exists(),'Refuse to overwrite a delivered package'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p,data in sorted(entries.items()):z.writestr(p,data)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    for p,data in entries.items():assert z.read(p)==data
(out/(name+'.audit.json')).write_text(json.dumps({'local_commit':revision,'github_commit':published,'entries':{p:hashlib.sha256(b).hexdigest() for p,b in entries.items()}},indent=2))
print(str(archive))
