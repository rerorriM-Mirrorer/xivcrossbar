-- Beta 1: native text may report stale extents for several draw frames.
-- Exercise the actual shared measurement logic and the public geometry/resource
-- wrappers, including fade-alpha preservation, without a Windower process.
local measure=require('ui/text_measure')
measure.clear_cache()
measure.frame=0;measure.enabled=true
local state,reads={},0
local function stale()
    reads=reads+1
    return reads==1 and 75 or 40
end
local width,phase=measure.width(state,'caption|font',stale,false)
assert(width==nil and phase=='pending' and reads==0,'new caption must wait until next frame')
for i=1,2 do
    measure.begin_frame()
    width,phase=measure.width(state,'caption|font',stale,false)
    assert(width==nil and phase=='pending','stale/single width must not be shown')
end
measure.begin_frame()
width,phase=measure.width(state,'caption|font',stale,false)
assert(width==40 and phase=='ready','two matching frame-separated widths should settle')
local read_again=false
local cached={}
width,phase=measure.width(cached,'caption|font',function()
    read_again=true;return 7
end,false)
assert(width==40 and phase=='ready' and not read_again,'previously verified width should be reused')
local never={}
measure.width(never,'never-settles',function()return nil end,false)
for i=1,8 do
    measure.begin_frame()
    width,phase=measure.width(never,'never-settles',function() return nil end,false)
end
assert(width==0 and phase=='fallback','bounded fallback must eventually release a caption')
local original_frame=measure.frame
local raw_objects={}
local function native()
    local o={values={alpha=255,bg_alpha=0,stroke_alpha=255,size=12,
        text='',font='sans-serif',stroke_width=2},visible=false,destroyed=false,reads=0}
    raw_objects[#raw_objects+1]=o
    return setmetatable(o,{__index=function(_,key)
        return function(self,...)
            local args={...}
            if key=='extents' then
                self.reads=self.reads+1
                return self.reads==1 and 70 or 50,12
            elseif key=='show' then self.visible=true
            elseif key=='hide' then self.visible=false
            elseif key=='visible' then if #args>0 then self.visible=args[1] else return self.visible end
            elseif key=='destroy' then self.destroyed=true
            elseif #args==0 then return self.values[key]
            else self.values[key]=args[1] end
        end
    end})
end
texts={new=native};images={new=native}
package.loaded.socket={gettime=function()return 10 end}
windower={get_windower_settings=function()return {ui_x_res=1280} end,prim={}}
local resources=require('ui/resources')
local geom=require('ui_geometry').new()
geom:configure_fade(true,.1,.5)
geom:set_text_fade(true)
geom:set_opacity(.5)
local proxy=resources.text({})
local caption=geom:surface(proxy,'text')
caption:text('Test');caption:alpha(200);caption:stroke_alpha(180)
caption:bg_alpha(160);caption:show()
caption:center(100,20)
local raw=raw_objects[1]
assert(raw.values.alpha==0 and raw.values.stroke_alpha==0,
    'Pending centered caption must suppress glyph and stroke despite active fade')
measure.begin_frame();geom:tick()
assert(raw.values.alpha==0,'Stale width must remain invisible')
measure.begin_frame();geom:tick()
assert(raw.values.alpha==0,'First good width must still wait')
measure.begin_frame();geom:tick()
assert(raw.values.alpha==100 and raw.values.stroke_alpha==90 and raw.values.bg_alpha==80,
    'Settled caption must restore requested opacity at current fade')
local x,y=caption:pos()
assert(x==75 and y==20,'Caption should use settled 50px width to center at 100')
caption:text('Changed')
assert(raw.values.alpha==0,'New text must be hidden before new extents are sampled')
measure.begin_frame();geom:tick()
assert(raw.values.alpha==0)
measure.begin_frame();geom:tick()
assert(raw.values.alpha==100,'Updated width should settle without losing fade opacity')
geom:set_opacity(1)
assert(raw.values.alpha==200 and raw.values.stroke_alpha==180)
caption:hide()
assert(not raw.visible and not raw.destroyed,'Hiding must not destroy caption')
caption:destroy()
assert(raw.destroyed,'Normal resource ownership must remain intact')
measure.frame=original_frame
print('Text settling: stale width wait, two-frame confirmation, reuse, fallback, pending transparency, fade restore and cleanup passed.')
