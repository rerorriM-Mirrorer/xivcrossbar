local now,allowed,menu=0,true,false
local bank=require('libs/banks/banks').new({settings={},clock=function()return now end,
    context=function()return allowed,menu end,ordinary=function()end,execute=function()end,save=function()end,say=function()end})
local panel=bank:panel('Left')
bank:edge(13,true);bank:edge(1,true)
assert(panel:feedback(4)==180 and panel:feedback(1)==0)
bank:edge(1,false);now=.03;assert(panel:feedback(4)==180,'fast tap was invisible')
now=.13;assert(panel:feedback(4)>0 and panel:feedback(4)<180)
now=.21;assert(panel:feedback(4)==0)
bank:edge(1,true);now=1;assert(panel:feedback(4)==72,'hold did not settle')
bank:edge(2,true);assert(panel:feedback(3)==180 and panel:feedback(4)==72)
bank:edge(1,false);now=1.07;assert(panel:feedback(4)==36,'release did not fade by elapsed time')
menu=true;bank:refresh();assert(panel:feedback(3)==0,'context left a held highlight')
bank:edge(2,false);bank:edge(2,true);assert(panel:feedback(3)==180)
bank:edge(13,false);assert(panel:feedback(3)==0,'shoulder release retained feedback')
bank:cancel();bank:command({'l2','enable'});bank:edge(13,true);bank:edge(11,true)
bank:edge(5,true);assert(panel:feedback(6)==180,'empty bank press was not acknowledged')
allowed=false;bank:refresh();assert(panel:feedback(6)==0)
-- Actual view: dynamic feedback progresses through an unchanged layout cache.
local objects={}
local function object()
    local o={visible=false,calls=0}
    for _,name in ipairs({'path','pos','size','alpha','font','color','stroke_width','stroke_alpha','stroke_color','bg_alpha','bg_visible','text'}) do
        o[name]=function(self,...)self.calls=self.calls+1;self[name..'_value']={...} end
    end
    function o:show()self.visible=true;self.calls=self.calls+1 end
    function o:hide()self.visible=false;self.calls=self.calls+1 end
    function o:measure_width()return 10 end
    function o:commit_measurement()end
    objects[#objects+1]=o;return o
end
package.loaded['ui/render_trace']={track=function()end}
local visible,feedback=true,180
local settings={X=10,Y=10,Scale=1,FollowCrossbar=false,Locked=true}
for i=1,8 do settings['Slot'..i]={Alias='Test'} end
local view=require('ui/bank_view').new({path='',settings={},bank={settings=function()return settings end,
    opacity=function()return visible and 1 or 0 end,mode=function()return 'l1' end,title=function()return 'L1' end,
    feedback=function(_,i)return i==4 and feedback or 0 end},resources={image=object,text=object,
    clear=function(list)for _,o in ipairs(list)do o.deleted=true end end}})
view:tick(true,1280,720);assert(#objects==50 and view.slots[4].feedback.visible)
local captions=view.title.calls;feedback=72;view:tick(true,1280,720)
assert(view.slots[4].feedback.alpha_value[1]==72 and view.title.calls==captions,'feedback rebuilt static text')
local calls=view.slots[4].feedback.calls;view:tick(true,1280,720);assert(view.slots[4].feedback.calls==calls)
feedback=0;view:tick(true,1280,720);assert(not view.slots[4].feedback.visible)
feedback=180;view:tick(true,1280,720);visible=false;view:tick(false,1280,720)
for _,o in ipairs(objects)do assert(not o.visible)end
view:destroy();for _,o in ipairs(objects)do assert(o.deleted)end
print('Bank feedback: fast taps, independent held slots, timed release, empty slots, layer/context/focus cleanup, actual cached view and fixed resource lifetime passed.')
