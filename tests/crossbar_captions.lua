-- Actual load/clear methods and actual geometry text cache. Record every native
-- caption write so a transient blank cannot be hidden by the final assertion.
windower={ffxi={get_player=function()return {main_job_id=1}end},addon_path='addon/'}
local geometry=require('ui_geometry').new()
local writes={}
local function native(record)
    return setmetatable({caption=''}, {__index=function(_,key)
        return function(self,value)
            if key=='text' then
                if value==nil then return self.caption end
                self.caption=value;if record then writes[#writes+1]=value end
            elseif key=='extents' then return #self.caption*6,12 end
        end
    end})
end
local bar={};for _,key in ipairs({'slot_background','slot_frame','slot_icon','slot_element','slot_text','slot_cost','slot_warmup','slot_recast','slot_recast_text'})do
    bar[key]={[1]=geometry:surface(native(key=='slot_text' or key=='slot_cost'),key=='slot_text' and 'text' or 'image')}
end
local ui={theme={slot_opacity=150},hotbars={[1]=bar},
    disabled_slots={on_cooldown={},on_warmup={}},
    get_slot_x=function()return 10 end,get_slot_y=function()return 20 end}
local env=setmetatable({ui=ui,get_icon_pathbase=function()return 'icons' end,
    maybe_get_default_action=function()return nil end},{__index=_G})
local file=assert(io.open('ui.lua'));local source=file:read('*a');file:close()
local first=assert(source:find('function ui:load_action(',1,true))
local last=assert(source:find('-- Disabled Slots',first,true))
assert(load(source:sub(first,last-1),'actual caption replacement','t',env))()
local recast_first=assert(source:find('function ui:clear_recast(',1,true))
local recast_last=assert(source:find('-- calculate recast time',recast_first,true))
assert(load(source:sub(recast_first,recast_last-1),'actual recast clear','t',env))()
local function action(label)return {type='ex',action='input /echo test',alias=label}end
local function bind(value)ui:load_action({},'test',1,1,value,{mp=100},true)end
bind(action('Sack'));assert(#writes==2 and writes[2]=='Sack') -- cost then caption
writes={};for _=1,100 do bind(action('Sack'))end
assert(#writes==0,'unchanged set caption was invalidated')
bind(action('Wardrobe'));assert(#writes==1 and writes[1]=='Wardrobe','replacement passed through blank')
writes={};bind(nil);assert(#writes==1 and writes[1]=='','empty slot retained old caption')
bind(action('Sack'));writes={};ui:clear_slot(1,1)
assert(#writes==1 and writes[1]=='','explicit clear retained old caption')
print('Actual crossbar loader: repeated same-caption switches do not rewrite native text; replacements avoid blank; empty/explicit clears work.')
