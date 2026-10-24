-- A: fixed-size owned resources: no per-frame text/image allocation. Geometry
-- and dragging are independent of the main trigger bars and their autohide.
local bank=require('libs/banks/legacy')
local M={}
-- Same 40px slots, horizontal slot spacing and half hotbar spacing as compact
-- XIVCrossbar. Coordinates describe columns/rows, not an independent layout.
local layout={{0,1},{1,2},{2,1},{1,0},{3,1},{4,2},{5,1},{4,0}}
-- These bundled artwork suffixes use b=Square and x=Circle, not Xbox semantics.
local icons={'dpad_playstation_left','dpad_playstation_down','dpad_playstation_right','dpad_playstation_up',
    'facebuttons_playstation_b','facebuttons_playstation_a','facebuttons_playstation_x','facebuttons_playstation_y'}
function M.new(options)
    local self={options=options,objects={},slots={},opacity=0,allocated=false}
    local function text()
        local t=options.resources.text({flags={draggable=false}})
        require('ui/render_trace').track(t,nil,options.owner or 'l1-companion','caption')
        t:bg_alpha(0);t:bg_visible(false)
        local typography=options.settings and options.settings.Texts or {}
        t:font(typography.Font or 'sans-serif');t:size(tonumber(typography.Size) or 7);t:color(228,231,240)
        t:stroke_width(1);t:stroke_alpha(180);t:hide()
        self.objects[#self.objects+1]=t;return t
    end
    function self:allocate()
        if self.allocated then return end
        self.allocated=true
        self.bg=options.resources.image({draggable=false})
        self.bg:path(options.path..'images/icons/default/ui/bar_bg_compact.png')
        self.bg:hide();self.objects[#self.objects+1]=self.bg
        self.title=text()
        local theme=options.settings and options.settings.Theme or {}
        local slot_theme=tostring(theme.Slot or 'ffxiv'):lower()
        local frame_theme=tostring(theme.Frame or 'ffxiv'):lower()
        for i=1,8 do
            local background=options.resources.image({draggable=false})
            background:path(options.path..'images/themes/'..slot_theme..'/slot.png')
            background:hide();self.objects[#self.objects+1]=background
            local icon=options.resources.image({draggable=false})
            icon:path(options.path..'images/icons/default/ui/binding_icons/'..icons[i]..'.png')
            icon:hide();self.objects[#self.objects+1]=icon
            local frame=options.resources.image({draggable=false})
            frame:path(options.path..'images/themes/'..frame_theme..'/frame.png')
            frame:hide();self.objects[#self.objects+1]=frame
            self.slots[i]={background=background,icon=icon,frame=frame,number=text(),alias=text()}
        end
        -- Allocate last so the existing white feedback sits above each slot.
        for _,slot in ipairs(self.slots) do
            slot.feedback=options.resources.image({draggable=false})
            slot.feedback:path(options.path..'images/icons/default/ui/feedback.png')
            slot.feedback:hide();self.objects[#self.objects+1]=slot.feedback
        end
    end
    function self:metrics()
        local d=options.bank:settings()
        local settings=options.settings or {};local style=settings.Style or {}
        local s=d.FollowCrossbar and (tonumber(settings.CrossbarScale) or 1) or d.Scale
        local horizontal=40+(tonumber(style.SlotSpacing) or 6)
        local vertical=(tonumber(style.HotbarSpacing) or 56)/2
        return s,horizontal,vertical,60+5*horizontal,92+2*vertical
    end
    function self:bounds()
        local d=options.bank:settings();local s,_,_,w,h=self:metrics()
        return {x=d.X,y=d.Y,width=w*s,height=h*s}
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
            for _,slot in ipairs(self.slots) do slot.feedback_alpha=nil end
            self.visible=false;return
        end
        local d=options.bank:settings();local s,horizontal,vertical,w,h=self:metrics();local x,y=d.X,d.Y
        local alpha=math.floor(255*self.opacity+.5)
        local mode=options.bank:mode()
        local typography=options.settings and options.settings.Texts or {}
        local font=typography.Font or 'sans-serif'
        local main_scale=tonumber(options.settings and options.settings.CrossbarScale) or 1
        local font_size=math.max(1,math.floor((tonumber(typography.Size) or 7)*main_scale+.5))
        local title=(options.bank.title and options.bank:title(mode) or (mode=='bank' and 'L1 + L2  Actions' or 'L1  Shortcuts'))..(d.Locked and '' or '  [drag]')
        local labels,parts={},{mode,tostring(s),tostring(x),tostring(y),tostring(d.Locked),tostring(alpha),tostring(horizontal),tostring(vertical),font,tostring(font_size),title}
        for i=1,8 do
            local entry=d['Slot'..i]
            local label=mode=='keyboard' and bank.references[i] or (entry.Alias~='' and entry.Alias or bank.buttons[i])
            if #label>10 then label=label:sub(1,9)..'~' end
            labels[i]=label;parts[#parts+1]=string.format('%q',label)
        end
        local key=table.concat(parts,'|')
        -- Feedback advances separately from the static caption/layout cache.
        local layout_changed=not self.visible or self.render_key~=key
        for i,slot in ipairs(self.slots) do
            local value=options.bank.feedback and options.bank:feedback(i) or 0
            local feedback_alpha=math.floor(value*self.opacity+.5)
            if layout_changed and feedback_alpha>0 or slot.feedback_alpha~=feedback_alpha then
                if feedback_alpha>0 then
                    local px,py=30+layout[i][1]*horizontal,36+layout[i][2]*vertical
                    slot.feedback:pos(x+(px-20)*s,y+py*s);slot.feedback:size(40*s,40*s)
                    slot.feedback:alpha(feedback_alpha);slot.feedback:show()
                else slot.feedback:hide() end
                slot.feedback_alpha=feedback_alpha
            end
        end
        -- A held companion is mostly static. Do not repeat native
        -- position/size/font/show calls on every render of every client.
        -- Retry deferred native glyph measurements before allowing the cache.
        if self.visible and self.render_key==key and not self.needs_measurement then return end
        self.visible=true;self.render_key=key;self.needs_measurement=false
        self.bg:pos(x,y);self.bg:size(w*s,h*s);self.bg:alpha(math.floor(alpha*.72));self.bg:show()
        self.title:text(title);self.title:font(font);self.title:size(font_size);self.title:pos(x+10*s,y+8*s)
        self.title:alpha(alpha);self.title:stroke_alpha(math.floor(alpha*.7));self.title:show()
        for i,slot in ipairs(self.slots) do
            local px,py=30+layout[i][1]*horizontal,36+layout[i][2]*vertical
            slot.background:pos(x+(px-20)*s,y+py*s);slot.background:size(40*s,40*s)
            slot.background:alpha(math.floor(alpha*.6));slot.background:show()
            slot.icon:pos(x+(px-20)*s,y+py*s);slot.icon:size(40*s,40*s);slot.icon:alpha(alpha);slot.icon:show()
            slot.frame:pos(x+(px-20)*s,y+py*s);slot.frame:size(40*s,40*s);slot.frame:alpha(alpha);slot.frame:show()
            slot.number:text(tostring(i));slot.number:font(font);slot.number:size(font_size);slot.number:pos(x+(px-18)*s,y+(py+1)*s)
            local label=labels[i]
            slot.alias:font(font)
            if slot.caption~=label then slot.alias:text(label);slot.caption=label end
            if slot.font_size~=font_size then slot.alias:size(font_size);slot.font_size=font_size end
            local width_text=slot.alias:measure_width()
            if width_text==nil then self.needs_measurement=true
            else
                slot.alias:pos(x+px*s-width_text/2,y+(py+40)*s)
                slot.alias:commit_measurement()
            end
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
