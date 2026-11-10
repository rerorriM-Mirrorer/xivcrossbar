-- Run the addon lifecycle with two independent clients and a shared reader.
local file = assert(io.open('xivcrossbar.lua'))
local source = file:read('*a')
file:close()
local first = assert(source:find('-- Native filtering and DirectLink have one active profile per client.', 1, true))
local last = assert(source:find('-- ON PRERENDER', first, true))
local reader = {state='ready', pid=10}
local clock = 0

local function client(attach_result)
    local calls, notices = {}, {}
    local info, actor = {}, {status=0}
    local match = 'Matched the sole attached controller'
    local function record(name)
        return function() calls[#calls+1] = name; return true end
    end
    local dll = {begin=function() calls[#calls+1]='attach'; return attach_result or 1,
            attach_result and 'Open the selected DirectInput device' or match, -2147024809 end,
        stop=record('off'), detach=record('detach'), hook_status=function() return 'hooks attached | '..match end,
        poll=function(context) calls[#calls+1]=context; return 1 end, poll_count=function() return 1 end,
        armed=function() return true end, status=function() return 'fixture' end}
    local env = setmetatable({
        require=function() return {open=function() return dll end} end,
        controller_profiles={profiles={xinput={backend='xinput'}},matches=function() return true end},
        controller_status=function() return reader end, settings={ControllerProfile='xinput',ControllerDevice=1},
        profile_clock=function() return clock end,
        clear_controller_input=record('clear'), message_bridge={}, gamepad_state={},
        config={save=function() end}, xivcrossbar={ready=true}, gamepad_mapper={},
        crossbar_menu_open=function() return false end,
        chat_format={say=function(_, text) notices[#notices+1]=text end},
        windower={addon_path='',has_focus=function() return true end,
            ffxi={get_info=function() return info end,get_player=function() return actor end}},
    }, {__index=_G})
    assert(load(source:sub(first,last-1), 'native lifecycle', 't', env))()
    return env, calls, notices, dll, info, actor
end

local a, calls, notices, dll, info, actor = client()
local b = client()
a.native_poll(); b.native_poll()
assert(a.native_mode=='guard' and b.native_mode=='guard' and calls[2]==4)
assert(#notices==0,'automatic device match should be silent')
a.message_bridge.last_beat,a.message_bridge.last_seen=1,clock
a.native_poll()
assert(a.native_filtering and calls[#calls]==1)
a.native_command('status')
assert(notices[#notices]:find('filtering',1,true))
assert(notices[#notices]:find('Matched the sole attached controller',1,true))
a.shoulder_banks=require('shoulder_banks')
a.settings.ShoulderBanks=require('defaults').ShoulderBanks
a.settings.ShoulderBanks.L1.Enabled=true
a.settings.ShoulderBanks.Targeting=true
a.message_bridge.extended=true
dll.shoulder_slots=true
dll.tap_tab=function() return 1 end
info.menu_open=true
a.native_poll()
assert(calls[#calls]==1 and not a.gamepad_state.shoulder_slots,'idle native menu keeps ownership')
for _, status in ipairs({1,3}) do
    actor.status=status
    a.native_poll()
    assert(calls[#calls]==1+0x200 and a.gamepad_state.shoulder_slots,'battle menu bit must permit slot capture')
    assert(not a.gamepad_state.shoulder_targeting,'targeting remains disabled under the native menu bit')
end
info.chat_open=true
a.native_poll()
assert(calls[#calls]==3 and not a.gamepad_state.shoulder_slots,'chat must suppress slot capture')
info.chat_open=false
actor.status=4
a.native_poll()
assert(calls[#calls]==1 and not a.gamepad_state.shoulder_slots,'cutscenes must suppress slot capture')
a.native_stop(true)
assert(table.concat(calls,','):find('off,clear,detach',1,true))
assert(a.native_mode==nil and not a.native_filtering and b.native_mode=='guard')
local reloaded, reload_calls = client()
reloaded.native_poll()
assert(reload_calls[1]=='attach' and reloaded.native_mode=='guard')

reader.state='stopped'
clock=1
b.native_poll()
assert(b.native_mode==nil and not b.native_receiving)
reader={state='ready',pid=11}
clock=2
b.native_poll()
assert(b.native_mode=='guard')
b.native_stop(nil,true)
clock=3
b.native_poll()
assert(b.native_mode=='guard','logout/login can reuse the same running reader')

local failed, failure_calls, failure_notices = client(0)
failed.native_poll()
assert(not failed.native_mode and not failed.native_filtering and failure_calls[1]=='attach')
failed.native_command('status')
assert(failure_notices[#failure_notices]:find('Hook Unavailable',1,true))
assert(failure_notices[#failure_notices]:find('0x80070057',1,true))
failed.native_command('auto')
failed.native_command('status')
assert(not failure_notices[#failure_notices]:find('Hook Unavailable',1,true))

local loader = package.loadlib
package.loadlib=function()
    return function()
        return {process_id=17, begin=function() return 1, 'Matched the sole attached controller', 0 end, detach=function() return 1 end}
    end
end
local module = require('native_gamepad').open('fixture')
package.loadlib=loader
local result, operation, code = module.begin()
assert(result==1 and operation=='Matched the sole attached controller' and code==0)
assert(module.hook_status():find(operation,1,true))
assert(module.detach() and module.hook_status():find('detached',1,true))
print('Native lifecycle: reader lease, immediate cleanup, independent clients, reload and detach status passed.')
