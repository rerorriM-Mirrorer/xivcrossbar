"""Merge the small native Travel prototype into a COPY of a job XML file."""
from pathlib import Path
from copy import deepcopy
import argparse
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent


def action(command, alias, kind='ex'):
    entry = ET.Element('slot')
    for key, value in (('action', command), ('alias', alias), ('type', kind)):
        ET.SubElement(entry, key).text = value
    return entry


def signature(element):
    return (element.tag, (element.text or '').strip(), tuple(signature(c) for c in element))


def put_slot(bar, slot, entry):
    entry = deepcopy(entry)
    entry.tag = 'slot_' + slot
    old = bar.find(entry.tag)
    if old is not None:
        if old.find('action') is not None and signature(old) != signature(entry):
            raise ValueError(f'{bar.tag}/{entry.tag} already has a different action; choose a free slot manually')
        bar.remove(old)
    bar.append(entry)


def merge(contents, include_ui=False):
    root = ET.fromstring(contents)
    basic = root.find('basic')
    if basic is None:
        raise ValueError('This prototype requires a Basic environment')
    combined = basic.find('hotbar_rl')
    if combined is None:
        combined = ET.SubElement(basic, 'hotbar_rl')
    put_slot(combined, 'lu', action('Travel', 'Travel Once', 'switch'))
    put_slot(combined, 'ld', action('xb crossbar travel', 'Travel Stay'))
    if include_ui:
        put_slot(combined, 'll', action('Utility', 'UI Once', 'switch'))

    travel = ET.Element('travel')
    ET.SubElement(travel, 'name').text = 'Travel'
    for name in ('l', 'r', 'rl'):
        hb = ET.SubElement(travel, 'hotbar_' + name)
        ET.SubElement(hb, 'slot_zz')
    bindings = {
        'lu': ('sw hp Windurst Woods 1', 'Woods HP1'),
        'll': ('sw hp Windurst Waters 1', 'Waters HP1'),
        'lr': ('sw hp Windurst Walls 1', 'Walls HP1'),
        'ld': ('sw hp Port Windurst 1', 'Port HP1'),
        'rl': ('sw sg Port Windurst', 'Port Guide'),
        'rd': ('input /echo [Travel test] One action dispatched', 'Test Return'),
        'rr': ('xb crossbar basic', 'Basic'),
        'ru': ('warp', 'Warp'),
    }
    for slot, (command, alias) in bindings.items():
        put_slot(travel.find('hotbar_r'), slot, action(command, alias))
    old = root.find('travel')
    if old is not None:
        if signature(old) != signature(travel):
            raise ValueError('Travel already exists with different contents; merge manually')
        root.remove(old)
    root.append(travel)
    if include_ui:
        utility = ET.Element('utility')
        ET.SubElement(utility, 'name').text = 'Utility'
        for name in ('l', 'r', 'rl'):
            hb = ET.SubElement(utility, 'hotbar_' + name)
            ET.SubElement(hb, 'slot_zz')
        for slot, command, alias in (('lu', 'at cycle', 'UI Cycle'),
            ('ld', 'at show', 'UI Show'), ('ll', 'at clean', 'UI Clean'),
            ('lr', 'at status', 'UI Status'), ('rr', 'xb crossbar basic', 'Basic')):
            put_slot(utility.find('hotbar_r'), slot, action(command, alias))
        old = root.find('utility')
        if old is not None:
            if signature(old) != signature(utility):
                raise ValueError('Utility already exists with different contents; merge manually')
            root.remove(old)
        root.append(utility)
    ET.indent(root, space='    ')
    return ET.tostring(root, encoding='unicode') + '\n'


def merge_catalog(contents):
    root = ET.fromstring(contents)
    entry = ET.Element('action')
    for key, value in (('name', 'UI Cycle'), ('alias', 'UI Cycle'), ('command', 'at cycle')):
        ET.SubElement(entry, key).text = value
    for old in list(root):
        if old.findtext('name') == 'UI Cycle':
            if signature(old) != signature(entry):
                raise ValueError('UI Cycle catalog entry already differs; merge manually')
            root.remove(old)
    root.append(entry)
    ET.indent(root, space='    ')
    return ET.tostring(root, encoding='unicode') + '\n'


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--job-file', type=Path, default=HERE/'layout-test/pack/data/hotbar/Fenrir/Cioara/WHM-NOSUB.xml')
    parser.add_argument('--output', type=Path, default=HERE/'utility-pages/Fenrir/Cioara/WHM-NOSUB.xml')
    parser.add_argument('--with-ui', action='store_true')
    parser.add_argument('--catalog', type=Path, default=HERE/'layout-test/pack/data/hotbar/Fenrir/Cioara/CustomActions.xml')
    parser.add_argument('--catalog-output', type=Path, default=HERE/'utility-pages/Fenrir/Cioara/CustomActions.xml')
    args = parser.parse_args()
    if args.job_file.resolve() == args.output.resolve():
        parser.error('Use a different output path so the original remains intact')
    if args.with_ui and args.catalog.resolve() == args.catalog_output.resolve():
        parser.error('Use a different catalog output path to retain the original')
    contents = merge(args.job_file.read_bytes(), args.with_ui)
    catalog = merge_catalog(args.catalog.read_bytes()) if args.with_ui else None
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(contents, encoding='utf-8')
    if catalog is not None:
        args.catalog_output.parent.mkdir(parents=True, exist_ok=True)
        args.catalog_output.write_text(catalog, encoding='utf-8')
    print(f'Wrote Travel prototype: {args.output}')
