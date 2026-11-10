dofile('tests/compact.lua')
local now, remaining = 0, 0
package.loaded.socket = {gettime=function() return now end}
windower.ffxi.get_spell_recasts=function() return {[24]=remaining} end
package.loaded['resources/crossbar_spells'].Cure={id=24,recast_id=24}
local options = require('theme').apply(require('defaults'))
options.button_layout='playstation'
options.fade_enabled=false
options.recast_flash_enabled=true
local ui = require('ui')
ui:setup(options,{})
ui.geometry:set_opacity(1)
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
local actions={basic={hotbar_1={
    slot_1={type='ma',action='Cure',source_environment='basic'},
    slot_2={type='ma',action='Cure',source_environment='basic'},
}}}
local skillchains={get_skillchain_window=function() return 0,0 end,
    get_skillchain_result=function() end}
local function render(active,menu)
    ui:check_recasts(actions,{mp=20,tp=0},'basic',{}, {active_bar=active or 1},
        skillchains,{},false,false,menu)
end
render()
assert(not next(ui.recast_flash_views),'already-ready slots must not flash')
remaining=60;render()
assert(ui.recast_flash_views[1]:alpha()==0 and not ui.recast_flash_views[1]:visible(),
    'First cooldown must prime the glow while hidden')
remaining=0;render()
local view, other=ui.recast_flash_views[1],ui.recast_flash_views[2]
assert(view:visible() and other:visible() and view:alpha()==156)
local surface=ui.geometry.surfaces[view]
assert(surface.bank==ui.geometry.banks[1])
assert(surface.path:find('images/assets/recast-glow.png',1,true))
assert(surface.width==48 and surface.height==48)
assert(surface.x==ui:get_slot_x(1,1)-4 and surface.y==ui:get_slot_y(1,1)-4)
now=.075;ui:tick_recast_flashes();assert(view:alpha()==39)
now=.11;ui:tick_recast_flashes();assert(view:visible() and view:alpha()<39)
now=.16;ui:tick_recast_flashes();render();assert(not view:visible(),'steady zero must not replay the flash')
remaining=60;render()
remaining=nil;render()
remaining=0;render();assert(not view:visible(),'missing recast is not a zero sample')
remaining=60;render()
actions.basic.hotbar_1.slot_1={type='ma',action='Cure',source_environment='basic'}
remaining=0;render();assert(not view:visible(),'new binding must acquire its own cooldown sample')
remaining=60;render()
remaining=0;render(3);render();assert(not view:visible(),'hidden bank must drop the cooldown sample')
remaining=60;render()
remaining=0;render(1,true);render();assert(not view:visible(),'menus must drop the cooldown sample')
remaining=60;render()
remaining=0;render();assert(view:visible())
ui:hide();assert(not view:visible())
print('Recast flash: observed expiry, simultaneous slots, fast fade and reset rules passed.')

-- Moogle has a native spell icon, but no custom Trust portrait path.
local current_trust
windower.ffxi.get_party=function() return {p1=current_trust} end
windower.ffxi.get_spells=function() return {[700]=true} end
file={new=function() return {exists=function() return false end} end}
package.loaded['resources/crossbar_spells'].Moogle={
    id=700,en='Moogle',category='trust',recast_id=24,
    default_icon='/images/icons/spells/moogle.png',custom_icon='trust/moogle.png',
}
local summon={type='ma',action='Moogle',alias='Moogle',source_environment='basic'}
actions.basic.hotbar_1.slot_1=summon
actions.basic.hotbar_1.slot_2=nil
ui:load_player_hotbar(actions,{mp=20,tp=0},'basic')
local bar=ui.hotbars[1]
local portrait=bar.slot_icon[1]:path()
local timer=bar.slot_recast_text[1]
assert(portrait:find('/images/icons/spells/moogle.png',1,true))
current_trust={mob={name='Moogle',spawn_type=14}}
render()
assert(bar.slot_icon[1]:path()==portrait and bar.slot_text[1]:text()=='Return')
local r,g,b=timer:color()
assert(timer:text()=='X' and timer:visible() and r==255 and g==149 and b==151)
render()
assert(timer:text()=='X' and timer:visible(),'Return marker disappeared on a steady party snapshot')
current_trust=nil
render()
assert(bar.slot_icon[1]:path()==portrait and bar.slot_text[1]:text()=='Moogle')
assert(timer:text()=='' and not timer:visible() and summon.action=='Moogle')

summon.icon='custom/moogle'
ui:load_player_hotbar(actions,{mp=20,tp=0},'basic')
portrait=bar.slot_icon[1]:path()
current_trust={mob={name='Moogle',spawn_type=14}}
render()
assert(portrait:find('/custom/moogle.png',1,true) and bar.slot_icon[1]:path()==portrait)
assert(timer:text()=='X')
print('Trust Return keeps native and custom portraits, shows the pink timer X, and restores the summon after party removal.')
