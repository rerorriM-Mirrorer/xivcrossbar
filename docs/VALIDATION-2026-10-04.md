# Validation: 2026-10-04

The standalone regression runner passes under LuaJIT 2.1 / Lua 5.1 semantics.
Its twelve reported groups cover the actual custom-action editor/selector,
command parsing/binding refresh, layer fallback and isolation, native page
dispatch/return, drag capture/offset persistence, sparse rendering and main
visibility events. External Windower services/resource records are fixtures;
FFXI itself was not run here.

The sparse-bar regression was also run against the **actual captured ui.lua**.
It failed at `ui.lua:732: attempt to index a nil value` before the later guards
and passed against the consolidated source. That establishes a real fixed
failure path; live four-bar acceptance remains separate.

All repository Lua files compile under Lua 5.1 checking, with one explicit
compatibility treatment: the unchanged bundled `libs/skillchain/skillchains.lua`
uses four string-literal method calls accepted by Windower's parser. Stock
LuaJIT rejects that syntax. `tools/check_syntax.py` parenthesizes those literal
receivers in a temporary copy only; every other file compiles unchanged.
Windower staff documented the parser difference in [Lua Interpreter](https://forums.windower.net/index.php?/topic/1165-lua-interpreter/).
No runtime vendor module was edited to satisfy the stock parser.

```text
luajit tests/run.lua
python3 tools/check_syntax.py --lua luajit
```

Python files compile; the optional historical generator's CLI opens. AHK code
is retained as an optional experiment and was not executed on Windows.
The working root wrappers and all captured controller/configuration bytes are
preserved in the package.

The package builder verifies the source archive SHA-256, forbids overwriting the
source, overlays only eight Lua files and README, and reads back the final ZIP
to compare every payload. All other 2,339 captured files match byte for byte,
including every XML, INI, AHK, image, cache and backup. The dated rollback ZIP
is byte-identical to the original upload. Existing directories are retained.

Current Fenrir XML parses; one pre-existing older Asura/Franklet catalog is
malformed and preserved. The package does not rewrite the capture to conceal
that historical issue. Diff whitespace checks pass for the published changes.
