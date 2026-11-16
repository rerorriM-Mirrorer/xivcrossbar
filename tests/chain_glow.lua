-- Chain glow maths (ui/chain_glow.lua), 2026-11-16.
package.path='./?.lua;'..package.path
local g=require('ui/chain_glow')
-- Magic Burst: element colour, breathing 140..230; quicker in the last 1.5 s.
local r,gg,b,a=g.burst('Fire',0,5)
assert(r==255 and gg==90 and b==40 and a==140)
assert(select(4,g.burst('Fire',.6,5))==230, 'peak of the 1.2 s breath')
assert(select(4,g.burst('Fire',.4,5))==208 and select(4,g.burst('Fire',.4,1))==140, 'quickens near the end')
for name,c in pairs(g.element_colors) do
    local r2,g2,b2=g.burst(name,0,5); assert(r2==c[1] and g2==c[2] and b2==c[3], name)
end
assert(g.element_colors.Lightning and g.element_colors.Dark, 'game element names')
-- Skillchain charging: white, brightening as the window approaches.
assert(select(4,g.charge(3,3))==60 and select(4,g.charge(0,3))==220 and select(4,g.charge(1.5,3))==140)
assert(select(1,g.charge(1,3))==255)
-- Window open: blue/white flicker with random arcs; fades out in the last 1.5 s.
local ar,ag,ab,aa=g.open(.1,5,function() return 0 end)
assert(ar==255 and ag==255 and ab==255 and aa==255, 'arc frame is pure white')
local lo,hi=255,0
for k=0,200 do
    local _,_,_,alpha=g.open(k/97,5,function() return .9 end)
    lo=math.min(lo,alpha); hi=math.max(hi,alpha)
end
assert(lo>=150-90*0.4-1 and hi<=240 and hi-lo>40, 'flicker range '..lo..'-'..hi)
local _,_,_,fading=g.open(0,.75,function() return 0 end)
assert(fading==128, 'arc fades with the window: '..tostring(fading))
local fr,fg,fb=g.open(0,5,function() return .9 end)
assert(fb==255 and fr<255, 'blue end of the flicker')
-- The library side: new helpers exist and only weaponskill skillchains charge.
local src=io.open('libs/skillchain/skillchains.lua'):read('*a')
assert(src:find('myself.get_skillchain_pending = function(id, resource)',1,true) and src:find('myself.get_burst_window = function()',1,true))
local ui_src=io.open('ui.lua'):read('*a')
assert(ui_src:find("if not menu_open and not availability_unavailable and crossbar_action then",1,true), 'no glows in the menu')
assert(ui_src:find("get_skillchain_pending(crossbar_action.id, 'weapon_skills')",1,true))
local main=io.open('xivcrossbar.lua'):read('*a')
assert(main:find("command == 'chainglow' or command == 'burstglow'",1,true) and main:find('ui:tick_chain_glows()',1,true))
print('chain glow: burst colours/breath, charge, flicker, arcs and fade passed')
