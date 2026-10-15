-- Real menu methods, with a native-style strong object registry. Hiding and
-- collectgarbage deliberately do not release objects; only destroy does.
local native = {}
local function object()
    local o = {values={}, shown=false}
    native[o] = true
    return setmetatable(o, {__index=function(_, key)
        return function(self, ...)
            assert(native[self], 'native object used after deletion: '..key)
            local args={...}
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
local prim_values,events={},{}
windower={addon_path='addon/',register_event=function(name,callback)
        events[name]=events[name] or {};table.insert(events[name],callback)
    end,send_command=function()end,
    get_windower_settings=function()return {ui_x_res=1280,ui_y_res=720}end,
    prim=setmetatable({}, {__index=function(_,key)return function(name,...)
        prim_values[name]=prim_values[name] or {};prim_values[name][key]={...}
    end end})}
local resources=require('ui/resources')
-- Metadata, malformed indexed values and unrelated objects must never receive
-- cleanup dispatch. Use no generic iterator when visiting List entries.
local one=resources.text({})
local unrelated={destroy=function()error('foreign object destroyed')end}
local malformed={one,73,unrelated,n=3}
local previous_ipairs=ipairs
ipairs=function()error('cleanup must not depend on global ipairs')end
resources.clear(malformed)
ipairs=previous_ipairs
assert(resources.is_disposed(one) and resources.snapshot().text==0)
resources.clear(malformed)
assert(resources.version=='cleanup5')
local binder=require('action_binder')
local options=require('theme').apply(require('defaults'))
options.button_layout='playstation';options.hotbar_number=6
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},function()end,function()end,
    options,function()return {'Basic'}end,0,0,1000,600)
local function totals()
    local r=resources.snapshot();local n=0
    for _ in pairs(native) do n=n+1 end
    assert(n==r.text+r.image, 'tracker differs from retained native objects')
    return n
end
local baseline=totals()
local peak
for i=1,200 do
    binder.custom_action_draft={name='Bow',alias='Bow',command='input /bow'}
    binder:display_edit_custom_action_review()
    local review_count=totals()
    peak=peak or review_count
    assert(review_count==peak, 'review objects accumulated across cycles')
    binder.custom_action_review_field='command'
    binder.text_entry_buffer='input /echo edited'
    binder:display_inline_custom_action_entry()
    binder:update_text_entry_display()
    binder.custom_action_review_field=nil
    binder:display_edit_custom_action_review()
    binder.action_name='Bow'
    binder:display_button_assigner()
    binder.active_crossbar=2;binder.button_a_pressed=true
    binder:show_pressed_buttons()
    binder:display_button_confirmer()
    binder:display_edit_custom_action_review()
    binder:hide();binder:reset_state()
    collectgarbage('collect')
    assert(totals()==baseline, 'closed menu retained temporary drawing objects')
end
-- Inline entry belongs to the previous review's hint list after editing ends.
-- Options must not dim that deleted caption, or restore one replaced mid-overlay.
binder.custom_action_draft={name='Bow',alias='Bow',command='input /bow'}
binder.custom_action_review_field='command';binder.text_entry_buffer='input /bow'
binder:display_inline_custom_action_entry()
local former_entry=binder.inline_entry_text
binder.custom_action_review_field=nil
binder:display_edit_custom_action_review()
assert(resources.is_disposed(former_entry))
binder:set_chooser_active(true)
binder:display_edit_custom_action_review()
binder:set_chooser_active(false)
binder:hide();binder:reset_state()
assert(totals()==baseline)
-- Legacy text entry previously created a caption and exit image per keystroke.
binder.text_entry_buffer='';binder.custom_action_review_field=nil
local typing_count
for i=1,150 do
    binder.text_entry_buffer=binder.text_entry_buffer..'a'
    binder:update_text_entry_display()
    typing_count=typing_count or totals()
    assert(totals()==typing_count, 'typing retained previous captions or exit images')
end
binder:hide();binder:reset_state()
assert(totals()==baseline)
-- Repeated footer redraw removes old image entries through List.remove so
-- the explicit n counter remains correct as replacement icons append.
binder:show_control_hints('Confirm','Go Back')
local footer_count=totals()
for i=1,100 do
    binder:show_control_hints('Confirm','Go Back')
    assert(binder.images.n==#binder.images and binder.images.n==3)
    assert(totals()==footer_count, 'footer redraw retained native objects')
end
binder:hide();binder:reset_state()
assert(totals()==baseline)
binder.custom_action_delete_target='Bow'
binder:display_delete_custom_action_confirm()
assert(prim_values.button_entry_bg.set_visibility[1]==false, 'delete screen shows text-entry bar')
binder:hide();binder:reset_state()
-- Screen reconstruction must replace the title, cursor and page artwork.
for i=1,10 do
    binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},function()end,function()end,
        options,function()return {'Basic'}end,0,0,1000,600)
    assert(totals()==baseline, 'setup retained prior menu objects')
end
resources.destroy_all();resources.destroy_all()
-- The root unload can dispose all registered images before this module's
-- later unload callback. Destruction must not hide native objects again.
for _,callback in ipairs(events.unload or {}) do callback() end
assert(totals()==0)
print('Upstream Windower Lists: 200 review/edit/bind/back cycles, 150 typed updates, 100 footer redraws and repeated setup retained no extra native-style objects.')
