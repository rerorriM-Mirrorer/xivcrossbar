local rumble = require('libs/grip_rumble')
local defaults = require('defaults')

-- Everything is off by default, in the shipped defaults too.
for _, key in pairs(rumble.keys) do assert(defaults.GripRumble[key] == false) end

local path = os.tmpname()
local focused, exists = true, true
local host = {
    path = function() return path end,
    exists = function() return exists end,
    open = io.open,
    focused = function() return focused end,
}
local function contents()
    local f = io.open(path, 'rb'); local text = f:read('a'); f:close(); return text
end
local function reset() local f = io.open(path, 'wb'); f:close() end
reset()

local settings = {}
local cue = rumble.new(settings, host)
assert(not cue:emit('slot') and not cue:emit('trigger') and not cue:emit('set') and not cue:emit('bind'))
assert(contents() == '')

-- Saved setting: each cue writes its own event name, one per line.
local saves, said = 0, {}
local function save() saves = saves + 1 end
local function say(m) said[#said + 1] = m end
assert(cue:command('all', 'on', save, say) and saves == 1)
assert(settings.GripRumble.SlotPress and settings.GripRumble.TriggerPull
    and settings.GripRumble.SetSwitch and settings.GripRumble.Binding)
assert(cue:emit('slot') and cue:emit('trigger') and cue:emit('set') and cue:emit('bind'))
assert(contents() == 'slotpress\ntriggerpull\nsetswitch\nbinding\n')

-- Repeating the same state does not save again (no settings.xml write storms).
assert(cue:command('all', 'on', save, say) and saves == 1)
assert(cue:command('trigger', 'off', save, say) and saves == 2)
assert(not cue:emit('trigger') and cue:emit('set'))

-- Focus: trigger/set/bind need the focused client; slot presses pass any_client.
reset(); focused = false
assert(not cue:emit('set') and not cue:emit('bind') and contents() == '')
assert(cue:emit('slot', true) and contents() == 'slotpress\n')
focused = true

-- GripRumble absent: nothing is written and nothing errors.
reset(); exists = false
assert(not cue:emit('slot', true) and contents() == '')
exists = true
host.open = function() return nil end
assert(not cue:emit('slot', true))
host.open = function() error('locked') end
assert(not cue:emit('slot', true))
host.open = io.open

-- Session override from //xb slotrumble (GripRumble's load-time sync) is never saved.
local fresh = {GripRumble = {SlotPress = true}}
local c2 = rumble.new(fresh, host)
assert(c2:enabled('slot'))
c2:session_command('off', say)
assert(not c2:enabled('slot') and fresh.GripRumble.SlotPress == true)
c2:session_command('on', say)
assert(c2:enabled('slot'))
assert(not c2:session_command('bogus', say))
-- Saving the slot cue clears the session override so the saved value rules again.
c2:session_command('off', say)
assert(c2:command('slot', 'off', save, say) and not c2:enabled('slot') and fresh.GripRumble.SlotPress == false)
assert(c2:command('slot', 'on', save, say) and c2:enabled('slot'))

-- Bad input saves nothing and prints usage; status reports every cue.
local before = saves
assert(not cue:command('bogus', 'on', save, say) and not cue:command('slot', 'maybe', save, say) and saves == before)
said = {}; cue:command('status', nil, save, say)
assert(#said == 4 and said[1]:match('^slot press') and said[2]:match('OFF$'))
-- Missing or malformed saved group behaves as off.
assert(not rumble.new({}, host):enabled('set') and not rumble.new({GripRumble = 'x'}, host):enabled('set'))
os.remove(path)
print('GripRumble cues: defaults off, event names, saved settings without repeat saves, focus, absence and session override passed.')
