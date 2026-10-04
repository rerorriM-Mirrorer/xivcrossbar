"""Compile addon/tests under Lua 5.1, accounting for one inherited Windower extension.

Only a temporary check copy gains parentheses around string-literal receivers;
the captured skillchain module and its runtime behavior remain untouched.
"""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
LITERAL_METHOD = re.compile(r'''('(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")(:[A-Za-z_]\w*\s*\()''')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lua', default='luajit', help='Lua 5.1 or LuaJIT executable')
    args = parser.parse_args()
    lua = str(Path(args.lua).resolve()) if Path(args.lua).is_file() else args.lua
    files = sorted(p for p in ROOT.rglob('*.lua') if '.git' not in p.parts)
    with tempfile.TemporaryDirectory(prefix='xivcrossbar-syntax-') as directory:
        checked = []
        for path in files:
            if path.relative_to(ROOT).as_posix() == 'libs/skillchain/skillchains.lua':
                # Windower staff documented this literal-method parser syntax.
                # It is not valid in stock Lua 5.1, so check equivalent syntax
                # in a copy rather than changing an enjoyed installation.
                source, count = LITERAL_METHOD.subn(r'(\1)\2', path.read_text())
                assert count == 4, 'Review changed Windower literal-method syntax'
                normalized = Path(directory) / 'skillchains.lua'
                normalized.write_text(source)
                checked.append(str(normalized))
            else:
                checked.append(str(path))
        subprocess.run([lua, 'tests/syntax.lua', *checked], cwd=ROOT, check=True)
    print('Windower literal-method syntax checked in one temporary copy; runtime files unchanged')
