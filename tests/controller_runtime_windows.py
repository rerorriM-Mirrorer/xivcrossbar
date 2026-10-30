"""Generate a direct-launch plan with production Lua on actual Windows files.

Lupa's embedded Lua 5.4 is a CI-only test dependency, never addon runtime code.
"""
import argparse
import json
from pathlib import Path
from lupa.lua54 import LuaRuntime
parser = argparse.ArgumentParser()
parser.add_argument('fixture')
parser.add_argument('output')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
fixture = Path(args.fixture)
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('package.path = ... .. "/?.lua;" .. package.path', root.as_posix())
runtime = lua.execute((root / 'libs/controller/runtime.lua').read_text(encoding='utf-8'))
profiles = lua.execute((root / 'libs/controller/profiles.lua').read_text(encoding='utf-8'))
resolver = runtime.new()
status = profiles.read_status((fixture / 'data/controller-status.ini').as_posix())
assert status and status.ahk_major == '2'
# The bootstrap wrote this cache during its verified launch; normal starts now
# return an executable plan and never execute CMD or PowerShell.
plan = resolver.plan(resolver, fixture.as_posix() + '/', 'ps5-extended', 2, 'ctrl', status)
assert plan.mode == 'direct' and plan.source == 'cache'
assert 'launch-controller.cmd' not in plan.command and 'powershell' not in plan.command.lower()
result = {key: plan[key] for key in ('mode', 'source', 'executable', 'arguments', 'command')}
Path(args.output).write_text(json.dumps(result), encoding='utf-8')
print('PASS production Lua selects cached direct AHK executable on Windows.')
