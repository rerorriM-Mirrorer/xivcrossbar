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

-- 2026-11-18: personal L1 maps work everywhere in-world. Touchpad map: chat,
-- cutscenes, FFXI/Trust/XIV Crossbar menus; only setup/login keep it raw. Zoom
-- (sent as '.'/',' keys): the same, except while typing text.
local function slice(from, len) local a=src:find(from,1,true); assert(a,from); return src:sub(a,a+len) end
local route=slice("if pressed and dik==203 and personal.TouchpadMap",260)
for _,guard in ipairs({'info.menu_open','info.chat_open',"context=='gameplay'",'status'}) do
    assert(not route:find(guard,1,true), 'touchpad map must not check '..guard)
end
assert(route:find("context~='setup' and context~='login'",1,true))
local map_at=src:find("if pressed and dik==203 and personal.TouchpadMap",1,true)
local trust_at=src:find("return 'trust-menu-priority'",1,true)
assert(map_at < trust_at, 'touchpad map is checked before the Trust menu takes presses')
local mask=slice("local eligible=(context==1 or (context==2 and not gamepad_mapper.is_showing)) and info",420)
assert(not mask:find('trust_slots',1,true) and not mask:find('menu_open',1,true))
assert(mask:find("personal.CameraZoom and not typing",1,true) and mask:find("personal.TouchpadMap and 2^17",1,true))
local zoom=slice("local zoomable = ",160)
assert(not zoom:find('crossbar_menu_open',1,true) and not zoom:find('status',1,true)
    and not zoom:find('controller_bridge.menu',1,true) and zoom:find('not typing',1,true))
local typing=slice("local typing = ",140)
assert(typing:find('chat_open',1,true) and typing:find('is_capturing_text',1,true) and typing:find('env_chooser.capturing',1,true))
assert(src:find('zoom=extras and zoomable and',1,true))
local ahk=io.open('controller_bridge.ahk'):read('*a')
assert(not ahk:find('CB.gameplay && CB.zoom',1,true) and ahk:find('A_TickCount-CM.seen<=350 && CB.zoom && CM.count=23',1,true),
    'AHK zoom no longer needs bridge_gameplay')

-- Enter with FFXI chat open is never taken by an XIV Crossbar menu.
-- 800: the Insert console passthrough (2026-11-21) now comes first.
local kb=slice("local function controller_keyboard(dik, pressed, flags, blocked)",3200)
assert(kb:find("if dik == 210 and text_input_guard.active then",1,true) and kb:find("console_toggle",1,true), "Insert opens the console while the menu blocks keys")
assert(kb:find("console_assumed_open = true",1,true) and src:find("if console_assumed_open then navigation = false end",1,true), "the block steps aside while the console is open")
assert(kb:find("local chat_key = dik == keyboard.enter or dik == 156 or dik == keyboard.esc",1,true)
    and kb:find("chat_enter:edge(true, pressed, menu, chat_open)",1,true)
    and kb:find("if verdict == 'pass' then return false end",1,true))

-- Menu mouse: the list widget no longer follows the pointer unless menumouse is on.
local list=io.open('ui/selectablelist.lua'):read('*a')
assert(list:find('selectable_list.mouse_enabled = false',1,true) and list:find('if blocked or not selectable_list.mouse_enabled then',1,true))
local _,n=src:gsub("require%('ui/selectablelist'%)%.mouse_enabled = action_binder%.mouse_enabled","")
assert(n==2, 'setup and //xb menumouse both set the list flag')
print('personal maps everywhere, typing zoom guard, chat Enter, list mouse: passed')
