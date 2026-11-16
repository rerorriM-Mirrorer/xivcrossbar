-- Runs the real set_active_environment source under narrow mocks, and guards the
-- other GripRumble hook sites in xivcrossbar.lua (static text checks).
local f = assert(io.open('xivcrossbar.lua'))
local source = f:read('*a')
f:close()
local function between(first, following)
    local a = assert(source:find(first, 1, true), 'missing source start: ' .. first)
    local b = assert(source:find(following, a + #first, true), 'missing source end: ' .. following)
    return source:sub(a, b - 1)
end

local cues, titles, loads = {}, 0, 0
local player = {hotbar = {}, vitals = {}, hotbar_settings = {active_environment = 'default'}}
function player:set_active_environment(name) self.hotbar_settings.active_environment = name end
local env = setmetatable({
    player = player,
    xivcrossbar = {ready = true},
    grip_rumble = {emit = function(_, feature, any) cues[#cues + 1] = feature .. (any and '*' or '') end},
    action_binder = {refresh_set_title = function() titles = titles + 1 end},
    set_display_name = function(_, name) return name end,
    ui = {set_set_name = function() end, load_player_hotbar = function() loads = loads + 1 end},
}, {__index = _G})
assert(load(between('function set_active_environment(environment_name)', "-- The chooser's Add New Set row"),
    'actual set_active_environment', 't', env))()

env.set_active_environment('boss')
assert(#cues == 1 and cues[1] == 'set' and loads == 1, 'a real set change cues once')
env.set_active_environment('boss')
assert(#cues == 1 and loads == 2, 'reapplying the same set (rebind, reload) must not cue')
env.xivcrossbar.ready = false
env.set_active_environment('default')
assert(#cues == 1, 'no cue before the addon is ready (startup/login)')

-- Static hook-site guards.
local function has(text, message) assert(source:find(text, 1, true), message) end
has("if accepted then grip_rumble:emit('slot', true) end", 'accepted slot press must cue without a focus check')
has("if (left_trigger_just_pressed or right_trigger_just_pressed) and gamepad_state.active_bar ~= 0 then\n        grip_rumble:emit('trigger')",
    'L2/R2 press that raises a crossbar must cue')
has("if bank and bank ~= gamepad_state.shoulder_bank then grip_rumble:emit('trigger') end\n        gamepad_state.shoulder_bank, gamepad_state.shoulder_bank_visible = bank, bank_visible",
    'enabled L1/R1/combination bank change must cue before state is overwritten')
local bind = between('function set_hotkey(', 'function delete_hotkey(')
assert(bind:find("grip_rumble:emit('bind')", 1, true), 'a successful binding must cue')
assert(not between('function delete_hotkey(', 'local function set_display_name'):find('grip_rumble', 1, true), 'clearing a slot must not cue')
assert(not source:find('slot_rumble_enabled', 1, true) and not source:find('emit_slotpress', 1, true), 'old session-only flag removed')
has("command == 'rumble'", '//xb rumble command registered')
has("command == 'slotrumble'", '//xb slotrumble kept for GripRumble sync')
print('GripRumble wiring: set switch (real source) and trigger, bank, binding and slot hook sites passed.')
