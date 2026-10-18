-- A: a deliberately small native vocabulary shared with the AHK key service.
-- Console commands never become SendEvent strings. Extend both validators when
-- adding a native key; user commands belong in the console action instead.
local M={}
local names={up='Up',right='Right',down='Down',left='Left',enter='Enter',escape='Escape',
    esc='Escape',space='Space',tab='Tab',numpadadd='NumpadAdd'}
function M.parse(value)
    if type(value)~='string' then return end
    value=value:lower()
    local modifier,key=value:match('^(%a+)%+([%w]+)$')
    if not key then key=value;modifier='' end
    local mods={['']='',ctrl='LControl',alt='LAlt',shift='LShift'}
    if mods[modifier]==nil then return end
    local native=names[key] or key:match('^[a-z0-9]$')
    if not native and key:match('^f%d%d?$') then
        local n=tonumber(key:sub(2));if n>=1 and n<=12 then native='F'..n end
    end
    if not native then return end
    return native,mods[modifier],(modifier~='' and modifier..'+' or '')..native:lower()
end
return M
