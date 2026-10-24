-- Exercise the complete renderer, not a duplicate of its bar-selection formula.
dofile('tests/compact.lua')
local ui=require('ui/crossbar')
ui.theme.hotbar_number=6
ui.autoattack:set_enabled(false)
ui.geometry.load_fade_state=nil;ui.geometry.startup_reveal=false
ui.geometry:configure_fade(false,0,0)
windower.ffxi.get_ability_recasts=function()return {}end
windower.ffxi.get_spell_recasts=function()return {}end
windower.ffxi.get_mob_by_target=function()return nil end
local hotbar={test={}}
local keys={'slot_background','slot_warmup','slot_icon','slot_frame','slot_recast','slot_element','slot_text','slot_cost','slot_recast_text'}
local expected,shown={},{}
for h=1,6 do
    hotbar.test['hotbar_'..h]={}
    for _,key in ipairs(keys)do for i=1,8 do
        local m=ui.geometry.surfaces[ui.hotbars[h][key][i]]
        local original=m.object.show
        m.object.show=function(self,...)
            assert(expected[h],'inactive bar was revealed: '..h..' '..key)
            shown[h]=true;return original(self,...)
        end
    end end
end
local tracker={get_skillchain_window=function()return 0,0 end}
for _,extras in ipairs({false,true}) do
    ui.AutoHideExtraBars=extras
    for active=0,6 do
        ui:hide();ui.geometry:set_opacity(0)
        expected={};shown={}
        if extras then
            if active<3 then expected[1]=true;expected[2]=true else expected[active]=true end
        elseif active==3 or active==4 then expected[active]=true
        else expected={[1]=true,[2]=true,[5]=true,[6]=true} end
        assert(ui:show(hotbar,'test'))
        assert(not next(shown),'show() bypassed slot selection')
        for h=1,6 do for _,key in ipairs(keys)do for i=1,8 do
            assert(not ui.geometry.surfaces[ui.hotbars[h][key][i]].visible,'reveal exposed a slot before selection')
        end end end
        ui:check_recasts(hotbar,{mp=100,tp=0},'test',{}, {active_bar=active},tracker,{},false,false)
        for h=1,6 do
            assert(not not shown[h]==not not expected[h],'selected bar missing')
            if not expected[h] then for _,key in ipairs(keys)do for i=1,8 do
                assert(not ui.geometry.surfaces[ui.hotbars[h][key][i]].visible)
            end end end
        end
    end
end
-- Actual status callback updates policy without directly showing/hiding UI.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find("windower.register_event('status change'",1,true))
local b=assert(source:find('-- Auto-attack swing timer: pause/unpause',a,true))
local callback
local env=setmetatable({xivcrossbar={ready=true,hide_hotbars=false,in_battle=false},
    ui={autoattack={enabled=false},show=function()error('status directly revealed UI')end,hide=function()error('status directly hid UI')end},
    player={set_is_in_battle=function()end},windower={register_event=function(_,fn)callback=fn end}}, {__index=_G})
assert(load(source:sub(a,b-1),'actual scene status callback','t',env))()
for _,status in ipairs({4,0,1,4,0}) do
    env.ui_dirty=false;env.ui.public_visible=true;callback(status)
    assert(env.ui_dirty and env.ui.public_visible==nil and env.xivcrossbar.hide_hotbars==(status==4))
end
print('Actual scene reveal: no intermediate slot/text/image reveal, fourteen bar selections with extra-bar policies, and status-only invalidation without direct show/hide passed.')
