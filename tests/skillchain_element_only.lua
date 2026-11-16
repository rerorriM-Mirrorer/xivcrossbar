-- Searing Light (Carbuncle) and other element-only abilities carry a Magic Burst
-- `element` but no `skillchain`. They must not create a skillchain window, and a
-- missing property list must never raise an error.
local f = assert(io.open('libs/skillchain/skillchains.lua'))
local source = f:read('*a')
f:close()
local function between(first, following)
    local a = assert(source:find(first, 1, true), 'missing source start: ' .. first)
    local b = assert(source:find(following, a + #first, true), 'missing source end: ' .. following)
    return source:sub(a, b - 1)
end

local skills = dofile('libs/skillchain/skills.lua')
local searing = skills.job_abilities[518]
assert(searing and searing.en == 'Searing Light' and searing.element and not searing.skillchain,
    'Searing Light is element-only data')

local env = setmetatable({
    resonating = {}, info = {player = 1}, next_frame = 0, targ_id = nil,
    unpack = table.unpack or unpack,
    sc_info = {Scission = {lvl = 1, Reverberation = {1, 'Reverberation'}}, Reverberation = {lvl = 1}},
    sc_elements = {Scission = {Earth = 'Earth'}},
}, {__index = _G})
assert(load(between('function aeonic_prop(', '-- Checks for Skillchain properties'), 'aeonic_prop', 't', env))()
assert(load(between('function check_sc_props(', '-- Checks for Magic Burst properties'), 'check_sc_props', 't', env))()
assert(load(between('function check_burst_props(', '-- TODO: Rename this'), 'check_burst_props', 't', env))()
assert(load(between('function apply_properties(', 'function action_handler(act)'), 'apply_properties', 't', env))()

-- The real data path: the handler passes aeonic_prop(ability, actor) as properties.
local props = env.aeonic_prop(searing, 1)
assert(props == nil)
env.apply_properties(77, 'job_abilities', 518, props, 3, 1)
assert(next(env.resonating) == nil, 'element-only action must not record a resonating skillchain')

-- Real skillchain openers still record one, and a chainbound entry keeps its level.
local poison = skills.job_abilities[513]
env.apply_properties(77, 'job_abilities', 513, env.aeonic_prop(poison, 1), 3, 1)
assert(env.resonating[77] and env.resonating[77].active[1] == 'Transfixion' and env.resonating[77].step == 1)
env.apply_properties(78, 'job_abilities', 0, nil, 2, 1, false, 2)
assert(env.resonating[78] and env.resonating[78].bound == 2)

-- Missing properties are a no-result, never an error (the old `#old` crash).
assert(env.check_sc_props(nil, {'Reverberation'}) == nil)
assert(env.check_sc_props({'Scission'}, nil) == nil)
assert(env.check_burst_props(nil, {'Earth'}) == nil)
assert(env.check_burst_props({'Scission'}, nil) == nil)
-- Normal behavior is unchanged.
local level, prop = env.check_sc_props({'Scission'}, {'Reverberation'})
assert(level == 1 and prop == 'Reverberation')
assert(env.check_burst_props({'Scission'}, {'Earth'}) == 'Earth')
print('Element-only abilities (Searing Light) create no skillchain window; nil properties are safe; real openers and chainbound unchanged.')
