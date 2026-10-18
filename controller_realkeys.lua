-- A: configuration/permission only. AHK owns real IJKL key delivery and masks
-- those physical directions from DirectLink, avoiding duplicate Lua setkey.
local M={}
function M.enabled(settings,token)
    return settings.ControllerRealKeys==true and settings.ControllerProfile=='ps5-extended'
        and settings.ControllerMessages==true and settings.GameplayDPad=='ijkl'
        and settings.InputTest~=true and token~=nil
end
function M.command(settings,mode,save,say)
    mode=type(mode)=='string' and mode:lower() or nil
    if mode and mode~='on' and mode~='off' and mode~='status' then
        say('Use //xb realkeys [on|off|status].');return false
    end
    local value=settings.ControllerRealKeys==true
    if mode~='status' then value=mode and mode=='on' or mode==nil and not value end
    local changed=value~=(settings.ControllerRealKeys==true)
    if changed then settings.ControllerRealKeys=value;save() end
    say('Real IJKL '..(value and 'ON' or 'OFF')..
        '. Requires updated AHK, profile x, messages on, dpad ijkl and inputtest off. Return to neutral; controller status reports permission, not a held key.')
    return changed
end
return M
