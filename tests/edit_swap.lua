-- Edit mode (2026-11-16): Swap screen, title styling and band.
-- Mock preamble copied from menu_resources.lua.
local native = {}
local function object()
    local o = {values={}, shown=false}
    native[o] = true
    return setmetatable(o, {__index=function(_, key)
        return function(self, ...)
            assert(native[self], 'native object used after deletion: '..key)
            local args={...}
            if key=='pos' and #args==2 then self.coords={args[1],args[2]} end
            if key=='destroy' then native[self]=nil
            elseif key=='show' then self.shown=true
            elseif key=='hide' then self.shown=false
            elseif key=='visible' and #args==0 then return self.shown
            elseif key=='extents' then return #(self.values.text or '')*6,14
            elseif #args==0 then return self.values[key] or (key=='alpha' and 255 or nil)
            else self.values[key]=args[1] end
        end
    end})
end
texts={new=object}; images={new=object}
package.loaded.texts=texts;package.loaded.images=images
for _,name in ipairs({'strings','tables','libs/mountroulette/mountroulette',
    'ui/item_icons','sw_zones','resources/crossbar_abilities','resources/crossbar_spells'}) do package.loaded[name]={} end
-- The upstream List has a numeric n member and range-checked assignments.
-- A plain array double hid the original cleanup regression.
_libs={tables=table}
class=function(value)
    local mt=type(value)=='table' and getmetatable(value)
    return mt and mt.__class or type(value)
end
dofile('tests/fixtures/windower_lists.lua')
package.loaded.lists=list
package.loaded['libs/kebab_casify']=function(s) return s:lower():gsub(' ','-') end
local player={hotbar_settings={active_environment='basic'},hotbar={basic={name='Basic'}},
    catalog_save_scope=function() return 'global' end}
package.loaded.player=player
package.loaded['text_input_guard']={update=function()end}
package.loaded.socket={gettime=function()return 1 end}
config={load=function(d)return d end}
package.preload['libs/settings_config']=function() return config end
local prim_values,events={},{}
local screen={ui_x_res=1280,ui_y_res=720}
windower={addon_path='addon/',register_event=function(name,callback)
        events[name]=events[name] or {};table.insert(events[name],callback)
    end,send_command=function()end,
    get_windower_settings=function()return screen end,
    prim=setmetatable({}, {__index=function(_,key)return function(name,...)
        prim_values[name]=prim_values[name] or {};prim_values[name][key]={...}
    end end})}
local binder=require('action_binder')
local options=require('theme').apply(require('defaults'))
options.button_layout='playstation';options.hotbar_number=6
local saved,bound={},{}
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},function(...)saved[#saved+1]={...}end,function()end,
    options,function()return {'Basic'}end,0,0,1000,600)



local chat={}
windower.add_to_chat=function(_,text) chat[#chat+1]=text end
windower.ffxi={get_player=function()return {main_job='WHM',sub_job='BLM',main_job_level=99,sub_job_level=49} end}
binder.on_bound=function(bank,slot) bound[#bound+1]={bank,slot} end
local swaps={}
binder.swap_binding=function(a,b) swaps[#swaps+1]={a,b}; return true end
binder.slot_icon_provider=function(bank,slot) return 'addon/icon_'..bank..'_'..slot..'.png' end
player.hotbar.basic.hotbar_2={slot_7={action='Cure'}}
player.hotbar.second={name='Second',hotbar_1={slot_3={action='Haste',alias='Haste!'}}}
local clock=100
local function tick(seconds) clock=clock+seconds; binder:tick_navigation(clock,true) end
tick(0)
local function choose_main(name)
    for col,rows in pairs(binder.selector.field_coords) do for row,o in pairs(rows) do
        if o.text==name then binder.selector.selected_row,binder.selector.selected_col=row,col end end end
    binder.selector:highlight_selection()
end
local function press(trigger, button)
    binder[trigger](binder,true); binder[button](binder,true); binder[button](binder,false); binder[trigger](binder,false)
end

-- Main menu title: spaced capitals, amber with a black outline, larger.
binder.is_hidden=false
binder.state=1
binder.theme_options.font_color_red=200
binder:set_title('Inner First')
assert(binder.title.values.color==200)
binder:display_action_type_selector()
assert(binder.title.values.text=='X I V   C R O S S B A R' and binder.title.values.size==20)
assert(binder.title.values.color==255 and binder.title.values.stroke_color==0, 'amber title, black outline')
binder:set_title('Inner Screen')
assert(binder.title.values.size==18 and binder.title.values.color==binder.theme_options.font_color_red, 'inner titles stay white')
binder:display_action_type_selector()
-- Title band: core + faded ends + amber line, fitted to the measured title.
local text_measure=require('ui/text_measure')
binder.title:show()
for _=1,12 do text_measure.begin_frame(); binder:update_destination_footer() end
assert(prim_values.xcb_title_band and prim_values.xcb_title_band.set_visibility[1]==true, 'band shown')
assert(prim_values.xcb_title_line.set_color[1]==230 and prim_values.xcb_title_line.set_color[2]==255, 'amber line')
local f1=prim_values.xcb_title_fade_1_1.set_color[1]
local f8=prim_values.xcb_title_fade_1_8.set_color[1]
assert(f1>f8 and f8>0, 'ends fade out')
binder.is_hidden=true; binder:update_destination_footer()
assert(prim_values.xcb_title_band.set_visibility[1]==false, 'band hides with the menu')
binder.is_hidden=false
-- Menu fade option deepens the bottom of the background.
local bg=require('ui/menu_background')
assert(bg.deep_fade==true, 'deeper fade is the default')
local main=io.open('xivcrossbar.lua'):read('*a')
assert(main:find("deep_fade=settings.MenuFade~=false",1,true), 'only an explicit off turns it off')
bg.deep_fade=true; bg.set_color(windower.prim,'dialog_bg',150,0,0,0)
local deep=prim_values.dialog_bg_gradient_32.set_color[1]
bg.deep_fade=false; bg.set_color(windower.prim,'dialog_bg',150,0,0,0)
assert(deep>prim_values.dialog_bg_gradient_32.set_color[1], 'deeper bottom with menufade on')

-- Swap is dummied out until a bound slot is selected.
binder:display_action_type_selector()
choose_main('Swap')
assert(binder.selector:get_selected_option().disabled)
binder:submit_selected_option()
assert(binder.state==1 and chat[#chat]:find('crossbar slot first'))
press('trigger_right','button_x') -- bank 2 slot 7 (Cure)
binder:update_destination_footer()
assert(not binder.selector:get_selected_option().disabled, 'Swap available on a bound slot')

-- Swap screen.
binder:submit_selected_option()
assert(binder.state==23)
assert(binder.title.values.text=='Swap Slot Bindings - \\cs(255,216,112)Cure\\cr', binder.title.values.text)
local view=binder.swap_view
assert(view.source_icon.values.path=='addon/icon_2_7.png', 'source icon')
assert(view.source_line.label.values.text=='BASIC:' and view.source_line.count==3)
assert(view.prompt:visible() and view.prompt.values.text=='Select set and crossbar slot to swap binds with:')
binder:update_destination_footer()
assert(not (binder.destination_footer_objects and binder.destination_footer_objects.label:visible()), 'edit footer hidden')
assert(binder:get_destination()==nil and binder:get_ghost()==nil, 'nothing highlighted before a second slot')
binder:submit_selected_option()
assert(#swaps==0 and chat[#chat]:find('swap with first'), 'Confirm waits for a second slot')

-- Choose the second slot: crossbar highlights it, the moved action breathes there.
press('trigger_right','button_x') -- the source itself: ignored
assert(binder.swap_target==nil)
press('trigger_left','dpad_up') -- bank 1 slot 4, empty
local t=binder.swap_target
assert(t and t.bank==1 and t.slot==4 and t.environment=='basic' and t.name==nil)
assert(not view.prompt:visible() and view.target_line.label.values.text=='BASIC:', 'target line replaces the prompt')
local d=binder:get_destination(); assert(d.bank==1 and d.slot==4 and d.ready)
local g,gb,gs=binder:get_ghost(); assert(g=='addon/icon_2_7.png' and gb==1 and gs==4)
press('trigger_left','dpad_up') -- again: cleared
assert(binder.swap_target==nil and view.prompt:visible())
-- Another set: the second slot can be anywhere.
player.hotbar_settings.active_environment='second'
press('trigger_left','dpad_right') -- bank 1 slot 3 on Second (Haste!)
t=binder.swap_target
assert(t.environment=='second' and t.name=='Haste!' and view.target_icon.values.path=='addon/icon_1_3.png')
player.hotbar_settings.active_environment='basic'
assert(binder:get_destination()==nil, 'not highlighted while another set is shown')
player.hotbar_settings.active_environment='second'
-- Circle clears the second slot first, then leaves.
binder:go_back(); assert(binder.state==23 and binder.swap_target==nil)
press('trigger_left','dpad_right')
-- Confirm: swap, flash, hold, main menu; the selection follows the action.
binder:submit_selected_option()
assert(#swaps==1 and swaps[1][1].environment=='basic' and swaps[1][1].bank==2 and swaps[1][1].slot==7)
assert(swaps[1][2].environment=='second' and swaps[1][2].bank==1 and swaps[1][2].slot==3)
assert(binder.bind_hold and view.flash:visible() and #bound>=1)
tick(.2); assert(view.flash.values.alpha<230 and view.flash.values.alpha>0, 'flash fades')
tick(.3)
assert(binder.state==1 and binder.destination.bank==1 and binder.destination.slot==3)
-- Esc / Enter reach the Swap screen too.
binder.state=23; binder.selector.is_showing=false
assert(binder:is_keyboard_review())
binder.state=1
-- An empty first slot works (it moves the other slot's action here); two
-- empty slots dummy out Confirm.
binder:display_action_type_selector()
press('trigger_left','dpad_left') -- bank 1 slot 1, empty on Second
binder:update_destination_footer()
choose_main('Swap')
assert(not binder.selector:get_selected_option().disabled, 'Swap available on an empty selected slot')
binder:submit_selected_option()
assert(binder.state==23 and binder.title.values.text:find('(empty)',1,true))
assert(binder.confirm_hint and binder.confirm_hint.caption.values.alpha==80, 'Confirm dummied out with no second slot')
press('trigger_left','button_b') -- bank 1 slot 5, empty too
assert(binder.swap_target and not binder:can_confirm_swap() and binder.confirm_hint.caption.values.alpha==80)
assert(not binder:is_bind_ready() and not binder:get_destination().ready, 'two empty slots are not swappable')
local before=#swaps
binder:submit_selected_option()
assert(#swaps==before and chat[#chat]:find('Both slots are empty'))
press('trigger_left','button_b') -- clear
press('trigger_left','dpad_right') -- bank 1 slot 3 (Cure on Second)
assert(binder:can_confirm_swap() and binder.confirm_hint.caption.values.alpha==255, 'Confirm available again')
binder:submit_selected_option()
assert(#swaps==before+1, 'an empty slot swaps with a bound one (a move)')
tick(.5)
assert(binder.state==1)

-- Circle with no second slot leaves Swap.
player.hotbar.second.hotbar_1.slot_3={action='Cure'}
binder:display_action_type_selector(); choose_main('Swap'); binder:update_destination_footer()
binder:submit_selected_option(); assert(binder.state==23)
binder:go_back(); assert(binder.state==1)
-- Page turning: only a quick, clean tap turns the page.
local spells=L{}
for i=1,60 do spells:append({id=i,name='Spell '..i,icon='images/s.png',data={target_type={Self=true}}}) end
binder.display_action_selector=function(self) self.selector:display_options(spells) end
binder.state,binder.action_type=2,4
binder.selector:set_page(1); binder:display_action_selector()
binder:trigger_right(true); tick(.1); binder:trigger_right(false)
assert(binder.selector.current_page==2, 'quick tap turns the page')
binder:trigger_right(true); tick(.4); binder:trigger_right(false)
assert(binder.selector.current_page==2, 'a held trigger does not turn the page')
binder:trigger_left(true); binder:button_a(true); binder:button_a(false); tick(.05); binder:trigger_left(false)
assert(binder.selector.current_page==2, 'a trigger used for a slot does not turn the page')
binder:trigger_left(true); tick(.05); binder:trigger_left(false)
assert(binder.selector.current_page==1)
print('Swap screen, title style, title band and menu fade: passed')
