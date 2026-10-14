-- Actual geometry: compare both text modes during open, close, reversal and
-- startup. Hidden slot labels must never be resurrected by either mode.
local now=0
package.loaded.socket={gettime=function() return now end}
local function object()
    return {visible=false,
        fit=function() end,
        size=function() end,
        alpha=function(self,n) self.a=n end,
        bg_alpha=function(self,n) self.bg=n end,
        stroke_alpha=function(self,n) self.stroke=n end,
        show=function(self) self.visible=true end,
        hide=function(self) self.visible=false end}
end
local geometry=require('ui_geometry')
for _,together in ipairs({false,true}) do
    now=0
    local g=geometry.new()
    g:configure_fade(true,1,1)
    g:set_text_fade(together)
    g:set_opacity(0)
    local raw,image,hidden=object(),object(),object()
    local text=g:surface(raw,'text')
    local icon=g:surface(image,'image')
    g:surface(hidden,'text')
    text:alpha(200);text:bg_alpha(100);text:stroke_alpha(180)
    text:show();icon:show();g:transition(true)
    now=.5;g:tick()
    assert(image.a==128)
    assert(raw.visible==together and raw.a==(together and 100 or 0))
    assert(raw.bg==(together and 50 or 0) and raw.stroke==(together and 90 or 0))
    assert(not hidden.visible)
    now=1;g:tick()
    assert(raw.visible and raw.a==200 and raw.stroke==180)
    g:transition(false);text:hide();icon:hide()
    now=1.5;g:tick()
    assert(raw.visible==together and raw.a==(together and 100 or 0))
    g:transition(true);text:show();icon:show()
    now=2;g:tick()
    assert(raw.visible==together)
    now=2.5;g:tick();assert(raw.visible and raw.a==200)
    g:transition(false);text:hide();icon:hide()
    now=3.5;g:tick();assert(not raw.visible and not image.visible)
    g:configure_fade(false,1,1,2,{claimed=false})
    g:set_opacity(0);g:transition(true);text:show();icon:show()
    now=4.5;g:tick();assert(g.opacity==.5)
    assert(raw.visible==together)
    g:set_text_fade(not together)
    assert(raw.visible~=together and not hidden.visible)
    now=5.5;g:tick();assert(raw.visible)
    g:transition(false);text:hide();icon:hide()
    assert(not raw.visible)
end
print('Text fade and endpoint visibility: open/close, reversal, startup, live switching and hidden-label checks passed.')
