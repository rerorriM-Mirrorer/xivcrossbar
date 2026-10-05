-- Contributing author: A. Avoid writing blank hotbars under a stale server.
-- The login event can precede the client updating get_info().server. Require
-- an in-world player and a stable server/name/id pair before opening storage.
local gate = {}
gate.__index = gate

function gate.new(clock, settle_seconds)
    return setmetatable({clock = clock, settle = settle_seconds or 0.75}, gate)
end

function gate:reset()
    self.candidate, self.since, self.loaded = nil, nil, nil
end

function gate:observe(info, player, entity, known_server)
    local ready = info and info.logged_in and type(info.server) == 'number'
        and info.server > 0 and info.zone and info.zone > 0
        and known_server and player and player.name and player.name ~= ''
        and type(player.id) == 'number' and player.id > 0
        and entity and entity.id == player.id and entity.name == player.name
    if not ready then
        self.candidate, self.since = nil, nil
        return nil
    end

    local key = info.server .. '/' .. player.name .. '/' .. player.id
    if key ~= self.candidate then
        self.candidate, self.since = key, self.clock()
        return nil
    end
    if key ~= self.loaded and self.clock() - self.since >= self.settle then
        self.loaded = key
        return info.server, player.name
    end
end

return gate
