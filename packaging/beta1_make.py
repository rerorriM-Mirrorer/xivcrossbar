"""Build one complete, installable beta folder; never package user state.

GitHub Actions uploads dist/ as one artifact whose ZIP contains xivcrossbar/.
Source and installed code match the checked-out commit exactly.
"""
from pathlib import Path
import hashlib, shutil, sys
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'dist'/'xivcrossbar'
EXCLUDE={'.git','.github','.gitignore','.gitattributes','dist','data','tests','packaging',
         '__pycache__','.pytest_cache','AGENTS.md'}
if DEST.parent.exists(): shutil.rmtree(DEST.parent)
DEST.mkdir(parents=True)
count=0
for src in sorted(ROOT.rglob('*')):
    if not src.is_file() or any(part in EXCLUDE for part in src.relative_to(ROOT).parts):
        continue
    relative=src.relative_to(ROOT)
    dst=DEST/relative
    dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src,dst)
    assert hashlib.sha256(src.read_bytes()).digest()==hashlib.sha256(dst.read_bytes()).digest()
    count+=1
required=['xivcrossbar.lua','controller_messages.lua','controller_messages.ahk',
          'controller_lease.lua','ffxi_directinput.ahk','README.md','LICENSE','NOTICE',
          'WORKFLOW.md','TESTING.md','FFXI_Input.py','FFXI_Input.sh']
assert all((DEST/p).exists() for p in required)
assert (DEST/'images').is_dir() and (DEST/'themes').is_dir()
assert not (DEST/'data').exists(), 'never ship saved state'
assert len(list((ROOT/'images').rglob('*')))>0
print(f'Beta 1 package: {count} exact-source files; root={DEST}; user data excluded.')
