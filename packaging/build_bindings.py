"""Recover a paired catalog/bar from supplied snapshots; no installed data access.

Only four L2 D-pad nodes are removed from the Franklet/Lionstag bar copies.
The separate matched catalog adopts linked values visible in the newer bar,
so installing the older catalog cannot silently roll those actions backward.
"""
from pathlib import Path
import argparse, copy, hashlib, re, zipfile
import xml.etree.ElementTree as ET

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--bar',type=Path,required=True)
p.add_argument('--catalog',type=Path,required=True)
p.add_argument('--published',required=True)
p.add_argument('--output',type=Path,required=True)
args=p.parse_args()
assert re.fullmatch('[0-9a-f]{40}',args.published)
assert not args.output.exists()
bar_bytes=args.bar.read_bytes();catalog_bytes=args.catalog.read_bytes()
bar=ET.fromstring(bar_bytes);catalog=ET.fromstring(catalog_bytes)
assert bar.tag=='hotbar' and catalog.tag=='custom_actions'
all_jobs=bar.find('all-jobs-default');assert all_jobs is not None
records={a.findtext('id'):a for a in catalog.findall('action')}
assert None not in records and len(records)==len(catalog.findall('action'))
snapshots={}
for slot in all_jobs.findall('./*/'):
    identity=slot.findtext('catalog_id')
    if not identity:continue
    assert slot.findtext('catalog_scope')=='global'
    assert identity in records and slot.findtext('type')=='ex'
    values={'name':slot.findtext('catalog_name') or records[identity].findtext('name'),
        'alias':slot.findtext('alias') or '', 'command':slot.findtext('action') or '',
        'icon':slot.findtext('icon') or '', 'linked_action':slot.findtext('linked_action') or '',
        'linked_type':slot.findtext('linked_type') or ''}
    assert identity not in snapshots or snapshots[identity]==values, 'Conflicting linked snapshots: '+identity
    snapshots[identity]=values
changes=[]
for identity,values in snapshots.items():
    record=records[identity]
    for field,value in values.items():
        previous=record.findtext(field) or ''
        if previous!=value:
            changes.append((identity,field,previous,value))
            node=record.find(field)
            if node is None:node=ET.SubElement(record,field)
            node.text=value
assert len({a.findtext('name') for a in catalog})==len(records)
ET.indent(catalog,space='    ')
matched=ET.tostring(catalog,encoding='utf-8')+b'\n'
for identity,values in snapshots.items():
    for field,value in values.items():assert (records[identity].findtext(field) or '')==value

# Preserve all unrelated bytes, including metadata and other trigger banks.
text=bar_bytes.decode('utf-8')
match=re.search(r'(<hotbar_l>)(.*?)(</hotbar_l>)',text,re.S);assert match
body=match[2]
for tag in ['slot_ll','slot_ld','slot_lr','slot_lu']:
    body,count=re.subn(rf'(?m)^[ \t]*<{tag}>[\s\S]*?</{tag}>[ \t]*\r?\n(?:[ \t]*\r?\n)?','',body)
    assert count==1,tag
adjusted=(text[:match.start(2)]+body+text[match.end(2):]).encode('utf-8')
def logical(node):return (node.tag,(node.text or '').strip(),tuple(logical(c) for c in node))
expected=copy.deepcopy(bar)
for tag in ['slot_ll','slot_ld','slot_lr','slot_lu']:
    bank=expected.find('./all-jobs-default/hotbar_l');bank.remove(bank.find(tag))
assert logical(ET.fromstring(adjusted))==logical(expected)

suggestions=[
    ('Inventory - Mog Sack','Sack','input /sack','item'),
    ('Inventory - Wardrobe','Wardrobe','input /wardrobe','item'),
    ('Party - Stop Everything','Stop All','trust stopall','disengage'),
    ('Party - Take Over','Take Over','trust follow me; trust assist me','assist'),
    ('Crossbar - Main','Main','xb bar basic','custom_actions'),
]
optional=ET.Element('custom_actions')
for number,(name,alias,command,icon) in enumerate(suggestions,1):
    a=ET.SubElement(optional,'action')
    for key,value in [('name',name),('id',f'a-suggestions-20261017:{number}'),('alias',alias),('command',command),('icon',icon)]:
        ET.SubElement(a,key).text=value
ET.indent(optional,space='    ')
optional_bytes=ET.tostring(optional,encoding='utf-8')+b'\n'

layout='''| Bar | D-pad | Square | Cross | Circle | Triangle |
| --- | --- | --- | --- | --- | --- |
| L2 | Cleared | Target NPC + report | Ask others to start Trust | Stand Down | Trust toggle + follow stop |
| R2 | Empty in this layer | Check | Attack | Return to basic/Main | Empty |
| R2 then L2 | Empty | Empty | Empty | Empty | Empty |
| L2 then R2 | Empty | Empty | Empty | Empty | Empty |
| Double L2 | Empty | Empty | All Confirm | All Cancel | NPC Interact |
| Double R2 | Empty | Empty | NPC Enter | All Cancel | NPC Interact |
'''
readme=f'''# Franklet / Lionstag — recovered Cioara binding set

Author A. Paired with Personal9 Test4; published source {args.published}.

This is a **bindings/catalog pack**, separate from the complete addon installer.
It uses the latest supplied ALL-JOBS-DEFAULT(3).xml (October 15) and uploaded
CustomActions.xml (October 14). It does not claim to be a fresh export from your
currently running PC. Original snapshots are included unchanged for reference.

## Contents and install

- Franklet/ALL-JOBS-DEFAULT.xml → xivcrossbar/data/hotbar/Fenrir/Franklet/ALL-JOBS-DEFAULT.xml
- Lionstag/ALL-JOBS-DEFAULT.xml → xivcrossbar/data/hotbar/Fenrir/Lionstag/ALL-JOBS-DEFAULT.xml
- Cioara/ALL-JOBS-DEFAULT.xml is the supplied bar unchanged, for another copy.
- global/CustomActions.xml is the matched global catalog, installed at
  xivcrossbar/data/CustomActions.xml if you want to use this recovered catalog.
- reference/CustomActions-uploaded.xml is the unchanged original catalog.
- optional/SUGGESTED-ACTIONS.xml lists five new optional actions; it is not an
  automatic import and does not replace your catalog or bind any slot.
- CONTROLLER-REFERENCE.md lists all current readers, controls and F8 options.

Unload XIVCrossbar on the affected clients before copying binding files so an
in-memory save does not overwrite the copy. Keep your current files as rollback.
Copy only the intended character's ALL-JOBS-DEFAULT file. Leave job/subjob files,
character catalogs, settings, shared sets and companion assignments alone.

On an installation with a newer global catalog, retain it and merge any desired
records through the custom-action editor rather than replacing all its contents.
The supplied catalog is global to this addon installation, not just these two
characters. Other clients using linked records with the same IDs can update too.

## Precisely what changes

Franklet and Lionstag copies remove only the four L2 D-pad slot nodes from the
All Jobs Default set. All other bar content, commands, aliases, icons and link
metadata remain unchanged. The two adjusted bar files are identical. Clearing
this last fallback layer does not erase bindings in a selected Main/job set or
its higher Default/Job Default providers.

The bar is newer than the uploaded catalog, and several IDs contain updated
commands/names. The matched global catalog preserves all {len(records)} existing IDs and
records, adopting only the linked values present in that newer bar. This prevents
catalog synchronization from silently reverting the supplied working bar.
See CATALOG-RECONCILIATION.md for every adjustment. No suggested actions are
added to that matched catalog automatically.

## Adjusted All Jobs Default layout

{layout}
The retained Return binding still labels itself Basic in this historical
snapshot. Its command selects basic, which current UI displays as Main.
No job-specific combat spells/abilities are added; those belong in job sets.

## Suggested small next layout

Keep bare D-pad/native confirm/cancel available for navigation. Put Sack and
Wardrobe in the first two slots of the editable L1-then-L2 bank, leaving the
other slots empty until a repeated need appears:

```
//xb l1 1 Sack input /sack
//xb l1 2 Wardrobe input /wardrobe
```

These edit the second companion layer, not the fixed first L1 shortcuts. They
are suggestions to apply manually, not settings installed by this ZIP. The
optional actions also include explicit Stop All, Take Over and Return to Main.
TrustMovement already handles movement takeover, so a manual Take Over slot is
useful as an occasional recovery/choice rather than a duplicate movement loop.

The supplied multi-client dialogue commands are preserved exactly, including
their older send-all form. They are not silently changed to newer SlowEnter
stagger commands, whose installed version must be checked separately.

## Validation

XML parses; 34 catalog IDs remain unique; every linked slot resolves to its
matching catalog command/alias/icon; duplicate linked snapshots agree. Semantic
comparison confirms only the four specified bar nodes were removed. Original
reference bytes are retained. Native FFXI execution of all these commands is
not re-tested here; it also depends on installed Switch/Send/Trust/SlowEnter/
NPCMirror/SendAllTarget addons and native command availability.

## Changelog

- October 16, 2026: recover current supplied Cioara pair, reconcile linked catalog
  values, clear only L2 D-pad for Franklet/Lionstag and include optional ideas.
'''
report='# Catalog reconciliation\n\n'
report+='The newer bar provides the values below; the original uploaded catalog remains in reference/.\n\n'
report+='| ID | Field | Uploaded catalog | Newer bar / matched catalog |\n| --- | --- | --- | --- |\n'
for identity,field,old,new in changes:
    escape=lambda x:x.replace('|','\\|').replace('\n',' ')
    report+=f'| {identity} | {field} | {escape(old)} | {escape(new)} |\n'
report+='\nNo IDs or unrelated catalog records were removed. Suggested actions remain separate.\n'
testing=f'''# Bindings Test 1 — October 16, 2026

Published controller source: {args.published}. These are user snapshot derivatives,
not a replacement for the entire addon. README specifies exact file destinations.

Static checks: four requested L2 D-pad nodes removed; all other bar semantics
and original reference bytes preserved; both character copies equal; catalog
IDs unique and all linked values match. Native action execution remains pending.

Live: select All Jobs Default on each intended character and check L2 D-pad is
empty. Check L2 faces, R2 Attack/Check/Return and double-trigger dialogue commands.
Recheck custom action edits remain linked and unrelated job/set data persists.
Dependencies must be loaded as on Cioara. Restore saved copies to roll back.

Source bar SHA256: {hashlib.sha256(bar_bytes).hexdigest()}
Source catalog SHA256: {hashlib.sha256(catalog_bytes).hexdigest()}
'''
entries={'README.md':readme.encode(),'TESTING.md':testing.encode(),
    'WORKFLOW.md':(root/'WORKFLOW.md').read_bytes(),
    'CONTROLLER-REFERENCE.md':(root/'docs/CONTROLLER-REFERENCE.md').read_bytes(),
    'CATALOG-RECONCILIATION.md':report.encode(),'global/CustomActions.xml':matched,
    'reference/CustomActions-uploaded.xml':catalog_bytes,'Cioara/ALL-JOBS-DEFAULT.xml':bar_bytes,
    'Franklet/ALL-JOBS-DEFAULT.xml':adjusted,'Lionstag/ALL-JOBS-DEFAULT.xml':adjusted,
    'optional/SUGGESTED-ACTIONS.xml':optional_bytes}
for name,data in entries.items():
    if name.endswith('.xml'):ET.fromstring(data)
args.output.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(args.output,'w',zipfile.ZIP_DEFLATED) as z:
    for name,data in entries.items():z.writestr(name,data)
with zipfile.ZipFile(args.output) as z:
    assert z.testzip() is None
    for name,data in entries.items():assert z.read(name)==data,name
print(f'{args.output.resolve()} | {len(entries)} files | {len(records)} matched actions | {len(changes)} catalog field reconciliations | only 4 bar slots cleared')
