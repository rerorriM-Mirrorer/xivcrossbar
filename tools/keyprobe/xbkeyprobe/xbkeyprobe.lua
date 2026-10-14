-- A: optional observer; an explicit F15 test command can also route DIK 102.
-- No automatic load, persistent binding or change to the crossbar transport.
_addon.name = 'XBKeyProbe'
_addon.author = 'A'
_addon.version = '1.1.0'
_addon.commands = {'xbkeyprobe'}
local enabled = false
local f15_command, f15_down = nil, false
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'status'
    if command=='on' then enabled=true
    elseif command=='off' then enabled=false
    elseif command=='toggle' then enabled=not enabled
    elseif command=='f15' then
        local args={...}
        if args[1]=='off' then f15_command=nil
        elseif #args>0 then f15_command=table.concat(args,' ') end
        windower.add_to_chat(207,'[XBKeyProbe] F15 test: '..(f15_command or 'OFF'))
        return
    elseif command=='help' then
        windower.add_to_chat(207,'[XBKeyProbe] on|off|toggle|status; f15 <command>|off. Observer alone consumes nothing.')
        return
    end
    windower.add_to_chat(207,'[XBKeyProbe] '..(enabled and 'ON' or 'OFF'))
end)
windower.register_event('keyboard', function(dik, pressed, flags, blocked)
    if enabled and pressed then
        windower.add_to_chat(207,('[XBKeyProbe] DIK=%s flags=%s blocked=%s'):format(
            tostring(dik),tostring(flags),tostring(blocked)))
    end
    if dik==102 then
        local fresh=pressed and not f15_down
        f15_down=pressed
        if f15_command then
            if fresh and not blocked then windower.send_command(f15_command) end
            return true
        end
    end
end)
