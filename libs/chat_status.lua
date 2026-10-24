-- A: the user's shared chat palette for quiet status and action feedback.
-- Return complete chat lines so owners retain their existing output callback.
local M={}
local function color(value,id)
    local text=tostring(value==nil and 'unknown' or value)
    return string.color and text:color(id) or text
end
M.ink=color
function M.value(value) return color(value,0) end
function M.command(value)
    return tostring(value):gsub('//xb',function() return color('//xb',200) end)
end
function M.profile(name)
    return ({['ps5-extended']='PS5', ['xinput-extended']='Xbox',
        ['ps5-directinput']='PS5 (Legacy)', xinput='Xbox (Legacy)',
        ['xinput-r1-chooser']='Xbox RB Chooser', ['f710-directinput']='F710',
        ['fightpadpro-directinput']='FightPadPro'})[name] or tostring(name or 'Unknown')
end
function M.state(value)
    local key=tostring(value or 'unknown'):lower()
    local text=({ready='Ready',stopped='Stopped',starting='Starting',
        ['waiting-neutral']='Release Controls',unfocused='Waiting for Game Focus',
        disconnected='Disconnected',['xinput-unavailable']='XInput Unavailable',
        initializing='Initializing'})[key] or key:gsub('(%a)([%w]*)',function(a,b)return a:upper()..b end)
    return color(text,key=='ready' and 158 or 140)
end
function M.heading(label)
    return color('=== ',140)..color(label:gsub('XIVCrossbar','XIVcrossbar'),200)..color(' ===',140)
end
function M.row(label,value)
    return color('  '..label..': ',207)..color(M.command(value),0)
end
function M.notice(value,tone)
    return color('[XIVcrossbar]',200)..' '..color(M.command(value),tone or 207)
end
function M.legacy(tone,message)
    local text=tostring(message)
    local body,count=text:gsub('^%[XIV[Cc]rossbar%]%s*','',1)
    if count==0 then return color(text,tone) end
    return M.notice(body,tone==123 and 167 or tone==140 and 140 or 207)
end
function M.on(value) return value==true or value=='1' end
function M.toggle(value) return color(M.on(value) and 'ON' or 'OFF',M.on(value) and 158 or 0) end
function M.controller(o)
    local lines={}
    local function add(label,value) lines[#lines+1]=M.row(label,value) end
    local s=o.status or {};local settings=o.settings
    lines[#lines+1]=M.heading(o.embedded and 'Controller' or 'XIVcrossbar | Controller')
    add('Controller',M.profile(s.running and s.profile or settings.ControllerProfile)..
        ' / Device '..tostring(s.running and s.device or settings.ControllerDevice))
    add('State',M.state(s.running and s.state or 'stopped')..' | Connected: '..M.toggle(s.running and M.on(s.connected)))
    add('Controls',s.running and (s.personal_version or 'Unmarked Wrapper') or 'Not Running')
    local wanted=settings.ControllerMessages and require('libs/controller/profiles').is_extended(settings.ControllerProfile)
    local route=s.running and (s.button_route or 'keys') or 'unknown'
    add('Input',not s.running and 'Unavailable' or route=='messages' and 'Messages' or
        wanted and color('Waiting for Messages',140) or 'Keyboard (Legacy)')
    if settings.ControllerProfile=='xinput-extended' then
        add('Guide Button',s.guide_touchpad=='available' and 'Touchpad Mapping' or 'Unavailable')
    end
    if o.pending then add('Profile Change',M.state(o.pending)) end
    if s.running and o.mismatch and not o.pending then
        add('Action','Select '..M.profile(settings.ControllerProfile)..' with //xb controller profile '..
            require('libs/controller/profiles').short_name(settings.ControllerProfile)..' '..tostring(settings.ControllerDevice))
    elseif wanted and s.running and s.button_protocol~='1' then
        add('Action','Restart the updated AHK wrapper for messages.')
    elseif s.running and settings.ControllerRealKeys and s.realkeys_protocol~='1' then
        add('Action','Restart the updated AHK wrapper for direct IJKL output.')
    end
    return lines
end
return M
