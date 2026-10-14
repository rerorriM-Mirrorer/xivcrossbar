"""Build a portable four-character all-jobs bundle from a supplied Switch set."""
from pathlib import Path
import argparse,copy,json,zipfile
import xml.etree.ElementTree as E

parser=argparse.ArgumentParser()
parser.add_argument('source',type=Path)
parser.add_argument('output',type=Path)
args=parser.parse_args()
root=E.parse(args.source).getroot()
assert root.tag=='hotbar'
source=root.find('switch')
assert source is not None,'Expected the supplied Switch crossbar set'
characters=('Cioara','Myrr','Clairvaux','Killala')
bars=('l','r','rl','lr','ll','rr')
slots=('lu','ll','lr','ld','ru','rl','rr','rd','zz')
result=E.Element('hotbar');shared=E.SubElement(result,'all-jobs-default')
for bar in bars:
    destination=E.SubElement(shared,'hotbar_'+bar)
    original=source.find('hotbar_'+bar)
    for slot in slots:
        element=E.SubElement(destination,'slot_'+slot)
        old=original.find('slot_'+slot) if original is not None else None
        if old is not None:
            for field in old:
                # Old IDs belong to a catalog snapshot; copy executable values.
                if not field.tag.startswith('catalog_') and field.tag!='source_environment':
                    element.append(copy.deepcopy(field))
        if element.find('action') is not None:
            E.SubElement(element,'source_environment').text='all-jobs-default'
# Latest chatlog records this bind after the attached XML copy was taken.
enter=shared.find('hotbar_rr/slot_rd')
for child in list(enter):enter.remove(child)
for key,value in [('action','se'),('alias','Enter'),('icon','custom_actions'),
                  ('source_environment','all-jobs-default'),('type','ex')]:
    E.SubElement(enter,key).text=value
E.SubElement(shared,'name').text='All Jobs Default'
E.indent(result,space='    ')
raw=E.tostring(result,encoding='unicode',short_empty_elements=False)+'\n'
args.output.mkdir(parents=True,exist_ok=True)
for character in characters:
    folder=args.output/'Fenrir'/character;folder.mkdir(parents=True,exist_ok=True)
    (folder/'ALL-JOBS-DEFAULT.xml').write_text(raw,encoding='utf-8')
# Validate identities, destinations, six bars, native action types and source copy.
assert {x.tag for x in shared if x.tag!='name'}=={'hotbar_'+b for b in bars}
assert not any(x.tag.startswith('catalog_') for x in shared.iter())
for direction,name in [('lu','Cioara'),('ll','Myrr'),('lr','Clairvaux'),('ld','Killala')]:
    assert shared.find('hotbar_l/slot_'+direction+'/action').text=='switch to '+name
for bar in source:
    if not bar.tag.startswith('hotbar_'):continue
    for slot in bar:
        for field in slot:
            if field.tag.startswith('catalog_') or field.tag=='source_environment':continue
            assert shared.find(bar.tag+'/'+slot.tag+'/'+field.tag).text==field.text
assert shared.find('hotbar_r/slot_rd/type').text=='a'
assert shared.find('hotbar_r/slot_rl/type').text=='ct'
assert shared.find('hotbar_r/slot_ru/target').text=='stnpc'
for character in characters:
    parsed=E.parse(args.output/'Fenrir'/character/'ALL-JOBS-DEFAULT.xml').getroot()
    assert parsed.find('all-jobs-default') is not None and len(parsed)==1
print(json.dumps({'characters':characters,'six_bars':True,'bound_slots':len(shared.findall('.//action')),
                  'source_set':'Switch','new_set':'All Jobs Default','identical_files':True,
                  'metadata':'portable commands; exact catalog matches may be adopted on load'}))
