-- Replay delayed native widths through real resource, layout, geometry and L1
-- code. Alpha-zero measurement is simulated here; Windower must verify it live.
local measure=require('ui/text_measure')
local resources=require('ui/resources')
local natives={}
local width_by_caption={}
local function native(kind)
    local o={kind=kind,caption='',font_value='Verdana',size_value=12,pad_value=0,
        alpha_value=255,stroke_alpha_value=180,bg_alpha_value=0,right_value=false,
        bold_value=false,italic_value=false,stroke_width_value=1,shown=false,reads=0,events={}}
    natives[#natives+1]=o
    return setmetatable(o,{__index=function(_,key)
        return function(self,...)
            local n=select('#',...);local value=(...)
            if key=='extents' then
                self.reads=self.reads+1
                return width_by_caption[self.caption] or #self.caption*self.size_value*.5,14
            elseif key=='text' then
                if n==0 then return self.caption end
                self.events[#self.events+1]={'text',value,self.alpha_value}
                self.caption=value
            elseif key=='pos' then
                self.x,self.y=...
                self.events[#self.events+1]={'pos',self.x,self.y,self.alpha_value}
            elseif key=='visible' then return self.shown
            elseif key=='show' then self.shown=true
            elseif key=='hide' then self.shown=false
            elseif key=='destroy' then self.destroyed=true
            elseif n==0 then return self[key..'_value']
            else self[key..'_value']=value end
        end
    end})
end
texts={new=function()return native('text')end}
images={new=function()return native('image')end}
windower={get_windower_settings=function()return{ui_x_res=960,ui_y_res=540}end}
local layout=require('ui/text_layout').new()
local function caption(label)
    local t=resources.text({});local o=natives[#natives]
    t:font('Verdana');t:size(12);t:text(label);t:show()
    return t,o
end
local function frame(update)
    measure.begin_frame();update()
end
local function settle(t,x,y)
    local width=t:measure_width()
    if width~=nil then t:pos(x-width/2,y);t:commit_measurement() end
    return width
end
-- Trace frames 334/335: never display x=238 from an unavailable width.
local t,o=caption('Ctrl+Space');width_by_caption['Ctrl+Space']=0
layout:center(t,238,202)
assert(o.alpha_value==0 and o.stroke_alpha_value==0 and o.bg_alpha_value==0)
assert(o.reads==0,'accepted same-frame extents')
for _=1,10 do layout:update() end
assert(o.reads==0,'repeated getters substituted for rendered frames')
width_by_caption['Ctrl+Space']=73
frame(function()layout:update()end);assert(o.alpha_value==0)
frame(function()layout:update()end)
assert(o.x==201.5 and o.y==202 and o.alpha_value==255 and o.stroke_alpha_value==180)
for _,event in ipairs(o.events) do
    assert(not(event[1]=='pos' and event[2]==238 and event[4]>0),'visible zero-width placement')
end
-- Cache can position a new object without re-measuring a familiar caption.
local cached,co=caption('Ctrl+Space')
assert(settle(cached,238,202)==73 and co.reads==0 and co.x==201.5)
-- Trace's stale positive heading: 211 first, 416 after renderer update.
local h,ho=caption('Old title');width_by_caption['Old title']=211
layout:center(h,640,46)
frame(function()layout:update()end);frame(function()layout:update()end)
assert(ho.x==534.5 and ho.alpha_value==255)
width_by_caption['Enter Button Combo']=211
h:text('Enter Button Combo');layout:center(h,640,46)
assert(ho.alpha_value==0,'new title retained visible old-width positioning')
h:alpha(114);h:stroke_alpha(79);h:bg_alpha(20)
assert(h:alpha()==114 and ho.alpha_value==0 and ho.stroke_alpha_value==0 and ho.bg_alpha_value==0)
frame(function()layout:update()end);assert(ho.alpha_value==0)
width_by_caption['Enter Button Combo']=416
frame(function()layout:update()end);assert(ho.alpha_value==0)
frame(function()layout:update()end)
assert(ho.x==432 and ho.alpha_value==114 and ho.stroke_alpha_value==79 and ho.bg_alpha_value==20)
-- Font fitting invalidates the measurement while preserving requested opacity.
local fit,fo=caption('A long fitting title')
layout:center(fit,200,80,80)
for _=1,10 do frame(function()layout:update()end) end
assert(fo.size_value==8 and fo.alpha_value==255 and fo.x==160)
-- Hidden, disposed or superseded captions never reappear from deferred work.
h:text('Abandoned');h:hide();frame(function()layout:update()end)
assert(not ho.shown)
h:text('Plain reused title');h:show()
assert(ho.shown and ho.alpha_value==114,'hidden centering owner gated ordinary reuse')
fit:text('Disposed');fit:destroy();frame(function()layout:update()end)
assert(fo.destroyed)
local rapid,ro=caption('First');layout:center(rapid,100,20)
frame(function()layout:update()end)
rapid:text('Last');layout:center(rapid,100,20)
frame(function()layout:update()end);frame(function()layout:update()end)
assert(ro.caption=='Last' and ro.x==88 and ro.alpha_value==255)
-- Missing native measurements have a bounded readable fallback, then freeze.
local broken,bo=caption('Never measured');width_by_caption['Never measured']=0
layout:center(broken,120,30)
for _=1,measure.max_frames do frame(function()layout:update()end) end
assert(bo.x==120 and bo.alpha_value==255)
width_by_caption['Never measured']=200;frame(function()layout:update()end)
assert(bo.x==120,'fallback recentered visibly after timeout')
-- Caption/style keys distinguish actual pixel size; scale/drag and panel fades
-- remain geometry's responsibility, including fade changes during settling.
local geometry=require('ui_geometry').new('settle-test')
geometry:set_scale(2);geometry:set_opacity(.5)
local raw,go=caption('Scaled');local g=geometry:surface(raw,'text')
g:size(12);g:alpha(200);g:stroke_alpha(160);g:center(100,30);g:show()
frame(function()geometry:tick()end);assert(go.alpha_value==0)
geometry:set_opacity(.25)
frame(function()geometry:tick()end)
assert(go.x==164 and go.y==60 and go.alpha_value==50 and go.stroke_alpha_value==40)
local reads=go.reads
geometry:move_surface(g,10,0);geometry:tick()
assert(go.x==184 and go.reads==reads,'moving an unchanged label remeasured it')
g:size(10);assert(go.alpha_value==0)
frame(function()geometry:tick()end);frame(function()geometry:tick()end)
assert(go.x==190 and go.alpha_value==50)
geometry:shutdown()
-- Real L1 renderer: a positive old width cannot seal its static render cache.
local settings={L1=require('l1_bank').defaults()}
local bank=require('l1_bank').new({settings=settings,clock=function()return 1 end})
local view=require('l1_view').new({bank=bank,resources=resources,path='',settings=settings})
bank:event('show');view:tick(true,960,540)
for _=1,3 do frame(function()view:tick(true,960,540)end) end
assert(not view.needs_measurement)
bank:event('bank');settings.L1.Slot1.Alias='New label'
width_by_caption['New label']=18
view:tick(true,960,540);assert(view.needs_measurement)
local alias
for _,v in ipairs(natives) do if v.caption=='New label' then alias=v end end
assert(alias and alias.alpha_value==0)
frame(function()view:tick(true,960,540)end)
width_by_caption['New label']=66
frame(function()view:tick(true,960,540)end);assert(alias.alpha_value==0 and view.needs_measurement)
frame(function()view:tick(true,960,540)end)
assert(not view.needs_measurement and alias.alpha_value==255 and alias.x==settings.L1.X+30-33)
local count=alias.reads;view:tick(true,960,540);assert(alias.reads==count)
view:destroy()
-- Comparison command restores pending opacity, with idempotent saved settings.
local s={TextSettling=true};local saves=0
local function command(mode)return measure.command(s,mode,function()saves=saves+1 end,function()end)end
local pending,po=caption('Comparison');layout:center(pending,100,20);assert(po.alpha_value==0)
assert(command('off') and saves==1);layout:update();assert(po.alpha_value==255 and po.x==70)
assert(not command('off') and not command('status') and not command('bad') and saves==1)
assert(command('on') and saves==2)
layout:update();assert(po.alpha_value==0)
frame(function()layout:update()end);frame(function()layout:update()end);assert(po.alpha_value==255)
-- Cache eviction is bounded and never retains native objects or fallback widths.
measure.clear_cache()
for i=1,measure.capacity+1 do
    local state={}
    measure.width(state,'bounded:'..i,function()return 10 end)
    frame(function()measure.width(state,'bounded:'..i,function()return 10 end)end)
    frame(function()assert(measure.width(state,'bounded:'..i,function()return 10 end)==10)end)
end
assert(measure.width({},'bounded:1',function()return 10 end)==nil,'old cache entry retained beyond capacity')
resources.destroy_all();assert(resources.snapshot().text==0 and resources.snapshot().image==0)
print('Actual text settling: captured zero/stale-positive widths, distinct frames, cache reuse/eviction, requested alpha/stroke/background, fitting, superseded/hidden/disposed labels, bounded fallback, scaled/fading geometry, L1 cache and comparison commands passed.')
