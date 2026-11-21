-- A (2026-11-21): UseBasicSet off (default) hides Basic from set lists and
-- fallbacks, like UseSharedSet; "Main" (Basic's XI label) cannot be created.
dofile('tests/compact.lua')
local choices = require('crossbar_destinations')
local bars = {basic={name='Basic'}, default={name='Default'}, ['job-default']={name='Job Default'},
    ['all-jobs-default']={name='All Jobs Default'}, shared={name='Shared'}, melee={name='Melee'}}
local function keys(list)
    local out = {}
    for _, e in ipairs(list) do out[e.key] = true end
    return out
end
assert(keys(choices.build(bars)).basic, 'Basic listed when not hidden')
local hidden = keys(choices.build(bars, nil, {hide_basic=true}))
assert(not hidden.basic and hidden.melee and hidden.shared, 'only Basic left out')

local theme = require('theme')
local defaults = require('defaults')
assert(defaults.UseBasicSet == false, 'off by default')
local options = theme.apply(defaults)
assert(options.UseBasicSet == false)
_libs=_libs or {}; _libs.tables=table; package.loaded.tables=package.loaded.tables or table
class=class or function(v) local mt=type(v)=='table' and getmetatable(v); return mt and mt.__class or type(v) end
dofile('tests/fixtures/windower_lists.lua')
package.loaded.lists=list
require('ui')
local chooser = require('environment_chooser')
chooser:setup(options)
assert(chooser.theme.use_basic_set == false)
local listed = keys(chooser:get_player_environments(bars))
assert(not listed.basic and listed.melee and listed['all-jobs-default'], 'chooser hides Basic')
assert(chooser:get_default_active_environment(bars, 'legacy', true) == 'melee', 'fallback skips Basic')
assert(chooser:get_default_active_environment({basic={}, default={}}, 'legacy', true) == 'default',
    'only Basic left: JOB/SUB')
assert(chooser:get_default_active_environment({basic={}, default={}}, 'legacy', false) == 'basic',
    'Basic shown: old behaviour')
assert(chooser:get_default_active_environment(bars, 'job-sub', true) == 'default')
for _, name in ipairs({'Basic', 'basic', 'Main', 'Shared'}) do
    chooser.new_set_name = name
    assert(not chooser:validate_new_set_name(), name .. ' is reserved in the chooser')
end
chooser.new_set_name = 'Tank'
assert(chooser:validate_new_set_name())
options.UseBasicSet = true
chooser:setup(options)
assert(keys(chooser:get_player_environments(bars)).basic, 'UseBasicSet on lists Basic')

-- Settings name in settings.xml: BasicSet.
local schema = require('libs/settings_schema')
assert(schema.decode({BasicSet=true}).UseBasicSet == true)
print('Basic set: hidden by default from lists and fallbacks; Basic/Main/Shared reserved; BasicSet setting.')
