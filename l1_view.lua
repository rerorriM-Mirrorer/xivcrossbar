-- A: fixed-size owned resources: no per-frame text/image allocation. Geometry
-- and dragging are independent of the main trigger bars and their autohide.
local bank=require('l1_bank')
local M={}
local layout={{36,100},{100,153},{164,100},{100,47},{218,100},{282,153},{346,100},{282,47}}
-- These bundled artwork suffixes use b=Square and x=Circle, not Xbox semantics.
local icons={'dpad_playstation_left','dpad_playstation_down','dpad_playstation_right','dpad_playstation_up',
    'facebuttons_playstation_b','facebuttons_playstation_a','facebuttons_playstation_x','facebuttons_playstation_y'}
function M.new(options)
    local self={options=options,objects={},slots={},opacity=0,allocated=false}
    local function text(size)
        local t=options.resources.text({flags={draggable=false}})
        t:bg_alpha(0);t:bg_visible(false)
        t:font('Verdana');t:size(size);t:color(228,231,240)
        t:stroke_width(1);t:stroke_alpha(180);t:hide()
        self.objects[#self.objects+1]=t;return t
    end
    function self:allocate()
        if self.allocated then return end
        self.allocated=true
        self.bg=options.resources.image({draggable=false})
        self.bg:path(options.path..'images/icons/iconpacks/default/ui/bar_bg_compact.png')
        self.bg:hide();self.objects[#self.objects+1]=self.bg
        self.title=text(11)
        for i=1,8 do
            local icon=options.resources.image({draggable=false})
            icon:path(options.path..'images/icons/iconpacks/default/ui/binding_icons/'..icons[i]..'.png')
            icon:hide();self.objects[#self.objects+1]=icon
            self.slots[i]={icon=icon,number=text(8),alias=text(10)}
        end
    end
    function self:bounds()
        local d=options.bank:settings()
        return {x=d.X,y=d.Y,width=382*d.Scale,height=205*d.Scale}
    end
    function self:clamp(width,height)
        local d=options.bank:settings();local b=self:bounds()
        d.X=math.max(0,math.min(d.X,math.max(0,width-b.width)))
        d.Y=math.max(0,math.min(d.Y,math.max(0,height-b.height)))
    end
    function self:tick(eligible,width,height)
        self.opacity=options.bank:opacity(eligible)
        if self.opacity<=0 and not self.allocated then return end
        self:allocate();self:clamp(width,height)
        if self.opacity<=0 then
            if self.visible~=false then for _,o in ipairs(self.objects) do o:hide() end end
            self.visible=false;return
        end
        self.visible=true
        local d=options.bank:settings();local s,x,y=d.Scale,d.X,d.Y
        local alpha=math.floor(255*self.opacity+.5)
        self.bg:pos(x,y);self.bg:size(382*s,205*s);self.bg:alpha(math.floor(alpha*.72));self.bg:show()
        local title='L1  '..(d.Mode=='bank' and 'Action Bank' or 'Keyboard Shortcuts')..(d.Locked and '' or '  [drag]')
        self.title:text(title);self.title:size(math.max(6,math.floor(11*s+.5)));self.title:pos(x+10*s,y+8*s)
        self.title:alpha(alpha);self.title:stroke_alpha(math.floor(alpha*.7));self.title:show()
        for i,slot in ipairs(self.slots) do
            local px,py=layout[i][1],layout[i][2]
            slot.icon:pos(x+(px-12)*s,y+py*s);slot.icon:size(24*s,24*s);slot.icon:alpha(alpha);slot.icon:show()
            slot.number:text(tostring(i));slot.number:size(math.max(4,math.floor(8*s+.5)));slot.number:pos(x+(px-24)*s,y+(py+2)*s)
            local entry=d['Slot'..i]
            local label=d.Mode=='keyboard' and bank.references[i] or (entry.Alias~='' and entry.Alias or bank.buttons[i])
            if #label>10 then label=label:sub(1,9)..'~' end
            slot.alias:text(label);slot.alias:size(math.max(4,math.floor(10*s+.5)))
            local extents=slot.alias:extents()
            local width_text=type(extents)=='number' and extents or 0
            slot.alias:pos(x+px*s-width_text/2,y+(py+27)*s)
            for _,t in ipairs({slot.number,slot.alias}) do
                t:alpha(alpha);t:stroke_alpha(math.floor(alpha*.7));t:show()
            end
        end
    end
    function self:destroy()
        options.resources.clear(self.objects)
        self.objects={};self.slots={};self.allocated=false;self.visible=false;self.opacity=0
    end
    return self
end
return M
