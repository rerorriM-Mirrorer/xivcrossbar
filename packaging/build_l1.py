"""Complete personal L1 test install from a clean, committed working tree.

TrustMovement is byte-for-byte sourced from the named existing companion ZIP;
none of its older AHK/Trust patch overlays are copied. No user state is shipped.
"""
from pathlib import Path
import argparse
import hashlib
import re
import subprocess
import zipfile

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--published',required=True)
parser.add_argument('--companion',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args()
def git(*cmd):
    return subprocess.check_output(['git',*cmd],cwd=root).decode().strip()
assert not git('status','--porcelain'), 'Commit all intended source first.'
assert git('branch','--show-current')=='personal/ps5extended'
assert re.fullmatch('[0-9a-f]{40}',args.published)
assert not args.output.exists(), 'Do not overwrite an existing delivery.'
local=git('rev-parse','HEAD')
header=(f'Complete personal L1 Test 5; branch: personal/ps5extended\n'
        f'Local source commit: {local}\nPublished source commit: {args.published}\n'
        'Runtime: personal9-l1test5; Controls=9.4-input\n'
        'TrustMovement 0.1.1 companion: unchanged receiver from TrustMovement-v0.1.1-Quiet.zip\n\n').encode()
entries={'xivcrossbar/TESTING.md':header+(root/'TESTING.md').read_bytes(),
         'xivcrossbar/WORKFLOW.md':(root/'WORKFLOW.md').read_bytes()}
for name in git('ls-files').splitlines():
    if name in ('TESTING.md','WORKFLOW.md') or name.startswith(('.', 'data/','tests/','packaging/')):
        continue
    if name.startswith(('images/','themes/','docs/','tools/keyprobe/')) or name.endswith(('.lua','.ahk','.bat')) or name in (
        'README.md','PERSONAL.md','COLOR-SETTINGS.md','LICENSE','NOTICE'):
        entries['xivcrossbar/'+name]=(root/name).read_bytes()
with zipfile.ZipFile(args.companion) as source:
    assert source.testzip() is None
    for file in ('trustmovement.lua','README.md'):
        entries['trustmovement/'+file]=source.read('addons/trustmovement/'+file)
    entries['trustmovement/README.md']=(
        b'# Personal RC3 L1 complete-package companion\n\n'
        b'Install this folder alongside xivcrossbar, not inside it. Preserve data/.\n'
        b'The current sender is already in xivcrossbar; do not install the older\n'
        b'wrapper from the original TrustMovement package. Keep AddonManager loading\n'
        b'this receiver. Trust quiet overlays are separate; retain any installed\n'
        b'ones. No automatic loader is added. Runtime receiver is unchanged v0.1.1.\n\n---\n\n'
        +entries['trustmovement/README.md'])
    companion_hash=hashlib.sha256(entries['trustmovement/trustmovement.lua']).hexdigest()
assert companion_hash=='1b9d83d33244bd3c0cf6088e7d0e276702b612d4eed69be567658fa01ec09e54'
required=['l1_bank.lua','l1_transport.lua','l1_view.lua','personal_controls.lua','personal_controls.ahk',
          'personal_gestures.ahk','controller_clients.ahk','movement_signal.ahk','ffxi_directinput.ahk',
          'images/icons/iconpacks/default/icon_list.txt','images/setup/gamepad-directinput.jpg',
          'themes/ffxiv/notice.png','set_labels.lua','WORKFLOW.md','TESTING.md','LICENSE','NOTICE']
for name in required: assert 'xivcrossbar/'+name in entries, name
for name in entries:
    assert '/data/' not in name and not name.lower().endswith(('.xml','.ini','.log','.bak','.lease','.l1')),name
    assert not name.startswith(('addons/','rollback/','scripts/'))
args.output.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(args.output,'w',zipfile.ZIP_DEFLATED) as out:
    for name,raw in entries.items(): out.writestr(name,raw)
with zipfile.ZipFile(args.output) as out:
    assert out.testzip() is None
    assert len(out.namelist())==len(entries)
    for name,raw in entries.items(): assert out.read(name)==raw,name
print(f'{args.output.resolve()} | {len(entries)} entries | {args.output.stat().st_size} bytes | published {args.published}')
