-- A: a subtle vertical alpha gradient using the existing primitive API.
-- Keep the panel's top alpha; extra black strips darken only toward the bottom.
local M = {panels={}}
local count = 32
function M.create(prim, name)
    if M.panels[name] then M.set_visibility(prim,name,false);return end
    prim.create(name)
    local panel={strips={}}
    M.panels[name]=panel
    for i=1,count do
        panel.strips[i]=name..'_gradient_'..i
        prim.create(panel.strips[i])
        prim.set_visibility(panel.strips[i],false)
    end
end
function M.set_color(prim, name, alpha, red, green, blue)
    prim.set_color(name,alpha,red,green,blue)
    local panel=M.panels[name];if not panel then return end
    local bottom=alpha==215 and 235 or math.min(255,alpha+40)
    for i,id in ipairs(panel.strips) do
        local desired=alpha+(bottom-alpha)*(i-1)/(count-1)
        local overlay=alpha<255 and (desired-alpha)*255/(255-alpha) or 0
        prim.set_color(id,math.floor(overlay+.5),red,green,blue)
    end
end
local function position(prim, panel)
    if not panel.x or not panel.width then return end
    for i,id in ipairs(panel.strips) do
        local top=math.floor(panel.height*(i-1)/count+.5)
        local bottom=math.floor(panel.height*i/count+.5)
        prim.set_position(id,panel.x,panel.y+top)
        prim.set_size(id,panel.width,bottom-top)
    end
end
function M.set_position(prim,name,x,y)
    prim.set_position(name,x,y)
    local panel=M.panels[name];if not panel then return end
    panel.x,panel.y=x,y;position(prim,panel)
end
function M.set_size(prim,name,width,height)
    prim.set_size(name,width,height)
    local panel=M.panels[name];if not panel then return end
    panel.width,panel.height=width,height;position(prim,panel)
end
function M.set_visibility(prim,name,visible)
    prim.set_visibility(name,visible)
    local panel=M.panels[name];if not panel then return end
    for _,id in ipairs(panel.strips) do prim.set_visibility(id,visible) end
end
return M
