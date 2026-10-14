-- Addon description
_addon.name = 'XIVCrossbar' -- based on Edeon's XIV Hotbar
_addon.author = 'Aliekber, various friendly neighborhood modders'
-- Credit goes to: Aeliya, BlueSummersC, FionaBrightgrass, GrayFox2510, Icydeath, qEagleStrikerp, Sylvebits, XerevNonori
_addon.version = '0.4.0-a.20261014.personal6-2'
_addon.language = 'english'
_addon.commands = {'xivcrossbar', 'xb', 'xcb'}

-- Libs
res = require 'resources'
config = require('config')
file = require('files')
texts = require('texts')
images = require('images')
tables = require('tables')
resources = require('resources')
xml = require('libs/xml2')   -- TODO: REMOVE

-- User settings
local defaults = require('defaults')
local settings = config.load(defaults)
-- A: profile selection replaces the independent legacy backend flags. Existing
-- unused XML fields remain harmless; only one shared reader can be active.
local controller_profiles = require('controller_profiles')
local personal_profile = require('personal_profile')
local function normalize_controller_settings()
    local changed,notice = personal_profile.normalize(settings,defaults,controller_profiles)
    if notice then windower.add_to_chat(123,'[XIVCrossbar] '..notice) end
    if changed then config.save(settings) end
end
normalize_controller_settings()
-- Windower reparses per-character settings on load/login/logout. Run the same
-- migration after each parse so an older character section cannot revert it.
config.register(settings,normalize_controller_settings)
-- A: retain the preference for future last-client shutdown. Unload does not
-- consume this flag yet; //xb controller stop remains the explicit shared stop.

-- A: immutable for this load; changing one client cannot safely reconfigure
-- the wrapper shared by every client. Reload all clients after stopping it.
local controller_modifier = tostring(settings.ControllerModifier or 'apps'):lower()
if controller_modifier ~= 'apps' and controller_modifier ~= 'ctrl' then
    controller_modifier = 'apps'
    windower.add_to_chat(123, '[XIVCrossbar] Invalid ControllerModifier; using apps.')
end
local controller_capture_dik = controller_modifier == 'ctrl' and 29 or 221
local controller_bind_prefix = controller_modifier == 'ctrl' and '^' or '#'

-- Load theme options according to settings
local character_identity = require('character_identity')
local theme = require('theme')
local theme_options = theme.apply(settings)
local buttonmapping = require('buttonmapping')
local resource_generator = require('resource_generator')
resource_generator.generate_outdated_resources()

-- Addon Dependencies
local action_manager = require('action_manager')
local keyboard = require('keyboard_mapper')
local gamepad = require('gamepad')
local transport = require('controller_transport')
local text_input_guard = require('text_input_guard')
local personal_controls = require('personal_controls').new()
local publish_personal_context
local visibility = require('visibility')
local player = require('player')
local ui = require('ui')
local env_chooser = require('environment_chooser')
local action_binder = require('action_binder')
local enchanted_items = require('enchanted_items')
local xivcrossbar = require('variables')
local skillchains = require('libs/skillchain/skillchains')
local consumables = require('consumables')
local gamepad_mapper = require('gamepad_mapper')
local gamepad_converter = require('gamepad_converter')
local function_key_bindings = require('function_key_bindings')

-----------------------------
-- Main
-----------------------------

local gamepad_state = {}
gamepad_state.left_trigger = false
gamepad_state.left_trigger_doublepress = false
gamepad_state.right_trigger = false
gamepad_state.right_trigger_doublepress = false
gamepad_state.active_bar = 0
local shift_pressed = false
local menu_escape_down = false
local shift_keys_down = {}
local release_gameplay_keys
local ui_dirty = false
local restart_pending = false
local left_trigger_lifted_during_doublepress_window = false
local right_trigger_lifted_during_doublepress_window = false
local is_left_doublepress_window_open = false
local is_right_doublepress_window_open = false
local y_adjust = 450

local function move_crossbars(x,y)
    ui:move_to(x,y)
    env_chooser:set_anchor(ui:get_set_chooser_anchor())
end

local crossbar_drag = require('ui_drag').new({
    enabled=function()
        return xivcrossbar.ready and ui.is_setup and ui.public_visible == true
            and ui.geometry.opacity > .01
    end,
    bounds=function() return ui:get_drag_bounds() end,
    offsets=function() return settings.Style.OffsetX,settings.Style.OffsetY end,
    move=function(x,y)
        settings.Style.OffsetX,settings.Style.OffsetY=x,y
        theme_options.offset_x, theme_options.offset_y = x,y
        move_crossbars(x,y)
    end,
    save=function() config.save(settings) end,
})

local function set_compact_mode(mode)
    mode = mode and mode:lower()
    if mode and mode ~= 'on' and mode ~= 'off' then
        windower.add_to_chat(123, '[XIVCrossbar] //xb compact [on|off]')
        return
    end
    local enabled = mode == 'on' or (not mode and not settings.iscompact)
    crossbar_drag:finish()
    settings.iscompact, theme_options.is_compact = enabled, enabled
    ui:set_compact(enabled)
    if ui.is_setup then env_chooser:set_anchor(ui:get_set_chooser_anchor()) end
    ui_dirty = true
    config.save(settings)
    windower.add_to_chat(207, '[XIVCrossbar] Compact: ' .. (enabled and 'ON' or 'OFF'))
end
windower.register_event('mouse',function(kind,x,y,delta,blocked)
    return crossbar_drag:mouse(kind,x,y,blocked)
end)

local function close_left_doublepress_window()
    is_left_doublepress_window_open = false
    left_trigger_lifted_during_doublepress_window = false
end

local function close_right_doublepress_window()
    is_right_doublepress_window_open = false
    right_trigger_lifted_during_doublepress_window = false
end

-- command to set a crossbar action in action_binder
function set_hotkey(hotbar, slot, action_type, action, target, command, icon, linked_action, linked_type, explicit_alias)
    if player.hotbar_load_ok == false then
        windower.add_to_chat(123, '[XIVCrossbar] Reload successfully before binding. Existing files were not changed.')
        return false
    end
    local environment = player.hotbar_settings.active_environment

    -- Custom-action bindings provide their own alias/linked metadata from the
    -- CustomActions.xml catalog, so the legacy name-based special cases below
    -- (which exist for the Attack / Ranged Attack / Assist / Last Synth
    -- categories) must not run — otherwise a custom action named "Attack"
    -- would get stomped. explicit_alias being non-nil is the signal that
    -- the caller knows exactly what it wants.
    local is_custom_action = (explicit_alias ~= nil or linked_action ~= nil or linked_type ~= nil)

    local alias = explicit_alias
    if is_custom_action and not require('custom_action_review').nonempty(alias) then alias = action end
    if (not is_custom_action) then
        if (action == 'Ranged Attack') then
            action = 'ra'
            alias = 'Ranged Attack'
            icon = 'ranged'
        elseif (action_type == 'ct' and action == 'Check') then
            action, alias, icon, target = 'check', 'Check', 'check', 't'
        elseif (action == 'Attack') then
            action = 'a'
            alias = 'Attack'
            icon = 'attack'
        elseif (action_type == 'assist') then
            action_type = 'ct'
            alias = action
            action = action:lower()
            icon = 'assist'
        elseif (action == 'Last Synth') then
            action = 'lastsynth'
            alias = 'Last Synth'
            icon = 'synth'
        elseif (action_type == 'ex' and action == icon) then
            alias = 'placeholder'
        elseif (action_type == 'ex' and (icon == 'home-point' or icon == 'survival-guide')) then
            alias = action
            local all = theme_options.enable_superwarp_all and ' all' or ''
            if (icon == 'home-point') then
                action = 'sw hp'.. all ..' '..alias
            else
                action = 'sw sg'.. all ..' '..alias
            end
        end
    end

    if is_custom_action and action_type == 'ex' and not require('custom_action_review').nonempty(command) then
        -- Preserve the blank catalog command; materialize only the slot's
        -- executable action using its explicit alias, then catalog name.
        action = require('custom_action_review').nonempty(alias) and alias or action
    elseif (command ~= nil and command ~= '') then
        -- If no explicit alias was provided, fall back to the human-readable
        -- action name being replaced by the raw command (existing behavior).
        if (alias == nil) then alias = action end
        action = command
    end

    local new_action = action_manager:build(action_type, action, target, alias, icon, nil, nil, nil, nil, linked_action, linked_type)
    player:add_action(new_action, environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
    local feedback=require('binding_feedback')
    windower.add_to_chat(207, feedback.bound(alias or action, feedback.set_name(player.hotbar,environment), hotbar, slot))
end

-- command to set a crossbar action in action_binder
function delete_hotkey(hotbar, slot)
    if player.hotbar_load_ok == false then
        windower.add_to_chat(123, '[XIVCrossbar] Reload successfully before clearing a binding. Existing files were not changed.')
        return false
    end
    local environment = player.hotbar_settings.active_environment

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
    local feedback=require('binding_feedback')
    windower.add_to_chat(207, feedback.cleared(feedback.set_name(player.hotbar,environment), hotbar, slot))
end

function get_crossbar_sets()
    return player:get_crossbar_names()
end

function create_new_set(name)
    if not player:create_new_environment(name) then return false end
    player:save_hotbar()
    reload_hotbar()
    windower.add_to_chat(207, '[XIVCrossbar] Created crossbar set: ' .. name)
    return true
end

-- Change Icon callback: replaces the icon of an already-bound slot, persists
-- the hotbar XML, and reloads so the new icon shows immediately. Wired into
-- action_binder.lua's :setup().
--   hotbar_num: 1-6 (which trigger combo: L/R/RL/LR/LL/RR)
--   slot_num: 1-8 (which face button or d-pad direction)
-- Operates on the currently-active environment.
function change_slot_icon(hotbar_num, slot_num, icon)
    if (hotbar_num == nil or slot_num == nil) then return end

    local environment = player.hotbar_settings.active_environment
    local updated = player:set_slot_icon(environment, hotbar_num, slot_num, icon)
    if (not updated) then
        windower.add_to_chat(123, '[XIVCrossbar] Change Icon: no action bound at the selected slot.')
        return
    end

    player:save_hotbar()
    reload_hotbar()
    set_active_environment(player.hotbar_settings.active_environment)
end

-- Global Icon Set callback: writes a SharedIcons.xml entry pairing an action
-- name with an icon path. After save, the SharedIcons fallback layer applies
-- the new icon to every slot in every job that matches the name (by alias or
-- action text). Wired into action_binder.lua's :setup().
function save_global_icon(name, icon)
    if (name == nil or name == '' or icon == nil or icon == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Global Icon Set: missing name or icon.')
        return
    end

    player.shared_icons[name] = icon
    player:save_shared_icons_file()
    reload_hotbar()
    set_active_environment(player.hotbar_settings.active_environment)

    windower.add_to_chat(123, '[XIVCrossbar] Global icon set: "' .. name .. '" -> ' .. icon)
end

-- Create Custom Action callback: persists a CustomActions.xml entry from a
-- record built up during the binder's create-flow. The record is the same
-- shape we read back via load_custom_actions: {name, alias, command, icon,
-- linked_action, linked_type}.
function save_custom_action(record)
    if player.hotbar_load_ok == false then
        windower.add_to_chat(123, '[XIVCrossbar] Reload successfully before saving custom actions.')
        return false
    end
    if (record == nil or record.name == nil or record.name == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Create Custom Action: missing name.')
        return false
    end
    -- A: a failed write must not leave a phantom saved catalog entry.
    local previous = player.custom_actions[record.name]
    player.custom_actions[record.name] = {
        command       = record.command,
        alias         = record.alias,
        icon          = record.icon,
        linked_action = record.linked_action,
        linked_type   = record.linked_type,
    }
    local ok, result = pcall(player.save_custom_actions_file, player)
    if not ok or result == false then
        player.custom_actions[record.name] = previous
        windower.add_to_chat(123, '[XIVCrossbar] Custom action was not saved. ' .. (not ok and tostring(result) or 'Reload and retry.'))
        return false
    end
    -- No reload needed for the catalog itself — the binder's existing
    -- "Custom Action" selector pulls from player.custom_actions in real time.
    windower.add_to_chat(207, '[XIVCrossbar] Custom action saved: "' .. record.name .. '"')
    return true
end

-- Edit Custom Action callback: persists changes to an existing entry,
-- handling rename by removing the old key before writing the new one. The
-- binder has already chat-warned the user about orphaned slot bindings if
-- the name changed.
function update_custom_action(original_name, record)
    if player.hotbar_load_ok == false then
        windower.add_to_chat(123, '[XIVCrossbar] Reload successfully before editing custom actions.')
        return false
    end
    if (record == nil or record.name == nil or record.name == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Edit Custom Action: missing name.')
        return false
    end
    local previous = player.custom_actions[original_name]
    local destination_previous = player.custom_actions[record.name]
    if (original_name ~= nil and original_name ~= record.name) then
        player.custom_actions[original_name] = nil
    end
    player.custom_actions[record.name] = {
        command       = record.command,
        alias         = record.alias,
        icon          = record.icon,
        linked_action = record.linked_action,
        linked_type   = record.linked_type,
    }
    local ok, result = pcall(player.save_custom_actions_file, player)
    if not ok or result == false then
        player.custom_actions[record.name] = destination_previous
        if original_name then player.custom_actions[original_name] = previous end
        windower.add_to_chat(123, '[XIVCrossbar] Custom action was not updated. ' .. (not ok and tostring(result) or 'Reload and retry.'))
        return false
    end
    windower.add_to_chat(207, '[XIVCrossbar] Custom action updated: "' .. record.name .. '"')
    return true
end

-- Delete Custom Action callback: removes an entry from the catalog and
-- rewrites CustomActions.xml. Slots that reference the deleted name are
-- left as-is; user is responsible for cleaning those up.
function delete_custom_action(name)
    if player.hotbar_load_ok == false then
        windower.add_to_chat(123, '[XIVCrossbar] Reload successfully before deleting custom actions.')
        return false
    end
    if (name == nil or name == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Delete Custom Action: missing name.')
        return false
    end
    if (player.custom_actions == nil or player.custom_actions[name] == nil) then
        windower.add_to_chat(123, '[XIVCrossbar] Delete Custom Action: entry "' .. name .. '" not found.')
        return
    end
    local previous = player.custom_actions[name]
    player.custom_actions[name] = nil
    local ok, result = pcall(player.save_custom_actions_file, player)
    if not ok or result == false then
        player.custom_actions[name] = previous
        windower.add_to_chat(123, '[XIVCrossbar] Custom action was not deleted. ' .. (not ok and tostring(result) or 'Reload and retry.'))
        return false
    end
    windower.add_to_chat(207, '[XIVCrossbar] Custom action deleted: "' .. name .. '". Existing slot bindings referencing it will not be auto-removed.')
    return true
end

-- A: the saved selection is per client; the running wrapper is shared.
local controller_switcher
local function controller_status()
    return controller_profiles.read_status(windower.addon_path .. 'data/controller-status.ini')
end
local function report_controller_status()
    local selected = settings.ControllerProfile .. ' / device ' .. settings.ControllerDevice
    windower.add_to_chat(207, '[XIVCrossbar] Selected: ' .. selected .. ' / ' .. controller_modifier)
    if controller_switcher and controller_switcher.pending then
        windower.add_to_chat(207, '[XIVCrossbar] Controller change: ' .. controller_switcher.pending.phase)
    end
    local status = controller_status()
    if status and status.running then
        windower.add_to_chat(207, '[XIVCrossbar] Running: ' .. status.profile .. ' / device ' .. status.device ..
            ' / ' .. status.modifier .. ' | source=' .. (status.origin or 'unknown') .. ' | ' .. status.state .. ' | connected=' .. tostring(status.connected == '1'))
        if status.profile=='ps5-extended' then
            windower.add_to_chat(207, '[XIVCrossbar] Personal: '..(status.personal_context or 'starting')..
                ' | PS hold='..(status.ps_hold or 'focus')..' | double tap='..
                (status.double_tap_ms or '250')..'ms')
        end
        if not controller_profiles.matches(status, settings.ControllerProfile, settings.ControllerDevice, controller_modifier)
            and not (controller_switcher and controller_switcher.pending) then
            windower.add_to_chat(123, '[XIVCrossbar] Running wrapper differs. Stop it, then start from the client with the desired selection.')
        end
    else
        windower.add_to_chat(207, '[XIVCrossbar] No fresh running-wrapper status. It may be stopped, starting, or an older wrapper.')
    end
end
function start_controller_wrappers(profile, device, modifier)
    profile = profile or settings.ControllerProfile
    device = device or settings.ControllerDevice
    modifier = modifier or controller_modifier
    local status = controller_status()
    if status and status.running then
        if not controller_profiles.matches(status, profile, device, modifier) then
            windower.add_to_chat(123, '[XIVCrossbar] Shared wrapper already uses another profile/device/modifier. Use //xb controller profile <name>.')
            return false
        end
        return true
    end
    -- Do not cancel a stop request before the existing process has consumed it.
    local stop_path = windower.addon_path .. 'data/input-stop.request'
    local request = io.open(stop_path, 'r')
    if request then
        local requested = tonumber(request:read('*a')); request:close()
        if not (status and status.fresh and status.state == 'stopped')
            and (not requested or os.time() - requested < 2) then
            windower.add_to_chat(207, '[XIVCrossbar] Stop is pending. Wait two seconds, then start again.')
            return false
        end
        os.remove(stop_path)
    end
    windower.create_dir(windower.addon_path .. 'data')
    local written, err = controller_profiles.write_launch(windower.addon_path .. 'data/controller-launch.ini',
        profile, device, modifier)
    if not written then
        windower.add_to_chat(123, '[XIVCrossbar] Could not save wrapper startup selection: ' .. tostring(err))
        return false
    end
    windower.send_command('run addons/xivcrossbar/ffxi_directinput.ahk ' .. modifier ..
        ' ' .. profile .. ' ' .. device)
    windower.add_to_chat(207, '[XIVCrossbar] Wrapper start requested: ' .. controller_profiles.short_name(profile) ..
        ' / device ' .. device .. ' / ' .. modifier)
    return true
end
local function stop_controller_wrapper()
    windower.create_dir(windower.addon_path .. 'data')
    local f = io.open(windower.addon_path .. 'data/input-stop.request', 'w')
    if not f then windower.add_to_chat(123, '[XIVCrossbar] Could not write wrapper stop request.'); return false end
    f:write(tostring(os.time())); f:close()
    windower.add_to_chat(207, '[XIVCrossbar] Shared wrapper stop requested for all clients.')
    return true
end
controller_switcher = require('controller_switch').new({
    clock=require('socket').gettime, status=controller_status,
    stop=stop_controller_wrapper, start=start_controller_wrappers,
    stop_pending=function()
        local f=io.open(windower.addon_path .. 'data/input-stop.request', 'r')
        if f then f:close(); return true end
        return false
    end,
})
windower.register_event('prerender', function() controller_switcher:step() end)
local function select_controller_profile(name, device, done)
    if not name then report_controller_status(); return end
    local profile, result = controller_profiles.validate(name, device or 1)
    if not profile then
        windower.add_to_chat(123, '[XIVCrossbar] ' .. result)
        if done then done(false, result) end
        return false
    end
    settings.ControllerProfile, settings.ControllerDevice = profile, result
    settings.PersonalProfileMigrated = true
    config.save(settings)
    windower.add_to_chat(207, '[XIVCrossbar] Selecting ' .. controller_profiles.short_name(profile) ..
        ' / device ' .. result .. (controller_profiles.profiles[profile].experimental and ' (experimental)' or ''))
    return controller_switcher:request(profile, result, controller_modifier, function(ok, detail)
        if ok then
            windower.add_to_chat(207, '[XIVCrossbar] Controller: ' .. controller_profiles.short_name(profile) .. ' / ' .. detail.state)
        elseif detail ~= 'Controller change cancelled.' and detail ~= 'Replaced by another controller selection.' then
            windower.add_to_chat(123, '[XIVCrossbar] ' .. tostring(detail))
        end
        if done then done(ok, detail) end
    end)
end

-- initialize addon
function initialize()
    local windower_player = windower.ffxi.get_player()
    local server = character_identity.resolve(windower.ffxi.get_info(), windower_player, resources.servers)
    if not server then
        xivcrossbar.ready = false
        storage.identity_valid = false
        return false
    end
    player.identity_confirmed = true

    -- A: config has refreshed character overrides by login. Build the layout
    -- from that table instead of the global theme cached before character load.
    theme_options = theme.apply(settings)

    if (buttonmapping.validate()) then
        theme_options.button_layout = buttonmapping.button_layout
        action_binder:setup(buttonmapping, set_hotkey, delete_hotkey, theme_options, get_crossbar_sets, 150, 150, windower.get_windower_settings().ui_x_res - 300,
            windower.get_windower_settings().ui_y_res - y_adjust, change_slot_icon, save_global_icon, save_custom_action, update_custom_action, delete_custom_action, create_new_set)
    else
        theme_options.button_layout = 'nintendo'
        local temp_buttonmapping = {}
        theme_options.confirm_button = 'a'
        theme_options.cancel_button = 'b'
        theme_options.mainmanu_button = 'y'
        theme_options.activewindow_button = 'x'
        gamepad_mapper:setup(buttonmapping, start_controller_wrappers, theme_options, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - y_adjust,
            {default_profile=defaults.ControllerProfile, select=function(profile, done)
                local device = profile == settings.ControllerProfile and settings.ControllerDevice or 1
                return select_controller_profile(profile, device, done)
            end})
        gamepad_mapper:show(true)
        action_binder:setup(temp_buttonmapping, set_hotkey, delete_hotkey, theme_options, get_crossbar_sets, 150, 150, windower.get_windower_settings().ui_x_res - 300,
            windower.get_windower_settings().ui_y_res - y_adjust, change_slot_icon, save_global_icon, save_custom_action, update_custom_action, delete_custom_action, create_new_set)
    end

    player:initialize(windower_player, server, theme_options, enchanted_items)
    if player:load_hotbar() == false then
        xivcrossbar.ready = false
        return
    end
    ui:setup(theme_options, enchanted_items)
    action_binder:set_ui_offset_callback(function(x, y)
        move_crossbars(x, y)
        if (settings.Style.OffsetX ~= x) then
            settings.Style.OffsetX = x
        end
        if (settings.Style.OffsetY ~= y) then
            settings.Style.OffsetY = y
        end
        config.save(settings)
    end)

    local default_active_environment = env_chooser:get_default_active_environment(player.hotbar)
    if not default_active_environment then
        windower.add_to_chat(123, '[XIVCrossbar] No crossbar sets are available. Check the XML files and reload.')
        xivcrossbar.ready = false
        ui:hide()
        return
    end
    set_active_environment(default_active_environment)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)

    consumables:setup()
    env_chooser:setup(theme_options)
    env_chooser:set_anchor(ui:get_set_chooser_anchor())
    gamepad_converter:setup(theme_options.button_layout)

    local current_player = windower.ffxi.get_player()
    ui.autoattack:set_engaged(current_player.status == 1 or current_player.status == 3, current_player.buffs)

    xivcrossbar.ready = true
    xivcrossbar.initialized = true
end

-- trigger hotbar action
function trigger_action(slot)
    if settings.InputTest then
        windower.add_to_chat(207, '[XIVCrossbar test] Crossbar ' .. tostring(gamepad_state.active_bar) .. ' slot ' .. slot .. ' — dummy action')
        ui:trigger_feedback(player.hotbar_settings.active_hotbar, slot)
        return
    end
    player:execute_action(slot)

    if (player.pending_env_switch ~= nil) then
        local target = player.pending_env_switch
        player.pending_env_switch = nil
        set_active_environment(target)
    end

    ui:trigger_feedback(player.hotbar_settings.active_hotbar, slot)
end

-- set battle environment
function set_battle_environment(in_battle)
    player:set_battle_environment(in_battle)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- set active environment
function set_active_environment(environment_name)
    player:set_active_environment(environment_name)
    action_binder:refresh_set_title()
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- The chooser's Add New Set row is UI state, never an executable hotbar.
local function select_chooser_environment(name)
    local was_typing=env_chooser.capturing
    env_chooser:cancel_name_entry()
    if player.hotbar[name] then set_active_environment(name) end
    env_chooser:show_player_environments(player.hotbar,name,ui:get_set_chooser_anchor())
    if was_typing and not gamepad_state.plus_button then env_chooser:close() end
    ui_dirty=true
end

-- check validity of an environment
function is_valid_environment(environment_name)
    return player:is_valid_environment(environment_name)
end

-- reload hotbar
function reload_hotbar()
    if not windower.ffxi.get_info().logged_in then return false end
    if not xivcrossbar.ready then
        initialize()
        return xivcrossbar.ready == true
    end
    if player:load_hotbar() == false then return false end
    -- Keep a valid shared/current set; otherwise choose from the newly loaded
    -- job, not the previous job's table. This does not rename or save any set.
    if not player:is_valid_environment(player.hotbar_settings.active_environment) then
        local selected = env_chooser:get_default_active_environment(player.hotbar)
        if not selected then
            windower.add_to_chat(123, '[XIVCrossbar] No crossbar sets are available. Check the XML files and reload.')
            ui:hide()
            return false
        end
        player:set_active_environment(selected)
    end
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
    return true
end

-- change active hotbar
function change_active_hotbar(new_hotbar)
    player:change_active_hotbar(new_hotbar)
end

-----------------------------
-- Addon Commands
-----------------------------

-- command to switch to a specific crossbar
function switch_crossbars_command(args)
    if not args[1] then
        print('XIVCROSSBAR: Invalid arguments: crossbar <crossbar_set>')
        return
    end

    local environment = args[1]:lower()

    if (is_valid_environment(environment)) then
        set_active_environment(environment)
    else
        print('XIVCROSSBAR: "' .. environment .. '" is not a valid crossbar set.')
    end
end

-- command to set an action in a hotbar
function set_action_command(args)
    if not args[5] then
        print('XIVCROSSBAR: Invalid arguments: set <mode> <hotbar> <slot> <action_type> <action> <target (optional)> <alias (optional)> <icon (optional)>')
        return
    end

    local environment = args[1]:lower()

    if (args[2] == nil) then
        if (is_valid_environment(args[2])) then
            set_active_environment(args[2])
        else
            print('XIVCROSSBAR: "' .. args[2] .. '" is not a valid crossbar set.')
        end
    end

    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local action_type = args[4]:lower()
    local action = args[5]
    local target = args[6] or nil
    local alias = args[7] or nil
    local icon = args[8] or nil

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    if target ~= nil then target = target:lower() end

    local new_action = action_manager:build(action_type, action, target, alias, icon)
    player:add_action(new_action, environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
end

-- command to delete an action from an hotbar
function delete_action_command(args)
    if not args[3] then
        print('XIVCROSSBAR: Invalid arguments: del <mode> <hotbar> <slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
end

-- command to copy an action to another slot
function copy_action_command(args, is_moving)
    local command = 'copy'
    if is_moving then command = 'move' end

    if not args[6] then
        print('XIVCROSSBAR: Invalid arguments: ' .. command .. ' <mode> <hotbar> <slot> <to_mode> <to_hotbar> <to_slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local to_environment = args[4]:lower()
    local to_hotbar = gamepad_converter:convert_to_crossbar(args[5]) or 0
    local to_slot = gamepad_converter:convert_to_slot(args[6]) or 0

    if hotbar < 1 or hotbar > 3 or to_hotbar < 1 or to_hotbar > 3 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 or to_slot < 1 or to_slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:copy_action(environment, hotbar, slot, to_environment, to_hotbar, to_slot, is_moving)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action alias
function update_alias_command(args)
    if not args[4] then
        print('XIVCROSSBAR: Invalid arguments: alias <mode> <hotbar> <slot> <alias>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local alias = args[4]

    if hotbar < 1 or hotbar > 7 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:set_action_alias(environment, hotbar, slot, alias)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action icon
function update_icon_command(args)
    if not args[4] then
        print('XIVCROSSBAR: Invalid arguments: icon <mode> <hotbar> <slot> <icon>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local icon = args[4]

    if hotbar < 1 or hotbar > 3 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:set_action_icon(environment, hotbar, slot, icon)
    player:save_hotbar()
    reload_hotbar()
end

-- Custom Action field-set chat command. Forms accepted:
--   //xivcrossbar ca <field> <value...>
--   //xivcrossbar custom <field> <value...>
-- Field token: a|alias, n|name, c|command. Value is everything after the
-- field token and is rejoined with spaces (Windower splits argv on spaces).
-- Only accepted while a Custom Action review screen is 
-- active; otherwise the binder reports the error to chat.
function custom_action_field_command(args)
    local kind, value, field_value = require('custom_action_review').route(args)
    if kind == 'open' then return action_binder:new_custom_action(value, 'command') end
    return action_binder:on_custom_action_field_set(value, field_value)
end

-- command to update action icon
function new_environment_command(args)
    if not args[1] then
        print('XIVCROSSBAR: Invalid arguments: new <name>')
        return
    end

    local environment = args[1]
    local env_lower = environment:lower()

    if (env_lower == 'default' or env_lower == 'job-default' or env_lower == 'all-jobs-default') then
        print('XIVCROSSBAR: Crossbar set name "' .. environment .. '" is reserved. Unable to create.')
        return
    end

    if not player:create_new_environment(environment) then return false end
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
    windower.add_to_chat(207, '[XIVCrossbar] Created crossbar set: ' .. environment)
end

-- Helpers for the rename / delete environment commands. Reserved keys are
-- the four pinned environments that the rest of the addon assumes always
-- exist; renaming or deleting any of them would break loading and many
-- fallback paths.
local PROTECTED_ENV_KEYS = {
    ['default'] = true,
    ['job-default'] = true,
    ['all-jobs-default'] = true,
    ['shared'] = true,
}

-- Count slots across all loaded environments whose type is 'switch' and
-- whose <action> equals the given kebab-cased env name. Used to warn the
-- user about bindings that will be left dangling by a rename or delete.
-- Only the currently-loaded job's hotbar files are scanned (other jobs'
-- per-job XMLs aren't in memory and aren't rewritten by this command).
local function count_switch_references(env_kebab)
    local count = 0
    if (player.hotbar == nil) then return 0 end
    for env_name, env in pairs(player.hotbar) do
        if (type(env) == 'table') then
            for key, hotbar in pairs(env) do
                if (type(hotbar) == 'table' and key:sub(1, 7) == 'hotbar_') then
                    for slot_key, slot in pairs(hotbar) do
                        if (type(slot) == 'table' and slot.type == 'switch' and slot.action == env_kebab) then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    return count
end

-- Rename an existing crossbar set (environment) in the currently-loaded
-- job's hotbar files. Re-keys player.hotbar[<old>] to player.hotbar[<new>],
-- updates the env's `name` field, repoints the active-environment pointer
-- if needed, and warns about any switch-type slots that still reference
-- the old name.
function rename_environment_command(args)
    if (not args[1] or not args[2]) then
        windower.add_to_chat(123, '[XIVCrossbar] Usage: //xcb rename <old name> <new name>')
        return
    end

    -- Since there's no real way to identify multiple words for the old and new tokens,
    -- everything but the LAST word is considered as the "old" name, and only the very 
    -- LAST word is treated as the new name.
    -- ex: "//xivcrossbar rn Boss Setup Solo" would rename "Boss Setup" -> "Solo".
    local old_name = args[1]
    local new_name = args[2]
    if (#args > 2) then
        local parts = {}
        for i = 1, #args - 1 do parts[#parts + 1] = args[i] end
        old_name = table.concat(parts, ' ')
        new_name = args[#args]
    end

    local old_key = kebab_casify(old_name)
    local new_key = kebab_casify(new_name)
    if not new_key:match('^[%a_][%w_.%-]*$') then
        windower.add_to_chat(123, '[XIVCrossbar] Use a set name starting with a letter, with letters, numbers, spaces, hyphens or underscores.')
        return
    end

    if (PROTECTED_ENV_KEYS[old_key]) then
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar set "' .. old_name .. '" is reserved and cannot be renamed.')
        return
    end
    if (PROTECTED_ENV_KEYS[new_key]) then
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar set name "' .. new_name .. '" is reserved.')
        return
    end
    if (old_key == new_key) then
        windower.add_to_chat(123, '[XIVCrossbar] New name resolves to the same key as the old name. Nothing to do.')
        return
    end
    if (player.hotbar[old_key] == nil) then
        windower.add_to_chat(123, '[XIVCrossbar] No crossbar set named "' .. old_name .. '" found in the current job.')
        return
    end
    if (player.hotbar[new_key] ~= nil) then
        windower.add_to_chat(123, '[XIVCrossbar] A crossbar set named "' .. new_name .. '" already exists.')
        return
    end

    -- Move the env dict to the new key and update its display name field.
    local env = player.hotbar[old_key]
    env.name = new_name
    player.hotbar[new_key] = env
    player.hotbar[old_key] = nil

    -- If the renamed env was active, repoint the pointer.
    if (player.hotbar_settings.active_environment == old_key) then
        player.hotbar_settings.active_environment = new_key
    end

    -- Warn about orphaned switch-type bindings that still reference the
    -- old name — those will not be auto-rewritten.
    local orphan_count = count_switch_references(old_key)

    player:save_hotbar()
    reload_hotbar()

    windower.add_to_chat(123, '[XIVCrossbar] Crossbar set renamed: "' .. old_name .. '" -> "' .. new_name .. '".')
    if (orphan_count > 0) then
        windower.add_to_chat(123, '[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) still reference the old name and will no longer work until updated.')
    end
end

-- Delete an existing crossbar set (environment) in the currently-loaded
-- job. Removes the entire env including all of its slot bindings, falls
-- the active-environment pointer back to a safe default if necessary, and
-- warns about any switch-type slots that still reference the deleted name.
-- There is NO going back, which is why you have to type the whole thing, 
-- no aliases to avoid mistakes.
function delete_environment_command(args)
    if (not args[1]) then
        windower.add_to_chat(123, '[XIVCrossbar] Usage: //xcb deleteset <name>')
        return
    end

    -- Allow multi-word names by joining argv.
    local target_name = table.concat(args, ' ')
    local target_key = kebab_casify(target_name)

    if (PROTECTED_ENV_KEYS[target_key]) then
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar set "' .. target_name .. '" is reserved and cannot be deleted.')
        return
    end
    if (player.hotbar[target_key] == nil) then
        windower.add_to_chat(123, '[XIVCrossbar] No crossbar set named "' .. target_name .. '" found in the current job.')
        return
    end

    -- Drop the env (and all its slot bindings) entirely.
    player.hotbar[target_key] = nil

    -- If the deleted env was active, switch to a safe fallback computed
    -- by env_chooser (same path as the addon's normal startup recovery).
    if (player.hotbar_settings.active_environment == target_key) then
        local fallback = env_chooser:get_default_active_environment(player.hotbar)
        set_active_environment(fallback)
    end

    -- Warn about orphaned switch-type bindings before saving so the count
    -- reflects the state seen by the user up to this moment.
    local orphan_count = count_switch_references(target_key)

    player:save_hotbar()
    reload_hotbar()

    windower.add_to_chat(123, '[XIVCrossbar] Crossbar set deleted: "' .. target_name .. '" (and all its slot bindings).')
    if (orphan_count > 0) then
        windower.add_to_chat(123, '[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) referenced the deleted set and will no longer work.')
    end
end

-- command to rerun the setup dialog
function remap()
    gamepad_mapper:setup(buttonmapping, start_controller_wrappers, theme_options, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - y_adjust,
            {default_profile=defaults.ControllerProfile, select=function(profile, done)
                local device = profile == settings.ControllerProfile and settings.ControllerDevice or 1
                return select_controller_profile(profile, device, done)
            end})
    gamepad_mapper:show(false)
end

function regenerate_resources()
    resource_generator.generate_all_resources()
end

-- command to display help for the user
function display_help_menu()
    local layout = theme_options.button_layout:lower()
    local minus_button = 'Minus'
    if (layout == 'playstation') then
        minus_button = 'Share'
    elseif (layout == 'xbox') then
        minus_button = 'Back'
    end
    local plus_button = 'Plus'
    if (layout == 'playstation') then
        plus_button = 'Options'
    elseif (layout == 'xbox') then
        plus_button = 'Start'
    end
    local left_trigger = 'L'
    if (layout == 'playstation') then
        left_trigger = 'L2'
    end
    local right_trigger = 'R'
    if (layout == 'playstation') then
        right_trigger = 'R2'
    end
    local buttons = 'A/B/X/Y'
    if (layout == 'playstation') then
        buttons = 'Face'
    end

    windower.add_to_chat(207, '================ XIVCrossbar Help ================')
    windower.add_to_chat(207, 'Command prefix: //xivcrossbar  -or-  //xb  -or-  //xcb')
    windower.add_to_chat(207, '--- Crossbar set management ---')
    windower.add_to_chat(207, 'new <name>                      Create a new crossbar set')
    windower.add_to_chat(207, 'rename <old> <new>              Rename an existing set (rn)')
    windower.add_to_chat(207, 'deleteset <name>                Delete a set and all its bindings')
    windower.add_to_chat(207, '--- Slot binding management ---')
    windower.add_to_chat(207, 'set <env> <hb> <slot> ...       Bind an action to a slot')
    windower.add_to_chat(207, 'clear <env> <hb> <slot>         Clear (remove) a slot binding')
    windower.add_to_chat(207, 'cp/copy <env> <hb> <slot> <dest hb> <dest slot>')
    windower.add_to_chat(207, 'mv/move <env> <hb> <slot> <dest hb> <dest slot>')
    windower.add_to_chat(207, 'icon/ic <env> <hb> <slot> <icon>')
    windower.add_to_chat(207, 'alias/al/caption <env> <hb> <slot> <text>   Set slot caption')
    windower.add_to_chat(207, 'controller status|start|stop|profiles')
    windower.add_to_chat(207, 'controller profile <name> [device]  Save controller reader selection')
    windower.add_to_chat(207, '--- Custom Actions ---')
    windower.add_to_chat(207, 'ca <name>                       Create/edit one custom-action review')
    windower.add_to_chat(207, 'ca name/alias/command <value>    Edit the current draft')
    windower.add_to_chat(207, '--- Other ---')
    windower.add_to_chat(207, 'status                          Version and current display/input settings')
    windower.add_to_chat(207, 'scale <0.25-2>              Scale crossbar independently of menus')
    windower.add_to_chat(207, 'compact [on/off]                Switch layout immediately; bare toggles')
    windower.add_to_chat(207, 'hide/show/auto                  Visibility; bound actions remain active')
    windower.add_to_chat(207, 'fade [on/off]                   Toggle fades (also ui fade)')
    windower.add_to_chat(207, 'textfade [on/off/status]         Fade text with the bar; OFF uses endpoint visibility')
    windower.add_to_chat(207, 'autoattack [on/off/status]       Enable/stop the optional swing estimate')
    windower.add_to_chat(207, 'autohide [on/off]               Trigger-only visibility; bare toggles')
    windower.add_to_chat(207, 'remap                           Rerun the gamepad setup utility')
    windower.add_to_chat(207, 'regenerate                      Regenerate cached resource files')
    windower.add_to_chat(207, 'reload                          Reload the active hotbar')
    windower.add_to_chat(207, 'restart                         Fade out, then reload the addon')
    windower.add_to_chat(207, 'help / ?                        Show this help')
    windower.add_to_chat(207, '================ Identifiers ================')
    windower.add_to_chat(207, 'Hotbar (<hb>):  l, r, rl, lr, ll, rr   (or 1-6)')
    windower.add_to_chat(207, 'Slot   (<slot>): ll, ld, lr, lu, rl, rd, rr, ru   (or 1-8)')
    windower.add_to_chat(207, '================ Gamepad (' .. theme_options.button_layout .. ') ================')
    windower.add_to_chat(207, '' .. plus_button .. ' + D-Pad (up/down): Switch between crossbar sets')
    windower.add_to_chat(207, '' .. minus_button .. ': Open/close button bind utility')
    windower.add_to_chat(207, '' .. left_trigger .. '/' .. right_trigger .. ' + D-Pad: Navigate button bind utility (when open)')
    windower.add_to_chat(207, '' .. left_trigger .. '/' .. right_trigger .. ' + D-Pad or ' .. buttons .. ' Button: Execute bound action')
    windower.add_to_chat(207, '===============================================')
end

-----------------------------
-- Bind Events
-----------------------------

local function set_text_fade(mode)
    mode = mode and mode:lower()
    if mode and mode~='on' and mode~='off' and mode~='status' then
        windower.add_to_chat(123,'[XIVCrossbar] //xb textfade [on|off|status]')
        return
    end
    if mode~='status' then
        local enabled = mode=='on' or (not mode and not settings.Animation.TextFade)
        settings.Animation.TextFade = enabled
        theme_options.text_fade = enabled
        ui.geometry:set_text_fade(enabled)
        config.save(settings)
    end
    windower.add_to_chat(207,'[XIVCrossbar] Text fade: '..
        (settings.Animation.TextFade and 'ON (with crossbar)' or 'OFF (endpoint visibility)'))
end

local function set_autoattack(mode)
    mode = mode and mode:lower()
    if mode and mode~='on' and mode~='off' and mode~='status' then
        windower.add_to_chat(123,'[XIVCrossbar] //xb autoattack [on|off|status]')
        return
    end
    if mode~='status' then
        local enabled=mode=='on' or (not mode and not settings.AutoAttackIndicator.Enabled)
        settings.AutoAttackIndicator.Enabled=enabled
        theme_options.aa_enabled=enabled
        ui:set_autoattack_enabled(enabled)
        if enabled and ui.is_setup then
            local current=windower.ffxi.get_player()
            if current then ui.autoattack:set_engaged(current.status==1 or current.status==3,current.buffs) end
        end
        config.save(settings)
    end
    windower.add_to_chat(207,'[XIVCrossbar] Autoattack estimate: '..
        (settings.AutoAttackIndicator.Enabled and 'ON' or 'OFF')..
        ' | Display opacity: '..tostring(settings.AutoAttackIndicator.Opacity))
end

-- A: Lua teardown cannot finish an animation. Close first, then ask Windower
-- for the same full reload as lua r; the shared controller process stays alive.
local function graceful_restart()
    if restart_pending then return end
    restart_pending = true
    xivcrossbar.ready = false
    crossbar_drag:finish()
    controller_switcher:cancel()
    if env_chooser.is_setup then env_chooser:close() end
    if action_binder.selector then
        action_binder:hide()
        action_binder:reset_state()
    end
    if gamepad_mapper.is_showing then gamepad_mapper:hide() end
    text_input_guard:release(windower.send_command)
    if release_gameplay_keys then release_gameplay_keys() end
    if ui.is_setup then ui:hide() end
    local delay = theme_options.fade_enabled and math.max(0, tonumber(theme_options.fade_out) or 0) or 0
    coroutine.schedule(function() windower.send_command('lua r xivcrossbar') end, delay)
end

-- ON LOAD
windower.register_event('load',function()
    if (buttonmapping.validate()) then
        start_controller_wrappers()
    end

    if windower.ffxi.get_info().logged_in then
        initialize()
    end
    skillchains.load()

    -- A: Windower bindings stop native F-key targeting; Lua still routes
    -- the keyboard event. Reserve only Apps+F1-F12 for this experiment.
    for index = 1, 12 do
        windower.send_command('bind ' .. controller_bind_prefix .. 'f' .. index .. ' xivcrossbar inputconsume')
    end

end)

-- ON LOGIN
windower.register_event('login',function()
    initialize()
    skillchains.login()
end)

-- ON LOGOUT
windower.register_event('logout', function()
    xivcrossbar.ready = false
    xivcrossbar.initialized = false
    player.identity_confirmed = false
    storage.identity_valid = false
    if release_gameplay_keys then release_gameplay_keys() end
    ui.autoattack:reset()
    ui:hide()
    skillchains.logout()

    if theme_options.on_logout_unload_addon then
        windower.send_command('lua u xivcrossbar')
    end
end)

-- ON UNLOAD
windower.register_event('unload',function()
    ui.autoattack:set_enabled(false)
    personal_controls:close()
    controller_switcher:cancel()
    crossbar_drag:finish()
    text_input_guard:reset_confirmation()
    text_input_guard:release(windower.send_command)
    -- Release the twelve combinations reserved by this test build.
    for index = 1, 12 do
        windower.send_command('unbind ' .. controller_bind_prefix .. 'f' .. index)
    end
    -- No broad killahk.bat: the wrapper is shared across FFXI clients.
    if release_gameplay_keys then release_gameplay_keys() end

end)

-- ON COMMAND
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    -- A: the binding consumes native input without echoing or executing
    -- an action; the keyboard router independently handles the actual slot.
    if command == 'inputconsume' then
        return
    elseif command == 'controller' then
        local mode, name, device = ...
        mode = type(mode) == 'string' and mode:lower() or 'status'
        if mode == 'stop' then controller_switcher:cancel(); stop_controller_wrapper()
        elseif mode == 'start' then
            if controller_switcher.pending then report_controller_status() else start_controller_wrappers() end
        elseif mode == 'profile' then select_controller_profile(name, device)
        elseif mode == 'status' then report_controller_status()
        elseif mode == 'profiles' then
            for _, id in ipairs(controller_profiles.order) do
                local profile = controller_profiles.profiles[id]
                windower.add_to_chat(207, '[XIVCrossbar] ' .. controller_profiles.short_name(id) .. (profile.experimental and ' (experimental)' or ' (default)'))
            end
        else windower.add_to_chat(207, '[XIVCrossbar] //xb controller status|start|stop|profiles|profile <name> [device]') end
        return
    elseif command == 'inputtest' or command == 'inputtrace' then
        local mode = (...)
        local key = command == 'inputtest' and 'InputTest' or 'InputTrace'
        if mode == 'on' then settings[key] = true
        elseif mode == 'off' then settings[key] = false
        else settings[key] = not settings[key] end
        config.save(settings)
        windower.add_to_chat(207, '[XIVCrossbar] ' .. key .. ' ' .. (settings[key] and 'ON' or 'OFF'))
        return
    elseif command == 'dpad' then
        local mode = (...)
        mode = mode and mode:lower()
        if mode and mode ~= 'arrows' and mode ~= 'ijkl' then
            windower.add_to_chat(123, '[XIVCrossbar] //xb dpad [arrows|ijkl]'); return
        end
        -- Release the old output before changing mapping; require another press.
        release_gameplay_keys()
        settings.GameplayDPad = mode or (settings.GameplayDPad == 'ijkl' and 'arrows' or 'ijkl')
        config.save(settings)
        windower.add_to_chat(207, '[XIVCrossbar] Gameplay D-pad: ' .. settings.GameplayDPad)
        return
    elseif command == 'inputstatus' then
        windower.add_to_chat(207, '[XIVCrossbar] ' .. _addon.version .. ' | ' .. controller_modifier .. ' | Profile=' .. settings.ControllerProfile .. ' | InputTest=' .. tostring(settings.InputTest) .. ' | InputTrace=' .. tostring(settings.InputTrace))
        return
    end
    local args = {...}
    if command == 'textfade' or (command == 'ui' and args[1] == 'textfade') then
        return set_text_fade(command == 'textfade' and args[1] or args[2])
    end
    if command == 'autoattack' then return set_autoattack(args[1]) end
    if command == 'fade' or command == 'scale' or command == 'hide' or command == 'show' or command == 'auto' then
        table.insert(args, 1, command)
        command = 'ui'
    end

    if command == 'status' then
        windower.add_to_chat(207, '[XIVCrossbar] ' .. _addon.version)
        report_controller_status()
        windower.add_to_chat(207, '[XIVCrossbar] Set: ' .. tostring(player.hotbar_settings.active_environment) .. ' | Visibility: ' .. settings.VisibilityMode .. ' | Scale: ' .. tostring(settings.CrossbarScale))
        windower.add_to_chat(207, '[XIVCrossbar] Fades: ' .. tostring(settings.Animation.Enabled) .. ' | Text fade: ' .. tostring(settings.Animation.TextFade) .. ' | D-pad: ' .. settings.GameplayDPad .. ' | Text entry: ' .. tostring(text_input_guard.active))
        windower.add_to_chat(207, '[XIVCrossbar] Compact: ' .. (settings.iscompact and 'ON' or 'OFF'))
        windower.add_to_chat(207, '[XIVCrossbar] Autoattack estimate: ' .. tostring(settings.AutoAttackIndicator.Enabled) .. ' | Opacity: ' .. tostring(settings.AutoAttackIndicator.Opacity))
        windower.add_to_chat(207, '[XIVCrossbar] Ready: ' .. tostring(xivcrossbar.ready == true) ..
            ' | Setup: ' .. tostring(gamepad_mapper.is_showing == true) .. ' (state ' .. tostring(gamepad_mapper.state) ..
            ') | Capture: ' .. tostring(gamepad_state.capturing == true))
        return
    end

    if command == 'compact' or (command == 'ui' and args[1] == 'compact') then
        return set_compact_mode(command == 'compact' and args[1] or args[2])
    end

    if command == 'ui' and args[1] == 'fade' then
        local mode = args[2] and args[2]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' then
            windower.add_to_chat(123, '[XIVCrossbar] //xb fade [on|off]'); return
        end
        local enabled = mode == 'on' or (not mode and not settings.Animation.Enabled)
        settings.Animation.Enabled = enabled
        theme_options.fade_enabled = enabled
        ui.geometry.deferring_hide = false
        ui.geometry:configure_fade(enabled, settings.Animation.FadeIn, settings.Animation.FadeOut)
        ui.public_visible = nil
        config.save(settings)
        windower.add_to_chat(207, '[XIVCrossbar] Fades: ' .. (enabled and 'ON' or 'OFF'))
        return
    end

    if command == 'ui' and args[1] == 'scale' then
        local scale = tonumber(args[2])
        if not scale or scale ~= scale or scale < .25 or scale > 2 then
            windower.add_to_chat(123, '[XIVCrossbar] //xb ui scale <0.25-2>'); return
        end
        settings.CrossbarScale = scale
        theme_options.crossbar_scale = scale
        ui:set_scale(scale)
        env_chooser:set_anchor(ui:get_set_chooser_anchor())
        config.save(settings)
        windower.add_to_chat(207, '[XIVCrossbar] Crossbar scale: ' .. tostring(scale))
        return
    end

    if command == 'autohide' then
        local mode = args[1] and args[1]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' then
            windower.add_to_chat(123, '[XIVCrossbar] //xb autohide [on|off]'); return
        end
        if mode == 'off' or (not mode and settings.VisibilityMode == 'oninput') then
            settings.VisibilityMode = 'always'
        else settings.VisibilityMode = 'oninput' end
        config.save(settings)
        windower.add_to_chat(207, '[XIVCrossbar] Visibility: ' .. settings.VisibilityMode)
        return
    elseif command == 'ui' and (args[1] == 'hide' or args[1] == 'show' or args[1] == 'auto') then
        settings.VisibilityMode = ({hide='hidden',show='always',auto='oninput'})[args[1]]
        ui.public_visible = nil
        config.save(settings)
        windower.add_to_chat(207, '[XIVCrossbar] Visibility: ' .. settings.VisibilityMode)
        return
    end

    if command == 'restart' then
        return graceful_restart()
    elseif command == 'reload' then
        return reload_hotbar()

    elseif command == 'bar' or command == 'crossbar' or command == 'hotbar' then
        switch_crossbars_command(args)
    elseif command == 'set' then
        set_action_command(args)
    elseif command == 'clear' then
        -- Renamed from "del" because you're just clearing the slot.
        -- And to avoid confusion with "deleteset" because of its
        -- destructive nature.
        delete_action_command(args)
    elseif command == 'deleteset' then
        -- Spelled out fully (no short alias) to avoid accidental triggering.
        -- This removes the whole crossbar set including every slot binding
        -- it contains.
        delete_environment_command(args)
    elseif command == 'rn' or command == 'rename' then
        rename_environment_command(args)
    elseif command == 'cp' or command == 'copy' then
        copy_action_command(args, false)
    elseif command == 'mv' or command == 'move' then
        copy_action_command(args, true)
    elseif command == 'ic' or command == 'icon' then
        update_icon_command(args)
    elseif command == 'al' or command == 'alias' or command == 'caption' then
        update_alias_command(args)
    elseif command == 'ca' or command == 'custom' then
        -- Custom Action field-set: Only used when creating/editing
        -- a custom action. Basically, when the action binder instructs you.
        custom_action_field_command(args)
    elseif command == 'n' or command == 'new' then
        new_environment_command(args)
    elseif #args > 0 and command == 'sw' or command == 'switch' then
		local to = table.concat(args, ' ')
        if is_valid_environment(to) then
			set_active_environment(args[1]:lower())
		end
    elseif command == 'remap' then
        remap()
    elseif command == 'regenerate' then
        regenerate_resources()
    elseif command == '?' or command == 'help' then
        display_help_menu()
    end
end)

local shifted_keys = {[2]='!',[3]='@',[4]='#',[5]='$',[6]='%',[7]='^',[8]='&',[9]='*',
    [10]='(',[11]=')',[12]='_',[13]='+',[26]='{',[27]='}',[39]=':',[40]='"',
    [41]='~',[43]='|',[51]='<',[52]='>',[53]='?'}
local keys = {
    [57] = ' ',
    [2] = '1',
    [3] = '2',
    [4] = '3',
    [5] = '4',
    [6] = '5',
    [7] = '6',
    [8] = '7',
    [9] = '8',
    [10] = '9',
    [11] = '0',
    [12] = '-',
    [13] = '=',
    [26] = '[',
    [27] = ']',
    [39] = ';',
    [40] = '\'',
    [41] = '`',
    [43] = '\\',
    [51] = ',',
    [52] = '.',
    [53] = '/',
    [30] = 'A',
    [48] = 'B',
    [46] = 'C',
    [32] = 'D',
    [18] = 'E',
    [33] = 'F',
    [34] = 'G',
    [35] = 'H',
    [23] = 'I',
    [36] = 'J',
    [37] = 'K',
    [38] = 'L',
    [50] = 'M',
    [49] = 'N',
    [24] = 'O',
    [25] = 'P',
    [16] = 'Q',
    [19] = 'R',
    [31] = 'S',
    [20] = 'T',
    [22] = 'U',
    [47] = 'V',
    [17] = 'W',
    [45] = 'X',
    [21] = 'Y',
    [44] = 'Z'
}

-- Port the personal branch's early Options handoff, retaining public rendering.
local set_chooser_button_down = false
local chooser_previous_environment
local function finish_set_chooser(cancel)
    if cancel then
        if chooser_previous_environment and player:is_valid_environment(chooser_previous_environment) then
            set_active_environment(chooser_previous_environment)
        end
        env_chooser:close()
    end
    if not env_chooser.capturing then
        if action_binder.chooser_active then action_binder:set_chooser_active(false,gamepad_state) end
        chooser_previous_environment = nil
    end
    ui_dirty = true
end

-- ON KEY
local function close_addon_menus()
    if env_chooser:is_showing() or env_chooser.capturing or action_binder.chooser_active then
        finish_set_chooser(true)
    end
    set_chooser_button_down = false
    if gamepad_mapper.is_showing then gamepad_mapper:hide() end
    if action_binder.selector then
        action_binder:hide()
        action_binder:reset_state()
    end
    text_input_guard:release(windower.send_command)
    if ui.is_setup then ui:maybe_show_button_hints() end
    if env_chooser.is_setup then env_chooser:maybe_unhide_default_sets_tooltip() end
    ui_dirty = true
end

local function handle_controller_key(dik, pressed, flags, blocked)
    local left_trigger_just_pressed = pressed and gamepad.is_left_trigger(dik) and not gamepad_state.left_trigger
    local right_trigger_just_pressed = pressed and gamepad.is_right_trigger(dik) and not gamepad_state.right_trigger
    local left_trigger_just_released = (not pressed) and gamepad.is_left_trigger(dik) and gamepad_state.left_trigger
    local right_trigger_just_released = (not pressed) and gamepad.is_right_trigger(dik) and gamepad_state.right_trigger

    ui_dirty = ui_dirty or left_trigger_just_pressed or right_trigger_just_pressed or left_trigger_just_released or right_trigger_just_released

    if (gamepad.is_left_trigger(dik)) then
        gamepad_state.left_trigger = pressed
    elseif (gamepad.is_right_trigger(dik)) then
        gamepad_state.right_trigger = pressed
    elseif (dik == controller_capture_dik) then
        gamepad_state.capturing = pressed
    elseif (dik == keyboard.shift or dik == 54) then
        -- A: right Shift is DIK 54; releasing one must retain the other.
        shift_keys_down[dik] = pressed
        shift_pressed = shift_keys_down[keyboard.shift] or shift_keys_down[54] or false
    elseif (gamepad.is_minus(dik)) then
        gamepad_state.minus_button = pressed
    elseif (gamepad.is_plus(dik)) then
        gamepad_state.plus_button = pressed
    end

    if (gamepad_mapper.is_showing) then
        if (gamepad.is_face_button_or_dpad(dik)) then
            if (gamepad.is_button_b(dik)) then
                gamepad_mapper:button_b(pressed)
            elseif (gamepad.is_button_a(dik)) then
                gamepad_mapper:button_a(pressed)
            elseif (gamepad.is_button_x(dik)) then
                gamepad_mapper:button_x(pressed)
            elseif (gamepad.is_button_y(dik)) then
                gamepad_mapper:button_y(pressed)
            end
            return true
        end

        if (gamepad.is_left_trigger(dik)) then
            gamepad_mapper:trigger_left(pressed)
        elseif (gamepad.is_right_trigger(dik)) then
            gamepad_mapper:trigger_right(pressed)
        end
        return gamepad.is_left_trigger(dik) or gamepad.is_right_trigger(dik) or dik == controller_capture_dik
    end

    if not gamepad_mapper.is_showing and gamepad.is_plus(dik) and
        (gamepad_state.capturing or set_chooser_button_down) and xivcrossbar.ready then
        local down = pressed and not set_chooser_button_down
        local up = not pressed and set_chooser_button_down
        set_chooser_button_down = pressed
        if down then
            if env_chooser.capturing then finish_set_chooser(true); return true end
            if not env_chooser:is_showing() then
                chooser_previous_environment = player.hotbar_settings.active_environment
                env_chooser:raise_layer()
                env_chooser:show_player_environments(player.hotbar,chooser_previous_environment,ui:get_set_chooser_anchor())
            end
            if not action_binder.is_hidden then action_binder:set_chooser_active(true) end
        elseif up then
            if env_chooser:is_showing() then env_chooser:hide_player_environments() end
            finish_set_chooser(false)
        end
        ui_dirty=true
        return true
    end
    if env_chooser:is_showing() and dik==keyboard.esc and pressed then
        finish_set_chooser(true)
        return true
    end
    if env_chooser:is_showing() and gamepad_state.capturing and gamepad.is_face_button_or_dpad(dik) then
        if pressed then
            local cancel=false
            for _,button in ipairs({'a','b','x','y'}) do
                if gamepad['is_button_'..button](dik) and action_binder:is_cancel_button(button) then cancel=true end
            end
            if cancel then finish_set_chooser(true)
            elseif gamepad.is_dpad_down(dik) or gamepad.is_dpad_up(dik) then
                local direction=gamepad.is_dpad_down(dik) and 'get_prev_environment' or 'get_next_environment'
                select_chooser_environment(env_chooser[direction](env_chooser,player.hotbar,env_chooser.current_environment))
            end
        end
        return true
    end
    if action_binder.chooser_active and (gamepad.is_left_trigger(dik) or gamepad.is_right_trigger(dik)) then return true end

    local only_left_trigger_just_pressed = left_trigger_just_pressed and not gamepad_state.right_trigger
    if (not is_left_doublepress_window_open and only_left_trigger_just_pressed) then
        is_left_doublepress_window_open = true
        is_right_doublepress_window_open = false
        coroutine.schedule(close_left_doublepress_window, 0.5)
    end
    local only_right_trigger_just_pressed = right_trigger_just_pressed and not gamepad_state.left_trigger
    if (not is_right_doublepress_window_open and only_right_trigger_just_pressed) then
        is_right_doublepress_window_open = true
        is_left_doublepress_window_open = false
        coroutine.schedule(close_right_doublepress_window, 0.5)
    end

    local only_left_trigger_just_released = left_trigger_just_released and not gamepad_state.right_trigger
    if (is_left_doublepress_window_open and only_left_trigger_just_released) then
        left_trigger_lifted_during_doublepress_window = true
    end
    local only_right_trigger_just_released = right_trigger_just_released and not gamepad_state.left_trigger
    if (is_right_doublepress_window_open and only_right_trigger_just_released) then
        right_trigger_lifted_during_doublepress_window = true
    end

    if (only_left_trigger_just_pressed and is_left_doublepress_window_open and left_trigger_lifted_during_doublepress_window) then
        gamepad_state.left_trigger_doublepress = true
        is_left_doublepress_window_open = false
    end
    if (only_right_trigger_just_pressed and is_right_doublepress_window_open and right_trigger_lifted_during_doublepress_window) then
        gamepad_state.right_trigger_doublepress = true
        is_right_doublepress_window_open = false
    end

    if (left_trigger_just_released and gamepad_state.left_trigger_doublepress) then
        gamepad_state.left_trigger_doublepress = false
    end
    if (right_trigger_just_released and gamepad_state.right_trigger_doublepress) then
        gamepad_state.right_trigger_doublepress = false
    end

    -- windower.send_command('@input /echo '..dik)

    if (not action_binder.chooser_active and action_binder:is_capturing_text() and keys[dik] ~= nil) then
        if (pressed) then
            if (shift_pressed) then
                action_binder:send_key(shifted_keys[dik] or keys[dik])
            else
                action_binder:send_key(keys[dik]:lower())
            end
        end
        return true
    elseif (not action_binder.chooser_active and action_binder:is_capturing_text() and dik == keyboard.backspace and pressed) then
        action_binder:send_backspace()
        return true
    elseif (not action_binder.chooser_active and action_binder:is_capturing_text() and dik == keyboard.esc and pressed) then
        action_binder:send_escape_text()
        return true
    elseif (not action_binder.chooser_active and action_binder:is_capturing_text() and dik == keyboard.enter and pressed) then
        action_binder:send_enter()
        return true
    end

    if (env_chooser.capturing and keys[dik] ~= nil) then
        if (pressed) then
            if (shift_pressed) then
                env_chooser:send_key(shifted_keys[dik] or keys[dik])
            else
                env_chooser:send_key(keys[dik]:lower())
            end
        end
        return true
    elseif (env_chooser.capturing and dik == keyboard.backspace and pressed) then
        env_chooser:send_backspace()
        return true
    elseif (env_chooser.capturing and dik == keyboard.esc and pressed) then
        env_chooser:send_escape()
        ui_dirty=true
        return true
    elseif (env_chooser.capturing and dik == keyboard.enter and pressed) then
        if (env_chooser:validate_new_set_name()) then
            if new_environment_command(L{env_chooser:get_new_set_name()}) ~= false then
                env_chooser:clear()
                text_input_guard:release(windower.send_command)
                finish_set_chooser(false)
                ui_dirty=true
            end
        else
            windower.send_command('input /echo [XIVCrossbar] Crossbar set name "' .. env_chooser:get_new_set_name() .. '" is reserved. Unable to create.')
        end
        return true
    end

    if (gamepad_state.capturing and gamepad_state.left_trigger and not gamepad_state.right_trigger) then
        if (gamepad_state.left_trigger_doublepress and theme_options.hotbar_number >= 5) then
            change_active_hotbar(5)
            gamepad_state.active_bar = 5
        else
            change_active_hotbar(1)
            gamepad_state.active_bar = 1
        end
    elseif (gamepad_state.capturing and gamepad_state.right_trigger and not gamepad_state.left_trigger) then
        if (gamepad_state.right_trigger_doublepress and theme_options.hotbar_number >= 6) then
            change_active_hotbar(6)
            gamepad_state.active_bar = 6
        else
            change_active_hotbar(2)
            gamepad_state.active_bar = 2
        end
    elseif (gamepad_state.capturing and gamepad_state.right_trigger and gamepad_state.left_trigger) then
        if (theme_options.hotbar_number > 3) then
            if (left_trigger_just_pressed) then
                -- R -> L = bar 3
                change_active_hotbar(3)
                gamepad_state.active_bar = 3
            elseif (right_trigger_just_pressed) then
                -- L -> R = bar 4
                change_active_hotbar(4)
                gamepad_state.active_bar = 4
            end
        else
            change_active_hotbar(3)
            gamepad_state.active_bar = 3
        end
    else
        gamepad_state.active_bar = 0
    end

    if (not gamepad_mapper.is_showing and gamepad_state.capturing and gamepad.is_minus(dik) and pressed) then
        if (action_binder:is_capturing_text()) then
            -- Don't close the binder while typing
            return true
        elseif (action_binder.is_hidden) then
            action_binder:show()
            ui:hide_button_hints()
            env_chooser:temp_hide_default_sets_tooltip()
        else
            close_addon_menus()
        end
        return true
    end

    if (not action_binder.is_hidden) then
        if (gamepad_state.capturing) then
            if (gamepad.is_face_button_or_dpad(dik)) then
                local action_binder_was_showing = not action_binder.is_hidden

                if (gamepad.is_dpad_left(dik)) then
                    action_binder:dpad_left(pressed)
                elseif (gamepad.is_dpad_down(dik)) then
                    action_binder:dpad_down(pressed)
                elseif (gamepad.is_dpad_right(dik)) then
                    action_binder:dpad_right(pressed)
                elseif (gamepad.is_dpad_up(dik)) then
                    action_binder:dpad_up(pressed)
                elseif (gamepad.is_button_b(dik)) then
                    action_binder:button_b(pressed)
                elseif (gamepad.is_button_a(dik)) then
                    action_binder:button_a(pressed)
                elseif (gamepad.is_button_x(dik)) then
                    action_binder:button_x(pressed)
                elseif (gamepad.is_button_y(dik)) then
                    action_binder:button_y(pressed)
                end
                if (action_binder_was_showing and action_binder.is_hidden) then
                    ui:maybe_show_button_hints()
                end
                return true
            end

            if (gamepad.is_left_trigger(dik)) then
                action_binder:trigger_left(pressed)
            elseif (gamepad.is_right_trigger(dik)) then
                action_binder:trigger_right(pressed)
            end
        end
    end

    local any_trigger_down = gamepad_state.left_trigger or gamepad_state.right_trigger
    if (gamepad_state.capturing and any_trigger_down and gamepad.is_face_button_or_dpad(dik)) then
        if (pressed) then
            if (gamepad.is_dpad_left(dik)) then
                trigger_action(1)
            elseif (gamepad.is_dpad_down(dik)) then
                trigger_action(2)
            elseif (gamepad.is_dpad_right(dik)) then
                trigger_action(3)
            elseif (gamepad.is_dpad_up(dik)) then
                trigger_action(4)
            elseif (gamepad.is_button_b(dik)) then
                trigger_action(5)
            elseif (gamepad.is_button_a(dik)) then
                trigger_action(6)
            elseif (gamepad.is_button_x(dik)) then
                trigger_action(7)
            elseif (gamepad.is_button_y(dik)) then
                trigger_action(8)
            end

            if (not (gamepad.is_plus(dik) or gamepad.is_minus(dik))) then
                return true
            end
        end
    end


end

-- A: menu decisions stay beside the menu code. Raw keys never masquerade
-- as ordinary Enter/arrows; only deliberate gameplay translation emits those.
local gameplay_down = {}
release_gameplay_keys = function()
    for dik, key in pairs(gameplay_down) do
        windower.send_command('setkey ' .. key .. ' up')
        gameplay_down[dik] = nil
    end
end
local function input_context()
    if gamepad_mapper.is_showing then return 'setup' end
    if env_chooser.capturing then return 'text' end
    if env_chooser:is_showing() then return 'sets' end
    if action_binder:is_capturing_text() then return 'text' end
    if not action_binder.is_hidden then return 'menu:' .. tostring(action_binder.state) end
    if gamepad_state.left_trigger or gamepad_state.right_trigger then return 'crossbar' end
    return 'gameplay'
end
publish_personal_context = function()
    if settings.ControllerProfile~='ps5-extended' or not windower.ffxi.get_info().logged_in then
        personal_controls:close();return
    end
    local context = (restart_pending or not xivcrossbar.ready) and 'setup' or input_context()
    personal_controls:update(windower.addon_path..'data/personal-controls/',player.name,
        settings.ControllerProfile,context)
end
windower.register_event('keyboard', function(dik, pressed, flags, blocked)
    -- Own Escape through key-up after closing: neither repeats nor release
    -- may cancel a native FFXI menu underneath the addon.
    if dik == keyboard.esc then
        if menu_escape_down then
            if not pressed then menu_escape_down = false end
            return true
        end
        if pressed and (gamepad_mapper.is_showing or action_binder.is_hidden == false or
            env_chooser:is_showing() or env_chooser.capturing) then
            menu_escape_down = true
            close_addon_menus()
            publish_personal_context()
            return true
        end
    end
    -- A: the field may close on key-down. Own its confirming Enter until
    -- release; normal keyboard Enter outside text entry remains untouched.
    if dik == keyboard.enter then
        local consumed, commit = text_input_guard:enter_edge(pressed,
            (not action_binder.chooser_active and action_binder:is_capturing_text()) or env_chooser.capturing)
        if consumed then
            if commit then handle_controller_key(dik, pressed, flags, blocked);publish_personal_context() end
            return true
        end
    end
    -- Setup tracing must precede capture/readiness filters, otherwise a lost
    -- marker or incomplete initialization produces no diagnostic at all.
    if settings.InputTrace and gamepad_mapper.is_showing then
        windower.add_to_chat(207, '[XIVCrossbar test] RAW DIK=' .. tostring(dik) ..
            (pressed and ' down' or ' up') .. ' capture=' .. tostring(gamepad_state.capturing == true) ..
            ' ready=' .. tostring(xivcrossbar.ready == true) .. ' setup=' .. tostring(gamepad_mapper.state) ..
            ' blocked=' .. tostring(blocked == true))
    end
    if dik == controller_capture_dik then
        if not pressed then
            release_gameplay_keys()
            transport:reset()
            gamepad_state.left_trigger = false
            gamepad_state.right_trigger = false
            gamepad_state.minus_button = false
            gamepad_state.plus_button = false
            gamepad_state.active_bar = 0
        end
        handle_controller_key(dik, pressed, flags, blocked)
        publish_personal_context()
        return true
    end
    local signal = transport.signals[dik]
    -- Consume owned releases even if capture was lost; no orphan game key-ups.
    if signal and (gamepad_state.capturing or transport.down[dik]) then
        -- The wizard bootstraps button configuration and can be visible before
        -- hotbar initialization finishes. Gameplay still requires readiness.
        if restart_pending or (not xivcrossbar.ready and not gamepad_mapper.is_showing) then return true end
        if blocked and pressed and input_context() ~= 'text' and not action_binder.chooser_active then
            if settings.InputTrace then windower.add_to_chat(123, '[XIVCrossbar test] BLOCKED ' .. signal.name .. ' DIK=' .. dik .. ' by another input handler') end
            return true
        end
        local context = input_context()
        local item, edge, owner = transport:edge(dik, pressed, context)
        if edge == 'repeat' then return true end
        if settings.InputTrace then
            local role = item.name
            if item.button == buttonmapping.confirm_button then role = role .. ' / Confirm' end
            if item.button == buttonmapping.cancel_button then role = role .. ' / Back' end
            windower.add_to_chat(207, '[XIVCrossbar test] ' .. role .. ' ' .. edge .. ' DIK=' .. dik .. ' context=' .. tostring(owner or context))
        end
        if gameplay_down[dik] and not pressed then
            windower.send_command('setkey ' .. gameplay_down[dik] .. ' up')
            gameplay_down[dik] = nil
        end
        -- Triggers and menu buttons must finish their transition even when the
        -- menu opens/closes between edges. Slots keep their original owner.
        local transition = item.logical >= 67
        if not pressed and owner ~= context and not transition then return true end
        -- The base set chooser uses only Up/Down; other slot buttons stay
        -- owned by that menu and must never fall through to a crossbar action.
        if context == 'sets' and item.logical <= 66 and item.logical ~= 59 and item.logical ~= 61 then return true end
        if item.logical <= 66 and context == 'gameplay' then
            local key = transport:gameplay_key(item, buttonmapping, settings.GameplayDPad)
            if settings.InputTest then
                if pressed then windower.add_to_chat(207, '[XIVCrossbar test] Gameplay ' .. item.name .. ' -> ' .. tostring(key) .. ' — dummy action') end
            elseif key and pressed then
                gameplay_down[dik] = key
                windower.send_command('setkey ' .. key .. ' down')
            end
            return true
        end
        if pressed and transition then release_gameplay_keys() end
        handle_controller_key(item.logical, pressed, flags, blocked)
        publish_personal_context()
        return true
    end
    -- A: plain F1-F12 pass through; Apps-gated signals were consumed above.
    if (dik >= 59 and dik <= 68) or dik == 87 or dik == 88 then return false end
    if gamepad_state.capturing and not signal and settings.InputTrace then
        windower.add_to_chat(123, '[XIVCrossbar test] UNMAPPED ' .. (pressed and 'DOWN' or 'UP') .. ' DIK=' .. tostring(dik) .. ' — compare data/input-transport.log')
        if settings.InputTest then return true end
    end
    local consumed=handle_controller_key(dik, pressed, flags, blocked)
    publish_personal_context()
    return consumed
end)

local frame = 0

-- A: a background key-up may never reach this client's Lua handler.
-- Release only gameplay keys we injected, retry them on regain, and clear
-- local controller ownership without submitting or discarding menu drafts.
local focus_release_keys = {}
local function clear_controller_input(regained)
    set_chooser_button_down=false
    menu_escape_down=false
    if action_binder.chooser_active then finish_set_chooser(true) end
    text_input_guard:reset_confirmation()
    for _, key in pairs(gameplay_down) do focus_release_keys[key] = true end
    release_gameplay_keys()
    if regained then
        for key in pairs(focus_release_keys) do windower.send_command('setkey ' .. key .. ' up') end
        focus_release_keys = {}
    end
    transport:reset()
    for _, key in ipairs({'capturing','left_trigger','right_trigger','minus_button','plus_button',
        'left_trigger_doublepress','right_trigger_doublepress'}) do gamepad_state[key] = false end
    gamepad_state.active_bar = 0
    close_left_doublepress_window()
    close_right_doublepress_window()
    action_binder:clear_controller_input()
    -- An Options-held list closes on focus change; text entry keeps its draft.
    if env_chooser:is_showing() and not env_chooser.capturing then env_chooser:close() end
    ui_dirty = true
end
windower.register_event('lose focus', function() clear_controller_input(false) end)
windower.register_event('gain focus', function() clear_controller_input(true) end)

-- ON PRERENDER
windower.register_event('prerender',function()
    publish_personal_context()
    text_input_guard:update(action_binder:is_capturing_text() or env_chooser.capturing, windower.send_command)
    if ui.is_setup then ui:set_chooser_open(env_chooser:is_showing()) end
    -- Elapsed-time fades must keep progressing even when recast frames skip.
    if ui.geometry then ui.geometry:tick() end
    -- allow settings to skip rendering frames
    frame = (frame + 1)  % (theme_options.frame_skip + 1)
    if (frame > 0 and not ui_dirty) then
        return
    end

    skillchains.prerender()
    if xivcrossbar.ready == false or restart_pending then
        return
    end

    if ui.is_setup and settings.VisibilityMode ~= 'hidden' and not xivcrossbar.hide_hotbars
        and (gamepad_state.left_trigger or gamepad_state.right_trigger) then
        ui.geometry:interrupt_startup_reveal()
    end
    local visible = visibility.should_show(settings.VisibilityMode,
        gamepad_state.left_trigger or gamepad_state.right_trigger, xivcrossbar.hide_hotbars,
        ui.is_setup and ui.geometry:is_startup_reveal_pending())
        or action_binder:is_moving_crossbars() or env_chooser:is_showing()
    if not visible then crossbar_drag:finish() end
    if ui.is_setup and ui.public_visible ~= visible then
        if visible then
            ui.public_visible = ui:show(player.hotbar, player.hotbar_settings.active_environment) == true
        else ui:hide(); ui.public_visible = false end
    end

    if visible and ui.feedback.is_active then
        ui:show_feedback()
    end

    if visible and ui.is_setup then
        local dim_default_slots = not action_binder.is_hidden        
        ui:check_recasts(player.hotbar, player.vitals, player.hotbar_settings.active_environment, player.current_spells, gamepad_state, skillchains, consumables, dim_default_slots, xivcrossbar.in_battle)
    end

    ui_dirty = false
end)

-- ON ACTIONS (filtered to Job Abilities)
windower.register_event('action', function(actor_id, category)
    -- Skip while initialize() hasn't run yet (e.g. addon loaded before
    -- the player is logged in). The login event will set ready=true once
    -- a character has been selected.
    if (not xivcrossbar.ready) then return end
    if (actor_id == player:get_id() and category == 6) then -- category 6 = Job Ability
        player:update_current_spells()
    end
end)

-- EVERY VANA'DIEL MINUTE
windower.register_event('time change', function(actor_id, category)
    if (not xivcrossbar.ready) then return end
    player:update_current_spells()
end)

-- ON MP CHANGE
windower.register_event('mp change', function(new, old)
    if (not xivcrossbar.ready) then return end
    player.vitals.mp = new
    ui:check_vitals(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
end)

-- ON TP CHANGE
windower.register_event('tp change', function(new, old)
    if (not xivcrossbar.ready) then return end
    player.vitals.tp = new
    ui:check_vitals(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
end)

-- ON STATUS CHANGE
windower.register_event('status change', function(new_status_id)
    if (not xivcrossbar.ready) then return end
    ui.public_visible = nil
    -- hide/show bar in cutscenes
    if xivcrossbar.hide_hotbars == false and new_status_id == 4 then
        xivcrossbar.hide_hotbars = true
        ui:hide()
    elseif xivcrossbar.hide_hotbars and new_status_id ~= 4 then
        xivcrossbar.hide_hotbars = false
        ui:show(player.hotbar, player.hotbar_settings.active_environment)
    end

    -- Disabling this for now, but we might want it later
    -- -- alternate environment on battle
    if xivcrossbar.in_battle == false and (new_status_id == 1 or new_status_id == 3) then
        xivcrossbar.in_battle = true
        player:set_is_in_battle(true)
    --     set_battle_environment(true)
    elseif xivcrossbar.in_battle and new_status_id ~= 1 and new_status_id ~= 3 then
        xivcrossbar.in_battle = false
        player:set_is_in_battle(false)
    --     set_battle_environment(false)
    end

    -- Auto-attack swing timer: show bar only while engaged.
    if ui.autoattack.enabled then
        local current=windower.ffxi.get_player()
        ui.autoattack:set_engaged(new_status_id == 1 or new_status_id == 3,current and current.buffs)
    end
end)

-- Auto-attack swing timer: pause/unpause when disabling debuffs come and go.
windower.register_event('gain buff', function(buff_id)
    if ui.autoattack.enabled then ui.autoattack:gain_buff(buff_id) end
end)

windower.register_event('lose buff', function(buff_id)
    if ui.autoattack.enabled then ui.autoattack:lose_buff(buff_id) end
end)

-- ON JOB CHANGE
windower.register_event('job change',function(main_job, main_job_level, sub_job, sub_job_level)
    -- skillchains has its own internal state and is fine pre-init, so it
    -- runs unconditionally. Everything below it depends on initialize().
    skillchains.job_change(main_job, main_job_level)
    if (not xivcrossbar.ready) then return end
    local sub = resources.jobs[sub_job]
    player:update_jobs(resources.jobs[main_job].ens, sub and sub.ens)
    if reload_hotbar() then player:queue_job_change_notice() end
end)

local CATEGORY_MELEE = 1
local CATEGORY_WEAPONSKILL = 3
local CATEGORY_COMPLETED_SPELL = 4
local CATEGORY_JOB_ABILITY = 6
local SUMMONING_MAGIC = 38
local RELEASE = 90
local LIGHT_ARTS = 211
local DARK_ARTS = 212
local ADDENDUM_WHITE = 234
local ADDENDUM_BLACK = 235

local no_pet_environment = nil

windower.register_event('action', function(act)
    if (not xivcrossbar.ready) then return end
    -- Don't swap crossbars when someone *else* summons or uses Light/Dark Arts
    local windower_player = windower.ffxi.get_player()
    if (act.actor_id ~= windower_player.id) then
        return
    end

    if ui.autoattack.enabled and act.actor_id == player.id then
        if act.category == CATEGORY_MELEE then ui.autoattack:record_swing()
        elseif act.category == CATEGORY_WEAPONSKILL then ui.autoattack:add_pause('ws',2)
        elseif act.category == CATEGORY_JOB_ABILITY then ui.autoattack:add_pause('ja',2) end
    end

    if (act.category == CATEGORY_JOB_ABILITY and act.actor_id == player.id) then
        gcd_start_time = os.clock()
        gcd_duration = 2.0
        gcd_kind = 'ja'
        gcd_active = true
    end

    if (act.category == CATEGORY_COMPLETED_SPELL) then
        local spell = resources.spells[act.param]
        if act.actor_id == player.id then
            gcd_start_time = os.clock()
            gcd_duration = theme_options.spell_lockout_duration or 3.0
            gcd_kind = 'spell'
            gcd_active = true
        end
        if (spell ~= nil and spell.skill == SUMMONING_MAGIC and is_valid_environment(spell.en:gsub(' ', ''):lower())) then
            no_pet_environment = player.hotbar_settings.active_environment
            set_active_environment(spell.en:gsub(' ', ''):lower())
        end
    elseif (act.category == CATEGORY_WEAPONSKILL) then
        if act.actor_id == player.id then
            gcd_start_time = os.clock()
            gcd_duration = 2.0
            gcd_kind = 'ws'
            gcd_active = true
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == RELEASE) then
        if (no_pet_environment ~= nil and is_valid_environment(no_pet_environment)) then
            set_active_environment(no_pet_environment)
            no_pet_environment = nil
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == LIGHT_ARTS) then
        if (is_valid_environment('lightarts')) then
            set_active_environment('lightarts')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == DARK_ARTS) then
        if (is_valid_environment('darkarts')) then
            set_active_environment('darkarts')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == ADDENDUM_WHITE) then
        if (is_valid_environment('addendumwhite')) then
            set_active_environment('addendumwhite')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == ADDENDUM_BLACK) then
        if (is_valid_environment('addendumblack')) then
            set_active_environment('addendumblack')
        end
    end
end)

windower.register_event('incoming chunk', function(id, data)
    skillchains.incoming_chunk(id, data)
end)

windower.register_event('zone change', function()
    skillchains.zone_change()
end)
