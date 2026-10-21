-- A: the help palette applied to status and single-action feedback.
-- Return complete chat lines so owners retain their existing output callback.
local M={}
local function color(value,id)
    local text=tostring(value==nil and 'unknown' or value)
    return string.color and text:color(id) or text
end
function M.heading(label)
    return color('--- ',140)..color(label,167)..color(' ---',140)
end
function M.row(label,value)
    return color('  '..label,207)..color(' -> ',200)..color(value,0)
end
function M.notice(value)
    return color('//xb',200)..color(' -> ',200)..color(value,0)
end
function M.on(value) return value==true or value=='1' end
function M.toggle(value) return M.on(value) and 'ON' or 'OFF' end
function M.controller(o,details)
    local lines={}
    local function add(label,value) lines[#lines+1]=M.row(label,value) end
    local s=o.status or {};local settings=o.settings;local bridge=o.bridge
    lines[#lines+1]=M.heading('XIVCrossbar | Controller')
    add('Controls',s.running and (s.personal_version or 'unmarked wrapper') or 'No fresh wrapper status')
    add('State',s.running and ((s.state or 'unknown')..' | connected '..M.toggle(s.connected)) or 'Stopped, starting, or status unavailable')
    local requested=settings.ControllerMessages and settings.ControllerProfile=='ps5-extended' and 'messages' or 'keys'
    add('Selected',settings.ControllerProfile..' | device '..tostring(settings.ControllerDevice))
    add('Route','active '..(s.running and (s.button_route or 'keys') or 'unknown')..' | requested '..requested)
    if s.running and (s.profile~=settings.ControllerProfile or tostring(s.device)~=tostring(settings.ControllerDevice)) then
        add('Running',tostring(s.profile)..' | device '..tostring(s.device))
    end
    add('Recovery','last reset '..(bridge.last_reason or 'none recorded')..' | recovering '..M.toggle(bridge.recovering))
    add('Trace','AHK '..M.toggle(s.input_trace)..' | Lua '..M.toggle(o.lua_trace))
    if o.pending then add('Profile change',o.pending) end
    local missing={}
    if s.running and settings.ControllerMessages and settings.ControllerProfile=='ps5-extended' then
        for _,item in ipairs({{'button_protocol','messages'},{'bank_protocol','banks'},
            {'hold_recovery_protocol','hold recovery'},{'r1_menu_protocol','Trust menu'}}) do
            if s[item[1]]~='1' then missing[#missing+1]=item[2] end
        end
    end
    if s.running and settings.ControllerRealKeys and s.realkeys_protocol~='1' then missing[#missing+1]='real IJKL' end
    if #missing>0 then add('Action','Restart the updated AHK wrapper for '..table.concat(missing,', ')..'.') end
    if s.running and o.mismatch and not o.pending then add('Action','Wrapper selection differs; stop/start from the client with the desired profile.') end
    if details then
        lines[#lines+1]=M.heading('Input diagnostics')
        add('Keys','fallback '..o.modifier..' | IJKL configured '..M.toggle(settings.ControllerRealKeys)..' | output '..(s.dpad_output or 'lua'))
        add('Messages','received '..tostring(bridge.received)..' | rejected '..tostring(bridge.rejected)..' | sent / ack '..(s.button_sent or '?')..' / '..(s.button_ack or '?'))
        add('Banks','sender '..M.toggle(s.banks_enabled)..' | receiver '..M.toggle(o.banks_active)..' | native ack '..(s.bank_native_ack or '?'))
        add('Protocols','buttons '..(s.button_protocol or 'absent')..' | banks '..(s.bank_protocol or 'absent')..' | recovery '..(s.hold_recovery_protocol or 'absent'))
        add('Menu output','Trust '..M.toggle(s.r1_menus)..' (protocol '..(s.r1_menu_protocol or 'absent')..') | IJKL protocol '..(s.realkeys_protocol or 'absent'))
        add('Context',(s.personal_context or 'unknown')..' | short pauses '..(s.context_pauses or '?')..' | lease misses '..(s.context_misses or '?'))
        add('Timing maxima','cycle '..(s.poll_max_ms or '?')..' ms | start gap '..(s.poll_gap_max_ms or '?')..' ms')
        add('Read / personal',(s.read_max_ms or '?')..' / '..(s.personal_max_ms or '?')..' ms')
        add('Errors','transport write '..(s.button_error or '?')..' | trace write '..(s.trace_error or '?'))
        add('F8 trials','configured R2 / R3 '..M.toggle(settings.ControllerTargetR2)..' / '..M.toggle(settings.ControllerTargetR3)..' | wrapper '..M.toggle(s.target_r2)..' / '..M.toggle(s.target_r3))
        add('Other controls','PS '..(s.ps_action or s.ps_hold or 'unknown')..' | Ctrl / Alt pairs '..(s.ctrl_pair or '?')..' / '..(s.alt_pair or '?'))
        add('Launch source',s.origin or 'unknown')
    elseif not o.hide_hint then lines[#lines+1]=M.notice('More: //xb controller status details') end
    return lines
end
return M
