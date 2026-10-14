-- A: catalog defaults are presentation/execution fallbacks, never writes.
local M = {}
function M.nonempty(value) return type(value)=='string' and value:match('%S') ~= nil end
function M.alias(d) return M.nonempty(d.alias) and d.alias or (d.name or '') end
function M.command(d) return M.nonempty(d.command) and d.command or M.alias(d) end
function M.route(args)
    local token=args[1] and args[1]:lower()
    local fields={a='alias',alias='alias',n='name',name='name',c='command',command='command'}
    if token=='new' then return 'open',table.concat(args,' ',2) end
    if fields[token] and args[2] then return 'field',fields[token],table.concat(args,' ',2) end
    return 'open',table.concat(args,' ')
end
function M.valid_name(name,catalog,original)
    return M.nonempty(name) and (name==original or not catalog or catalog[name]==nil)
end
return M
