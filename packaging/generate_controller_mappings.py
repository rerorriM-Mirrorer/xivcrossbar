"""Generate physical mappings for the AHK reader and native gamepad guard."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('packaging/controller_mappings.json')


def values(items):
    return ', '.join(map(str, items))


def generate(data):
    direct = data['directinput_buttons']
    profiles = dict(direct)
    profiles.update({alias: direct[target] for alias, target in data['directinput_aliases'].items()})
    masks = data['xinput_masks']
    shoulders = data['xinput_shoulders']
    chooser = data['xinput_alternate_chooser']
    threshold = data['xinput_trigger_threshold']
    logical = data['logical_order']
    assert len(masks) + len(shoulders) + 2 == len(logical)
    assert all(len(buttons) == len(logical) - 4 for buttons in profiles.values())

    ahk_profiles = '\n'.join(
        f'        case "{profile}":\n            return [{values(buttons)}]'
        for profile, buttons in profiles.items()
    )
    ahk = f'''; Generated from {SOURCE.as_posix()}. Edit the source and regenerate.
; Logical order: {values(logical)}.
; The DirectInput POV supplies the first four inputs.
ControllerDirectInputButtons(profile) {{
    switch profile {{
{ahk_profiles}
    }}
}}

ControllerXInputButtons(profile) {{
    return [{values(masks[:-1])},
        profile = "xinput-r1-chooser" ? {chooser} : {masks[-1]}]
}}

ControllerXInputShoulders(profile) {{
    return [{shoulders[0]}, profile = "xinput-r1-chooser" ? 0 : {shoulders[1]}]
}}

ControllerXInputTriggerThreshold() => {threshold}
'''
    native = f'''// Generated from {SOURCE.as_posix()}. Edit the source and regenerate.
#pragma once

namespace xb {{
constexpr unsigned xbox[] = {{{values(masks)}}};
constexpr unsigned xbox_shoulders[] = {{{values(shoulders)}}};
constexpr unsigned xbox_alternate_chooser = {chooser};
constexpr unsigned xbox_trigger_threshold = {threshold};
constexpr unsigned dualsense[] = {{{values(button - 1 for button in direct["ps5-directinput"])}}};
constexpr unsigned fightpad[] = {{{values(button - 1 for button in direct["fightpadpro-directinput"])}}};
constexpr unsigned logical_buttons[] = {{{values(range(4, len(logical)))}}};
}}
'''
    return {'controller_mappings.ahk': ahk, 'native/controller_mappings.hpp': native}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    data = json.loads((ROOT / SOURCE).read_text(encoding='utf-8'))
    stale = []
    for name, contents in generate(data).items():
        path = ROOT / name
        if args.check:
            if not path.is_file() or path.read_text(encoding='utf-8') != contents:
                stale.append(name)
        else:
            path.write_text(contents, encoding='utf-8', newline='\n')
    if stale:
        parser.exit(1, 'Regenerate controller mappings: ' + ', '.join(stale) + '\n')


if __name__ == '__main__':
    main()
