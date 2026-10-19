-- Actual UI indicators with mock Windower rendering. Inspect their final
-- shapes, shared fade/drag transform and flush two-color auto-attack join.
dofile('tests/compact.lua')
local ui = require('ui/crossbar')
local calls, creates = {}, 0
windower.prim = setmetatable({}, {__index=function(_,method)
    return function(name,...)
        local p = calls[name] or {}; calls[name] = p
        p[method] = {...}
        if method=='create' then creates=creates+1 end
    end
end})
windower.ffxi.get_mob_by_target = function() return {hpp=100} end
local theme = require('ui/theme').apply(require('libs/defaults'))
theme.button_layout = 'playstation'
ui:setup(theme,{})
local function shape(name,x,y,width,height)
    local m = ui.geometry.primitives[name]
    local sx,sy = ui.geometry:point(x,y)
    local s = ui.geometry.scale
    assert(m.x==x and m.y==y and m.width==width and m.height==height)
    for _,suffix in ipairs({'','_left_cap','_right_cap'}) do
        local p = calls[name..suffix]
        local pos,size = p.set_position,p.set_size
        assert(pos and size)
        assert(size[1]>=0 and size[2]>=0)
        assert(pos[1]>=sx-0.001 and pos[1]+size[1]<=sx+width*s+0.001)
        assert(pos[2]>=sy-0.001 and pos[2]+size[2]<=sy+height*s+0.001)
    end
end
local count=0
for _,scale in ipairs({.6,1,1.5}) do
    ui:set_scale(scale)
    ui:display_skillchain_indicator({},1.5,0)
    local m=ui.geometry.primitives.skillchain_indicator
    shape('skillchain_indicator',m.x,m.y,300,4)
    local cap=calls.skillchain_indicator_left_cap
    assert(cap.set_position[2]>calls.skillchain_indicator.set_position[2])
    ui:display_skillchain_indicator({},0,3.5)
    m=ui.geometry.primitives.skillchain_indicator
    shape('skillchain_indicator',m.x,m.y,300,10)

    gcd_active=true;gcd_kind='spell';gcd_duration=3;gcd_start_time=os.clock()
    ui:display_gcd_indicator()
    m=ui.geometry.primitives.gcd_indicator
    shape('gcd_indicator',m.x,m.y,m.width,6)

    ui.theme.aa_opacity=220;ui.autoattack:set_enabled(true)
    ui.autoattack:set_engaged(true);ui.autoattack.estimate=10
    ui.autoattack.last_swing_time=os.clock()-2
    ui:display_aa_indicator()
    local red=ui.geometry.primitives.aa_indicator_red
    local green=ui.geometry.primitives.aa_indicator_green
    assert(red.x+red.width==green.x,'auto-attack colors meet')
    assert(red.round_right==false and green.round_left==false,'no inset at internal join')
    shape('aa_indicator_red',red.x,red.y,red.width,6)
    shape('aa_indicator_green',green.x,green.y,green.width,6)
    local redBody=calls.aa_indicator_red
    local greenBody=calls.aa_indicator_green
    assert(math.abs(redBody.set_position[1]+redBody.set_size[1]-greenBody.set_position[1])<.001)

    local before=creates
    local oldX,oldY=ui.geometry.x,ui.geometry.y
    ui.geometry:set_origin(oldX+13,oldY-7,ui.geometry.screen_x+13,ui.geometry.screen_y-7,true)
    red=ui.geometry.primitives.aa_indicator_red
    shape('aa_indicator_red',red.x,red.y,red.width,6)
    ui.geometry:set_opacity(.5)
    for _,suffix in ipairs({'','_left_cap','_right_cap'}) do
        assert(calls['aa_indicator_red'..suffix].set_color[1]==110)
    end
    ui.geometry.deferring_hide=true
    local p=ui.geometry:prim()
    p.set_visibility('aa_indicator_red',false)
    assert(calls.aa_indicator_red_left_cap.set_visibility[1]==true)
    ui.geometry:set_opacity(0)
    for _,suffix in ipairs({'','_left_cap','_right_cap'}) do
        assert(calls['aa_indicator_red'..suffix].set_visibility[1]==false)
    end
    ui.geometry:set_opacity(1)
    ui:set_compact(not ui.is_compact)
    assert(creates==before,'no new primitives during fade/drag/compact changes')

    for _,width in ipairs({0,.5,1,2,3,600}) do
        p.set_rounding('gcd_indicator',true,true)
        p.set_position('gcd_indicator',20,30)
        p.set_size('gcd_indicator',width,6)
        p.set_visibility('gcd_indicator',true)
        shape('gcd_indicator',20,30,width,6)
        if width==0 then
            for _,suffix in ipairs({'','_left_cap','_right_cap'}) do
                assert(calls['gcd_indicator'..suffix].set_visibility[1]==false)
            end
        end
        count=count+1
    end
end
ui.geometry.deferring_hide=false
ui:set_autoattack_enabled(true)
ui.autoattack:set_engaged(true)
ui.theme.aa_opacity=220
ui:display_aa_indicator()
ui.geometry.deferring_hide=true
ui:set_autoattack_enabled(false)
for _,name in ipairs({'aa_indicator_red','aa_indicator_green','aa_indicator_bg'}) do
    assert(not ui.geometry.primitives[name].defer_visible)
    for _,suffix in ipairs({'','_left_cap','_right_cap'}) do
        assert(calls[name..suffix].set_visibility[1]==false,'disabled autoattack survived a closing fade')
    end
end
assert(gcd_active,'disabling swing estimate changed action lockout')
ui.geometry.deferring_hide=false
ui.theme.skillchain_window_opacity=0
ui:display_skillchain_indicator({},0,7)
for _,name in ipairs({'skillchain_indicator','skillchain_indicator_bg'}) do
    for _,suffix in ipairs({'','_left_cap','_right_cap'}) do
        assert(calls[name..suffix].set_visibility[1]==false,'disabled skillchain backing still visible')
    end
end
print(count..' narrow-bar cases plus actual UI indicator geometry, fades and flush-join checks passed.')
