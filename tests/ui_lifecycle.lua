-- Complete UI reconstruction and the actual deferred-destruction boundary.
dofile('tests/compact.lua')
local resources=require('ui/resources')
local ui=require('ui')
local options=require('theme').apply(require('defaults'))
options.button_layout='playstation'
ui:setup(options,{})
local baseline=resources.snapshot()
for i=1,30 do
    ui:setup(options,{})
    local r=resources.snapshot()
    assert(r.text==baseline.text and r.image==baseline.image,
        'repeated crossbar setup retained previous slots, costs or labels')
end
local now,deletions=0,0
package.loaded.socket={gettime=function()return now end}
local geometry=require('ui_geometry').new()
geometry:configure_fade(true,1,1)
local raw={size=function()end,fit=function()end,alpha=function()end,show=function()end,hide=function()end,
    destroy=function()deletions=deletions+1 end}
local proxy=geometry:surface(raw,'image')
proxy:show();geometry:transition(false)
proxy:destroy();proxy:destroy()
assert(#geometry.retired==1 and deletions==0,'deferred object queued more than once')
now=2;geometry:tick()
assert(#geometry.retired==0 and deletions==1)
proxy:destroy();assert(deletions==1)
local raw2={size=function()end,fit=function()end,alpha=function()end,show=function()end,hide=function()end,
    destroy=function()deletions=deletions+1 end}
local p2=geometry:surface(raw2,'image')
geometry:set_opacity(1);p2:show();geometry:transition(false);p2:destroy()
geometry:dispose_surfaces();geometry:shutdown();p2:destroy()
assert(deletions==2 and #geometry.retired==0)
package.loaded.lists={};package.loaded.strings={}
L=function(t)return t or {}end
local chooser=require('environment_chooser')
chooser:setup(options)
baseline=resources.snapshot()
for i=1,20 do
    chooser:setup(options)
    local r=resources.snapshot()
    assert(r.text==baseline.text and r.image==baseline.image,'chooser setup retained prior labels')
end
ui.geometry:shutdown();ui.geometry:shutdown();resources.destroy_all()
assert(resources.snapshot().text==0 and resources.snapshot().image==0)
print('30 crossbar rebuilds and 20 chooser rebuilds stayed bounded; deferred destruction, repeated disposal and shutdown released each object once.')
