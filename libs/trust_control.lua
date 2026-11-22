-- A: Trust toggle slots. A Custom (ex) slot whose command is one of the pair
-- commands below shows, and sends, the face that fits the party state Trust
-- publishes in addons/trust/data/control-state-<server>-<id>.txt. Either
-- command of a pair can be bound; the saved slot is never rewritten. Without a
-- fresh file (Trust not loaded, old Trust, stale heartbeat) the slot is left
-- exactly as bound.
local M = {}

M.STALE = 15 -- seconds; Trust rewrites the file at least every 5 s

-- Faces. Icons are names in the active icon pack.
M.faces = {
    ready     = {command='trust actall',   alias='Ready',      icon='assist'},
    standdown = {command='trust pauseall', alias='Stand Down', icon='follow'},
    start     = {command='trust startall', alias='Start',      icon='assist'}, -- A: same as Ready
    stop      = {command='trust stopall',  alias='Stop',       icon='disengage'},
}
local pair_of = {
    actall='ready', pauseall='ready', standdown='ready',
    startall='start', stopall='start',
}
-- Labels and icons that belong to the toggles; anything else the user chose is kept.
local own_alias, own_icon = {}, {}
for _, face in pairs(M.faces) do
    own_alias[face.alias:lower():gsub('[^%w]', '')] = true
    own_icon[face.icon] = true
end
for word in pairs(pair_of) do own_alias[word] = true; own_alias['trust'..word] = true end

local function key(s) return tostring(s or ''):lower():gsub('[^%w]', '') end

-- 'trust actall', '//trust actall', 'lua c trust actall' -> 'actall'
function M.command_word(command)
    local text = tostring(command or ''):lower():gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')
    text = text:gsub('^/+', ''):gsub('^lua c ', ''):gsub('^lua command ', '')
    return text:match('^trust (%a+)$')
end

function M.pair(action)
    if not action or action.type ~= 'ex' then return end
    return pair_of[M.command_word(action.action) or '']
end

function M.parse(contents, id, now)
    local owner, state, intent, stamp = tostring(contents or ''):gsub('\r\n', '\n'):match(
        '^trust%-control1\n(%d+)\n(%a+)\n(%a+)\n(%d+)\nEND\n$')
    if not owner or tonumber(owner) ~= id then return end
    stamp = tonumber(stamp)
    if not stamp or now - stamp > M.STALE or stamp - now > M.STALE then return end
    return {state=state, intent=intent}
end

-- The state the buttons follow: the last party-wide request sent from this
-- client, or this client's own state if it has sent none.
function M.party_state(snapshot)
    if not snapshot then return end
    if snapshot.intent and snapshot.intent ~= 'none' then return snapshot.intent end
    return snapshot.state
end

-- Which face a pair shows. engaged = this character is engaged.
function M.face(pair, snapshot, engaged)
    local state = M.party_state(snapshot)
    if not state then return end
    if pair == 'ready' then
        -- Act, Start and Stop offer Stand Down; Pause (and Retreat) offer Ready.
        return (state == 'act' or state == 'start' or state == 'stop') and 'standdown' or 'ready'
    elseif pair == 'start' then
        return (engaged or state == 'act' or state == 'start') and 'stop' or 'start'
    end
end

function M.resolve(action, snapshot, engaged)
    local pair = M.pair(action)
    if not pair then return end
    local name = M.face(pair, snapshot, engaged)
    if not name then return end
    local face = M.faces[name]
    local out = {}
    for k, v in pairs(action) do out[k] = v end
    out.action = face.command
    if not action.alias or own_alias[key(action.alias)] then out.alias = face.alias end
    if not action.icon or action.icon == '' or own_icon[action.icon] then out.icon = face.icon end
    out.trust_face = name
    return out
end

-- File reader, cached and read at most every 0.25 s.
function M.reader(options)
    local self = {next_read = 0}
    function self:snapshot()
        local now = options.clock()
        if now < self.next_read then return self.value end
        self.next_read = now + .25
        self.value = nil
        local id, path = options.target()
        if not id or not path then return end
        local f = options.open(path, 'rb')
        if not f then return end
        local contents = f:read(257)
        f:close()
        self.value = M.parse(contents, id, options.time())
        return self.value
    end
    return self
end

local shared
function M.shared()
    if not shared then
        shared = M.reader({
            clock = require('socket').gettime, time = os.time, open = io.open,
            target = function()
                local p, info = windower.ffxi.get_player(), windower.ffxi.get_info()
                if not p or not p.id or not info or not info.server then return end
                return p.id, windower.windower_path..'addons/trust/data/control-state-'..info.server..'-'..p.id..'.txt'
            end,
        })
    end
    return shared
end

function M.engaged()
    local p = windower.ffxi.get_player()
    return p ~= nil and p.status == 1
end

return M
