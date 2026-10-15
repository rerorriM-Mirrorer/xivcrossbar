local ui_resources = require('ui/resources')
-- A: six preloaded frames; four aligned layers restore the faint DAT alpha.
-- The brightest extracted pixels have alpha 102/255. Four full-strength layers
-- produce about 87% opacity there without changing the texture or its outline.
local images=require('images')
local cursor={}
local methods={};methods.__index=methods
function cursor.new(folder,options)
    options=options or {}
    local self=setmetatable({frames={},clock=options.clock or os.clock,
        fps=options.fps or 12,x=options.x or 0,y=options.y or 0,
        scale=options.scale or 1,shown=false,frame=nil},methods)
    assert(self.fps>0 and self.scale>0,'fps and scale must be positive')
    for i=1,6 do
        self.frames[i]={}
        for layer=1,4 do
            self.frames[i][layer]=ui_resources.image({pos={x=self.x,y=self.y},visible=false,
                size={width=32*self.scale,height=20*self.scale},
                color={alpha=255,red=255,green=255,blue=255},
                texture={path=folder..'/frames/cursor_'..string.format('%02d',i)..'.png',fit=true},
                draggable=false})
        end
    end
    return self
end
function methods:pos(x,y) self.x,self.y=x,y end
function methods:show()
    if not self.shown then self.started=self.clock();self.shown=true end
    self:update()
end
function methods:hide()
    self.shown=false;self.frame=nil
    for _,frame in ipairs(self.frames) do
        for _,part in ipairs(frame) do part:hide() end
    end
end
function methods:update()
    if not self.shown then return end
    local index=math.floor(math.max(0,self.clock()-self.started)*self.fps)%6+1
    if self.frame~=index then
        if self.frame then for _,part in ipairs(self.frames[self.frame]) do part:hide() end end
        self.frame=index
        for _,part in ipairs(self.frames[index]) do part:show() end
    end
    for _,part in ipairs(self.frames[index]) do
        part:pos(self.x,self.y);part:size(32*self.scale,20*self.scale)
    end
end
function methods:destroy()
    -- Deletion hides each image itself. Root cleanup may already have deleted
    -- the owned images before the selector's unload callback runs.
    self.shown=false;self.frame=nil
    for _,frame in ipairs(self.frames) do
        for _,part in ipairs(frame) do part:destroy() end
    end
    self.frames={}
end
return cursor
