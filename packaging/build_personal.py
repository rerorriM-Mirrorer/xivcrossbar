"""Build the complete personal install from audited source; no installed data."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json
import re
import subprocess
import sys
from PIL import Image

root=Path(__file__).resolve().parents[1]
output=Path(sys.argv[1]).resolve()
output.mkdir(parents=True,exist_ok=True)
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
paths=subprocess.check_output(['git','ls-files','-z'],cwd=root).split(b'\0')
files=[]
for raw in paths:
    if not raw:continue
    p=Path(raw.decode())
    if p.parts[0] in {'tests','packaging'} or str(p) in {'TESTING.md','WORKFLOW.md'}:continue
    assert p.parts[0] not in {'data','upload','config.ini'},p
    assert (p.suffix.lower() in {'.lua','.ahk','.png','.jpg','.jpeg','.json','.md','.bat'}
            or (p.name=='icon_list.txt' and p.parts[0]=='images') or str(p) in {'LICENSE','NOTICE'}),p
    files.append(p)
assert (root/'ffxi_directinput.ahk').is_file()
for name in re.findall(r'^#Include %A_ScriptDir%\\(.+)$',(root/'ffxi_directinput.ahk').read_text(),re.M):
    assert Path(name) in files,name
required_external={'resources','config','files','texts','images','tables','strings','sets','lists',
 'socket','logger','chat','json','bit','packets','actions','functions','math','ffi','os','coroutine',
 'io','luau','pack','string'}
generated={'resources/crossbar_spells','resources/crossbar_abilities'}
startup=(root/'xivcrossbar.lua').read_text()
assert startup.index('resource_generator.generate_outdated_resources()') < startup.index("require('ui/crossbar')")
for name in generated:
    assert f"files.new('{name}.lua', true)" in (root/'libs/resource_generator.lua').read_text()
imports=set()
for p in files:
    if p.suffix=='.lua':imports.update(re.findall(r"\brequire\s*(?:\(\s*)?['\"]([^'\"]+)['\"]",(root/p).read_text()))
for module in imports:
    if module not in required_external and module not in generated:
        candidates=[Path(module+'.lua'),Path(module.replace('.','/')+'.lua'),Path(module)/'init.lua']
        assert any(p in files for p in candidates),('missing dependency',module)
images=0
for p in files:
    if p.suffix.lower() in {'.png','.jpg','.jpeg'}:
        with Image.open(root/p) as image:image.verify()
        images+=1
rollback_names=['ffxi_directinput.ahk','personal_controls.ahk','xivcrossbar.lua','ui/crossbar.lua',
    'ui/geometry.lua','README.md','PERSONAL.md']
archive=output/'XIVCrossbar-Personal2-Complete.zip'
assert not archive.exists(),'Refuse to replace a delivered package silently'
entries={f'xivcrossbar/{p.as_posix()}':(root/p).read_bytes() for p in files}
for name in ['WORKFLOW.md','TESTING.md']:entries[name]=(root/name).read_bytes()
for name in rollback_names:
    entries[f'rollback/xivcrossbar/{name}']=subprocess.check_output(
        ['git','show',f'recovered-personal1-20261013:{name}'],cwd=root)
entries['rollback/README.md']=b'''# Personal 1 code rollback\n\nStop/unload on all clients and back up the install first. Copy only this\nxivcrossbar/ folder's files into the complete installed addon. They restore the\nrecovered delivered Personal 1 files changed by Personal 2. Keep installed\nimages/modules/data/config.ini. Personal 1 does not reference the new\npersonal_gestures.ahk or tools/keyprobe; those may be removed after rollback.\nSelect ps5 for regular controls, or ps5extended for the older Personal 1 mapping.\nFor a full public rollback restore your original public RC3 backup instead.\n'''
with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=9) as z:
    for name,data in sorted(entries.items()):z.writestr(name,data)
with ZipFile(archive) as z:
    assert z.testzip() is None
    assert set(z.namelist())==set(entries)
    for name,data in entries.items():assert z.read(name)==data,name
audit={'revision':revision,'runtime':re.search(r"_addon.version = '([^']+)'",(root/'xivcrossbar.lua').read_text())[1],
       'complete_install':True,'image_files':images,'runtime_lua_files':sum(p.suffix=='.lua' for p in files),
       'generated_at_startup':sorted(generated),'Windower_dependencies':sorted(required_external & imports),
       'entries':{n:hashlib.sha256(b).hexdigest() for n,b in sorted(entries.items())},
       'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
(output/'PACKAGE-AUDIT.json').write_text(json.dumps(audit,indent=2)+'\n')
print(json.dumps({'archive':str(archive),'bytes':archive.stat().st_size,'entries':len(entries),
                  'images':images,'Lua':audit['runtime_lua_files'],'revision':revision}))
