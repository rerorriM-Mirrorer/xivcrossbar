-- Load real addon code with just Windower's external services stubbed.
-- The selectors, binder state machine and player dispatch run unchanged.
local M = {}
unpack = unpack or table.unpack
local list_methods = {}
function list_methods:append(v) self[#self + 1] = v; return self end
function list_methods:contains(v)
    for _, value in ipairs(self) do if value == v then return true end end
    return false
end
function list_methods:sort(fn) table.sort(self, fn); return self end
function list_methods:concat(sep) return table.concat(self, sep) end
function list_methods:filter(fn)
    local out = L{}
    for k, v in pairs(self) do if fn(v, k) then out:append(v) end end
    return out
end
L = function(t) return setmetatable(t or {}, {__index = list_methods}) end
S = function(t)
    local out = {}
    for _, v in ipairs(t or {}) do out[v] = true end
    return setmetatable(out, {__index = {contains = function(s, v) return rawget(s, v) == true end}})
end
T = function(t) return t end
string.contains = function(s, v) return s:find(v, 1, true) ~= nil end
string.split = function(s, sep)
    local out = L{}
    for v in s:gmatch('[^' .. sep .. ']+') do out:append(v) end
    return out
end
string.xml_escape = function(s)
    return s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'):gsub("'", '&apos;')
end
function M.surface()
    return setmetatable({}, {__index = function(t, k)
        if k:sub(1, 1) == '_' then return nil end
        return function(self, value, second)
            if k == 'destroy' then
                self._destroyed, self._visible, self._show = true, false, false
            elseif k == 'show' or k == 'hide' then
                self._visible, self._show = k == 'show', k == 'show'
            elseif k == 'visible' then
                if value == nil then return self._visible == true end
                self._visible = value
            elseif k == 'extents' then
                return #(self._text or '') * (self._size or 12) * .6, (self._size or 12) * 1.4
            elseif k == 'path' and value ~= nil then
                self._path_calls = (self._path_calls or 0) + 1; self._path = value
            elseif value == nil then
                if k == 'pos' then return self._pos or 0, self._pos_y or 0 end
                if k == 'size' then return self._size or 40, self._size_y or 40 end
                return self['_' .. k]
            else self['_' .. k], self['_' .. k .. '_y'] = value, second end
            return self
        end
    end})
end
function M.reset()
    M.events, M.commands, M.messages, M.logs, M.files, M.primitives = {}, {}, {}, {}, {}, {}
    _addon = {}
    windower = {
        addon_path = './',
        register_event = function(event, fn)
            M.events[event] = M.events[event] or {}; table.insert(M.events[event], fn)
        end,
        send_command = function(cmd) table.insert(M.commands, cmd) end,
        add_to_chat = function(_, msg) table.insert(M.messages, msg) end,
        console = {write = function(msg) table.insert(M.logs, msg) end},
        prim = setmetatable({}, {__index = function(_, method) return function(name, ...)
            local p = M.primitives[name] or {}; M.primitives[name] = p
            p[method] = {...}
        end end}),
        get_windower_settings = function() return {ui_x_res = 1920, ui_y_res = 1080} end,
        ffxi = {
            get_player = function() return {name = 'Myrr', main_job = 'THF', sub_job = nil, status = 0} end,
            get_info = function() return {logged_in = true, zone = 230} end,
            get_abilities = function() return {job_abilities = {35}, weapon_skills = {16}} end,
            get_spells = function() return {} end,
        },
    }
    config = {load = function(v) return v end, save = function() end}
    file = {new = function(path) return {
        exists = function() return true end,
        write = function(_, content) M.files[path] = content end,
    } end}
    defaults = {Style = {OffsetX = 0, OffsetY = 0}, General = {}}
    res = {job_abilities = {[35] = {id = 35, en = 'Provoke', recast_id = 5, targets = {Enemy = true}}},
        weapon_skills = {[16] = {id = 16, en = 'Wasp Sting', targets = {Enemy = true}}}}
    resources = res
    for _, name in ipairs({'lists', 'strings', 'tables', 'sets'}) do
        package.loaded[name] = true
    end
    package.loaded['texts'] = {new = M.surface}
    package.loaded['images'] = {new = M.surface}
    package.loaded['resources'] = res
    -- Runtime caches are generated from Windower resources and ignored by Git.
    -- A fresh checkout needs only these two resource records for the editor
    -- regressions; the binder/selector logic itself still runs unchanged.
    package.loaded['resources/crossbar_abilities'] = {
        provoke = {id=35, en='Provoke', type='ja', recast_id=5,
            category='abilities', default_icon='/images/icons/abilities/00005.png',
            custom_icon='abilities/provoke.png'},
        ['wasp-sting'] = {id=16, en='Wasp Sting', type='ws',
            category='dagger', default_icon='/images/icons/weapons/dagger.png',
            custom_icon='weaponskills/dagger/wasp-sting.png'},
    }
    package.loaded['resources/crossbar_spells'] = {}
    package.loaded['files'] = file
    package.loaded['config'] = config
    package.loaded['defaults'] = defaults
    package.loaded['theme'] = {apply = function() return {iconpack = 'test'} end}
    package.loaded['socket'] = {gettime = os.clock}
    package.loaded['ui/icon_extractor'] = {}
    package.loaded['libs/mountroulette/mountroulette'] = {}
    M.player = {custom_actions = {Test = {alias = 'Test', command = 'sat alltargetreport'}}}
    package.loaded['player'] = M.player
    package.loaded['ui/selectablelist'] = nil
    package.loaded['action_binder'] = nil
    package.path = './?.lua;' .. package.path
end
function M.emit(event, ...)
    for _, fn in ipairs(M.events[event] or {}) do fn(...) end
end
function M.binder()
    local binder = require('action_binder')
    local theme = {iconpack = 'test', frame_theme = 'test', font = 'Arial', font_size = 12}
    binder:setup({button_layout = 'playstation', confirm_button = 'cross', cancel_button = 'circle'},
        function() end, function() end, theme, function() return {} end,
        0, 0, 1200, 800, nil, nil,
        function(d) M.saved = d end, function(original, d) M.updated = {original, d} end)
    return binder
end
function M.pick(binder, id)
    for col, rows in pairs(binder.selector.field_coords) do
        for row, option in pairs(rows) do
            if option.id == id then
                binder.selector.selected_col, binder.selector.selected_row = col, row
                binder:submit_selected_option()
                return
            end
        end
    end
    error('No selectable option ' .. tostring(id))
end
M.reset()
return M
