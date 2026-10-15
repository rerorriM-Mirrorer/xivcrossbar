"""Run available Lua 5.4 after normalizing inherited Windower string methods.

This is a source-preserving fallback, not a claim of Lua 5.1/Windower execution.
"""
import ctypes
import ctypes.util
from pathlib import Path
import re
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
lib = ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_char_p]
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]

def normalize(source):
    return re.sub(r'''('(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")(?=:\w+\s*\()''', r'(\1)', source)

def run(source, name, execute=True):
    state = lib.luaL_newstate()
    try:
        lib.luaL_openlibs(state)
        code = source.encode()
        result = lib.luaL_loadbufferx(state, code, len(code), name.encode(), None)
        if result == 0 and execute:
            result = lib.lua_pcallk(state, 0, -1, 0, 0, None)
        if result:
            raise RuntimeError(lib.lua_tolstring(state, -1, None).decode())
    finally:
        lib.lua_close(state)

with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    paths = [p for p in root.rglob('*.lua') if '.git' not in p.parts]
    for p in paths:
        text = normalize(p.read_text())
        destination = target / p.relative_to(root)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(text)
        run(text, str(p.relative_to(root)), execute=False)
    print(f'{len(paths)} Lua sources parsed after temporary Windower syntax normalization.')
    for test in sys.argv[1:]:
        prefix = f'package.path = {str(target / "?.lua")!r} .. ";" .. {str(target / "?/init.lua")!r} .. ";" .. package.path\n'
        run(prefix + normalize((root / test).read_text()), test)
