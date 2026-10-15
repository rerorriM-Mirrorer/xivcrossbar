-- Run from repository root: luatex --luaonly tests/trustmovement/receiver_test.lua
-- Mocked Windower integration, not a live FFXI or Windows input test.
local events, messages, commands = {}, {}, {}
local focused, now = true, 100
local info = {logged_in=true, chat_open=false, menu_open=false}
local player = {name='Myrr', status=0}
local settings = {mode='test'}
local root = 'tests/trustmovement/.state/'
local count = 0
local function check(value, description)
    count = count + 1
    assert(value, 'FAIL: ' .. description)
end
local function contains(list, needle)
    for _, text in ipairs(list) do if text:find(needle, 1, true) then return true end end
    return false
end
function string.color(value) return value end
package.preload.chat = function() return {} end
package.preload.config = function() return {
    load=function(defaults)
        check(defaults.mode=='test', 'default is diagnostic')
        check(defaults.quiet==true, 'new quiet default is enabled')
        return settings
    end,
    save=function(value) check(value==settings, 'save same configuration') end,
} end
package.preload.socket = function() return {gettime=function() return now end} end
_addon = {}
windower = {
    addon_path=root,
    ffxi={get_info=function() return info end, get_player=function() return player end},
    has_focus=function() return focused end,
    add_to_chat=function(_, value) messages[#messages+1]=value end,
    send_command=function(value) commands[#commands+1]=value end,
    create_dir=function() end,
    register_event=function(event, callback) events[event]=callback end,
}
local function lease()
    local file=io.open(root .. 'data/Myrr.lease', 'r')
    if not file then return nil end
    local value=file:read('*a'); file:close(); return value
end
local function pulse(flags)
    check(events.keyboard(123,true,flags or 0,false)==true, 'owns signal down')
    check(events.keyboard(123,false,flags or 0,false)==true, 'owns signal up')
end
assert(loadfile('companions/trustmovement/trustmovement.lua'))()
events.load()
check(lease():find('ready=1',1,true), 'publishes ready lease')
check(events.keyboard(59,true,0,false)==nil, 'leaves crossbar F1 alone')
pulse()
check(#commands==0, 'test sends no game commands')
check(contains(messages,'Movement received on Myrr (#1)'), 'diagnostic identifies receiver')
events.keyboard(123,true,0,false)
local before=#messages
events.keyboard(123,true,0,false)
check(#messages==before, 'held signal debounced')
events.keyboard(123,false,0,false)
pulse(15)
check(contains(messages,'(#3)'), 'held keyboard modifiers accepted')
focused=false; before=#messages; pulse()
check(#messages==before, 'background client remains silent')
events['lose focus']()
check(lease():find('ready=0',1,true), 'background lease blocks injection')
focused=true; events['gain focus']()
check(lease():find('ready=1',1,true), 'focus updates lease immediately')
info.menu_open=true; now=now+1; events.prerender()
check(lease():find('ready=0',1,true), 'native menu blocks lease')
before=#commands; pulse(); check(#commands==before, 'menu cannot execute commands')
info.menu_open=false; info.chat_open=true; now=now+1; events.prerender()
check(lease():find('ready=0',1,true), 'chat blocks lease')
info.chat_open=false; player.status=4; now=now+1; events.prerender()
check(lease():find('ready=0',1,true), 'cutscene blocks lease')
player.status=0; now=now+1; events.prerender()
check(lease():find('ready=1',1,true), 'closing menu restores eligibility')
events['addon command']('live'); before=#messages; pulse()
check(#messages==before, 'quiet live movement emits no acknowledgment')
check(commands[#commands]=='lua c trust follow me --quiet; lua c trust assist me --quiet', 'exact quiet commands, ordered')
check(not commands[#commands]:find('stop',1,true) and not commands[#commands]:find('start',1,true), 'no start/stop management')
events['addon command']('off'); before=#commands; pulse()
check(#commands==before, 'off never sends commands')
check(lease():find('ready=0',1,true), 'off blocks wrapper signal')
events['addon command']('TEST')
check(settings.mode=='test', 'mode command is case-insensitive')
before=#messages; events['addon command']('nonsense')
check(#messages>before+2 and contains(messages,'//tm live'), 'invalid command shows full help')
events['addon command']('status')
check(contains(messages,'executed=1'), 'status distinguishes requests from diagnostics')
events['addon command']('live')
events['addon command']('quiet','off'); before=#messages; pulse()
check(#messages==before+1, 'verbose mode restores movement acknowledgment')
check(commands[#commands]=='lua c trust follow me; lua c trust assist me', 'verbose uses original commands')
events['addon command']('quiet','on'); before=#messages; pulse()
check(#messages==before, 'explicit quiet on is effective')
events['addon command']('quiet','on')
check(settings.quiet==true, 'explicit quiet on is idempotent')
events['addon command']('quiet','invalid')
check(settings.quiet==true, 'invalid quiet argument does not change setting')
events['addon command']('restart')
check(commands[#commands]=='lua reload trustmovement', 'restart dispatches once')
check(lease()==nil, 'restart removes readiness lease')
events.load(); events.logout()
check(lease()==nil, 'logout removes lease')
info.logged_in=false; now=now+1; events.prerender()
check(lease()==nil, 'logged-out receiver cannot advertise readiness')
info.logged_in=true; events.load(); events.unload()
check(lease()==nil, 'unload removes lease')
print('PASS: ' .. count .. ' mocked receiver assertions')
