local alive,created,calls={},0,0
local measurement_ready=true
local function object()
    local o={};alive[o]=true;created=created+1
    return setmetatable(o,{__index=function(_,key)return function(self,...)
        assert(alive[self],'disposed surface reused')
        calls=calls+1
        if key=='text' then self.last_text=(...) end
        if key=='font' then self.last_font=(...) end
        if key=='pos' or key=='size' then self['last_'..key]={...} end
        -- This layout fixture supplies an already-settled measurement. Deferred
        -- rendering is exercised with real resources in text_settle.lua.
        if key=='extents' or key=='measure_width' then return measurement_ready and 42 or nil,10 end
        if key=='destroy' then alive[self]=nil end
    end end})
end
local resources={text=object,image=object,clear=function(list)for _,o in ipairs(list)do o:destroy()end end}
local now=5;local settings={L1=require('libs/banks/legacy').defaults()}
local bank=require('libs/banks/legacy').new({settings=settings,clock=function()return now end})
local view=require('ui/bank_view').new({bank=bank,resources=resources,path='',settings=settings})
settings.Texts={Font='Arial',Size=9}
view:tick(true,960,540);assert(created==0,'hidden companion allocated surfaces')
bank:event('show');view:tick(true,960,540);local fixed=created
assert(fixed==42)
assert(view.title.last_font=='Arial' and view.title.last_size[1]==9)
assert(view.slots[1].alias.last_font=='Arial' and view.slots[1].alias.last_size[1]==9)
settings.CrossbarScale=1.25;settings.L1.FollowCrossbar=false;settings.L1.Scale=1
view:tick(true,960,540)
assert(view.slots[1].alias.last_size[1]==11,'bank text diverged from main text scale')
settings.CrossbarScale=nil;settings.L1.FollowCrossbar=true;view:tick(true,960,540)
assert(view.slots[1].background and view.slots[1].frame)
assert(view:bounds().width==290 and view:bounds().height==148)
-- Compare with actual main-bar coordinate functions, not a second formula.
local f=assert(io.open('ui/crossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function ui:get_slot_x(',1,true))
local b=assert(source:find('\n-----------------------------',a,true))
local main={pos_x=50,pos_y=100,slot_spacing=6,hotbar_spacing=56,is_compact=true,theme={}}
assert(load(source:sub(a,b-1),'actual main compact coordinates','t',setmetatable({ui=main},{__index=_G})))()
for i=1,8 do
    local first,slot=view.slots[1].background.last_pos,view.slots[i].background.last_pos
    assert(slot[1]-first[1]==main:get_slot_x(1,i)-main:get_slot_x(1,1))
    assert(slot[2]-first[2]==main:get_slot_y(1,i)-main:get_slot_y(1,1))
    assert(view.slots[i].icon.last_size[1]==40 and view.slots[i].icon.last_size[2]==40)
end
settings.CrossbarScale=.75;assert(view:bounds().width==290*.75)
settings.CrossbarScale=1
for _,res in ipairs({{960,540},{1280,720},{1600,900},{1920,1080},{2560,1440},{3840,2160}})do
    for _,scale in ipairs({.4,.8,1,2})do
        settings.CrossbarScale=scale;settings.L1.X=10000;settings.L1.Y=-500
        view:tick(true,res[1],res[2]);local b=view:bounds()
        assert(b.x>=0 and b.y>=0 and b.x+b.width<=res[1] and b.y+b.height<=res[2])
    end
end
for i=1,300 do
    view:tick(false,960,540);view:tick(true,960,540)
    assert(created==fixed,'per-frame surfaces allocated')
end
local idle=calls
view:tick(true,960,540);view:tick(true,960,540)
assert(calls==idle,'static companion repeats native draw calls')
bank:event('bank');view:tick(true,960,540);local before=calls
settings.L1.Slot1.Alias='New label';view:tick(true,960,540)
assert(calls>before,'alias edit did not invalidate render cache')
view:destroy();view:destroy();assert(next(alive)==nil)
measurement_ready=false
bank.held=true;view:tick(true,960,540);assert(created==fixed*2 and view.needs_measurement)
measurement_ready=true;view:tick(true,960,540);assert(not view.needs_measurement)
local settled=calls;view:tick(true,960,540);assert(calls==settled)
view:destroy();assert(next(alive)==nil)
print('L1 companion: actual main compact coordinates/40px icons, following scale, 42 fixed surfaces, 24 clamps, 300 reveal/hide cycles and teardown passed.')
-- Both new-bank panels reuse these actual compact coordinates and resources.
settings.CompanionBanks=require('libs/banks/banks').defaults();settings.CrossbarScale=1
local native_menu=false
local banks=require('libs/banks/banks').new({settings=settings,clock=function()return now end,
    context=function()return true,native_menu end,ordinary=function()end,execute=function()end})
require('tests/fixtures/bank_legacy')(banks)
local left=require('ui/bank_view').new({bank=banks:panel('Left'),resources=resources,path='',settings=settings})
local right=require('ui/bank_view').new({bank=banks:panel('Right'),resources=resources,path='',settings=settings})
local before=created
banks:edge(13,true);left:tick(true,960,540);right:tick(true,960,540)
assert(created==before+84 and left.slots[8].alias.last_text=='Case')
banks:edge(11,true);left:tick(true,960,540);assert(left.title.last_text=='L1 + L2  Available')
banks:edge(11,false);banks:edge(13,false);banks:edge(14,true)
left:tick(true,960,540);right:tick(true,960,540)
assert(created==before+84 and right:bounds().x==960-290)
assert(right.title.last_text=='R1  NPC' and right.slots[8].alias.last_text=='Open Trust')
banks:edge(12,true);right:tick(true,960,540)
assert(right.title.last_text=='R1 + R2  Available')
assert(right:bounds().x==960-290 and settings.CompanionBanks.RightPanel.Slot1==nil)
right:tick(false,960,540);assert(right.opacity==0)
banks:cancel();banks:edge(13,true);native_menu=true;banks:refresh()
left:tick(false,960,540);assert(left.opacity==0)
left:tick(true,960,540);assert(left.opacity==0,'default native-menu drawing guard lost')
settings.CompanionBanks.L1.ShowOnMenu=true
left:tick(true,960,540);assert(left.slots[8].alias.last_text=='Wave')
settings.CompanionBanks.L1.Visible=false
left:tick(true,960,540);assert(left.opacity==0 and left.visible==false)
left:destroy();right:destroy();assert(next(alive)==nil)
print('Actual new-bank panels: 84 fixed surfaces, shared side anchors, compact spacing/scale, right recovery, context labels and teardown passed.')
