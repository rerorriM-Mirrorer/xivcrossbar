-- A: native glyph measurements can arrive after the text is first drawn.
-- Keep the desired center and revisit it on render, without rewriting captions.
local ui_resources = require('ui/resources')
local trace = require('ui/render_trace')
local layout = {}
layout.__index = layout

function layout.new()
    return setmetatable({entries=setmetatable({}, {__mode='k'})}, layout)
end

function layout:center(text, x, y, max_width)
    self.entries[text] = {x=x, y=y, max_width=max_width}
    self:update_text(text, self.entries[text])
end

function layout:update_text(text, entry)
    if entry.resizing then entry.resizing=nil; return end
    local width = text:extents()
    if trace.enabled then trace.call(text,'caption-measure',entry.x,entry.y,entry.max_width,width) end
    if not width or width <= 0 then return end
    if entry.max_width and width > entry.max_width then
        local size = text:size()
        local fitted = math.max(8, math.floor(size * entry.max_width / width))
        if fitted < size then
            text:size(fitted)
            if trace.enabled then trace.event('caption-fit',text,size,fitted,width,entry.max_width) end
            entry.resizing=true
            return
        end
    end
    local x = entry.x - width / 2
    if x ~= entry.last_x then text:pos(x, entry.y); entry.last_x=x end
end

function layout:update()
    for text, entry in pairs(self.entries) do
        if ui_resources.is_disposed(text) or (text.visible and not text:visible()) then self.entries[text]=nil
        else self:update_text(text, entry) end
    end
end

return layout
