--[[
        Copyright © 2021, Rubenator
        All rights reserved.
        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:
            * Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
            * Redistributions in binary form must reproduce the above copyright
              notice, this list of conditions and the following disclaimer in the
              documentation and/or other materials provided with the distribution.
            * Neither the name of EquipViewer nor the
              names of its contributors may be used to endorse or promote products
              derived from this software without specific prior written permission.
        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL Rubenator BE LIABLE FOR ANY
        DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
-- icon_extractor v1.1.2
-- Written by Rubenator of Leviathan
-- Base Extraction Code graciously provided by Trv of Windower discord
local icon_extractor = {}
-- Windower's logger error() prints and returns; validation must stop execution.
local error = (_raw and _raw.error) or error

local game_path_default = windower.ffxi_path
local game_path = game_path_default

local string = require('string')
local io = require('io')
local math = require('math')

local concat = table.concat
local floor = math.floor
local byte = string.byte
local char = string.char
local sub = string.sub

local file_size = '\122\16\00\00'
local reserved1 = '\00\00'
local reserved2 = '\00\00'
local starting_address = '\122\00\00\00'

local default = '\00\00\00\00'

local dib_header_size = '\108\00\00\00'
local bitmap_width = '\32\00\00\00'
local bitmap_height = '\32\00\00\00'
local n_color_planes = '\01\00'
local bits_per_pixel = '\32\00'
local compression_type = '\03\00\00\00'
local image_size = '\00\16\00\00'
local h_resolution_target = default
local v_resolution_target = default
local default_n_colors = default
local important_colors = default
local alpha_mask = '\00\00\00\255'
local red_mask = '\00\00\255\00'
local green_mask = '\00\255\00\00'
local blue_mask = '\255\00\00\00'
local colorspace = 'sRGB'
local endpoints = string.rep('\00', 36)
local red_gamma = default
local green_gamma = default
local blue_gamma = default

local header = 'BM' .. file_size .. reserved1 .. reserved2 .. starting_address
        .. dib_header_size .. bitmap_width .. bitmap_height .. n_color_planes
        .. bits_per_pixel .. compression_type .. image_size
        .. h_resolution_target .. v_resolution_target
        .. default_n_colors .. important_colors
        .. red_mask .. green_mask .. blue_mask .. alpha_mask
        .. colorspace .. endpoints .. red_gamma .. green_gamma .. blue_gamma

--local icon_file = io.open('C:/Program Files (x86)/PlayOnline/SquareEnix/FINAL FANTASY XI/ROM/118/106.DAT', 'rb')
local color_lookup = {}
local bmp_segments = {}

for i = 0x000, 0x0FF do
    color_lookup[string.char(i)] = ''
end

-- A: item records exist in both legacy (0xC00) and expanded (0x1400)
-- layouts. Captured client records establish the expanded stride; accept a
-- candidate only when its decoded item ID and complete bitmap both match.
local item_record_sizes = {0xC00, 0x1400}

local item_dat_map = {
    [1]={min=0x0001, max=0x0FFF, dat_path='118/106', offset=-1}, -- General Items
    [2]={min=0x1000, max=0x1FFF, dat_path='118/107', offset=0}, -- Usable Items
    [3]={min=0x2000, max=0x21FF, dat_path='118/110', offset=0}, -- Automaton Items
    [4]={min=0x2200, max=0x27FF, dat_path='301/115', offset=0}, -- General Items 2
    [5]={min=0x2800, max=0x3FFF, dat_path='118/109', offset=0}, -- Armor Items
    [6]={min=0x4000, max=0x59FF, dat_path='118/108', offset=0}, -- Weapon Items
    [7]={min=0x5A00, max=0x6FFF, dat_path='286/73', offset=0}, -- Armor Items 2
    [8]={min=0x7000, max=0x73FF, dat_path='217/21', offset=0}, -- Maze Items, Basic Items
    [9]={min=0x7400, max=0x77FF, dat_path='288/80', offset=0}, -- Instinct Items
    [10]={min=0xF000, max=0xF1FF, dat_path='288/67', offset=0}, -- Monipulator Items
    [11]={min=0xFFFF, max=0xFFFF, dat_path='174/48', offset=0}, -- Gil
}

local last_item_record
local item_by_id = function (id, output_path)
    last_item_record = nil
    if type(id) ~= 'number' or id ~= floor(id) then error('Invalid item icon ID ' .. tostring(id)) end
    local dat_stats = find_item_dat_map(id)
    if not dat_stats then error('Unsupported item icon ID ' .. tostring(id)) end
    local icon_file = open_dat(dat_stats)
    
    local index = id - (dat_stats.min + dat_stats.offset)
    local function read_bitmap(size)
        local offset = index * size
        assert(icon_file:seek('set', offset), 'Could not seek item DAT record')
        local record = icon_file:read(size)
        last_item_record = {id=id, data=record, path='ROM/' .. dat_stats.dat_path .. '.DAT',
            offset=offset, record_size=size}
        if not record or #record ~= size then error('Short item DAT record for ID ' .. tostring(id)) end
        local decoded = record:gsub('.', function(c)
            local n = byte(c)
            return char((n % 0x20) * 8 + floor(n / 0x20))
        end)
        local found_id = byte(decoded, 1) + byte(decoded, 2) * 256
        last_item_record.decoded_id = found_id
        if found_id ~= id then
            error('Item DAT ID mismatch: requested ' .. tostring(id) .. ', found ' .. found_id ..
                ' in ' .. last_item_record.path .. ' at byte ' .. offset)
        end
        local bitmap_header = char(40,0,0,0,32,0,0,0,32,0,0,0,1,0,8,0)
        local at = decoded:find(bitmap_header, 0x101, true)
        if not at or at + 40 + 0x800 - 1 > #record then
            error('No complete 32x32 item bitmap for ID ' .. tostring(id))
        end
        return convert_item_icon_to_bmp(record:sub(at + 40, at + 40 + 0x800 - 1))
    end
    local bmp, failure
    local preferred = dat_stats.record_size
    -- Remember the working stride, but revalidate every item. Index zero can
    -- fit either size, so permit another candidate if the next ID rejects it.
    local sizes = preferred and {preferred, preferred == 0xC00 and 0x1400 or 0xC00} or item_record_sizes
    for _, size in ipairs(sizes) do
        local ok, result = pcall(read_bitmap, size)
        if ok then
            bmp = result
            dat_stats.record_size = size
            break
        end
        failure = result
    end
    if not bmp then error(failure) end
    local f, err = io.open(output_path, 'wb')
    if not f then error(err) end
    local written, write_error = f:write(bmp)
    local closed, close_error = f:close()
    if not written or not closed then
        os.remove(output_path)
        error(write_error or close_error or 'Could not finish item bitmap')
    end
    -- Do not yield across a menu's protected-call boundary on Lua 5.1. The
    -- complete file must be closed before the renderer can use it.
end
icon_extractor.item_by_id = item_by_id

local failed_items = {}
local function write_diagnostic(path, record, failure)
    if not record or not record.data then return false end
    -- Small local evidence captures, not game-file edits. At most one record
    -- per failed item per load; collect these rather than uploading whole DATs.
    local raw_path = path:gsub('%.bmp$', '.record.dat')
    local f, err = io.open(raw_path, 'wb')
    if not f then error(err) end
    local written, write_error = f:write(record.data)
    local closed, close_error = f:close()
    if not written or not closed then error(write_error or close_error or 'Could not save item diagnostic') end
    local hex = record.data:sub(1,32):gsub('.', function(c) return string.format('%02X ',byte(c)) end)
    local info = 'requested_id=' .. record.id .. '\nsource=' .. record.path .. '\nbyte_offset=' .. record.offset ..
        '\nrecord_size=' .. tostring(record.record_size) .. '\nrecord_length=' .. #record.data .. '\ndecoded_id=' .. tostring(record.decoded_id) ..
        '\nencoded_first_32=' .. hex .. '\nfailure=' .. tostring(failure) .. '\n'
    f, err = io.open(path:gsub('%.bmp$', '.record.txt'), 'wb')
    if not f then error(err) end
    written, write_error = f:write(info)
    closed, close_error = f:close()
    if not written or not closed then error(write_error or close_error or 'Could not finish item diagnostic') end
    return true
end

function icon_extractor.safe_item_by_id(id, output_path)
    local key = tostring(id)
    if failed_items[key] then return false end
    local ok, err = pcall(item_by_id, id, output_path)
    if not ok then
        failed_items[key] = true
        local captured, saved = pcall(write_diagnostic, output_path, last_item_record, err)
        local note = captured and saved and ' (record diagnostic saved beside the icon cache)' or ''
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Item icon ' .. key .. ': ' .. tostring(err) .. note))
    end
    return ok
end

function find_item_dat_map(id)
    for _,stats in pairs(item_dat_map) do
        if id >= stats.min and id <= stats.max then
            return stats
        end
    end
    return nil
end

function open_dat(dat_stats)
    local icon_file = nil
    if dat_stats.file then
        icon_file = dat_stats.file
    else
        if not game_path then
            error('ffxi_path must be set before using icon_extractor library')
        end
        local filename = game_path .. '/ROM/' .. tostring(dat_stats.dat_path) .. '.DAT'
        local err
        icon_file, err = io.open(filename, 'rb')
        if not icon_file then
            error(err)
            return
        end
        dat_stats.file = icon_file
    end
    return icon_file
end

-- 32 bit color palette-indexed bitmaps. Bits are rotated and must be decoded.
local encoded_to_decoded_char = {}
local encoded_byte_to_rgba = {}
local alpha_encoded_to_decoded_adjusted_char = {}
local decoded_byte_to_encoded_char = {}
for i = 0x000, 0x0FF do
    encoded_byte_to_rgba[i] = ''
    local n = (i % 0x20) * 0x8 + floor(i / 0x20)
    encoded_to_decoded_char[char(i)] = char(n)
    decoded_byte_to_encoded_char[n] = char(i)
    n = n * 0x2
    n = n < 0x100 and n or 0x0FF
    alpha_encoded_to_decoded_adjusted_char[char(i)] = char(n)
end
local decoder = function(a, b, c, d)
    return encoded_to_decoded_char[a]..
        encoded_to_decoded_char[b]..
        encoded_to_decoded_char[c]..
        alpha_encoded_to_decoded_adjusted_char[d]
end
function convert_item_icon_to_bmp(data)
    local color_palette = string.gsub(sub(data, 0x001, 0x400), '(.)(.)(.)(.)', decoder)
    -- rather than decoding all 2048 bytes, decode only the palette and index it by encoded byte
    for i = 0x000, 0x0FF do
        local offset = i * 0x4 + 0x1
        encoded_byte_to_rgba[decoded_byte_to_encoded_char[i]] = sub(color_palette, offset, offset + 0x3)
    end

    return header .. string.gsub(sub(data, 0x401, 0x800), '(.)', function(a) return encoded_byte_to_rgba[a] end)
end


local buff_dat_map = {
    [1]={min=0x000, max=0x400, dat_path='119/57', offset=0},
}
function find_buff_dat_map(id)
    for _,stats in pairs(buff_dat_map) do
        if id >= stats.min and id <= stats.max then
            return stats
        end
    end
    return nil
end
local buff_by_id = function (id, output_path)
    local dat_stats = find_buff_dat_map(id)
    local icon_file = open_dat(dat_stats)
    
    local id_offset = dat_stats.min + dat_stats.offset
    icon_file:seek('set', (id - id_offset) * 0x1800)
    local data = icon_file:read(0x1800)

    bmp = convert_buff_icon_to_bmp(data)

    local f = io.open(output_path, 'wb')
    f:write(bmp)
    coroutine.yield()
    f:close()
end
icon_extractor.buff_by_id = buff_by_id


local ffxi_path = function(location)
    game_path = location or game_path_default
    close_dats()
end
icon_extractor.ffxi_path = ffxi_path


-- A mix of 32 bit color uncompressed and *color palette-indexed bitmaps
-- Offsets defined specifically for status icons
-- * some maps use this format as well, but at 512 x 512
function convert_buff_icon_to_bmp(data)
    local length = byte(data, 0x282) -- The length is technically sub(0x281, 0x284), but only 0x282 is unique

    if length == 16 then -- uncompressed
        data = sub(data, 0x2BE, 0x12BD)
        data = string.gsub(data, '(...)\x80', '%1\xFF') -- All of the alpha bytes are currently 0 or 0x80.
    elseif length == 08 then -- color table
        local color_palette = sub(data, 0x2BE, 0x6BD)
        color_palette = string.gsub(color_palette, '(...)\x80', '%1\xFF')
    
        local n = 0x0
        for i = 1, 0x400, 0x4 do
            color_lookup[char(n)] = sub(color_palette, i, i + 3)
            n = n + 1
        end
    
        data = string.gsub(sub(data, 0x6BE, 0xABD), '(.)', function(i) return color_lookup[i] end)
    elseif length == 04 then -- XIVIEW
        data = sub(data, 0x2BE, 0x12BD)
    end
    
    return header .. data
end

function close_dats()
    for _,dat in pairs(item_dat_map) do
        if dat and dat.file then
            dat.file:close()
            dat.file = nil
            dat.record_size = nil
        end
    end
    for _,dat in pairs(buff_dat_map) do
        if dat and dat.file then
            dat.file:close()
            dat.file = nil
            dat.record_size = nil
        end
    end
end

windower.register_event('unload', function()
    close_dats()
end);

return icon_extractor
