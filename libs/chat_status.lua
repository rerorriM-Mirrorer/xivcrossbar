-- A: the user's shared chat palette for quiet status and action feedback.
-- Return complete chat lines so owners retain their existing output callback.
local M={}
-- Optional here for isolated simulated tests; Windower provides this library.
pcall(require,'chat')
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
    -- The public code also uses "XIVCROSSBAR:" for old command errors.
    if count==0 then body,count=text:gsub('^XIVCROSSBAR:%s*','',1) end
    if count==0 then return color(text,tone) end
    local prefix=color('[XIVcrossbar]',200)..' '
    -- Reuse the same colored label/white value convention as status rows.
    local label,value=body:match('^([%w%s%-%/]+):%s*(.+)
function M.on(value) return value==true or value=='1' end
function M.toggle(value) return color(M.on(value) and 'ON' or 'OFF',M.on(value) and 158 or 0) end
)
    if label then
        return prefix..color(label..':',tone==123 and 167 or 207)..' '..color(M.command(value),0)
    end
    return prefix..color(M.command(body),tone==123 and 167 or tone==140 and 140 or tone==0 and 0 or 207)
end
function M.say(tone,message)
    windower.add_to_chat(0,M.legacy(tone,message))
end
function M.fail(message)
    M.say(123,'[XIVCrossbar] '..tostring(message))
end

function M.on(value) return value==true or value=='1' end
function M.toggle(value) return color(M.on(value) and 'ON' or 'OFF',M.on(value) and 158 or 0) end
