-- A: per-character targeting controls; AHK owns pulse ordering and native keys.
local M={}
-- Private short forms toggle when bare; long forms retain their status behavior.
function M.shortcut(settings,source,mode,save,say)
    if mode==nil then
        local enabled=source=='both' and settings.ControllerTargetR2 and settings.ControllerTargetR3 or
            source=='r2' and settings.ControllerTargetR2 or source=='r3' and settings.ControllerTargetR3
        mode=enabled and 'off' or 'on'
    elseif type(mode)=='string' and mode:lower()=='status' then mode=nil end
    return M.command(settings,source,mode,save,say)
end
function M.command(settings,source,mode,save,say)
    source=type(source)=='string' and source:lower() or 'status'
    mode=type(mode)=='string' and mode:lower() or nil
    if source~='status' and source~='r2' and source~='r3' and source~='both' or
        mode and mode~='on' and mode~='off' or source=='status' and mode then
        say('Use //xb controller target [r2|r3|both] [on|off].');return false
    end
    if mode then
        local enabled=mode=='on'
        if source=='r2' or source=='both' then settings.ControllerTargetR2=enabled end
        if source=='r3' or source=='both' then settings.ControllerTargetR3=enabled end
        save()
    end
    say('F8 trials: R2='..(settings.ControllerTargetR2 and 'on' or 'off')..
        ', R3='..(settings.ControllerTargetR3 and 'on' or 'off')..'. Extended profiles (x / xbox); fresh unmodified gameplay presses only.')
    return mode and true or nil
end
return M
