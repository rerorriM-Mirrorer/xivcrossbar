-- Complete UI reconstruction and the actual deferred-destruction boundary.
dofile('tests/compact.lua')
local resources=require('ui/resources')
local ui=require('ui')
local options=require('theme').apply(require('defaults'))
options.button_layout='playstation'
ui:setup(options,{})
local baseline=resources.snapshot()
for i=1,30 do
    ui:setup(options,{})
    local r=resources.snapshot()
    assert(r.text==baseline.text and r.image==baseline.image,
        'repeated crossbar setup retained previous slots, costs or labels')
end
local now,deletions=0,0
package.loaded.socket={gettime=function()return now end}
local geometry=require('ui_geometry').new()
geometry:configure_fade(true,1,1)
local raw={size=function()end,fit=function()end,alpha=function()end,show=function()end,hide=function()end,
    destroy=function()deletions=deletions+1 end}
local proxy=geometry:surface(raw,'image')
proxy:show();geometry:transition(false)
proxy:destroy();proxy:destroy()
assert(#geometry.retired==1 and deletions==0,'deferred object queued more than once')
now=2;geometry:tick()
assert(#geometry.retired==0 and deletions==1)
proxy:destroy();assert(deletions==1)
local raw2={size=function()end,fit=function()end,alpha=function()end,show=function()end,hide=function()end,
    destroy=function()deletions=deletions+1 end}
local p2=geometry:surface(raw2,'image')
geometry:set_opacity(1);p2:show();geometry:transition(false);p2:destroy()
geometry:dispose_surfaces();geometry:shutdown();p2:destroy()
assert(deletions==2 and #geometry.retired==0)
package.loaded.lists={};package.loaded.strings={}
L=function(t)return t or {}end
local chooser=require('environment_chooser')
chooser:setup(options)
baseline=resources.snapshot()
for i=1,20 do
    chooser:setup(options)
    local r=resources.snapshot()
    assert(r.text==baseline.text and r.image==baseline.image,'chooser setup retained prior labels')
end
print('30 crossbar rebuilds and 20 chooser rebuilds stayed bounded; deferred destruction, repeated disposal and shutdown released each object once.')

-- A set refresh prepares textures without revealing hidden banks or resetting
-- the fade. Test both layouts and record native texture writes for one slot.
local skillchains={get_skillchain_window=function()return 0,0 end}
local selected={active_bar=0}
local actions={
    basic={},
    other={hotbar_1={slot_1={type='ex',action='echo other',alias='Other',icon='other'}}},
    ['all-jobs-default']={hotbar_1={slot_1={type='ex',action='echo all',alias='All',icon='all'}}},
}
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
for _, compact in ipairs({false,true}) do
    options.is_compact=compact
    options.hotbar_number=5
    options.fade_enabled=true
    ui:setup(options,{})
    assert((ui.button_hints == nil) == compact, 'initial hint allocation ignored layout')
    local icon=ui.hotbars[1].slot_icon[1]
    local center=ui.geometry.surfaces[ui.hotbars[3].slot_background[1]]
    local raw=ui.geometry.surfaces[icon].object
    local set_path=raw.path
    local paths={}
    raw.path=function(self,path)
        paths[#paths+1]=path
        return set_path(self,path)
    end
    ui:load_player_hotbar(actions,{},'basic')
    assert(not icon:visible() and not center.draw_visible,'loading a set revealed a hidden bank')
    assert(ui:show(actions,'basic'))
    assert(not center.draw_visible,'show primed the unselected center bank')
    ui.public_visible=true
    ui.geometry:set_opacity(1)
    ui.geometry.fade.active=false
    ui.geometry.fade.value=1
    ui:check_recasts(actions,{},'basic',{},selected,skillchains,{},false,false,true)
    assert(icon:visible() and not center.draw_visible)
    assert(#paths==1 and paths[1]:match('/all%.png$'))
    ui:load_player_hotbar(actions,{},'other')
    assert(ui.public_visible and icon:visible(),'set refresh changed visibility')
    assert(#paths==2 and paths[2]:match('/other%.png$'),'slot changed through a temporary texture')
    ui:load_player_hotbar(actions,{},'basic')
    ui:load_player_hotbar(actions,{},'basic')
    assert(#paths==3 and paths[3]:match('/all%.png$'),'inherited icon was rewritten unnecessarily')
    local cost=ui.hotbars[1].slot_cost[1]
    local badge=ui.hotbars[1].slot_recast[1]
    local raw_badge=ui.geometry.surfaces[badge].object
    local raw_cost=ui.geometry.surfaces[cost].object
    local badge_hide, cost_show=raw_badge.hide,raw_cost.show
    local hides, shows=0,0
    raw_badge.hide=function(self) hides=hides+1; return badge_hide(self) end
    raw_cost.show=function(self) shows=shows+1; return cost_show(self) end
    for _=1,3 do
        ui:check_recasts(actions,{},'basic',{},selected,skillchains,{},true,false,true)
    end
    assert(badge:visible() and badge:path():match('/all%-jobs%-default%.png$'))
    assert(not cost:visible() and hides==0 and shows==0,'inherited badge or cost toggled during render')
    ui:check_recasts(actions,{},'basic',{},selected,skillchains,{},false,false,true)
    assert(not badge:visible() and cost:visible(),'regular overlay did not return')
    ui:hide()
    assert(ui.geometry.surfaces[icon].defer_visible and not center.defer_visible,
        'the center joined the side-bank fade')
end
ui.geometry:shutdown();ui.geometry:shutdown();resources.destroy_all()
assert(resources.snapshot().text==0 and resources.snapshot().image==0)
print('Full and compact set refreshes kept bank visibility and wrote only final slot textures.')
