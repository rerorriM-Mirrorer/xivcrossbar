-- Narrow Beta 1 text opacity regression: real public geometry, no FFXI hardware.
local now=100
package.loaded.socket={gettime=function()return now end}
local geometry=require('ui_geometry')
local defaults=require('defaults')
local theme=require('theme')
assert(defaults.Animation.TextFade==false,'New installs must retain endpoint text default')
assert(theme.apply(defaults).text_fade==false,'Theme must preserve default')
defaults.Animation.TextFade=true
assert(theme.apply(defaults).text_fade==true,'Theme must load saved opt-in')
defaults.Animation.TextFade=false
local raw={visible=false,calls={}}
local function method(key)
    return function(self,...)
        local args={...}
        self.calls[key]=(self.calls[key] or 0)+1
        if key=='show' then self.visible=true
        elseif key=='hide' then self.visible=false
        elseif key=='destroy' then self.destroyed=true
        elseif #args>0 then self[key..'_value']=args[1]
        else return self[key..'_value'] end
    end
end
for _,key in ipairs({'alpha','bg_alpha','stroke_alpha','show','hide','destroy','pos','size'}) do
    raw[key]=method(key)
end
windower={get_windower_settings=function()return {ui_x_res=960} end,prim={}}
local g=geometry.new()
g:configure_fade(true,.1,.5)
local text=g:surface(raw,'text')
text:alpha(200);text:bg_alpha(160);text:stroke_alpha(180)
g:set_opacity(.5)
text:show()
assert(not raw.visible,'Default text must wait for fully visible endpoint')
assert(raw.alpha_value==0 and raw.stroke_alpha_value==0 and raw.bg_alpha_value==0)
g:set_text_fade(true)
assert(raw.visible,'Opting in must reveal labels at intermediate opacity')
assert(raw.alpha_value==100 and raw.stroke_alpha_value==90 and raw.bg_alpha_value==80,
    'Text, stroke and background must share alpha curve')
g:set_opacity(1)
assert(raw.alpha_value==200 and raw.visible)
g:transition(false)
text:hide()
assert(g.deferring_hide,'Expected deferred fade-out')
g:set_opacity(.5)
assert(raw.visible and raw.alpha_value==100,'Text must stay present through fade-out')
g:set_opacity(0)
assert(not raw.visible,'Text must disappear at fade-out endpoint')
-- Compare switching off without a rebuild and legacy endpoint behavior.
g:transition(true)
g:set_opacity(.5)
text:show()
assert(raw.visible,'Opt-in text should show during fade-in')
g:set_text_fade(false)
assert(not raw.visible,'Turning option off should immediately restore endpoint-only labels')
g:set_opacity(1)
assert(raw.visible and raw.alpha_value==200)
-- No unexpected alpha changes for ordinary images.
local icon={calls={},alpha=method('alpha'),show=method('show'),hide=method('hide'),fit=method('fit')}
local image=g:surface(icon,'image')
image:alpha(200)
g:set_opacity(.5)
image:show()
assert(icon.alpha_value==100 and icon.visible,'Image fades must remain unchanged')
-- Command is a standalone toggle with persisted state, not a renderer reload.
local f=assert(io.open('xivcrossbar.lua','rb'))
local source=f:read('*a');f:close()
assert(source:find("if command == 'textfade'",1,true))
assert(source:find('ui.geometry:set_text_fade(enabled)',1,true))
assert(source:find('settings.Animation.TextFade = enabled',1,true))
assert(source:find('config.save(settings)',source:find("if command == 'textfade'",1,true),true))
print('Text fade: persisted opt-in/default, alpha+stroke+background, fade-in/out, live toggle and unchanged images passed.')
