-- Real shipped XML parser, with just Windower's collection/string extensions
-- adapted for this Lua 5.4 harness. Re-run the entire persistence regression
-- using its real DOM, including attribute nodes and escaped console commands.
local methods={}
local function collection(t)return setmetatable(t or {},{__index=methods})end
T=collection;L=collection
function methods:append(v)table.insert(self,v);return self end
function methods:last(n)return self[#self-(n or 1)+1]end
function methods:remove()return table.remove(self)end
function methods:update(t)for k,v in pairs(t or {})do self[k]=v end;return self end
function methods:containskey(k)return self[k]~=nil end
function methods:contains(v)for _,x in ipairs(self)do if x==v then return true end end;return false end
function methods:filter(fn)local r=collection();for _,v in ipairs(self)do if fn(v)then r:append(v)end end;return r end
function methods:find(fn)for i,v in ipairs(self)do if fn(v)then return i end end end
function methods:length()return #self end
function methods:it()local i=0;return function()i=i+1;if self[i]~=nil then return self[i],i end end end
function S(t)local r={};for _,v in ipairs(t)do r[v]=true end;return setmetatable(r,{__index={contains=function(self,v)return self[v]==true end}})end
function string.it(s)return s:gmatch('.')end
function string.startswith(s,p)return s:sub(1,#p)==p end
function string.endswith(s,p)return s:sub(-#p)==p end
function string.contains(s,p)return s:find(p,1,true)~=nil end
function string.length(s)return #s end
function string.trim(s)return (s:gsub('^%s+',''):gsub('%s+$',''))end
function string.spaces_collapse(s)return (s:gsub('%s+',' '))end
function string.number(s,base)return tonumber(s,base)end
function string.split(s,separator)
    local r=collection();for v in (s..separator):gmatch('(.-)'..separator)do r:append(v)end;return r
end
local mt=getmetatable('')
mt.__unm=function(s)return function(v)return v~=s end end
mt.__index=function(s,k)if type(k)=='number'then return s:sub(k,k)end;return string[k]end
_libs={tables=table,lists=methods,sets={},strings=string,files={}}
bank_test_parse=require('libs/xml2').parse
dofile('tests/bank_storage.lua')
if bank_settings_attachment then
    local f=assert(io.open(bank_settings_attachment));local original=f:read('*a');f:close()
    local Store=require('libs/banks/storage')
    local records=assert(Store.decode(original,bank_test_parse))
    assert(records.cioara.CompanionBanks.LeftPanel.X==1657)
    assert(records.cioara.CompanionBanks.RightPanel.Y==1675)
    local files={main=original}
    local store=Store.new({path='banks',main='main',parse=bank_test_parse,
        read=function(p)return files[p]end,lock=function()return function()end end,
        replace=function(p,s)files[p]=s;return true end})
    assert(store:prepare())
    for name in pairs(records)do store:refresh(nil,name);assert(store.ready)end
    local output=assert(io.open(bank_settings_output,'wb'));output:write(files.banks);output:close()
    assert(files['main.before-bank-cleanup.bak']==original)
end
print('Actual shipped XML parser: bank migration, persistence, attributes, escape roundtrip, invalid/newer input and recovery passed.')

local Store=require('libs/banks/storage')
local raw=Store.encode({global={CompanionBanks=require('libs/banks/banks').defaults()},
    test={CompanionBanks={R1R2={AllowCutscenes=true}}}})
local records=assert(Store.decode(raw,bank_test_parse))
assert(records.test.CompanionBanks.R1R2.AllowCutscenes==true)
assert(records.global.CompanionBanks.R1R2.AllowCutscenes==false)
assert(not Store.decode(raw:gsub('<AllowCutscenes>true</AllowCutscenes>','<AllowCutscenes>invalid</AllowCutscenes>'),bank_test_parse))
print('Cutscene bank permission: real XML boolean roundtrip and malformed-value rejection passed.')
