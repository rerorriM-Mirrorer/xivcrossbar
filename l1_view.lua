-- A: fixed-size owned resources: no per-frame text/image allocation. Geometry
-- and dragging are independent of the main trigger bars and their autohide.
local bank=require('l1_bank')
local M={}
-- Centers use the main crossbar's 40px slots + 6px spacing. The second
-- diamond begins after a single empty center, rather than a wide panel gap.
local layout={{30,82},{76,128},{122,82},{76,36},{168,82},{214,128},{260,82},{214,36}}
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
        local theme=options.settings and options.settings.Theme or {}
        local slot_theme=tostring(theme.Slot or 'ffxiv'):lower()
        local frame_theme=tostring(theme.Frame or 'ffxiv'):lower()
        for i=1,8 do
            local background=options.resources.image({draggable=false})
            background:path(options.path..'themes/'..slot_theme..'/slot.png')
            background:hide();self.objects[#self.objects+1]=background
            local icon=options.resources.image({draggable=false})
            icon:path(options.path..'images/icons/iconpacks/default/ui/binding_icons/'..icons[i]..'.png')
            icon:hide();self.objects[#self.objects+1]=icon
            local frame=options.resources.image({draggable=false})
            frame:path(options.path..'themes/'..frame_theme..'/frame.png')
            frame:hide();self.objects[#self.objects+1]=frame
            self.slots[i]={background=background,icon=icon,frame=frame,number=text(8),alias=text(9)}
        end
    end
    function self:bounds()
        local d=options.bank:settings()
        return {x=d.X,y=d.Y,width=292*d.Scale,height=182*d.Scale}
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
        local d=options.bank:settings();local s,x,y=d.Scale,d.X,d.Y
        local alpha=math.floor(255*self.opacity+.5)
        local labels,parts={},{d.Mode,tostring(s),tostring(x),tostring(y),tostring(d.Locked),tostring(alpha)}
        for i=1,8 do
            local entry=d['Slot'..i]
            local label=d.Mode=='keyboard' and bank.references[i] or (entry.Alias~='' and entry.Alias or bank.buttons[i])
            if #label>10 then label=label:sub(1,9)..'~' end
            labels[i]=label;parts[#parts+1]=string.format('%q',label)
        end
        local key=table.concat(parts,'|')
        -- A persistent companion is mostly static. Do not repeat native
        -- position/size/font/show calls on every render of every client.
        -- Retry deferred native glyph measurements before allowing the cache.
        if self.visible and self.render_key==key and not self.needs_measurement then return end
        self.visible=true;self.render_key=key;self.needs_measurement=false
        self.bg:pos(x,y);self.bg:size(292*s,182*s);self.bg:alpha(math.floor(alpha*.72));self.bg:show()
        local title='L1  '..(d.Mode=='bank' and 'Action Bank' or 'Keyboard Shortcuts')..(d.Locked and '' or '  [drag]')
        self.title:text(title);self.title:size(math.max(6,math.floor(11*s+.5)));self.title:pos(x+10*s,y+8*s)
        self.title:alpha(alpha);self.title:stroke_alpha(math.floor(alpha*.7));self.title:show()
        for i,slot in ipairs(self.slots) do
            local px,py=layout[i][1],layout[i][2]
            slot.background:pos(x+(px-20)*s,y+py*s);slot.background:size(40*s,40*s)
            slot.background:alpha(math.floor(alpha*.6));slot.background:show()
            slot.icon:pos(x+(px-18)*s,y+(py+2)*s);slot.icon:size(36*s,36*s);slot.icon:alpha(alpha);slot.icon:show()
            slot.frame:pos(x+(px-20)*s,y+py*s);slot.frame:size(40*s,40*s);slot.frame:alpha(alpha);slot.frame:show()
            slot.number:text(tostring(i));slot.number:size(math.max(4,math.floor(8*s+.5)));slot.number:pos(x+(px-18)*s,y+(py+1)*s)
            local label=labels[i]
            local font_size=math.max(4,math.floor(9*s+.5))
            if slot.caption~=label then slot.alias:text(label);slot.caption=label end
            if slot.font_size~=font_size then slot.alias:size(font_size);slot.font_size=font_size end
            local extents=slot.alias:extents()
            local width_text=type(extents)=='number' and extents or 0
            if width_text<=0 then self.needs_measurement=true end
            slot.alias:pos(x+px*s-width_text/2,y+(py+40)*s)
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
