-- Trust toggle slots: command matching, Trust's control-state file, the face
-- table A chose (2026-11-21), label/icon preservation, reader throttle, wiring.
local T = require('libs/trust_control')
local checks = 0
local function check(v, label) checks = checks + 1; assert(v, label) end
local function source(path) local f = assert(io.open(path)); local s = f:read('*a'); f:close(); return s end

-- Commands that make a slot a toggle.
check(T.command_word('trust actall') == 'actall', 'plain')
check(T.command_word('  //Trust   PauseAll ') == 'pauseall', 'slashes, case, spaces')
check(T.command_word('lua c trust stopall') == 'stopall', 'lua c form')
check(T.command_word('trust actall; trust start') == nil, 'macros stay untouched')
check(T.pair({type='ex', action='trust actall'}) == 'ready', 'actall pair')
check(T.pair({type='ex', action='trust standdown'}) == 'ready', 'standdown also belongs to Ready')
check(T.pair({type='ex', action='trust startall'}) == 'start', 'startall pair')
check(T.pair({type='ct', action='trust actall'}) == nil, 'only Custom (ex) slots')
check(T.pair({type='ex', action='trust start'}) == nil, 'local start is not a toggle')

-- Trust's file (format from trust cylibs/trust/control_publish.lua).
local file = 'trust-control1\n7\nact\nnone\n1000\nEND\n'
check(T.parse(file, 7, 1000).state == 'act', 'parse')
check(T.parse(file:gsub('\n', '\r\n'), 7, 1003).intent == 'none', 'CRLF tolerated')
check(T.parse(file, 8, 1000) == nil, 'other character ignored')
check(T.parse(file, 7, 1016) == nil, 'stale heartbeat ignored')
check(T.parse('garbage', 7, 1000) == nil, 'bad file ignored')

-- Face table.
local function faces(state, intent, engaged)
    local snap = {state = state, intent = intent or 'none'}
    return T.face('ready', snap, engaged), T.face('start', snap, engaged)
end
local r, s = faces('pause');  check(r == 'ready' and s == 'start', 'Pause: Ready + Start')
r, s = faces('act');          check(r == 'standdown' and s == 'stop', 'Act: Stand Down + Stop')
r, s = faces('start');        check(r == 'standdown' and s == 'stop', 'Start: Stand Down + Stop')
r, s = faces('stop');         check(r == 'standdown' and s == 'start', 'Stop: Stand Down + Start')
r, s = faces('retreat');      check(r == 'ready' and s == 'start', 'Retreat: Ready + Start')
r, s = faces('pause', nil, true); check(r == 'ready' and s == 'stop', 'engaged: Stop')
r, s = faces('pause', 'act'); check(r == 'standdown' and s == 'stop', 'party request wins over local stick pause')
check(T.face('ready', nil) == nil, 'no file: no face')

-- Resolution keeps the saved slot and the user's own label/icon.
local bound = {type='ex', action='trust actall', alias='Ready', icon='assist'}
local out = T.resolve(bound, {state='act', intent='act'}, false)
check(out.action == 'trust pauseall' and out.alias == 'Stand Down' and out.icon == 'follow', 'Stand Down face')
check(bound.action == 'trust actall' and bound.alias == 'Ready', 'saved slot untouched')
out = T.resolve({type='ex', action='trust actall', alias='Go Team', icon='cheer'}, {state='act', intent='act'})
check(out.action == 'trust pauseall' and out.alias == 'Go Team' and out.icon == 'cheer', 'custom label/icon kept')
out = T.resolve({type='ex', action='trust stopall', alias='trust stopall'}, {state='pause', intent='pause'})
check(out.action == 'trust startall' and out.alias == 'Start' and out.icon == 'engage', 'command-text label replaced')
check(T.resolve(bound, nil) == nil, 'no fresh file: slot as bound')

-- Reader: cached, at most every 0.25 s.
local now, opens = 0, 0
local reader = T.reader({clock=function() return now end, time=function() return 1000 end,
    target=function() return 7, 'cs' end,
    open=function() opens = opens + 1; return {read=function() return file end, close=function() end} end})
check(reader:snapshot().state == 'act' and opens == 1, 'first read')
now = .1; check(reader:snapshot() and opens == 1, 'cached')
now = .3; reader:snapshot(); check(opens == 2, 'reread after 0.25 s')

-- Wiring.
local ui, player, binder = source('ui.lua'), source('player.lua'), source('action_binder.lua')
check(ui:find("resolved = trust_control.resolve(action, trust_control.shared():snapshot(), trust_control.engaged())", 1, true), 'drawn face')
check(ui:find('or previous.icon ~= resolved.icon', 1, true), 'icon change redraws')
check(player:find("action = trust_control.resolve(action, trust_control.shared():snapshot(), trust_control.engaged()) or action", 1, true), 'sent face')
check(binder:find("name = 'Trust Controls'", 1, true) and binder:find("[action_types.TRUST_CONTROLS] = 'ex'", 1, true), 'main menu entry binds Custom')
check(T.shared and T.engaged, 'shared reader')
print('trust_control: ' .. checks .. ' checks ok')
