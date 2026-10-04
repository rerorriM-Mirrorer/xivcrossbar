-- Compile without executing: a missing Windower service cannot hide a syntax
-- error. Run this with Lua 5.1 or LuaJIT and the Lua paths to check as arguments.
for _, path in ipairs(arg) do
    local chunk, message = loadfile(path)
    assert(chunk, message)
end
print(('PASS: %d Lua files parse under %s'):format(#arg, _VERSION))
