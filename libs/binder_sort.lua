local M={}
function M.summons(a,b)
    local a_spirit=tostring(a.name or ''):match(' Spirit$')~=nil
    local b_spirit=tostring(b.name or ''):match(' Spirit$')~=nil
    if a_spirit~=b_spirit then return not a_spirit end
    return a.id<b.id
end
return M
