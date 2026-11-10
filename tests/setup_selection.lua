local events, colors, visible = {}, {}, {}
local object = setmetatable({}, {__index=function(_, method)
    if method=='extents' then return function() return 300, 16 end end
    return function() end
end})
local shown
package.loaded.texts = {}
package.loaded['ui/resources'] = {
    clear=function() end, text=function() return object end, image=function() return object end,
}
package.loaded['ui/animated_cursor'] = {new=function()
    return {show=function() shown=true end, hide=function() shown=false end,
        pos=function() end, update=function() end, destroy=function() shown=false end}
end}
package.loaded.socket = {gettime=os.clock}
function L() return {append=function() end} end
function setup_image() end
windower = {
    addon_path='xivcrossbar/', register_event=function(name,fn) events[name]=fn end,
    get_windower_settings=function() return {ui_x_res=960, ui_y_res=540} end,
    prim=setmetatable({
        set_color=function(name,...) colors[name]={...} end,
        set_visibility=function(name,value) visible[name]=value end,
    }, {__index=function() return function() end end}),
}
local mapper = require('gamepad_mapper')
local chosen, finish, selections
local function configure()
    selections=0
    mapper:setup({},nil,{iconpack='default'},0,0,0,0,{select=function(profile, callback)
        chosen, finish = profile, callback
        selections=selections+1
    end})
end
local key, mouse = events.keyboard, events.mouse
local function tap(dik)
    assert(key(dik,true,0,false))
    assert(key(dik,false,0,false))
end
local function click(x,y)
    assert(mouse(1,x,y,0,false))
    assert(mouse(2,x,y,0,false))
end

configure()
-- A press that began in the game keeps its release when setup opens.
assert(not key(28,true,0,false))
assert(not mouse(1,5,5,0,false))
mapper:show(true)
assert(not key(28,false,0,false))
assert(not mouse(2,180,150,0,false))
assert(key(28,true,0,false))
assert(key(28,true,0,false) and selections==0, 'Held Enter advances only once')
assert(key(28,false,0,false) and shown)
tap(205); tap(208)
assert(mapper.profile_index==4 and colors.gamepad_profile_4[2]==101)

local first, second = mapper.profile_buttons[1], mapper.profile_buttons[2]
local x, y = first.x+12, first.y+12
assert(mouse(0,x,y,0,false) and mapper.profile_index==1)
assert(mouse(10,180,150,120,false))
assert(mouse(4,180,150,0,false) and mouse(5,5,5,0,false))
assert(not mouse(10,5,5,120,false))
assert(mouse(1,x,y,0,false) and mouse(2,5,5,0,false))
assert(selections==0)
assert(mouse(1,x,y,0,false) and mouse(2,second.x+12,y,0,false))
assert(selections==0)
assert(not mouse(1,x,y,0,true) and not mouse(2,x,y,0,false))
assert(selections==0)
assert(mouse(3,x,y,0,false) and mouse(2,x,y,0,false) and selections==0)
click(x,y)
assert(chosen=='ps5-directinput' and selections==1 and not shown)
tap(28)
assert(selections==1,'Enter is consumed while the reader starts')
finish(true,{connected='1'})
assert(shown and visible.gamepad_layout_selection)

tap(205)
assert(mapper.layout_index==2)
local xbox = mapper.controller_choices[3]
assert(mouse(0,xbox.x+10,xbox.y+10,0,false) and mapper.layout_index==3)
assert(key(28,true,0,false))
assert(mapper.button_layout=='xbox' and not shown and not visible.gamepad_layout_selection)
tap(200); tap(208)
assert(key(28,true,0,false) and key(28,false,0,false), 'Enter release stays with setup')
tap(28) -- remap prompt consumes Enter without treating it as a controller button

mapper:show(false)
tap(28)
finish(true,{connected='1'})
local gamecube = mapper.controller_choices[4]
click(gamecube.x+10,gamecube.y+10)
assert(mapper.button_layout=='gamecube')
mapper:show(false)
assert(mouse(1,x,y,0,false))
mapper:hide()
assert(mouse(2,5,5,0,false) and selections==2, 'Closing setup consumes the release without selection')
print('Setup selection: Enter, arrows, shared highlight, reader startup, blocked clicks and paired ownership passed.')
