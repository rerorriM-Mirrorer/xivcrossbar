-- Target picker order (2026-11-16). Mock preamble copied from menu_resources.lua.
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
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},function()end,function()end,
    options,function()return {'Basic'}end,0,0,1000,600)
local order=function(tt, at, stpc)
    local out={}
    for _,o in ipairs(binder.target_options_for(tt, at, stpc)) do out[#out+1]=o.id end
    return table.concat(out,',')
end
local WS, WHM, JA = 2, 4, 1
-- Self-only weaponskill: <me> first, <st> kept, no <t>/<stnpc>/<bt>/<stpc>.
assert(order({Self=true}, WS, true)=='SELF,SELECT_TARGET', order({Self=true}, WS, true))
assert(order({Self=true}, WS, false)=='SELF,SELECT_TARGET')
-- Ordinary weaponskill: <t> leads.
assert(order({Enemy=true}, WS, true)=='CURRENT_TARGET,SELECT_NPC,SELECT_TARGET,BATTLE_TARGET',
    order({Enemy=true}, WS, true))
-- Self-only ability/spell keeps previous behavior.
assert(order({Self=true}, JA, true)=='SELF,SELECT_PLAYER')
assert(order({Self=true}, JA, false)=='SELF')
-- Enemy spell that can also self-target: <t> before <me>.
assert(order({Self=true,Enemy=true}, WHM, true)=='CURRENT_TARGET,SELF,SELECT_NPC,SELECT_TARGET,BATTLE_TARGET')
-- Party spell without <t>: unchanged order.
assert(order({Self=true,Party=true,Ally=true,Player=true}, WHM, true)=='SELF,SELECT_PARTY,SELECT_ALLIANCE,SELECT_PLAYER')
assert(order({Corpse=true}, WHM, true)=='SELECT_PARTY,SELECT_ALLIANCE,SELECT_PLAYER')
-- Main menu title.
local src=io.open('action_binder.lua'):read('*a')
assert(src:find("self:set_title('X I V   C R O S S B A R', true)",1,true) and not src:find("'Select Action Type'",1,true))
assert(src:find('ws.targets',1,true), 'weaponskill picker must use resource targets')
print('target picker order: 8 checks passed')
