local res = require('resources')
-- Windower's logger exports a non-raising error(). Guards need Lua's exception.
local error = (_raw and _raw.error) or error
local storage = require('storage')
local catalog = require('custom_catalog')
local catalog_bindings = require('catalog_bindings')
local action_manager = require('action_manager')
local mount_roulette = require('libs/mountroulette/mountroulette')

settings = config.load(defaults)
local player = {}

player.name = ''
player.main_job = ''
player.main_job_level = ''
player.sub_job = ''
player.sub_job_level = ''
player.server = ''

player.vitals = {}
player.vitals.mp = 0
player.vitals.tp = 0

player.sch_jp_spent = 0

player.hotbar = {}

player.hotbar_settings = {}
player.hotbar_settings.max = 1
player.hotbar_settings.active_hotbar = 1
player.hotbar_settings.active_environment = 'Field'

player.auto_create_xml = true

-- initialize player
function player:initialize(windower_player, server, theme_options, enchanted_items)
    self.name = windower_player.name
    self.main_job = windower_player.main_job
    self.main_job_level = windower_player.main_job_level
    self.sub_job = windower_player.sub_job
    self.sub_job_level = windower_player.sub_job_level
    self.server = server
    self.id = windower_player.id
    self.enchanted_items = enchanted_items
    self.hotbar_settings.max = theme_options.hotbar_number
    self.vitals.mp = windower_player.vitals.mp
    self.vitals.tp = windower_player.vitals.tp
    self.sch_jp_spent = windower_player.job_points.sch.jp_spent
    self.auto_create_xml = theme_options.AutoCreateXML

    storage:setup(self)
end

local avatar_names = S{'Shiva','Ramuh','Garuda','Leviathan','Diabolos','Titan','Fenrir','Ifrit','Carbuncle','Fire Spirit','Air Spirit','Ice Spirit','Thunder Spirit','Light Spirit','Dark Spirit','Earth Spirit','Water Spirit','Cait Sith','Alexander','Odin','Atomos','Siren'}
local job_abilities = S{'Light Arts','Dark Arts'}

local unescape = function(str)
    return str:gsub('&apos;', '\''):gsub('quote', '"')
end

-- update player jobs
function player:update_jobs(main, sub)
    self.main_job = main
    self.sub_job = sub

    storage:update_filename(main, sub)
end

function player:get_id()
    return self.id
end

-- Updates the set of spells the player can currently cast. Does not take
-- MP, recast timers, or special ability requirements into account. Only
-- whether or not FFXI's job data says the spell is there.
function player:update_current_spells()
    local mainJobSpellList = T()
    if windower.ffxi.get_player()['main_job_id'] == 16 then
        mainJobSpellList = T(windower.ffxi.get_mjob_data().spells)
        -- Returns all values but 512
        :filter(function(id) return id ~= 512 end)
        -- Transforms them from IDs to lowercase English names
        :map(function(id) return res.spells[id].english:lower() end)
    end

    local subJobSpellList = T()
    if windower.ffxi.get_player()['sub_job_id'] == 16 then
        subJobSpellList = T(windower.ffxi.get_sjob_data().spells)
        -- Returns all values but 512
        :filter(function(id) return id ~= 512 end)
        -- Transforms them from IDs to lowercase English names
        :map(function(id) return res.spells[id].english:lower() end)
    end

    self.current_spells = {}
    for _, spellName in ipairs(subJobSpellList) do
        self.current_spells[spellName] = true
    end
    for _, spellName in ipairs(mainJobSpellList) do
        self.current_spells[spellName] = true
    end
end

-- Returns true if the player has the spell and (if BLU) the spell is set.
function player:has_spell(spellName)
    return self.current_spells[spellName] == true
end

-- load hotbar for current player and job combination
function player:load_hotbar()
    if not self.identity_confirmed or not storage.identity_valid then return false end
    -- A: keep the last complete view when parsing any layer fails. A
    -- parser exception must block saves just like an explicit XML read error.
    local previous = {hotbar=self.hotbar, shared_icons=self.shared_icons,
        custom_actions=self.custom_actions}
    self.hotbar_load_ok = false
    storage.hotbar_read_error = nil
    storage.created_files = {}
    self.last_created_files = nil
    local ok, err = pcall(function()
        self:update_current_spells()
        self:reset_hotbar()
        local newly_created = false

        -- Load shared-icons table first so it's available during slot parsing
        -- when per-job XMLs are read below.
        self.shared_icons = {}
        if storage.shared_icons_file:exists() then
            if self:load_shared_icons(storage.shared_icons_file) == false then
                error('Could not read SharedIcons.xml; existing files were retained.')
            end
        elseif self.auto_create_xml then
            self:create_shared_icons()
        end

        -- Both catalogs are readable; the setting affects only new saves.
        local catalog_ok,catalog_error=self:refresh_custom_catalogs(false)
        if not catalog_ok then error(catalog_error) end

        -- if normal hotbar file exists, load it. If not, create a default hotbar
        if storage.file:exists() then
            if self:load_from_file(storage.file) == false then error(storage.hotbar_read_error) end
        elseif self.auto_create_xml then
            newly_created = true
            self:create_default_hotbar()
        end

        -- if job default file exists, load it. If not, create a default version
        if storage.job_default_file:exists() then
            if self:load_from_file(storage.job_default_file) == false then error(storage.hotbar_read_error) end
        elseif self.auto_create_xml then
            newly_created = true
            self:create_job_default_hotbar()
        end

        -- if all jobs file exists, load it. If not, create a default version
        if storage.all_jobs_file:exists() then
            if self:load_from_file(storage.all_jobs_file) == false then error(storage.hotbar_read_error) end
        elseif self.auto_create_xml then
            newly_created = true
            self:create_all_jobs_default_hotbar()
        end

        -- if shared file exists, load it. If not, create an empty version
        if storage.shared_file:exists() then
            if self:load_from_file(storage.shared_file) == false then error(storage.hotbar_read_error) end
        elseif self.auto_create_xml then
            newly_created = true
            self:create_shared_hotbar()
        end

        if (newly_created) then
            player:store_new_hotbars()
        end
        if not self.has_reported_load then
            windower.add_to_chat(207, '[XIVCrossbar] Loaded crossbar sets for ' .. self.main_job .. '/' .. (self.sub_job or 'NOSUB') .. ' (job, defaults and shared).')
            self.has_reported_load = true
        end
    end)
    if not ok then
        self.hotbar, self.shared_icons, self.custom_actions =
            previous.hotbar, previous.shared_icons, previous.custom_actions
        storage.hotbar_read_error = storage.hotbar_read_error or tostring(err)
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar load failed; the previous bars were retained. ' .. tostring(err))
        return false
    end
    self:sync_catalog_bindings(true)
    self.hotbar_load_ok = true
    self.last_created_files = storage.created_files
    return true
end

-- Main/subjob can arrive as two events. Load immediately, but coalesce only
-- their notices so chat reports the final combination and all new XML files.
function player:queue_job_change_notice()
    self.job_notice_files = self.job_notice_files or {}
    for _, name in ipairs(self.last_created_files or {}) do
        self.job_notice_files[name] = true
    end
    self.job_notice_generation = (self.job_notice_generation or 0) + 1
    local generation = self.job_notice_generation
    coroutine.schedule(function()
        if generation ~= self.job_notice_generation then return end
        local names = {}
        for name in pairs(self.job_notice_files) do names[#names + 1] = name end
        table.sort(names)
        self.job_notice_files = nil
        if not self.hotbar_load_ok then return end
        local created = #names > 0 and ' (created ' .. table.concat(names, ', ') .. ')' or ''
        windower.add_to_chat(207, '[XIVCrossbar] Crossbar sets ready for ' ..
            self.main_job .. '/' .. (self.sub_job or 'NOSUB') .. created .. '.')
    end, 0.3)
end

function kebab_casify(str)
    return str:lower():gsub(' ', '-'):gsub('\'', '')
end

-- Map on-disk slot names back to the integer form the rest of the code uses.
-- Old numeric-style names ('1'..'9') pass through unchanged for backward compat.
local slot_name_to_int = {
    ll = '1', ld = '2', lr = '3', lu = '4',
    rl = '5', rd = '6', rr = '7', ru = '8',
    zz = '9',
}

local function normalize_slot_id(raw)
    return slot_name_to_int[raw] or raw
end

-- Map on-disk hotbar names back to the integer form the rest of the code uses.
-- Old numeric-style names ('1'..'6') pass through unchanged for backward compat.
local hotbar_name_to_int = {
    l  = '1',
    r  = '2',
    rl = '3',
    lr = '4',
    ll = '5',
    rr = '6',
}

local function normalize_hotbar_id(raw)
    return hotbar_name_to_int[raw] or raw
end

-- load a hotbar from existing file
function player:load_from_file(storage_file)
    local contents, parse_error = xml.read(storage_file)

    if not contents or contents.name ~= 'hotbar' then
        local path = storage_file.path or storage.filename
        storage.hotbar_read_error = tostring(path) .. ': ' .. (parse_error or 'Expected a hotbar XML document.')
        windower.add_to_chat(123, '[XIVCrossbar] Could not load ' .. storage.hotbar_read_error)
        windower.add_to_chat(123, '[XIVCrossbar] Hotbar saving is paused to preserve your files. Correct the XML and reload.')
        return false
    end

    -- parse xml to hotbar
    for key, environment in ipairs(contents.children) do
        -- A: the XML tag owns identity/scope; <name> is only its label.
        -- Create empty sets too, rather than relying on finding a slot first.
        local environment_key = kebab_casify(environment.name)
        local environment_name = nil
        for key, hotbar in ipairs(environment.children) do     -- hotbar number
            if (hotbar.name == 'name') then
                for key, name in ipairs(hotbar.children) do
                    environment_name = name.value
                end
            end
        end
        if (environment_name == nil) then
            environment_name = environment.name
        end
        if not self.hotbar[environment_key] then
            self.hotbar[environment_key] = {}
            self:setup_environment_hotbars(environment_key)
        end
        self.hotbar[environment_key].name = environment_name
        for key, hotbar in ipairs(environment.children) do     -- hotbar number
            if (hotbar.name ~= 'name') then
                local hotbar_id = normalize_hotbar_id(hotbar.name:gsub('hotbar_', ''))
                -- Bars outside the configured visible count still belong to
                -- the saved file. Retain them without enabling their UI/input.
                local hotbar_key = 'hotbar_' .. hotbar_id
                self.hotbar[environment_key][hotbar_key] = self.hotbar[environment_key][hotbar_key] or {}
                for key, slot in ipairs(hotbar.children) do       -- slot number
                    local new_action = {}
                    local fallback_alias

                    for key, tag in ipairs(slot.children) do   -- action
                        local value = tag.children and tag.children[1] and tag.children[1].value
                        if tag.name == 'type' then
                            new_action.type = value
                        elseif tag.name == 'action' then
                            new_action.action = value and unescape(value) or nil
                        elseif tag.name == 'target' then
                            if tag.children[1] == nil then
                                new_action.target = nil
                            else
                                new_action.target = tag.children[1].value
                            end

                        elseif tag.name == 'alias' then
                            fallback_alias = value
                            if (settings.Hotbar.HideActionName == true) then
                                new_action.alias = ' '
                            else
                                new_action.alias = value
                            end
                        elseif tag.name == 'icon' then
                            new_action.icon = value
                        elseif tag.name:match('^catalog_') then
                            new_action[tag.name] = value
                        elseif tag.name == 'equip_slot' then
                            new_action.equip_slot = value
                        elseif tag.name == 'warmup' then
                            new_action.warmup = value
                        elseif tag.name == 'cooldown' then
                            new_action.cooldown = value
                        elseif tag.name == 'usable' then
                            new_action.usable = value
                        elseif tag.name == 'linked_action' then
                            if tag.children[1] ~= nil then
                                new_action.linked_action = tag.children[1].value
                            end
                        elseif tag.name == 'linked_type' then
                            if tag.children[1] ~= nil then
                                new_action.linked_type = tag.children[1].value
                            end
                        end
                    end

                    -- Older blank console slots can still execute their alias.
                    if new_action.type == 'ex' and (not new_action.action or new_action.action == '')
                        and fallback_alias and fallback_alias:match('%S') then
                        new_action.action = fallback_alias
                    end

                    if (new_action.icon == nil and self.shared_icons ~= nil) then
                        if (new_action.action ~= nil and self.shared_icons[new_action.action] ~= nil) then
                            new_action.icon = self.shared_icons[new_action.action]
                        elseif (new_action.alias ~= nil and self.shared_icons[new_action.alias] ~= nil) then
                            new_action.icon = self.shared_icons[new_action.alias]
                        end
                    end

                    self:add_action(
                        action_manager:build(new_action.type, new_action.action, new_action.target, new_action.alias, new_action.icon, new_action.equip_slot, new_action.warmup, new_action.cooldown, new_action.usable, new_action.linked_action, new_action.linked_type),
                        environment_key,
                        hotbar_id,
                        normalize_slot_id(slot.name:gsub('slot_', ''))
                    )
                end
            end
        end
    end
    return true
end

-- A: a missing layer file may contain sets already imported from another
-- XML. Populate only absent sets/bars so creating that file retains the imports.
local function ensure_default_set(self, key, name)
    self.hotbar[key] = self.hotbar[key] or {}
    self.hotbar[key].name = self.hotbar[key].name or name
    self:setup_environment_hotbars(key)
end

-- create a default hotbar
function player:create_default_hotbar()
    ensure_default_set(self, 'default', 'Default')
    ensure_default_set(self, 'basic', 'Basic')
end

-- create a fallback hotbar that applies to all subjobs of this job
function player:create_job_default_hotbar()
    ensure_default_set(self, 'job-default', 'Job Default')
end

-- create a fallback hotbar that applies to all jobs on this character
function player:create_all_jobs_default_hotbar()
    ensure_default_set(self, 'all-jobs-default', 'All Jobs Default')
end

-- create an empty shared hotbar that is selectable but does not participate in fallback layering
function player:create_shared_hotbar()
    ensure_default_set(self, 'shared', 'Shared')
end

-- Parse SharedIcons.xml into player.shared_icons as a simple name→path table.
-- Entries with empty/missing name or icon are silently skipped.
function player:load_shared_icons(storage_file)
    self.shared_icons = {}
    local contents = xml.read(storage_file)
    if (contents == nil or contents.name ~= 'shared_icons') then
        windower.add_to_chat(123, '[XIVCrossbar] SharedIcons.xml is malformed; reload after correcting it.')
        return false
    end

    for _, entry in ipairs(contents.children) do
        if (entry.name == 'entry') then
            local entry_name = nil
            local entry_icon = nil
            for _, tag in ipairs(entry.children) do
                if (tag.name == 'name' and tag.children[1] ~= nil) then
                    entry_name = tag.children[1].value
                elseif (tag.name == 'icon' and tag.children[1] ~= nil) then
                    entry_icon = tag.children[1].value
                end
            end
            if (entry_name ~= nil and entry_name ~= '' and entry_icon ~= nil and entry_icon ~= '') then
                self.shared_icons[entry_name] = entry_icon
            end
        end
    end
end

function player:save_shared_icons_file()
    if storage.hotbar_read_error then error('Reload successfully before saving icons.') end
    if (storage.shared_icons_file == nil) then return end

    local keys = {}
    for name in pairs(self.shared_icons) do
        if (name ~= nil and name ~= '') then
            table.insert(keys, name)
        end
    end
    table.sort(keys)

    local lines = L{}
    lines:append('<shared_icons>')
    for _, name in ipairs(keys) do
        local icon = self.shared_icons[name]
        if (icon ~= nil and icon ~= '') then
            lines:append('    <entry>')
            lines:append('        <icon>' .. icon:xml_escape() .. '</icon>')
            lines:append('        <name>' .. name:xml_escape() .. '</name>')
            lines:append('    </entry>')
        end
    end
    lines:append('</shared_icons>')
    lines:append('')

    storage:write_file(storage.shared_icons_file, table.concat(lines, '\n'))
end

function player:create_shared_icons()
    self.shared_icons = {}
    local template = {
        shared_icons = {
            entry = {
                name = '',
                icon = '',
            }
        }
    }
    storage:write_file(storage.shared_icons_file, table.to_xml(template))
end

local function read_catalog_file(path)
    local f,err=io.open(path,'rb')
    if not f then
        -- Missing catalog is an empty source, never an empty replacement file.
        local relative=path:sub(#windower.addon_path+1)
        if not file.new(relative):exists() then return nil end
        return nil,err or ('Could not read '..path)
    end
    local raw=f:read('*a');f:close();return raw
end

local catalog_id_counter=0

function player:catalog_save_scope()
    return self.custom_action_save_scope=='character' and 'character' or 'global'
end

function player:refresh_custom_catalogs(sync)
    if not self.identity_confirmed or not storage.identity_valid then return false,'Log in before reading character catalogs.' end
    local sources={}
    local raw_sources={}
    for _,scope in ipairs({'global','character'}) do
        local path=scope=='global' and storage.global_catalog_path or storage.character_catalog_path
        local raw,read_error=read_catalog_file(path)
        if read_error then return false,read_error end
        local records,parse_error
        if self.catalog_raw and self.catalog_raw[scope]==raw and self.catalog_sources then
            records=self.catalog_sources[scope]
        else records,parse_error=catalog.decode(raw,xml.parse) end
        raw_sources[scope]=raw
        if not records then return false,path..': '..tostring(parse_error) end
        sources[scope]=records
    end
    self.catalog_sources,self.catalog_raw=sources,raw_sources
    self.custom_actions=catalog.view(sources.global,sources.character,self:catalog_save_scope())
    return true,sync~=false and self:sync_catalog_bindings(false) or false
end

function player:sync_catalog_bindings(adopt_legacy)
    local changed=false
    for _,environment in pairs(self.hotbar or {}) do
        if type(environment)=='table' then
            for key,bar in pairs(environment) do
                if type(bar)=='table' and key:match('^hotbar_') then
                    for _,slot in pairs(bar) do
                        if type(slot)=='table' and slot.action then
                            if adopt_legacy and not slot.catalog_id then
                                local record,scope=catalog_bindings.legacy_match(slot,self.catalog_sources)
                                if record then catalog_bindings.attach(slot,record,scope) end
                            end
                            if slot.catalog_id then
                                local record=catalog_bindings.find(self.catalog_sources[slot.catalog_scope],slot.catalog_id)
                                if record and catalog_bindings.apply(slot,record) then changed=true end
                            end
                        end
                    end
                end
            end
        end
    end
    return changed
end

function player:find_custom_action(name)
    return catalog.find(self.custom_actions or {},name,self:catalog_save_scope())
end

function player:custom_name_available(name,original_key)
    if type(name)~='string' or not name:match('%S') then return false end
    local original=original_key and self.custom_actions[original_key]
    local scope=original and original._scope or self:catalog_save_scope()
    local found=self.catalog_sources and self.catalog_sources[scope][name]
    return not found or (original and original.name==name)
end

function player:save_catalog_edit(original_key,record)
    if storage.hotbar_read_error or not storage.identity_valid then return false,'Reload successfully after login before saving.' end
    local original=original_key and self.custom_actions[original_key]
    if original_key and not original then return false,'Catalog entry no longer exists; reopen the action.' end
    local expected=record and record._expected or original
    local scope=original and original._scope or (record and record._scope) or self:catalog_save_scope()
    local path=scope=='global' and storage.global_catalog_path or storage.character_catalog_path
    windower.create_dir(path:match('^(.*)[/\\]'))
    local backend=require('windows_file').new()
    local next_record=catalog.copy(record)
    if next_record then
        catalog_id_counter=catalog_id_counter+1
        next_record.id=original and original.id or next_record.id or (self.name..':'..backend.pid..':'..tostring(require('socket').gettime())..':'..catalog_id_counter)
    end
    local ok,err=catalog.save({lock=backend.lock,replace=backend.replace,read=read_catalog_file,parse=xml.parse},path,expected,next_record)
    if not ok then return false,err end
    -- Use the committed snapshot as this draft's revision. A different client
    -- may edit immediately afterwards; rereading here must not bless its edits
    -- as this draft's expected version.
    self.catalog_sources[scope]=err
    self.catalog_raw[scope]=nil
    self.custom_actions=catalog.view(self.catalog_sources.global,self.catalog_sources.character,self:catalog_save_scope())
    self:sync_catalog_bindings(false)
    if record then
        local _,key=catalog.find(self.custom_actions,record.name,scope)
        record._scope,record._key,record.id=scope,key,next_record.id
        record._expected=catalog.copy(next_record)
    end
    return true
end

function player:store_new_hotbars()
    local new_hotbar = {}
    new_hotbar.hotbar = self.hotbar

    storage:store_new_hotbar(new_hotbar)
end

-- reset player hotbar
function player:reset_hotbar()
    self.hotbar = {}

    self.hotbar_settings.active_hotbar = 1
end

function player:setup_environment_hotbars(environment)
    for h=1,self.hotbar_settings.max,1 do
        local bar_key = 'hotbar_' .. h
        self.hotbar[environment][bar_key] = self.hotbar[environment][bar_key] or {}

        -- This is a hack to make sure all newly-created crossbars show up in the crossbar set selector
        self.hotbar[environment][bar_key]['slot_9'] = self.hotbar[environment][bar_key]['slot_9'] or {}
    end
end

-- set bar environment
function player:set_active_environment(environment)
    self.hotbar_settings.active_environment = kebab_casify(environment)
end

-- is valid environment
function player:is_valid_environment(environment)
    return self.hotbar[environment] ~= nil
end

function player:set_is_in_battle(in_battle)
    self.in_battle = in_battle
end

-- set bar environment to battle
function player:set_battle_environment(in_battle)
    local environment = 'Field'
    if in_battle then environment = 'Battle' end

    self.hotbar_settings.active_environment = environment
end

-- change active hotbar
function player:change_active_hotbar(new_hotbar)
    self.hotbar_settings.active_hotbar = new_hotbar

    if self.hotbar_settings.active_hotbar > self.hotbar_settings.max then
        self.hotbar_settings.active_hotbar = 1
    end
end

function player:get_crossbar_names()
    local names = L{}

    for name, hotbar in pairs(self.hotbar) do
        names:append(hotbar.name or name)
    end

    return names
end

-- add given action to a hotbar
function player:add_action(action, environment, hotbar, slot)
    if environment == nil or environment == '' then
        return
    end

    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    local env_key = kebab_casify(environment)
    if (env_key == nil) then
        return
    end

    if self.hotbar[env_key] == nil then
        self.hotbar[env_key] = {}
        self.hotbar[env_key]['name'] = environment
        self:setup_environment_hotbars(env_key)
    end

    if self.hotbar[env_key]['hotbar_' .. hotbar] == nil then
        windower.console.write('XIVCROSSBAR: invalid hotbar (hotbar number)')
        return
    end

    if self.hotbar[env_key]['hotbar_' .. hotbar]['slot_' .. slot] == nil then
        self.hotbar[env_key]['hotbar_' .. hotbar]['slot_' .. slot] = {}
    end

    self.hotbar[env_key]['hotbar_' .. hotbar]['slot_' .. slot] = action
end

function create_send_command_coroutine(command)
    return function()
        windower.send_command(command)
    end
end

function player:create_use_item_coroutine(item_name)
    local enchanted_items = self.enchanted_items
    return function()
        enchanted_items:use(item_name)
    end
end

function player:execute_action(slot)
    local h = self.hotbar_settings.active_hotbar
    local env = self.hotbar_settings.active_environment

    local action = self.hotbar[env]['hotbar_' .. h]['slot_' .. slot]
    local is_missing = action == nil or action.action == nil

    if (is_missing and env ~= 'default' and env ~= 'job-default' and env ~= 'all-jobs-default' and self.hotbar['default'] and self.hotbar['default']['hotbar_' .. h] and
        self.hotbar['default']['hotbar_' .. h]['slot_' .. slot]) then
        action = self.hotbar['default']['hotbar_' .. h]['slot_' .. slot]
    elseif (is_missing and env ~= 'job-default' and env ~= 'all-jobs-default' and self.hotbar['job-default'] and self.hotbar['job-default']['hotbar_' .. h] and
        self.hotbar['job-default']['hotbar_' .. h]['slot_' .. slot]) then
        action = self.hotbar['job-default']['hotbar_' .. h]['slot_' .. slot]
    elseif (is_missing and env ~= 'all-jobs-default' and self.hotbar['all-jobs-default'] and self.hotbar['all-jobs-default']['hotbar_' .. h] and
        self.hotbar['all-jobs-default']['hotbar_' .. h]['slot_' .. slot]) then
        action = self.hotbar['all-jobs-default']['hotbar_' .. h]['slot_' .. slot]
    end

    if action and action.catalog_id then self:refresh_custom_catalogs() end
    local is_still_missing = action == nil or action.action == nil
    if (is_still_missing) then return end

    if action.type == 'switch' then
        local target_env = kebab_casify(action.action or '')
        if (not self:is_valid_environment(target_env)) then
            windower.add_to_chat(123, '[XIVCrossbar] Cannot switch - set "' .. tostring(action.action) .. '" not found in current job.')
            return
        end
        if (self.temp_switch_previous_env == nil) then
            self.temp_switch_previous_env = env
        end
        self.pending_env_switch = target_env
        return
    end

    self:dispatch_action(action)

    if (self.temp_switch_previous_env ~= nil) then
        self.pending_env_switch = self.temp_switch_previous_env
        self.temp_switch_previous_env = nil
    end
end

function player:dispatch_action(action)
    if action.type == 'ct' then
        local command = '/' .. action.action

        if  action.target ~= nil then
            command = command .. ' <' ..  action.target .. '>'
        end

        windower.send_command('input ' .. command)
        return
    end

    if action.type == 'gs' then
        local command = 'gs equip '

        if  action.target ~= nil then
            command = command .. action.action
        end
        windower.send_command(command)
        return
    end
    if action.type == 'gsc' then
        local command = 'gs c cycle '
        command = command .. action.action
        windower.send_command(command)
        return
    end

    if action.type == 'ex' then
        windower.send_command(action.action)
        return
    end

    if action.type == 'enchanteditem' then
        local item = action.action
        local equip_slot = action.equip_slot
        local delay = 0.5
        if (action.warmup ~= nil) then
            delay = delay + action.warmup
        end
        local recast = action.cooldown

        if (equip_slot ~= nil) then
            windower.send_command('gs disable ' .. equip_slot)
            windower.send_command('input /equip '.. equip_slot .. ' "' .. item .. '"')
            self.enchanted_items:equip(item)
        end

        local use_item = create_send_command_coroutine('input /item "' .. item .. '" <' .. action.target .. '>')
        coroutine.schedule(use_item, delay)
        local mark_used_item = player:create_use_item_coroutine(item)
        coroutine.schedule(mark_used_item, delay)

        if (equip_slot ~= nil) then
            local reactivate_equip_slot = create_send_command_coroutine('gs enable ' .. equip_slot)
            coroutine.schedule(reactivate_equip_slot, delay + 2)
        end
        return
    end

    local target_string = ''
    if (action.target ~= nil) then
        target_string = '" <' .. action.target .. '>'
    end

    if action.type == 'mount' then
        if is_player_mounted() then
            windower.send_command('input /dismount')
            return
        elseif action.action == 'Mount Roulette' then
            mount_roulette:ride_random_mount()
            return
        elseif action.action ~= 'Mount Roulette' then
            windower.send_command('input /' .. action.type .. ' "' .. action.action .. '"' .. target_string)
            return
        end
    elseif (action.type == 'ta' and action.action == 'Switch Target' and action.alias == 'Switch Target') then
        if (self.in_battle) then
            windower.send_command('input /a ' .. target_string)
        else
            windower.send_command('input /ta ' .. target_string)
        end
        return
    end

    -- run all other actions
    windower.send_command('input /' .. action.type .. ' "' .. action.action .. target_string)

    -- switch to avatars bar if it exists
    -- TODO: Check if this is redundant, Aliekber mentioned he wanted to implement this at some point
	if action.type == 'ma' and avatar_names:contains(action.action:capitalize()) then
		local env = nil
		local abil_name_lc = action.action:lower()
        abil_name_lc = abil_name_lc:gsub("%s+","") -- TODO: removes whitespace, is there a more readable way of doing this, e.g. "trim" or something? If not, make a helper library for this.

		for hb,_ in pairs(self.hotbar) do
            -- TODO: Change this so that it is case insensitive
			if abil_name_lc == hb:lower() or abil_name_lc:startswith(hb:lower()) then
				env = hb
				break
			end
		end

		if env ~= nil then
			set_active_environment(env)
		end
	elseif action.type == 'pet' and action.action:capitalize() == "Release" then -- go back to basic if release is used.
		-- TODO: Implement a fallback in case a player has no basic hotbar
        set_active_environment("basic")
	end

    -- switch to set defined in job_abilities (without spaces)
    -- TODO: This looks redundant to the bit above, they can probably be merged into one block.
	if action.type == 'ja' and job_abilities:contains(action.action:capitalize()) then
		local env = nil
		local abil_name_lc = action.action:lower()
		abil_name_lc = abil_name_lc:gsub("%s+","") -- TODO: removes whitespace, is there a more readable way of doing this, e.g. "trim" or something? If not, make a helper library for this.

        for hb,_ in pairs(self.hotbar) do
			if abil_name_lc == hb:lower() or abil_name_lc:startswith(hb:lower()) then
				env = hb
				break
			end
		end

		if env ~= nil then
			set_active_environment(env)
		end
	end
end

-- remove action from slot
function player:remove_action(environment, hotbar, slot)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    if self.hotbar[environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil then return end

    self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] = nil
end

-- update a slot's icon
function player:set_slot_icon(environment, hotbar, slot, icon)
    if (environment == nil) then return false end
    if (self.hotbar[environment] == nil) then return false end
    local hb = self.hotbar[environment]['hotbar_' .. hotbar]
    if (hb == nil) then return false end
    local action = hb['slot_' .. slot]
    if (action == nil or action.action == nil) then return false end
    action.icon = icon
    return true
end

-- copy action from one slot to another
function player:copy_action(environment, hotbar, slot, to_environment, to_hotbar, to_slot, is_moving)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if to_environment == 'b' then to_environment = 'battle' elseif to_environment == 'f' then to_environment = 'field' end
    if slot == 10 then slot = 0 end
    if to_slot == 10 then to_slot = 0 end

    if self.hotbar[environment] == nil or self.hotbar[to_environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil or self.hotbar[to_environment]['hotbar_' .. to_hotbar] == nil then return end

    self.hotbar[to_environment]['hotbar_' .. to_hotbar]['slot_' .. to_slot] = self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot]

    if is_moving then self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] = nil end
end

-- update action alias
function player:set_action_alias(environment, hotbar, slot, alias)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    if self.hotbar[environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] == nil then return end

    self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot].alias = alias
end

-- update action icon
function player:set_action_icon(environment, hotbar, slot, icon)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    if self.hotbar[environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] == nil then return end

    self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot].icon = icon
end

-- create a new environment for the existing hotbar
function player:create_new_environment(name)
    -- A: every creation path must preserve existing normalized set keys.
    if type(name) ~= 'string' or not name:match('%S') then
        windower.add_to_chat(123, '[XIVCrossbar] A nonblank crossbar set name is required.')
        return false
    end
    local key = kebab_casify(name)
    -- Set keys become XML element names; rejecting unsafe keys avoids writing
    -- a file that cannot be loaded on the immediate reload.
    if not key:match('^[%a_][%w_.%-]*$') then
        windower.add_to_chat(123, '[XIVCrossbar] Use a set name starting with a letter, with letters, numbers, spaces, hyphens or underscores.')
        return false
    end
    if key == 'default' or key == 'job-default' or key == 'all-jobs-default' or key == 'shared' or self.hotbar[key] ~= nil then
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar set already exists or is reserved: ' .. name)
        return false
    end
    local new_environment = {name = name}
    for h=1,self.hotbar_settings.max do
        new_environment['hotbar_' .. h] = {}
        for i=1,8 do new_environment['hotbar_' .. h]['slot_' .. i] = {} end
    end
    self.hotbar[key] = new_environment
    return true
end

function get_player_buffs()
    return T(windower.ffxi.get_player().buffs)
end

function is_player_mounted()
    local _player = windower.ffxi.get_player()

    if _player then
        return _player.status == 85 or _player.status == 5 or get_player_buffs():contains(252)
    end

    return false
end

-- save current hotbar
function player:save_hotbar()
    local new_hotbar = {}
    new_hotbar.hotbar = self.hotbar

    storage:save_hotbar(new_hotbar)
end

return player
