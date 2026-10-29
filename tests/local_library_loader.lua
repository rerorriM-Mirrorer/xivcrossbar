-- Simulate Windower's shared library resolver without the addon's local ? root.
-- Ensure a complete ZIP's nested libs are reachable on stock Windower.
local function read(path)
    local file=assert(io.open(path,'rb'))
    local contents=file:read('*a')
    file:close()
    return contents
end
local source=read('xivcrossbar.lua')
local begin=assert(source:find('-- A: Windower\'s default module search roots',1,true))
local finish=assert(source:find('\n-- Libs',begin,true))
local snippet=source:sub(begin,finish-1)
local original=package.path
local root=assert(original:match('^([^;]*)%?%.lua;'))
local shared=root..'nonexistent-shared/?.lua'
package.path=shared
assert(not pcall(require,'libs/kebab_casify'),
    'Missing module should reproduce without the addon root in package.path')
windower={addon_path=root:gsub('/',string.char(92))}
assert(load(snippet))()
assert(package.path:find(root..'?.lua',1,true),
    'Local library root is not added to the module search path')
local fn=require('libs/kebab_casify')
assert(type(fn)=='function','Bundled Lua module should be importable')
for lib in source:gmatch([[require%s*%(%s*['"](libs/[^'"]+)['"]]]) do
    assert(io.open(lib..'.lua','rb'), 'Missing local module: '..lib)
end
package.path=original
print('Windower-style missing local libs reproduction, search-path fix and bundled module import passed.')
