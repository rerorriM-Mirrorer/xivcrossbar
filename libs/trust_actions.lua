-- Trust membership and learned spells are observed once per draw/press pass.
-- Only typed Trust spells are changed; arbitrary macros remain user-owned.
local M={}
local function key(s)return tostring(s or ''):lower():gsub('%s*%(uc%)',''):gsub('[^%w]','')end
local aliases={arkhm='aahm',arkev='aaev',arktt='aatt',arkmr='aamr',arkgk='aagk'}
local source,index
local function spell_for(action,spells)
    if not action or action.type~='ma' then return end
    local direct=spells and spells[require('libs/kebab_casify')(action.action or '')]
    if type(direct)=='table' and (direct.type=='Trust' or direct.category=='trust') then return direct end
    if source~=spells then
        source,index=spells,{}
        for _,spell in pairs(spells or {})do
            if type(spell)=='table' and (spell.type=='Trust' or spell.category=='trust') then index[key(spell.en or spell.name)]=spell end
        end
    end
    return index and index[key(action.action)]
end
function M.snapshot(ffxi)
    local party=ffxi.get_party and ffxi.get_party() or {}
    local trusts={}
    for i=1,5 do
        local member=party['p'..i]
        local mob=member and member.mob
        if mob and mob.spawn_type==14 and (not party.p0 or not party.p0.zone or not member.zone or party.p0.zone==member.zone) then
            trusts[key(mob.name or member.name)]=mob.name or member.name
        end
    end
    return {trusts=trusts,known=ffxi.get_spells and ffxi.get_spells()}
end
function M.resolve(action,state,spells)
    local spell=spell_for(action,spells);if not spell then return end
    local name=key(spell.en or spell.name)
    local present=state.trusts and state.trusts[aliases[name] or name]
    if not present then return end
    local out={};for k,v in pairs(action)do out[k]=v end
    out.type,out.action,out.target='ct','refa "'..present..'"',nil
    out.alias='Return'
    out.trust_spell_name=action.action
    out.linked_action,out.linked_type=nil,nil
    out.trust_dismiss=true
    return out
end
function M.unavailable(action,state,spells)
    local spell=spell_for(action,spells);if not spell then return end
    if not state.known then return 'Trust availability is not ready.' end
    if state.known[spell.id]~=true then return 'This Trust has not been learned.' end
end
return M
