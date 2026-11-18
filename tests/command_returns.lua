-- 2026-11-18: every branch of the first //xb command chain must return, or the
-- command runs and then falls through to "Unknown command".
local src=io.open('xivcrossbar.lua'):read('*a')
local s=src:find("    if command == 'legacy' or command == 'default' or command == 'me' then",1,true)
assert(s,'chain start')
local e=src:find('\n    end\n',s,true); assert(e,'chain end')
local chain=src:sub(s,e)
local branches,checked={},0
for head in chain:gmatch('\n    elseif ([^\n]+)') do branches[#branches+1]=head end
local pieces={}
local pos=1
for start in function() local a=chain:find('\n    elseif ',pos,true); if a then pos=a+1 end; return a end do pieces[#pieces+1]=start end
pieces[#pieces+1]=#chain
for i=1,#pieces-1 do
    local body=chain:sub(pieces[i],pieces[i+1])
    assert(body:find('%f[%w]return%f[%W]'), 'branch without return: '..branches[i])
    checked=checked+1
end
for _,name in ipairs({'menufade','menumouse','chainglow','undo'}) do
    assert(chain:find("command == '"..name.."'",1,true),name)
end
assert(checked>=15,'checked '..checked)
print('command chain: '..checked..' branches all return')

-- 2026-11-18 log: L1+touchpad (map) and L1+right stick (zoom) must keep working
-- while an FFXI menu is open; the game reports battle menus as menus.
local function slice(from, len) local a=src:find(from,1,true); assert(a,from); return src:sub(a,a+len) end
local route=slice("if pressed and dik==203 and personal.TouchpadMap",400)
assert(not route:find('info.menu_open',1,true) and route:find('not info.chat_open',1,true), 'touchpad map ignores FFXI menus')
local mask=slice("local eligible=context==1 and info and",120)
assert(not mask:find('info.menu_open',1,true) and mask:find('chat_open',1,true), 'native zoom/map capture ignores FFXI menus')
local zoom=slice("local zoomable = ",190)
assert(not zoom:find('info.menu_open',1,true) and zoom:find('crossbar_menu_open()',1,true) and zoom:find('status ~= 4',1,true))
assert(src:find('zoom=extras and zoomable and',1,true), 'lease zoom uses zoomable')
print('L1 maps and zoom stay on in FFXI menus: passed')
