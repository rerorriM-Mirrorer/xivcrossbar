-- Real drawing objects preserve their text when text(nil) is used as a getter.
dofile('tests/compact.lua')
local ui=require('ui/crossbar')
local empty={source_environment='all-jobs-default'}
local bound={type='ex',action='echo BloodPacts',alias='BloodPacts'}
local bars={['all-jobs-default']={hotbar_1={slot_1=empty}},
    ['job-default']={hotbar_1={slot_1=bound}}, default={hotbar_1={slot_1={}}}}
ui.hotbars[1].slot_text[1]:text('BloodPacts')
ui:load_action(bars,'all-jobs-default',1,1,empty,{mp=100,tp=0},true)
assert(ui.hotbars[1].slot_text[1]:text()=='','empty All Jobs Default retained previous label')
assert(maybe_get_default_action(bars,'test',1,1)==bound,'empty Default blocked Job Default')
assert(maybe_get_default_action(bars,'shared',1,1)==nil,'Shared inherited defaults')
-- Exercise the actual dispatcher, with only its environment/command boundary mocked.
local f=assert(io.open('libs/player.lua'));local source=f:read('*a');f:close()
local chunk=assert(source:match('(function player:execute_action.-)\nfunction player:dispatch_action'))
local fired
local player={hotbar=bars,hotbar_settings={active_environment='test',active_hotbar=1},
    dispatch_action=function(_,action) fired=action end}
bars.test={hotbar_1={slot_1={}}}
local env=setmetatable({player=player,require=require},{__index=_G})
assert(load(chunk,'actual slot dispatch','t',env))()
player:execute_action(1);assert(fired==bound,'dispatch disagrees with visible inheritance')
fired=nil;player.hotbar_settings.active_environment='all-jobs-default'
player:execute_action(1);assert(fired==nil,'empty global slot fired')
-- The selected layer never inherits from a more specific default.
local inherit=require('libs/slot_inheritance').fallback
local global={type='ex',action='echo global'}
bars['all-jobs-default'].hotbar_1.slot_1=global
assert(inherit(bars,'job-default',1,1)==global)
assert(inherit(bars,'all-jobs-default',1,1)==nil)
bars['job-default'].hotbar_1.slot_1={}
assert(inherit(bars,'test',1,1)==global)
local job={type='ex',action='echo job'};bars.default.hotbar_1.slot_1=job
assert(inherit(bars,'test',1,1)==job)
assert(inherit(bars,'default',1,1)==global)
bars.shared={hotbar_1={slot_1={}}}
fired=nil;player.hotbar_settings.active_environment='shared'
player:execute_action(1);assert(fired==nil,'Shared dispatched an invisible inherited binding')
print('Empty saved slots clear captions and fall through to real inherited bindings; dispatch matches display.')
