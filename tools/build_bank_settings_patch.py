"""A: revise an explicitly supplied bank snapshot using the actual Lua defaults.

No ordinary crossbars, catalogs, controller settings or panel fields are edited.
The output is a separate settings ZIP, never part of the cumulative code patch.
"""
import argparse
import copy
import hashlib
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def factory_entries():
    source = """local B=require('libs/banks/banks')
for _,layer in ipairs({'l1','l1l2','r1','r1r2'})do
 for _,context in ipairs({'Closed','Menu'})do for i=1,8 do
  local e=B.factory(layer,i,context=='Menu')
  print('BANKDEF',layer,context,i,e.Alias,e.Kind,e.Command,e.Key,tostring(e.Hold))
 end end
end
"""
    with tempfile.TemporaryDirectory() as directory:
        probe = Path(directory) / 'export.lua'
        probe.write_text(source)
        result = subprocess.run(['python3', 'tests/run_lua.py', str(probe)],
                                cwd=ROOT, text=True, capture_output=True, check=True)
    entries = {}
    for line in result.stdout.splitlines():
        if not line.startswith('BANKDEF\t'):
            continue
        _, layer, context, slot, *values = line.split('\t')
        assert len(values) == 5
        entries[layer, context, int(slot)] = dict(zip(
            ('Alias', 'Kind', 'Command', 'Key', 'Hold'), values))
    assert len(entries) == 64
    return entries


def build(source, destination, revision):
    entries = factory_entries()
    with zipfile.ZipFile(source) as archive:
        original = archive.read('data/companion_banks.xml')
    root = ET.fromstring(original)
    before = copy.deepcopy(root)
    names = {'l1': 'L1', 'l1l2': 'L1L2', 'r1': 'R1', 'r1r2': 'R1R2'}
    titles = {'l1': 'L1 Party', 'l1l2': 'L1 + L2 Available',
              'r1': 'R1 NPC', 'r1r2': 'R1 + R2 Available'}
    characters = []
    for character in root:
        banks = character.find('CompanionBanks')
        if banks is None:
            continue
        characters.append(character.tag)
        for layer, name in names.items():
            bank = banks.find(name)
            if bank is None:
                bank = ET.SubElement(banks, name)
            for key, value in {'Enabled': str(layer in ('l1', 'r1')).lower(),
                               'Visible': 'true', 'ShowOnMenu': 'true',
                               'MenuActions': 'false', 'Title': titles[layer]}.items():
                node = bank.find(key)
                if node is None:
                    node = ET.SubElement(bank, key)
                node.text = value
            for context in ('Closed', 'Menu'):
                old = bank.find(context)
                if old is not None:
                    bank.remove(old)
                node = ET.SubElement(bank, context)
                for slot in range(1, 9):
                    item = ET.SubElement(node, 'Slot' + str(slot))
                    for key, value in entries[layer, context, slot].items():
                        ET.SubElement(item, key).text = value
    # Assert every original panel subtree and unrelated field is preserved.
    def unrelated(tree):
        tree = copy.deepcopy(tree)
        for character in tree:
            banks = character.find('CompanionBanks')
            if banks is None:
                continue
            for name in names.values():
                bank = banks.find(name)
                if bank is not None:
                    banks.remove(bank)
        return ET.tostring(tree)
    assert unrelated(root) == unrelated(before)
    for character in root:
        banks = character.find('CompanionBanks')
        if banks is None:
            continue
        for layer, name in names.items():
            for context in ('Closed', 'Menu'):
                for slot in range(1, 9):
                    item = banks.find(f'{name}/{context}/Slot{slot}')
                    assert {node.tag: node.text or '' for node in item} == entries[layer, context, slot]
    ET.indent(root, space='    ')
    revised = b'<?xml version="1.1" ?>\n' + ET.tostring(root, encoding='utf-8') + b'\n'
    note = (f'A — Bank settings snapshot — source {revision}\n'
            f'Input SHA256 {hashlib.sha256(original).hexdigest()}\n'
            f'Sections: {", ".join(characters)}\n'
            'This is the supplied snapshot, not a cross-client merge. Install only where\n'
            'it represents your current bank file. Back up first and unload all clients.\n'
            'Franklet is absent from the supplied snapshot. On the laptop, use\n'
            '//xb bank preset cioara apply on each character instead: it preserves\n'
            'that installation\'s panel positions and other character sections.\n'
            'Only data/companion_banks.xml is installable. backup/ contains the original.\n'
            'Ordinary job/All Jobs Default bars are unchanged. New code required.\n')
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('xivcrossbar/data/companion_banks.xml', revised)
        archive.writestr('backup/companion_banks.xml', original)
        archive.writestr('xivcrossbar/BANK-SETTINGS-INSTALL.txt', note)
        for name in ('WORKFLOW.md', 'TESTING.md'):
            archive.writestr('xivcrossbar/' + name, (ROOT / name).read_bytes())
    with zipfile.ZipFile(destination) as archive:
        assert archive.testzip() is None
        assert archive.read('backup/companion_banks.xml') == original
    print('Verified settings sections:', ', '.join(characters))
    print('All original panel fields and unrelated settings preserved; 64 actual Lua defaults per section verified.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--revision', required=True)
    args = parser.parse_args()
    build(args.source, args.destination, args.revision)
