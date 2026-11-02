-- Validate everything before writing either the shared catalog or current set.
local M={aliases={l=true,r=true,ll=true,rr=true,lr=true,rl=true}}
function M.bind(trigger,args,player,converter,count,bind)
    if player.hotbar_load_ok==false or not player.identity_confirmed then return false,'Log in and reload successfully before binding.' end
    if #args~=3 or not tostring(args[2] or ''):match('%S') or not tostring(args[3] or ''):match('%S') then
        return false,'Use //xb '..trigger..' <button> "Label" "Command".'
    end
    local bar,slot=converter:convert_to_crossbar(trigger),converter:convert_to_slot(args[1])
    if count==3 and bar==4 then bar=3 end
    if not bar or bar<1 or bar>count or not slot or slot<1 or slot>8 then return false,'That trigger or button is unavailable with the current bank count.' end
    local ok,err=player:refresh_custom_catalogs(false);if not ok then return false,err end
    local name,command=args[2],args[3]
    local existing=player.catalog_sources.global[name]
    local record
    if existing then
        if existing.deleted=='true' or existing.command~=command or (existing.alias or existing.name)~=name
                or (existing.icon or '')~='custom_actions' or existing.linked_action or existing.linked_type then
            return false,'A different global action already uses that label. Choose another label or edit the existing action.'
        end
        record=existing
    else
        record={name=name,alias=name,command=command,icon='custom_actions',_scope='global'}
        ok,err=player:save_catalog_edit(nil,record);if not ok then return false,err end
    end
    return bind(bar,slot,'ex',name,nil,command,'custom_actions',nil,nil,name,{scope='global',id=record.id})~=false
end
return M
