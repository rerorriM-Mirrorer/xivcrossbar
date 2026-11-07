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
