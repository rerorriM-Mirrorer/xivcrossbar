-- A: Undo history for edit-mode changes (2026-11-16).
-- Each record is the slot exactly as it was stored before a change made from
-- the XIV Crossbar menu (bind, Clear, Change Icon). Undo puts that record back.
-- The history is kept per character and saved beside that character's
-- crossbar files (data/hotbar/<server>/<name>/EditUndo.lua), so it survives
-- reloads and job changes. Plain data only; no Windower objects.
local M = {limit = 9}
M.__index = M

-- store = {read = function() -> string|nil, write = function(string)}
function M.new(store, limit)
    local self = setmetatable({store = store, limit = limit or M.limit, records = {}}, M)
    self:load()
    return self
end

local function copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for k, v in pairs(value) do out[copy(k)] = copy(v) end
    return out
end
M.copy = copy

-- Serialise plain tables of strings, numbers and booleans.
local function serialize(value, indent)
    local t = type(value)
    if t == 'string' then return string.format('%q', value)
    elseif t == 'number' or t == 'boolean' then return tostring(value)
    elseif t ~= 'table' then return 'nil' end
    indent = indent or ''
    local inner = indent .. '  '
    local keys = {}
    for k in pairs(value) do keys[#keys+1] = k end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == 'number'
    end)
    local parts = {}
    for _, k in ipairs(keys) do
        local key = type(k) == 'number' and ('[' .. k .. ']') or ('[' .. string.format('%q', k) .. ']')
        parts[#parts+1] = inner .. key .. ' = ' .. serialize(value[k], inner)
    end
    if #parts == 0 then return '{}' end
    return '{\n' .. table.concat(parts, ',\n') .. '\n' .. indent .. '}'
end
M.serialize = serialize

-- Read a saved history without giving the file access to anything.
local function deserialize(text)
    if type(text) ~= 'string' or text == '' then return nil end
    local source = 'return ' .. text:gsub('^%s*return%s+', '')
    local chunk
    if setfenv and loadstring then
        chunk = loadstring(source)                 -- Lua 5.1 (Windower)
        if chunk then setfenv(chunk, {}) end
    else
        chunk = load(source, 'EditUndo', 't', {})  -- Lua 5.2+
    end
    if not chunk then return nil end
    local ok, value = pcall(chunk)
    if ok and type(value) == 'table' then return value end
end
M.deserialize = deserialize

function M:load()
    self.records = {}
    local text = self.store and self.store.read and self.store.read()
    local saved = deserialize(text)
    if saved and type(saved.records) == 'table' then
        for _, record in ipairs(saved.records) do
            if type(record) == 'table' and record.environment and record.bank and record.slot then
                self.records[#self.records+1] = record
            end
        end
    end
    while #self.records > self.limit do table.remove(self.records, 1) end
end

function M:save()
    if self.store and self.store.write then
        self.store.write('return ' .. serialize({version = 1, records = self.records}) .. '\n')
    end
end

-- before: the stored slot table, or nil for an empty slot.
function M:push(environment, bank, slot, before, label)
    self.records[#self.records+1] = {environment = environment, bank = bank, slot = slot,
        before = before ~= nil and copy(before) or false, label = label}
    while #self.records > self.limit do table.remove(self.records, 1) end
    self:save()
end

-- Several slots changed together (Swap): one Undo restores them all.
-- entries: {{environment=, bank=, slot=, before=}, ...}
function M:push_group(entries, label)
    local group = {}
    for i, e in ipairs(entries) do
        group[i] = {environment = e.environment, bank = e.bank, slot = e.slot,
            before = e.before ~= nil and copy(e.before) or false}
    end
    local first = group[1]
    self.records[#self.records+1] = {environment = first.environment, bank = first.bank, slot = first.slot,
        before = first.before, group = group, label = label}
    while #self.records > self.limit do table.remove(self.records, 1) end
    self:save()
end

function M:pop()
    local record = table.remove(self.records)
    if record then self:save() end
    return record
end

function M:count() return #self.records end

return M
