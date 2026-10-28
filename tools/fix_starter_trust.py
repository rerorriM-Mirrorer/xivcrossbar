"""Remove only the redundant trust page from an installed-starter XML payload.

The universal all-trust page and every unrelated page/slot remain untouched.
This operates on a supplied starter ZIP, never discovers live user settings.
"""
import argparse
from pathlib import Path
import zipfile
import xml.etree.ElementTree as ET


def corrected(raw):
    root = ET.fromstring(raw)
    old = root.find('trust')
    if old is None:
        return None
    root.remove(old)
    ET.indent(root, space='    ')
    return ET.tostring(root, encoding='utf-8') + b'\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('starter_zip', type=Path)
    parser.add_argument('output_directory', type=Path)
    args = parser.parse_args()
    count = 0
    with zipfile.ZipFile(args.starter_zip) as archive:
        for name in archive.namelist():
            if not name.startswith('xivcrossbar/data/hotbar/Fenrir/') or not name.endswith('/SMN-WHM.xml'):
                continue
            parts = Path(name).parts
            if len(parts) != 6 or any(part in ('.', '..') for part in parts):
                raise ValueError('Unexpected starter path: ' + name)
            body = corrected(archive.read(name))
            if body is None:
                continue
            target = args.output_directory.joinpath(*parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(body)
            count += 1
    print(f'Corrected {count} SMN/WHM starter files.')


if __name__ == '__main__':
    main()
