-- A: the user's shared chat palette for quiet status and action feedback.
-- Return complete chat lines so owners retain their existing output callback.
local M={}
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
    if count==0 then body,count=text:gsub('^XIVCROSSBAR:%s*','',1) end
    -- Already styled headings and field rows must not be recolored.
    if count==0 then return tone==0 and text or color(text,tone) end
    local prefix=color('[XIVcrossbar]',200)..' '
    local action,slot,set=body:match('^Bound "(.-)" to (.-) %- (.-) Crossbar%.$')
    if action then
        return prefix..color('Bound ',207)..color('"'..action..'"',0)..
            color(' to ',207)..color(slot,0)..color(' | Set: ',207)..color(set,0)
    end
    local cleared,from=body:match('^Cleared (.-) %- (.-) Crossbar%.$')
    if cleared then
        return prefix..color('Cleared ',207)..color(cleared,0)..
            color(' | Set: ',207)..color(from,0)
    end
    local label,value=body:match('^([%w%s%-%/]+):%s*(.+)$')
    if label then
        local v
        if value=='ON' then v=color('ON',158)
        elseif value=='OFF' then v=color('OFF',0)
        else v=color(M.command(value),0) end
        return prefix..color(label..':',tone==123 and 167 or 207)..' '..v
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
return M
)
    if action then
        return prefix..color('Bound ',207)..color('"'..action..'"',0)..
            color(' to ',207)..color(slot,0)..color(' | Set: ',207)..color(set,0)
    end
    local cleared,from=body:match('^Cleared (.-) %- (.-) Crossbar%.
end
function M.say(tone,message)
    windower.add_to_chat(0,M.legacy(tone,message))
end
function M.fail(message)
    M.say(123,'[XIVCrossbar] '..tostring(message))
end
function M.on(value) return value==true or value=='1' end
function M.toggle(value) return color(M.on(value) and 'ON' or 'OFF',M.on(value) and 158 or 0) end
return M
)
    if cleared then
        return prefix..color('Cleared ',207)..color(cleared,0)..
            color(' | Set: ',207)..color(from,0)
    end
    local label,value=body:match('^([%w%s%-%/]+):%s*(.+)
end
function M.say(tone,message)
    windower.add_to_chat(0,M.legacy(tone,message))
end
function M.fail(message)
    M.say(123,'[XIVCrossbar] '..tostring(message))
end
function M.on(value) return value==true or value=='1' end
function M.toggle(value) return color(M.on(value) and 'ON' or 'OFF',M.on(value) and 158 or 0) end
return M
)
    if label then
        local v
        if value=='ON' then v=color('ON',158)
        elseif value=='OFF' then v=color('OFF',0)
        else v=color(M.command(value),0) end
        return prefix..color(label..':',tone==123 and 167 or 207)..' '..v
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
return M
