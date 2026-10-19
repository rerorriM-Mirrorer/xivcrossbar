-- One resolver for shipped artwork and saved/custom paths from older layouts.
-- Existing legacy files take priority so a merge update cannot erase personal
-- artwork. New installs use only the canonical images/ tree.
local M={}
local fallback={abilities=true,spells=true,weapons=true,elements=true,skillchain=true}
local cache={}
local function root() return (windower and windower.addon_path or ''):gsub('\\','/'):gsub('/+$','')..'/' end
local function exists(path)
    if windower and windower.file_exists then return windower.file_exists(path) end
    local f=io.open(path,'rb');if f then f:close();return true end;return false
end
function M.invalidate() cache={} end
function M.canonical(relative)
    local p=relative:gsub('\\','/'):gsub('^/+','')
    p=p:gsub('^themes/','images/themes/'):gsub('^images/icons/iconpacks/','images/icons/')
    local category,tail=p:match('^images/icons/([^/]+)/(.*)$')
    if fallback[category] then p='images/icons/default/fallback/'..category..'/'..tail end
    return p
end
function M.candidates(relative)
    local p=M.canonical(relative);local candidates={}
    local function add(s) for _,v in ipairs(candidates) do if v==s then return end end;candidates[#candidates+1]=s end
    local theme=p:match('^images/themes/(.*)$')
    local pack,tail=p:match('^images/icons/([^/]+)/(.*)$')
    if theme or pack then add('images/overrides/'..p:sub(8)) end
    if theme then add('themes/'..theme)
    elseif pack then
        local category,rest=tail:match('^fallback/([^/]+)/(.*)$')
        if pack=='default' and fallback[category] then add('images/icons/'..category..'/'..rest)
        else add('images/icons/iconpacks/'..pack..'/'..tail) end
    end
    add(p)
    if pack and pack~='default' then
        add('images/overrides/icons/default/'..tail)
        add('images/icons/iconpacks/default/'..tail);add('images/icons/default/'..tail)
    end
    return candidates
end
function M.resolve(path)
    if type(path)~='string' then return path end
    local base=root();local normalized=path:gsub('\\','/')
    local relative
    if normalized:sub(1,#base):lower()==base:lower() then relative=normalized:sub(#base+1):gsub('^/+','')
    elseif normalized:match('^/?images/') or normalized:match('^/?themes/') then relative=normalized:gsub('^/','')
    else return path end
    local key=base..relative
    if cache[key] then return cache[key] end
    for _,candidate in ipairs(M.candidates(relative)) do
        local full=base..candidate
        if exists(full) then cache[key]=full;return full end
    end
    return base..M.canonical(relative)
end
function M.exists(path) return exists(M.resolve(path)) end
function M.pack_roots(pack)
    -- Scan both locations when updating by merge. The selector deduplicates
    -- stems; the resolver applies the same legacy override preference.
    return {root()..'images/overrides/icons/'..pack,root()..'images/icons/iconpacks/'..pack,root()..'images/icons/'..pack}
end
return M
