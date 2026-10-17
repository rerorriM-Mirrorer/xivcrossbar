-- A: labels never redefine set keys, XML scope, switch actions or SMN return.
local M={}
function M.display(key,name)
    if key=='basic' and (name==nil or tostring(name):lower()=='basic') then return 'Main' end
    return name or key or ''
end
return M
