-- A: keyboard transport can start before login; character storage cannot.
local M = {}
function M.resolve(info, player, servers)
    if not info or info.logged_in ~= true or not player then return nil end
    local server = servers and servers[info.server]
    if not server or type(server.en) ~= 'string' or server.en == '' then return nil end
    if type(player.name) ~= 'string' or not player.name:match('^%a+$') then return nil end
    if type(player.main_job) ~= 'string' or player.main_job == '' then return nil end
    return server.en
end
return M
