-- Addon description
_addon.name = 'XIVCrossbar' -- based on Edeon's XIV Hotbar
_addon.author = 'Aliekber, various friendly neighborhood modders'
-- Credit goes to: Aeliya, BlueSummersC, FionaBrightgrass, GrayFox2510, Icydeath, qEagleStrikerp, Sylvebits, XerevNonori
_addon.version = '0.4.0-beta1.20261109.hook1'
_addon.language = 'english'
_addon.commands = {'xivcrossbar', 'xb', 'xcb'}

-- A: Windower's default module search roots include the shared addons/libs
-- folder, but not necessarily this addon's own nested libs/ directory.
-- Extend Lua's path *only for this addon's local fallback*. Otherwise a
-- request such as require('libs/xml2') probes addons/libs/libs/xml2.lua
-- instead of xivcrossbar/libs/xml2.lua, even in a complete installation.
-- Keep shared Windower libraries first and preserve existing package.path.
do
    local root = assert(windower.addon_path, 'XIVCrossbar needs windower.addon_path')
    root = root:gsub('\\', '/')
    if root:sub(-1) ~= '/' then root = root .. '/' end
    local local_modules = root .. '?.lua'
    if not package.path:find(local_modules, 1, true) then
        package.path = package.path .. ';' .. local_modules
    end
end

-- Libs
res = require 'resources'
config = require('config')
file = require('files')
texts = require('texts')
images = require('images')
tables = require('tables')
resources = require('resources')
xml = require('libs/xml2')   -- TODO: REMOVE
local chat_format = require('libs/chat_status')
local command_help = require('libs/command_help')

-- User settings
local defaults = require('defaults')
local default_skillchain_opacity = defaults.SkillchainIndicator.Opacity
local settings = config.load(defaults)
-- Keep new/changed captions transparent until Windower reports a stable width.
require('ui/text_measure').enabled=settings.TextSettling~=false
-- A: profile selection replaces the independent legacy backend flags. Existing
-- unused XML fields remain harmless; only one shared reader can be active.
local controller_profiles = require('controller_profiles')
local selected_profile, selected_device = controller_profiles.validate(settings.ControllerProfile, settings.ControllerDevice)
if not selected_profile then
    chat_format.say(123, '[XIVCrossbar] Invalid controller selection; using PS5 DirectInput device 1.')
    selected_profile, selected_device = 'ps5-directinput', 1
end
settings.ControllerProfile, settings.ControllerDevice = selected_profile, selected_device
local client_registry
config.save(settings)

local controller_modifier = 'messages' -- distinguishes older keyboard-injecting readers

-- Load theme options according to settings
local character_identity = require('character_identity')
local profile_clock = require('socket').gettime
local profile_gate = require('profile_gate').new(profile_clock)
local theme = require('theme')
local theme_options = theme.apply(settings)
theme_options.shoulder_banks = true
local buttonmapping = require('buttonmapping')
local resource_generator = require('resource_generator')
resource_generator.generate_outdated_resources()

-- Addon Dependencies
local action_manager = require('action_manager')
local keyboard = require('keyboard_mapper')
local gamepad = require('gamepad')
local transport = require('controller_transport')
local shoulder_banks = require('shoulder_banks')
local text_input_guard = require('text_input_guard')
local review_keyboard = require('libs/controller/review_keyboard').new()
local visibility = require('visibility')
local player = require('player')
local storage = require('storage')
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
        chat_format.say(123, '[XIVCrossbar] //xb compact [on|off]')
        return
    end
    local enabled = mode == 'on' or (not mode and not settings.iscompact)
    crossbar_drag:finish()
    settings.iscompact, theme_options.is_compact = enabled, enabled
    ui:set_compact(enabled)
    if ui.is_setup then env_chooser:set_anchor(ui:get_set_chooser_anchor()) end
    ui_dirty = true
    config.save(settings)
    chat_format.say(207, '[XIVCrossbar] Compact: ' .. (enabled and 'ON' or 'OFF'))
end
local function set_display_preset(mode)
    mode = mode and mode:lower()
    if mode and mode ~= 'legacy' and mode ~= 'xi' and mode ~= 'status' then
        chat_format.say(123, '[XIVCrossbar] //xb display [legacy|xi|status]')
        return
    end
    if mode ~= 'status' then
        local preset = mode or (settings.DisplayPreset == 'xi' and 'legacy' or 'xi')
        local xi = preset == 'xi'
        settings.DisplayPreset = preset
        settings.VisibilityMode = xi and 'oninput' or 'always'
        settings.Animation.Enabled, settings.Animation.TextFade = xi, xi
        theme_options.fade_enabled, theme_options.text_fade = xi, xi
        theme_options.load_fade_in = xi and settings.Animation.LoadFadeIn or 0
        theme_options.display_palette = theme.display_palette(preset)
        theme_options.slot_pulse_enabled = xi
        if xi then
            crossbar_drag:finish()
            settings.iscompact, theme_options.is_compact = true, true
            settings.Animation.SlotGlow = true
            settings.Animation.RecastFlash = true
            settings.Animation.TriggerScale = true
            theme_options.slot_glow_enabled = true
            theme_options.recast_flash_enabled = true
            ui:set_slot_glow_enabled(true)
            ui.recast_flash_enabled = true
        end
        ui:set_display_layout(theme_options.display_palette, xi or ui.is_compact)
        if ui.is_setup then env_chooser:set_anchor(ui:get_set_chooser_anchor()) end
        ui:set_slot_pulse_enabled(xi)
        ui.geometry.deferring_hide = false
        ui.geometry:configure_fade(xi, settings.Animation.FadeIn, settings.Animation.FadeOut)
        ui.geometry:interrupt_startup_reveal()
        ui.geometry:set_text_fade(xi)
        if ui.is_setup and xivcrossbar.ready then
            ui:check_vitals(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
        end
        ui.public_visible = nil
        ui_dirty = true
        config.save(settings)
    end
    chat_format.say(207, '[XIVCrossbar] Display: ' .. settings.DisplayPreset:upper())
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
        chat_format.say(123, '[XIVCrossbar] Reload successfully before binding. Existing files were not changed.')
        return false
    end
    local active_environment = player.hotbar_settings.active_environment
    local environment = shoulder_banks.destination(active_environment, hotbar)

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
    set_active_environment(active_environment)
    local feedback=require('binding_feedback')
    chat_format.say(207, feedback.bound(alias or action, feedback.set_name(player.hotbar,environment), hotbar, slot))
end

-- command to set a crossbar action in action_binder
function delete_hotkey(hotbar, slot)
    if player.hotbar_load_ok == false then
        chat_format.say(123, '[XIVCrossbar] Reload successfully before clearing a binding. Existing files were not changed.')
        return false
    end
    local active_environment = player.hotbar_settings.active_environment
    local environment = shoulder_banks.destination(active_environment, hotbar)

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(active_environment)
    local feedback=require('binding_feedback')
    chat_format.say(207, feedback.cleared(feedback.set_name(player.hotbar,environment), hotbar, slot))
end

local function set_display_name(key, name)
    if settings.DisplayPreset == 'xi' then
        return require('crossbar_destinations').xi_label(key, name, player.main_job, player.sub_job)
    end
    return name
end

function get_crossbar_sets()
    return require('crossbar_destinations').build(player.hotbar, set_display_name)
end

function create_new_set(name)
    if not player:create_new_environment(name) then return false end
    player:save_hotbar()
    reload_hotbar()
    chat_format.say(207, '[XIVCrossbar] Created crossbar set: ' .. name)
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

    local active_environment = player.hotbar_settings.active_environment
    local environment = shoulder_banks.destination(active_environment, hotbar_num)
    local updated = player:set_slot_icon(environment, hotbar_num, slot_num, icon)
    if (not updated) then
        chat_format.say(123, '[XIVCrossbar] Change Icon: no action bound at the selected slot.')
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
        chat_format.say(123, '[XIVCrossbar] Global Icon Set: missing name or icon.')
        return
    end

    player.shared_icons[name] = icon
    player:save_shared_icons_file()
    reload_hotbar()
    set_active_environment(player.hotbar_settings.active_environment)

    chat_format.say(123, '[XIVCrossbar] Global icon set: "' .. name .. '" -> ' .. icon)
end

-- Create Custom Action callback: persists a CustomActions.xml entry from a
-- record built up during the binder's create-flow. The record is the same
-- shape we read back via load_custom_actions: {name, alias, command, icon,
-- linked_action, linked_type}.
function save_custom_action(record)
    if player.hotbar_load_ok == false then
        chat_format.say(123, '[XIVCrossbar] Reload successfully before saving custom actions.')
        return false
    end
    if (record == nil or record.name == nil or record.name == '') then
        chat_format.say(123, '[XIVCrossbar] Create Custom Action: missing name.')
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
        chat_format.say(123, '[XIVCrossbar] Custom action was not saved. ' .. (not ok and tostring(result) or 'Reload and retry.'))
        return false
    end
    -- No reload needed for the catalog itself — the binder's existing
    -- "Custom Action" selector pulls from player.custom_actions in real time.
    chat_format.say(207, '[XIVCrossbar] Custom action saved: "' .. record.name .. '"')
    return true
end

-- Edit Custom Action callback: persists changes to an existing entry,
-- handling rename by removing the old key before writing the new one. The
-- binder has already chat-warned the user about orphaned slot bindings if
-- the name changed.
function update_custom_action(original_name, record)
    if player.hotbar_load_ok == false then
        chat_format.say(123, '[XIVCrossbar] Reload successfully before editing custom actions.')
        return false
    end
    if (record == nil or record.name == nil or record.name == '') then
        chat_format.say(123, '[XIVCrossbar] Edit Custom Action: missing name.')
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
        chat_format.say(123, '[XIVCrossbar] Custom action was not updated. ' .. (not ok and tostring(result) or 'Reload and retry.'))
        return false
    end
    chat_format.say(207, '[XIVCrossbar] Custom action updated: "' .. record.name .. '"')
    return true
end

-- Delete Custom Action callback: removes an entry from the catalog and
-- rewrites CustomActions.xml. Slots that reference the deleted name are
-- left as-is; user is responsible for cleaning those up.
function delete_custom_action(name)
    if player.hotbar_load_ok == false then
        chat_format.say(123, '[XIVCrossbar] Reload successfully before deleting custom actions.')
        return false
    end
    if (name == nil or name == '') then
        chat_format.say(123, '[XIVCrossbar] Delete Custom Action: missing name.')
        return false
    end
    if (player.custom_actions == nil or player.custom_actions[name] == nil) then
        chat_format.say(123, '[XIVCrossbar] Delete Custom Action: entry "' .. name .. '" not found.')
        return
    end
    local previous = player.custom_actions[name]
    player.custom_actions[name] = nil
    local ok, result = pcall(player.save_custom_actions_file, player)
    if not ok or result == false then
        player.custom_actions[name] = previous
        chat_format.say(123, '[XIVCrossbar] Custom action was not deleted. ' .. (not ok and tostring(result) or 'Reload and retry.'))
        return false
    end
    chat_format.say(207, '[XIVCrossbar] Custom action deleted: "' .. name .. '". Existing slot bindings referencing it will not be auto-removed.')
    return true
end

-- A: the saved selection is per client; the running wrapper is shared.
-- Optional, on-demand observation only: inactive in normal gameplay.
local diagnostic
local controller_switcher
local message_lease=require('controller_lease').new({clock=profile_clock})
local message_bridge
local native_gamepad, native_mode, native_command, native_poll, native_receiving, native_filtering, native_stop
local native_attach_failure
local controller_bridge = require('controller_bridge')
controller_bridge.menu = controller_bridge.new(profile_clock, windower.send_command, function(message)
    chat_format.say(207, '[XIVCrossbar bridge test] '..message)
end)
local function controller_status()
    return controller_profiles.read_status(windower.addon_path .. 'data/controller-status.ini')
end
local function report_controller_status(embedded)
    chat_format.say(0,chat_format.heading(embedded and 'Controller' or 'XIVcrossbar | Controller'))
    chat_format.say(0,chat_format.row('Selected',controller_profiles.short_name(settings.ControllerProfile)..
        ' / Device '..tostring(settings.ControllerDevice)))
    local status=controller_status()
    local pending=controller_switcher and controller_switcher.pending
    if pending then
        chat_format.say(0,chat_format.row('Changing',chat_format.state(pending.phase)))
    end
    if status and status.running then
        chat_format.say(0,chat_format.row('Running',controller_profiles.short_name(status.profile)..
            ' / Device '..tostring(status.device)))
        chat_format.say(0,chat_format.row('State',chat_format.state(status.state)..
            ' | Connected: '..chat_format.toggle(status.connected == '1')))
        local route=status.route or 'waiting-lease'
        chat_format.say(0,chat_format.row('Input',route))
        local guard_status = native_attach_failure and 'Hook Unavailable'
            or native_filtering and 'Filtering'
            or native_receiving and 'Waiting for DirectLink'
            or native_mode == 'guard' and 'Waiting for FFXI to Read the Controller'
            or 'Pass-Through'
        chat_format.say(0,chat_format.row('Native Guard',guard_status))
        if native_attach_failure then
            chat_format.say(0,chat_format.row('Hook Detail',native_attach_failure))
        end
        if not controller_profiles.matches(status,settings.ControllerProfile,settings.ControllerDevice,controller_modifier)
            and not pending then
            chat_format.say(123,'[XIVCrossbar] Running wrapper differs. Stop it, then start from the client with the desired selection.')
        end
    else
        chat_format.say(0,chat_format.row('State',chat_format.state('stopped')))
        chat_format.say(0,chat_format.row('Input','Waiting for reader'))
    end
end
-- The one diagnostic owns its output file. AHK contributes only a temporary feed.
diagnostic=require('diagnostic_bridge').new({
    path=windower.addon_path,clock=profile_clock,
    mkdir=windower.create_dir,
    pid=function() return native_gamepad and native_gamepad.process_id end,
    say=function(message) chat_format.say(207,'[XIVCrossbar] '..message) end,
    frame_state=function()
        local v=windower.get_windower_settings()
        return {bar=gamepad_state.shoulder_display or gamepad_state.active_bar,
            set=player.hotbar_settings and player.hotbar_settings.active_environment and "loaded",
            editor=action_binder.state,
            width=v.ui_x_res or v.x_res,height=v.ui_y_res or v.y_res,
            scale=settings.CrossbarScale,
            route=message_bridge and message_bridge.token and 'messages' or 'waiting-lease'}
    end,
    snapshot=function()
        local p=windower.ffxi.get_player()
        local info=windower.ffxi.get_info()
        local viewport=windower.get_windower_settings()
        local status=controller_status() or {}
        local reader={}
        for _,key in ipairs({'profile','device','state','connected','ready','route','ahk','running','fresh',
            'clients_reason','clients_loaded','clients_locked','clients_owner_errors','clients_invalid_records',
            'clients_records','clients_seen','clients_last_kill','bridge_movement','bridge_ps'}) do
            reader[key]=status[key]
        end
        if reader.bridge_ps then reader.bridge_ps=reader.bridge_ps:gsub(' HWND %d+',' [window]') end
        local menu=controller_bridge.menu
        return {
            version=_addon.version,profile=settings.ControllerProfile,device=settings.ControllerDevice,
            ready=xivcrossbar.ready,focus=windower.has_focus(),
            chat_open=info and info.chat_open,menu_open=info and info.menu_open,
            character_status=p and p.status,modifier=controller_modifier,
            controller=reader,
            native={mode=native_mode,receiving=native_receiving,filtering=native_filtering,
                hook=native_gamepad and native_gamepad.hook_status(),
                sample=native_gamepad and native_gamepad.snapshot and native_gamepad.snapshot()},
            receiver=message_bridge and {ack=message_bridge.ack,received=message_bridge.received,
                rejected=message_bridge.rejected,reason=message_bridge.reason,
                heartbeat_age_ms=message_bridge.last_beat and math.floor((profile_clock()-message_bridge.last_seen)*1000),
                ack_age_ms=message_bridge.last_ack_at and math.floor((profile_clock()-message_bridge.last_ack_at)*1000)} or {},
            bridges={movement=controller_bridge.mode(settings,'movement'),ps=controller_bridge.mode(settings,'ps'),
                menu=controller_bridge.mode(settings,'menu'),lease=menu.token and menu.state or 'none',
                lease_reason=menu.lease_reason,last_menu_action=menu.last,menu_claim=gamepad_state.trust_menu_live},
            hud={compact=ui.is_compact,fade=settings.Animation.Enabled,visibility=settings.VisibilityMode,
                event_bars=settings.EventBars == true,
                hint_objects=ui.button_hints ~= nil},
            ui_objects=require('ui/resources').snapshot(),
            viewport={width=viewport.ui_x_res or viewport.x_res,height=viewport.ui_y_res or viewport.y_res},
            scale=settings.CrossbarScale,display=settings.DisplayPreset,trigger_banks=settings.Hotbar.Number,
            bar=gamepad_state.active_bar,shoulder=gamepad_state.shoulder_bank,
            shoulder_visible=gamepad_state.shoulder_bank_visible,
            triggers={l2=gamepad_state.left_trigger,r2=gamepad_state.right_trigger},
            editor={state=action_binder.state,page=action_binder.page,showing=not action_binder.is_hidden},
        }
    end,
})
local controller_runtime = require('libs/controller/runtime').new()
local launch_attempt
function start_controller_wrappers(profile, device, modifier)
    profile = profile or settings.ControllerProfile
    device = device or settings.ControllerDevice
    modifier = modifier or controller_modifier
    local status = controller_status()
    if status and status.running then
        if not controller_profiles.matches(status, profile, device, modifier) then
            chat_format.say(123, '[XIVCrossbar] Shared wrapper already uses another profile/device/modifier. Use //xb controller profile <name>.')
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
            chat_format.say(207, '[XIVCrossbar] Stop is pending. Wait two seconds, then start again.')
            return false
        end
        os.remove(stop_path)
    end
    windower.create_dir(windower.addon_path .. 'data')
    local written, err = controller_profiles.write_launch(windower.addon_path .. 'data/controller-launch.ini',
        profile, device, modifier)
    if not written then
        chat_format.say(123, '[XIVCrossbar] Could not save wrapper startup selection: ' .. tostring(err))
        return false
    end
    local plan, launch_error = controller_runtime:plan(windower.addon_path, profile, device, modifier)
    if not plan then
        chat_format.say(123, '[XIVCrossbar] Could not start wrapper: ' .. tostring(launch_error))
        return false
    end
    local attempt = {}
    launch_attempt = attempt
    windower.send_command(plan.command)
    if plan.mode == 'direct' then
        coroutine.schedule(function()
            if launch_attempt ~= attempt then return end
            local current = controller_status()
            if current and current.running then return end
            windower.send_command(plan.fallback_command)
        end, 1)
    end
    chat_format.say(207, '[XIVCrossbar] Wrapper start requested: ' .. controller_profiles.short_name(profile) ..
        ' / device ' .. device .. ' / ' .. modifier)
    return true
end
local function stop_controller_wrapper()
    launch_attempt = nil
    windower.create_dir(windower.addon_path .. 'data')
    local f = io.open(windower.addon_path .. 'data/input-stop.request', 'w')
    if not f then chat_format.say(123, '[XIVCrossbar] Could not write wrapper stop request.'); return false end
    f:write(tostring(os.time())); f:close()
    if native_mode=='guard' then native_stop() end
    chat_format.say(207, '[XIVCrossbar] Shared wrapper stop requested for all clients.')
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
        chat_format.say(123, '[XIVCrossbar] ' .. result)
        if done then done(false, result) end
        return false
    end
    settings.ControllerProfile, settings.ControllerDevice = profile, result
    config.save(settings)
    chat_format.say(207, '[XIVCrossbar] Selecting ' .. controller_profiles.short_name(profile) ..
        ' / device ' .. result .. (controller_profiles.profiles[profile].experimental and ' (experimental)' or ''))
    return controller_switcher:request(profile, result, controller_modifier, function(ok, detail)
        if ok then
            chat_format.say(207, '[XIVCrossbar] Controller: ' .. controller_profiles.short_name(profile) .. ' / ' .. detail.state)
        elseif detail ~= 'Controller change cancelled.' and detail ~= 'Replaced by another controller selection.' then
            chat_format.say(123, '[XIVCrossbar] ' .. tostring(detail))
        end
        if done then done(ok, detail) end
    end)
end

-- initialize addon
function initialize(server_id, expected_name, expected_id)
    local windower_player = windower.ffxi.get_player()
    local info = windower.ffxi.get_info()
    local server = character_identity.resolve(info, windower_player, resources.servers)
    local entity = windower_player and windower_player.id and windower.ffxi.get_mob_by_id(windower_player.id)
    -- The wrapper and login keys need no character storage. Only an observed,
    -- settled in-world identity may open/create the character's XML files.
    if not server_id or not server or info.server ~= server_id or not info.zone or info.zone <= 0 or
        windower_player.name ~= expected_name or windower_player.id ~= expected_id or
        not entity or entity.id ~= expected_id or entity.name ~= expected_name then
        xivcrossbar.ready = false
        storage.identity_valid = false
        player.identity_confirmed = false
        if not server_id then profile_gate.loaded = nil end
        return false, 'identity'
    end
    player.identity_confirmed = true

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
            {select=function(profile, done)
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
    theme_options.is_compact = settings.iscompact
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
        chat_format.say(123, '[XIVCrossbar] No crossbar sets are available. Check the XML files and reload.')
        xivcrossbar.ready = false
        ui:hide()
        return
    end
    set_active_environment(default_active_environment)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment)

    consumables:setup()
    env_chooser:setup(theme_options, set_display_name)
    env_chooser:set_anchor(ui:get_set_chooser_anchor())
    gamepad_converter:setup(theme_options.button_layout)

    local current_status = windower.ffxi.get_player().status
    aa_set_engaged(current_status == 1 or current_status == 3)

    xivcrossbar.hide_hotbars = windower_player.status == 4
    xivcrossbar.ready = true
    xivcrossbar.initialized = true
    return true
end

-- Continue observing after initialization: a valid-looking lobby server can
-- correct later. A normal reload cleans old drawing resources before rebuilding.
local function check_profile_ready()
    local info = windower.ffxi.get_info()
    local current_player = windower.ffxi.get_player()
    local entity = current_player and current_player.id and windower.ffxi.get_mob_by_id(current_player.id)
    local server_record = info and resources.servers[info.server]
    local server_id, name, id = profile_gate:observe(info, current_player, entity, server_record)
    if not server_id then return end
    if xivcrossbar.ready then
        xivcrossbar.ready = false
        storage.identity_valid = false
        player.identity_confirmed = false
        restart_pending = true
        crossbar_drag:finish()
        if ui.is_setup then ui:hide() end
        chat_format.say(0, '[XIVCrossbar] Character/server changed; reloading for '..server_record.en..'/'..name..'.')
        windower.send_command('lua r xivcrossbar')
        return
    end
    local ok, reason = initialize(server_id, name, id)
    if not ok and reason == 'identity' then profile_gate.loaded = nil end
end

-- Test-only, reset on reload. GripRumble's helper owns the event stream.
local slot_rumble_enabled = false
local function emit_slotpress()
    if not slot_rumble_enabled then return end
    local path = windower.addon_path .. '../GripRumble/events.txt'
    if not windower.file_exists(path) then return end
    local file = io.open(path, 'a')
    if not file then return end
    file:write('slotpress\n')
    file:close()
end

-- trigger hotbar action
function trigger_action(slot, bank, input_seq)
    local bar = bank or player.hotbar_settings.active_hotbar
    ui:press_slot_pulse(bar, slot)
    if ui.slot_glow_enabled then ui_dirty = true end
    if settings.InputTest then
        if diagnostic and diagnostic.input_active and diagnostic:input_active() then
            diagnostic:record('ACTION',('seq=%s bank=%d slot=%d result=dummy'):format(tostring(input_seq),bar,slot))
        end
        chat_format.say(207, '[XIVCrossbar test] Crossbar ' .. tostring(bank or gamepad_state.active_bar) .. ' slot ' .. slot .. ' — dummy action')
        ui:trigger_feedback(bar, slot)
        return
    end
    local accepted = player:execute_action(slot, bank)
    if diagnostic and diagnostic.input_active and diagnostic:input_active() then
        diagnostic:record('ACTION',('seq=%s bank=%d slot=%d result=%s')
            :format(tostring(input_seq),bar,slot,accepted and 'accepted' or 'empty-or-rejected'))
    end

    if (player.pending_env_switch ~= nil) then
        local target = player.pending_env_switch
        player.pending_env_switch = nil
        set_active_environment(target)
    end

    ui:trigger_feedback(bar, slot)
    if accepted then emit_slotpress() end
end

-- set battle environment
function set_battle_environment(in_battle)
    player:set_battle_environment(in_battle)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
end

-- set active environment
function set_active_environment(environment_name)
    player:set_active_environment(environment_name)
    action_binder:refresh_set_title()
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
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
            chat_format.say(123, '[XIVCrossbar] No crossbar sets are available. Check the XML files and reload.')
            ui:hide()
            return false
        end
        player:set_active_environment(selected)
    end
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
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
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: crossbar <crossbar_set>')
        return
    end

    local environment = args[1]:lower()

    if (is_valid_environment(environment)) then
        set_active_environment(environment)
    else
        chat_format.say(123,'XIVCROSSBAR: "' .. environment .. '" is not a valid crossbar set.')
    end
end

-- Switch to a named set, accepting display names containing spaces.
-- Normalize once so validation and selection use the same stored key.
function switch_environment_command(args)
    if not args[1] then
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: switch <crossbar_set>')
        return
    end

    local name = table.concat(args, ' ')
    local environment = kebab_casify(name)
    if is_valid_environment(environment) then
        set_active_environment(environment)
    else
        chat_format.say(123,'XIVCROSSBAR: "' .. name .. '" is not a valid crossbar set.')
    end
end

-- command to set an action in a hotbar
function set_action_command(args)
    if not args[5] then
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: set <mode> <hotbar> <slot> <action_type> <action> <target (optional)> <alias (optional)> <icon (optional)>')
        return
    end

    local environment = args[1]:lower()

    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local action_type = args[4]:lower()
    local action = args[5]
    local target = args[6] or nil
    local alias = args[7] or nil
    local icon = args[8] or nil

    if hotbar < 1 or hotbar > (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) then
        chat_format.say(123,'XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        chat_format.say(123,'XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
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
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: del <mode> <hotbar> <slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0

    if hotbar < 1 or hotbar > (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) then
        chat_format.say(123,'XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        chat_format.say(123,'XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
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
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: ' .. command .. ' <mode> <hotbar> <slot> <to_mode> <to_hotbar> <to_slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local to_environment = args[4]:lower()
    local to_hotbar = gamepad_converter:convert_to_crossbar(args[5]) or 0
    local to_slot = gamepad_converter:convert_to_slot(args[6]) or 0

    if hotbar < 1 or hotbar > (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) or to_hotbar < 1 or to_hotbar > (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) then
        chat_format.say(123,'XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) .. '.')
        return
    end

    if slot < 1 or slot > 8 or to_slot < 1 or to_slot > 8 then
        chat_format.say(123,'XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:copy_action(environment, hotbar, slot, to_environment, to_hotbar, to_slot, is_moving)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action alias
function update_alias_command(args)
    if not args[4] then
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: alias <mode> <hotbar> <slot> <alias>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local alias = args[4]

    if hotbar < 1 or hotbar > (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) then
        chat_format.say(123,'XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        chat_format.say(123,'XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:set_action_alias(environment, hotbar, slot, alias)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action icon
function update_icon_command(args)
    if not args[4] then
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: icon <mode> <hotbar> <slot> <icon>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local icon = args[4]

    if hotbar < 1 or hotbar > (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) then
        chat_format.say(123,'XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. (theme_options.hotbar_number == 5 and 6 or theme_options.hotbar_number) .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        chat_format.say(123,'XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
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
        chat_format.say(123,'XIVCROSSBAR: Invalid arguments: new <name>')
        return
    end

    local environment = args[1]
    local env_lower = environment:lower()

    if (env_lower == 'default' or env_lower == 'job-default' or env_lower == 'all-jobs-default') then
        chat_format.say(123,'XIVCROSSBAR: Crossbar set name "' .. environment .. '" is reserved. Unable to create.')
        return
    end

    if not player:create_new_environment(environment) then return false end
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
    chat_format.say(207, '[XIVCrossbar] Created crossbar set: ' .. environment)
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
        chat_format.say(123, '[XIVCrossbar] Usage: //xcb rename <old name> <new name>')
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
        chat_format.say(123, '[XIVCrossbar] Use a set name starting with a letter, with letters, numbers, spaces, hyphens or underscores.')
        return
    end

    if (PROTECTED_ENV_KEYS[old_key]) then
        chat_format.say(123, '[XIVCrossbar] Crossbar set "' .. old_name .. '" is reserved and cannot be renamed.')
        return
    end
    if (PROTECTED_ENV_KEYS[new_key]) then
        chat_format.say(123, '[XIVCrossbar] Crossbar set name "' .. new_name .. '" is reserved.')
        return
    end
    if (old_key == new_key) then
        chat_format.say(123, '[XIVCrossbar] New name resolves to the same key as the old name. Nothing to do.')
        return
    end
    if (player.hotbar[old_key] == nil) then
        chat_format.say(123, '[XIVCrossbar] No crossbar set named "' .. old_name .. '" found in the current job.')
        return
    end
    if (player.hotbar[new_key] ~= nil) then
        chat_format.say(123, '[XIVCrossbar] A crossbar set named "' .. new_name .. '" already exists.')
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

    chat_format.say(123, '[XIVCrossbar] Crossbar set renamed: "' .. old_name .. '" -> "' .. new_name .. '".')
    if (orphan_count > 0) then
        chat_format.say(123, '[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) still reference the old name and will no longer work until updated.')
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
        chat_format.say(123, '[XIVCrossbar] Usage: //xcb deleteset <name>')
        return
    end

    -- Allow multi-word names by joining argv.
    local target_name = table.concat(args, ' ')
    local target_key = kebab_casify(target_name)

    if (PROTECTED_ENV_KEYS[target_key]) then
        chat_format.say(123, '[XIVCrossbar] Crossbar set "' .. target_name .. '" is reserved and cannot be deleted.')
        return
    end
    if (player.hotbar[target_key] == nil) then
        chat_format.say(123, '[XIVCrossbar] No crossbar set named "' .. target_name .. '" found in the current job.')
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

    chat_format.say(123, '[XIVCrossbar] Crossbar set deleted: "' .. target_name .. '" (and all its slot bindings).')
    if (orphan_count > 0) then
        chat_format.say(123, '[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) referenced the deleted set and will no longer work.')
    end
end

-- command to rerun the setup dialog
function remap()
    gamepad_mapper:setup(buttonmapping, start_controller_wrappers, theme_options, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - y_adjust,
            {select=function(profile, done)
                local device = profile == settings.ControllerProfile and settings.ControllerDevice or 1
                return select_controller_profile(profile, device, done)
            end})
    gamepad_mapper:show(false)
end

function regenerate_resources()
    resource_generator.generate_all_resources()
end

-----------------------------
-- Bind Events
-----------------------------

-- A: Lua teardown cannot finish an animation. Close first, then ask Windower
-- to unload or reload. The shared wrapper follows its last-client policy.
local function graceful_restart(unload)
    if restart_pending then return end
    restart_pending = true
    xivcrossbar.ready = false
    crossbar_drag:finish()
    controller_switcher:cancel()
    native_stop()
    if message_bridge then message_bridge:reset('restart') end
    message_lease:close()
    if env_chooser.is_setup then env_chooser:close() end
    if action_binder.selector then
        action_binder:hide()
        action_binder:reset_state()
    end
    if gamepad_mapper.is_showing then gamepad_mapper:hide() end
    text_input_guard:reset_confirmation()
    text_input_guard:update(false, windower.send_command, false)
    if ui.is_setup then ui:hide() end
    local delay = theme_options.fade_enabled and math.max(0, tonumber(theme_options.fade_out) or 0) or 0
    coroutine.schedule(function() windower.send_command(unload and 'lua u xivcrossbar' or 'lua r xivcrossbar') end, delay)
end

-- ON LOAD
windower.register_event('load',function()
    local ok, registry = pcall(function()
        return require('libs/controller/clients').new({directory=windower.addon_path..'data/controller-clients/'})
    end)
    if ok then
        client_registry = registry
        local registered, err = registry:register(settings.StopWrapperAfterLastClient ~= false)
        if not registered then
            chat_format.say(123, '[XIVCrossbar] Controller client registration failed: '..tostring(err))
        end
    else
        chat_format.say(123, '[XIVCrossbar] Last-client shutdown unavailable: '..tostring(registry))
    end
    if (buttonmapping.validate()) then
        start_controller_wrappers()
    end

    if windower.ffxi.get_info().logged_in then
        initialize()
    end
    skillchains.load()


end)

-- ON LOGIN
windower.register_event('login',function()
    profile_gate:reset()
    initialize()
    skillchains.login()
end)

-- ON LOGOUT
windower.register_event('logout', function()
    if player.cancel_summon_swap then player:cancel_summon_swap() end
    profile_gate:reset()
    xivcrossbar.ready = false
    xivcrossbar.initialized = false
    storage.identity_valid = false
    player.identity_confirmed = false
    transport:reset()
    if native_mode then native_stop(nil, true) end
    if diagnostic then diagnostic:record('LIFECYCLE','logout') end
    if message_bridge then message_bridge:reset('logout') end
    message_lease:close()
    gamepad_state.left_trigger, gamepad_state.right_trigger = false, false
    gamepad_state.active_bar = 0
    ui:hide()
    skillchains.logout()

    if theme_options.on_logout_unload_addon then
        windower.send_command('lua u xivcrossbar')
    end
end)

-- ON UNLOAD
windower.register_event('unload',function()
    if player.cancel_summon_swap then player:cancel_summon_swap() end
    launch_attempt = nil
    native_stop(settings.NativeDetachOnUnload~=false)
    if diagnostic then diagnostic:close() end
    controller_switcher:cancel()
    if message_bridge then message_bridge:reset('unload') end
    message_lease:close()
    crossbar_drag:finish()
    text_input_guard:reset_confirmation()
    text_input_guard:update(false, windower.send_command, false)
    -- No broad killahk.bat: the wrapper is shared across FFXI clients.
    if ui.geometry then ui.geometry:shutdown() end
    require('ui/resources').destroy_all()
    if client_registry then client_registry:close(settings.StopWrapperAfterLastClient ~= false) end
end)

-- ON COMMAND
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    if command == 'rendertrace' then
        local mode = (...) or 'start'
        return diagnostic:command(mode=='save' and 'stop' or mode, mode=='mark' and table.concat({...},' ',2) or 'render')
    elseif command == 'diagnose' or command == 'diagnostics' then
        local mode,note,device=...
        if mode=='native' and native_command then
            if note=='detach' then
                if device=='on' or device=='off' then
                    settings.NativeDetachOnUnload=device=='on'
                    config.save(settings)
                end
                chat_format.say(207, '[XIVCrossbar] Detach native hooks on unload: ' ..
                    (settings.NativeDetachOnUnload~=false and 'ON' or 'OFF'))
                return
            end
            return native_command(note=='block' and 'probe' or note=='pass' and 'off' or note=='auto' and 'auto' or 'status', nil, device)
        end
        return diagnostic:command(mode,mode=='mark' and table.concat({...},' ',2) or note)
    elseif command == 'nativepad' then
        if native_command then return native_command(...) end
    elseif command == 'controller' then
        local mode, name, device = ...
        mode = type(mode) == 'string' and mode:lower() or 'status'
        if mode == 'stop' then controller_switcher:cancel(); stop_controller_wrapper()
        elseif mode == 'start' then
            if controller_switcher.pending then report_controller_status() else start_controller_wrappers() end
        elseif mode == 'profile' then select_controller_profile(name, device)
        elseif mode == 'status' then report_controller_status()
        elseif mode == 'trace' then return diagnostic:command(name or 'start','input')
        elseif mode == 'profiles' then
            for _, id in ipairs(controller_profiles.order) do
                local profile = controller_profiles.profiles[id]
                chat_format.say(207, '[XIVCrossbar] ' .. controller_profiles.short_name(id) .. (profile.experimental and ' (experimental)' or ' (default)'))
            end
        else chat_format.say(207, '[XIVCrossbar] //xb controller status|start|stop|profiles|profile <name> [device]') end
        return
    elseif command == 'bridge' then
        local feature, mode = ...
        local function say(message) chat_format.say(207, '[XIVCrossbar bridge] '..message) end
        controller_bridge.command(settings, feature, mode, function() config.save(settings) end, say)
        if not feature or feature == 'status' then
            local wrapper = controller_status()
            local menu = controller_bridge.menu
            say('Trust menu '..(menu.token and menu.state or 'no active lease')..' | last '..(menu.last or 'idle'))
            if wrapper and wrapper.running and controller_profiles.matches(wrapper,settings.ControllerProfile,settings.ControllerDevice,controller_modifier) then
                say('Reader movement '..(wrapper.bridge_movement or 'unavailable')..' | PS '..(wrapper.bridge_ps or 'unavailable'))
            else say('Matching reader unavailable') end
        end
        return
    elseif command == 'triggerbanks' then
        local value = tonumber((...))
        if value == 3 or value == 4 or value == 5 or value == 6 then
            if settings.Hotbar.Number ~= value then
                settings.Hotbar.Number = value
                config.save(settings)
                graceful_restart(false)
            end
        else
            chat_format.say(207, '[XIVCrossbar] Trigger banks '..settings.Hotbar.Number..' | //xb triggerbanks [3|4|5|6]')
        end
        return
    elseif command == 'jobsets' then
        if not xivcrossbar.ready or not player.hotbar_load_ok then return end
        local actor = windower.ffxi.get_player()
        if not actor then return end
        local count = require('libs/job_crossbars').ensure(player.hotbar, actor, res.spells, windower.ffxi.get_spells(),
            player.hotbar_settings.max)
        if count > 0 then
            player:save_hotbar()
            reload_hotbar()
        end
        chat_format.say(207, '[XIVCrossbar] Created '..count..' missing job category sets.')
        return
    elseif command == 'bank' then
        local section, option, value = ...
        return shoulder_banks.command(settings.ShoulderBanks, settings.ControllerProfile, section, option, value,
            function() config.save(settings) end,
            function(message) chat_format.say(207, '[XIVCrossbar] '..message) end)
    elseif command == 'slotrumble' then
        local mode = (...)
        if mode == 'on' then slot_rumble_enabled = true
        elseif mode == 'off' then slot_rumble_enabled = false
        elseif mode ~= nil then
            chat_format.say(123, '[XIVCrossbar] //xb slotrumble [on|off]')
            return
        end
        chat_format.say(207, '[XIVCrossbar] Slot rumble ' .. (slot_rumble_enabled and 'ON' or 'OFF'))
        return
    elseif command == 'inputtest' or command == 'inputtrace' then
        local mode, extra = ...
        mode = mode and mode:lower()
        if extra or (mode and mode ~= 'on' and mode ~= 'off' and mode ~= 'status') then
            chat_format.fail('Use //xb '..command..' [on|off|status].')
            return command_help.show(nil, theme_options.button_layout, settings.ControllerProfile)
        end
        local key = command == 'inputtest' and 'InputTest' or 'InputTrace'
        if mode ~= 'status' then
            if mode then settings[key] = mode == 'on'
            else settings[key] = not settings[key] end
            config.save(settings)
        end
        chat_format.say(207, '[XIVCrossbar] ' .. key .. ' ' .. (settings[key] and 'ON' or 'OFF'))
        return
    elseif command == 'inputstatus' then
        chat_format.say(207, '[XIVCrossbar] ' .. _addon.version .. ' | ' .. controller_modifier .. ' | Profile=' .. settings.ControllerProfile .. ' | InputTest=' .. tostring(settings.InputTest) .. ' | InputTrace=' .. tostring(settings.InputTrace))
        return
    end
    local args = {...}
    if command == 'fade' or command == 'scale' or command == 'hide' or command == 'show' or command == 'auto' then
        table.insert(args, 1, command)
        command = 'ui'
    end

    if command == 'resources' then
        local owner=require('ui/resources')
        local r=owner.snapshot()
        chat_format.say(0, '[XIVCrossbar] UI '..owner.version..': '..r.text..' text, '..r.image..' images | Created/deleted: '..r.created_text..'/'..r.destroyed_text..' text, '..r.created_image..'/'..r.destroyed_image..' images.')
        chat_format.say(0, '[XIVCrossbar] Compare counts on the same screen after repeated edits; these cover XIVCrossbar only.')
        return
    end
    if command == 'status' then
        chat_format.say(0,chat_format.heading('XIVcrossbar | Status'))
        chat_format.say(0,chat_format.row('Version',_addon.version))
        chat_format.say(0,chat_format.row('Addon',chat_format.state(xivcrossbar.ready and 'ready' or 'initializing')))
        chat_format.say(0,chat_format.row('Character',
            storage.identity_valid and (player.server..'/'..player.name) or 'Awaiting in-world login'))
        chat_format.say(0,chat_format.row('Current Set',set_display_name(player.hotbar_settings.active_environment, tostring(player.hotbar_settings.active_environment))))
        chat_format.say(0,chat_format.heading('Crossbars'))
        chat_format.say(0,chat_format.row('Layout',
            (settings.iscompact and 'Compact' or 'Full')..' | Scale: '..tostring(settings.CrossbarScale)))
        chat_format.say(0,chat_format.row('Visibility',settings.VisibilityMode..' | Display: '..settings.DisplayPreset:upper()))
        chat_format.say(0,chat_format.row('Animation',
            'Fades: '..chat_format.toggle(settings.Animation.Enabled)..
            ' | Text Fade: '..chat_format.toggle(settings.Animation.TextFade == true)..
            ' | Text Settling: '..chat_format.toggle(settings.TextSettling ~= false)))
        chat_format.say(0,chat_format.row('Autoattack Estimate',chat_format.toggle(settings.AutoAttackIndicator.Enabled~=false)))
        chat_format.say(0,chat_format.row('D-pad','Native'))
        report_controller_status(true)
        return
    end

    if command == 'display' then return set_display_preset(args[1]) end

    if command == 'compact' or (command == 'ui' and args[1] == 'compact') then
        return set_compact_mode(command == 'compact' and args[1] or args[2])
    end

    if command == 'skillchain' or command == 'lockout' or command == 'autoattack' then
        local mode = args[1] and args[1]:lower()
        local amount = tonumber(mode)
        if mode and mode ~= 'on' and mode ~= 'off' and mode ~= 'status'
            and (not amount or amount < 0 or amount > 255 or amount % 1 ~= 0) then
            chat_format.say(123, '[XIVCrossbar] //xb '..command..' [on|off|status|0-255]')
            return
        end

        if mode ~= 'status' then
            if command == 'skillchain' then
                local enabled = mode == 'on' or (not mode and settings.SkillchainIndicator.Opacity == 0)
                local opacity = amount or (enabled and default_skillchain_opacity or 0)
                settings.SkillchainIndicator.Opacity = opacity
                theme_options.skillchain_window_opacity = opacity
                ui.theme.skillchain_window_opacity = opacity
            elseif command == 'autoattack' then
                local aa = settings.AutoAttackIndicator
                local enabled = mode == 'on' or (amount and amount > 0)
                    or (not mode and aa.Enabled == false)
                aa.Opacity = amount or (enabled and aa.Opacity == 0 and 220 or aa.Opacity)
                aa.Enabled = enabled == true
                theme_options.aa_enabled, theme_options.aa_opacity = aa.Enabled, aa.Opacity
                ui.theme.aa_opacity = aa.Opacity
                ui:set_autoattack_enabled(aa.Enabled)
                if aa.Enabled and ui.is_setup then
                    local current = windower.ffxi.get_player()
                    if current then aa_set_engaged(current.status == 1 or current.status == 3) end
                end
            else
                local enabled = mode == 'on' or (not mode and settings.LockoutOpacity == 0)
                local opacity = amount or (enabled and -1 or 0)
                settings.LockoutOpacity = opacity
                theme_options.lockout_opacity = opacity
                ui.theme.lockout_opacity = opacity
            end
            ui_dirty = true
            config.save(settings)
        end

        local opacity
        if command == 'skillchain' then opacity = settings.SkillchainIndicator.Opacity
        elseif command == 'autoattack' then
            opacity = settings.AutoAttackIndicator.Enabled ~= false and settings.AutoAttackIndicator.Opacity or 0
        else opacity = settings.LockoutOpacity end
        local label = ({skillchain='Skillchain', lockout='Lockout', autoattack='Autoattack'})[command]
        local status = opacity == -1 and 'per-action settings' or tostring(opacity)
        chat_format.say(207, '[XIVCrossbar] '..label..' strip opacity: '..status)
        return
    end
    if command == 'textsettle' then
        return require('ui/text_measure').command(settings,args[1],
            function() config.save(settings) end,
            function(message) chat_format.say(207,'[XIVCrossbar] '..message) end)
    end
    if command == 'banklabels' then
        local mode = args[1] and args[1]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' and mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb banklabels [on|off|status]')
            return
        end
        if mode ~= 'status' then
            local enabled = mode == 'on' or (not mode and settings.Texts.BankLabels == false)
            settings.Texts.BankLabels = enabled
            theme_options.bank_labels_visible = enabled
            ui:set_bank_labels_visible(enabled)
            ui_dirty = true
            config.save(settings)
        end
        chat_format.say(207, '[XIVCrossbar] Bank labels: ' .. (settings.Texts.BankLabels ~= false and 'On' or 'Off'))
        return
    end

    if command == 'slotlabelstroke' then
        local mode = args[1] and args[1]:lower() or 'status'
        if mode ~= 'black' and mode ~= 'amber' and mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb slotlabelstroke [black|amber|status]')
            return
        end
        if mode ~= 'status' then
            settings.Texts.SlotLabelStroke = mode
            theme_options.slot_label_stroke = mode
            ui:set_slot_label_stroke(mode)
            config.save(settings)
        end
        chat_format.say(207, '[XIVCrossbar] Slot label outline: ' ..
            (settings.Texts.SlotLabelStroke == 'amber' and 'Amber' or 'Black'))
        return
    end

    if command == 'banklabeloffset' or command == 'slotlabeloffset' or command == 'costoffset' then
        local bank = command == 'banklabeloffset'
        local cost = command == 'costoffset'
        local prefix = bank and 'BankLabel' or cost and 'Cost' or 'SlotLabel'
        local x_key, y_key = prefix .. 'OffsetX', prefix .. 'OffsetY'
        local x, y = tonumber(args[1]), tonumber(args[2])
        if x and y and math.abs(x) < math.huge and math.abs(y) < math.huge and not args[3] then
            settings.Texts[x_key], settings.Texts[y_key] = x, y
            if bank then
                theme_options.bank_label_offset_x, theme_options.bank_label_offset_y = x, y
                ui:set_bank_label_offset(x, y)
            elseif cost then
                theme_options.cost_offset_x, theme_options.cost_offset_y = x, y
                ui:set_cost_offset(x, y)
            else
                theme_options.slot_label_offset_x, theme_options.slot_label_offset_y = x, y
                ui:set_slot_label_layout(settings.Texts.SlotLabelAlign, x, y)
            end
            config.save(settings)
        elseif (args[1] and args[1]:lower() ~= 'status') or args[2] then
            chat_format.say(123, '[XIVCrossbar] //xb ' .. command .. ' <x> <y> | status')
            return
        end
        chat_format.say(207, ('[XIVCrossbar] %s offset (X, Y) = %g, %g'):format(
            bank and 'Bank label' or cost and 'Cost text' or 'Slot label', settings.Texts[x_key] or 0, settings.Texts[y_key] or 0))
        return
    end

    if command == 'slotlabelalign' then
        local mode = args[1] and args[1]:lower() or 'status'
        if mode == 'left' or mode == 'center' then
            settings.Texts.SlotLabelAlign = mode
            theme_options.slot_label_align = mode
            ui:set_slot_label_layout(mode, settings.Texts.SlotLabelOffsetX or 0, settings.Texts.SlotLabelOffsetY or 0)
            config.save(settings)
        elseif mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb slotlabelalign [left|center|status]')
            return
        end
        chat_format.say(207, '[XIVCrossbar] Slot label alignment: ' ..
            (settings.Texts.SlotLabelAlign == 'center' and 'Center' or 'Left'))
        return
    end

    if command == 'banklabelopacity' then
        local opacity = tonumber(args[1])
        if opacity and opacity >= 0 and opacity <= 255 and opacity % 1 == 0 then
            settings.Texts.BankLabelOpacity = opacity
            theme_options.bank_label_opacity = opacity
            ui:set_bank_label_opacity(opacity)
            ui_dirty = true
            config.save(settings)
        elseif args[1] and args[1]:lower() ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb banklabelopacity [0-255|status]')
            return
        end
        chat_format.say(207, '[XIVCrossbar] Bank label opacity: ' .. (settings.Texts.BankLabelOpacity or 255))
        return
    end

    if command == 'textfade' or (command == 'ui' and args[1] == 'textfade') then
        local mode = command == 'textfade' and args[1] or args[2]
        mode = mode and mode:lower()
        if mode and mode ~= 'on' and mode ~= 'off' and mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb textfade [on|off|status]')
            return
        end
        if mode ~= 'status' then
            local enabled = mode == 'on' or (not mode and not settings.Animation.TextFade)
            settings.Animation.TextFade = enabled
            theme_options.text_fade = enabled
            ui.geometry:set_text_fade(enabled)
            config.save(settings)
        end
        chat_format.say(207, '[XIVCrossbar] Text fade: ' ..
            (settings.Animation.TextFade and 'ON (with crossbar)' or 'OFF (endpoint visibility)'))
        return
    end

    if command == 'recastflash' then
        local mode = args[1] and args[1]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' and mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb recastflash [on|off|status]')
            return
        end
        if mode ~= 'status' then
            local enabled = mode == 'on' or (not mode and not settings.Animation.RecastFlash)
            settings.Animation.RecastFlash = enabled
            theme_options.recast_flash_enabled = enabled
            ui.recast_flash_enabled = enabled
            ui:clear_recast_flashes()
            ui_dirty = true
            config.save(settings)
        end
        chat_format.say(207, '[XIVCrossbar] Recast flash: ' .. (settings.Animation.RecastFlash and 'ON' or 'OFF'))
        return
    end

    if command == 'slotglow' then
        local mode = args[1] and args[1]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' and mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb slotglow [on|off|status]')
            return
        end
        if mode ~= 'status' then
            local enabled = mode == 'on' or (not mode and not settings.Animation.SlotGlow)
            settings.Animation.SlotGlow = enabled
            theme_options.slot_glow_enabled = enabled
            ui:set_slot_glow_enabled(enabled)
            config.save(settings)
            ui_dirty = true
        end
        chat_format.say(207, '[XIVCrossbar] Slot glow: ' .. (settings.Animation.SlotGlow and 'ON' or 'OFF'))
        return
    end

    if command == 'triggerscale' then
        local mode = args[1] and args[1]:lower()
        local animation = settings.Animation
        local shift = mode and tonumber((mode:gsub('%%$', '')))
        if shift and shift >= 0 and shift <= 25 then
            -- Preserve the saved small factor so existing 0.99 values become a 1% shift.
            animation.SmallScale = 1 - shift/100
        elseif not mode or mode == 'on' or mode == 'off' then
            animation.TriggerScale = mode == 'on' or (not mode and not animation.TriggerScale)
        elseif mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb triggerscale [on|off|status|0-25]')
            return
        end
        if mode ~= 'status' then config.save(settings); ui_dirty = true end
        local state = animation.TriggerScale and 'ON' or 'OFF'
        local percent = (1 - (tonumber(animation.SmallScale) or .95))*100
        chat_format.say(207, ('[XIVCrossbar] Trigger scale: %s | Shift: ±%g%%'):format(state, percent))
        return
    end

    if command == 'ui' and args[1] == 'fade' then
        local mode = args[2] and args[2]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' then
            chat_format.say(123, '[XIVCrossbar] //xb fade [on|off]'); return
        end
        local enabled = mode == 'on' or (not mode and not settings.Animation.Enabled)
        settings.Animation.Enabled = enabled
        diagnostic:record('HUD', 'fade=' .. tostring(enabled))
        theme_options.fade_enabled = enabled
        ui.geometry.deferring_hide = false
        ui.geometry:configure_fade(enabled, settings.Animation.FadeIn, settings.Animation.FadeOut)
        ui.public_visible = nil
        ui_dirty = true
        config.save(settings)
        chat_format.say(207, '[XIVCrossbar] Fades: ' .. (enabled and 'ON' or 'OFF'))
        return
    end

    if command == 'ui' and args[1] == 'scale' then
        local scale = tonumber(args[2])
        if not scale or scale ~= scale or scale < .25 or scale > 2 then
            chat_format.say(123, '[XIVCrossbar] //xb ui scale <0.25-2>'); return
        end
        settings.CrossbarScale = scale
        theme_options.crossbar_scale = scale
        ui:set_scale(scale)
        env_chooser:set_anchor(ui:get_set_chooser_anchor())
        config.save(settings)
        chat_format.say(207, '[XIVCrossbar] Crossbar scale: ' .. tostring(scale))
        return
    end

    if command == 'eventbars' then
        local mode = args[1] and args[1]:lower() or 'status'
        if mode == 'on' or mode == 'off' then
            settings.EventBars = mode == 'on'
            ui_dirty = true
            config.save(settings)
        elseif mode ~= 'status' then
            chat_format.say(123, '[XIVCrossbar] //xb eventbars [on|off|status]')
            return
        end
        chat_format.say(207, '[XIVCrossbar] Event banks: ' ..
            (settings.EventBars and 'Reveal on hold' or 'Original behavior'))
        return
    end

    if command == 'autohide' then
        local mode = args[1] and args[1]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' then
            chat_format.say(123, '[XIVCrossbar] //xb autohide [on|off]'); return
        end
        if mode == 'off' or (not mode and settings.VisibilityMode == 'oninput') then
            settings.VisibilityMode = 'always'
        else settings.VisibilityMode = 'oninput' end
        config.save(settings)
        chat_format.say(207, '[XIVCrossbar] Visibility: ' .. settings.VisibilityMode)
        return
    elseif command == 'ui' and (args[1] == 'hide' or args[1] == 'show' or args[1] == 'auto') then
        settings.VisibilityMode = ({hide='hidden',show='always',auto='oninput'})[args[1]]
        ui.public_visible = nil
        config.save(settings)
        chat_format.say(207, '[XIVCrossbar] Visibility: ' .. settings.VisibilityMode)
        return
    end

    if command == 'unload' then
        return graceful_restart(true)
    elseif command == 'restart' then
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
    elseif command == 'sw' or command == 'switch' then
        switch_environment_command(args)
    elseif command == 'remap' then
        remap()
    elseif command == 'regenerate' then
        regenerate_resources()
    elseif command == '?' or command == 'help' then
        command_help.show(table.concat(args, ' '), theme_options.button_layout, settings.ControllerProfile)
    else
        chat_format.fail('Unknown command "'..command..'".')
        command_help.show(nil, theme_options.button_layout, settings.ControllerProfile)
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
local function crossbar_menu_open()
    return gamepad_mapper.is_showing or not action_binder.is_hidden
        or env_chooser:is_showing() or env_chooser.capturing
end

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
    if ui.is_setup then ui:show_button_hints() end
    if env_chooser.is_setup then env_chooser:maybe_unhide_default_sets_tooltip() end
    ui_dirty = true
end

local function handle_controller_key(dik, pressed, flags, blocked, input_seq)
    local left_trigger_just_pressed = pressed and gamepad.is_left_trigger(dik) and not gamepad_state.left_trigger
    local right_trigger_just_pressed = pressed and gamepad.is_right_trigger(dik) and not gamepad_state.right_trigger
    local left_trigger_just_released = (not pressed) and gamepad.is_left_trigger(dik) and gamepad_state.left_trigger
    local right_trigger_just_released = (not pressed) and gamepad.is_right_trigger(dik) and gamepad_state.right_trigger

    ui_dirty = ui_dirty or left_trigger_just_pressed or right_trigger_just_pressed or left_trigger_just_released or right_trigger_just_released

    if (gamepad.is_left_trigger(dik)) then
        gamepad_state.left_trigger = pressed
    elseif (gamepad.is_right_trigger(dik)) then
        gamepad_state.right_trigger = pressed
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
        return gamepad.is_left_trigger(dik) or gamepad.is_right_trigger(dik)
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
        if (gamepad_state.right_trigger_doublepress and theme_options.hotbar_number >= 5) then
            change_active_hotbar(6)
            gamepad_state.active_bar = 6
        else
            change_active_hotbar(2)
            gamepad_state.active_bar = 2
        end
    elseif (gamepad_state.capturing and gamepad_state.right_trigger and gamepad_state.left_trigger) then
        if (theme_options.hotbar_number == 4 or theme_options.hotbar_number == 6) then
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
                    ui:show_button_hints()
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
        if crossbar_menu_open() then return true end
        if (pressed) then
            local slot = gamepad.crossbar_slot(dik)
            if slot then trigger_action(slot,nil,input_seq) end

            if (not (gamepad.is_plus(dik) or gamepad.is_minus(dik))) then
                return true
            end
        end
    end


end

local function input_context()
    if gamepad_mapper.is_showing then return 'setup' end
    if not xivcrossbar.ready then return 'login' end
    if env_chooser.capturing then return 'text' end
    if env_chooser:is_showing() then return 'sets' end
    if action_binder:is_capturing_text() then return 'text' end
    if not action_binder.is_hidden then return 'menu:' .. tostring(action_binder.state) end
    if gamepad_state.left_trigger or gamepad_state.right_trigger then return 'crossbar' end
    return 'gameplay'
end
local function controller_keyboard(dik, pressed, flags, blocked)
    -- Physical keyboard review controls are owned through release. Enter
    -- confirming a text field belongs to text_input_guard, not this handler.
    if review_keyboard:edge(dik,pressed,action_binder,
        not restart_pending and windower.has_focus() and not blocked
        and not env_chooser:is_showing() and not env_chooser.capturing
        and not (dik==keyboard.enter and text_input_guard.enter_down)) then
        return true
    end
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
            return true
        end
    end
    -- A: the field may close on key-down. Own its confirming Enter until
    -- release; normal keyboard Enter outside text entry remains untouched.
    if dik == keyboard.enter then
        local consumed, commit = text_input_guard:enter_edge(pressed,
            (not action_binder.chooser_active and action_binder:is_capturing_text()) or env_chooser.capturing)
        if consumed then
            if commit then handle_controller_key(dik, pressed, flags, blocked) end
            return true
        end
    end
    -- Internal logical DIKs never claim the physical keyboard equivalents.
    if transport.signals[dik] then return false end
    return handle_controller_key(dik, pressed, flags, blocked)
end
windower.register_event('keyboard', controller_keyboard)

-- DirectLink routes addon input only. FFXI receives untouched native
-- gameplay/navigation, including dialogue and the login screens.
local function route_controller_message(dik, pressed, chord, seq)
    if restart_pending or native_mode ~= 'guard' or not native_filtering then return 'guard-inactive' end
    local context = input_context()
    local info = windower.ffxi.get_info()
    if info and info.chat_open and context ~= 'setup' then context = 'native-chat' end
    local item, edge, owner = transport:edge(dik, pressed, context)
    if not item or edge == 'repeat' then return 'unmapped-or-held',context end
    if controller_bridge then
        local claimed, decision = controller_bridge.menu:edge(dik, pressed, buttonmapping,gamepad_state.trust_menu_live)
        if claimed then return decision or 'trust-menu-release',context end
    end
    if gamepad_state.trust_menu_live and pressed then return 'trust-menu-priority',context end
    if dik == 89 or dik == 90 then
        if native_gamepad and native_gamepad.shoulder_slots and action_binder:is_binding_combo() then
            local bank = shoulder_banks.select(settings.ShoulderBanks, settings.ControllerProfile, transport.down, true, true)
            action_binder:set_shoulder_combo(shoulder_banks.ids[bank])
            ui_dirty = true
        end
        local eligible = context == 'gameplay' and info and not info.menu_open and windower.has_focus()
        if gamepad_state.shoulder_targeting and shoulder_banks.targeting(settings.ShoulderBanks, settings.ControllerProfile, eligible)
            and dik == 90 and pressed then
            local actor = windower.ffxi.get_player()
            if actor and actor.status ~= 4 then
                local action = shoulder_banks.target_action(dik, pressed, chord, transport.down,
                    not not windower.ffxi.get_mob_by_target('t'))
                if action == 'tab' then
                    local sent = native_gamepad.tap_tab() == 1
                    return sent and 'targeting-tab-sent' or 'targeting-tab-unavailable',context
                elseif action == 'targetnpc' then
                    windower.send_command('input /targetnpc')
                    return 'targeting-acquire-sent',context
                end
            end
        end
        if chord then return 'shoulder-chord',context end
        if context == 'crossbar' then return 'trigger-priority',context,gamepad_state.active_bar end
        if pressed then
            for slot_dik=59,66 do
                if transport.down[slot_dik] then return 'shoulder-after-held-slot',context end
            end
        end
        return 'shoulder-state',context
    end
    local slot = not pressed and gamepad.crossbar_slot(dik)
    if slot then
        ui:release_slot_pulse(slot)
        if ui.slot_glow_enabled then ui_dirty = true end
    end
    local transition = item.logical >= 67
    if settings.InputTrace then
        chat_format.say(207, '[XIVCrossbar test] '..item.name..' '..edge..' | '..tostring(owner or context))
    end
    if context == 'login' or (pressed and context == 'native-chat') then return 'native-context',context end
    if not pressed and (not owner or (owner ~= context and not transition) or owner == 'native-chat') then return 'release-context-changed',context end
    if item.logical <= 66 and context == 'gameplay' and pressed and gamepad_state.shoulder_slots
        and info and windower.has_focus() then
        local bank = shoulder_banks.select(settings.ShoulderBanks, settings.ControllerProfile, transport.down, true)
        local slot = gamepad.crossbar_slot(dik)
        if bank and slot then
            trigger_action(slot, shoulder_banks.ids[bank],seq)
            return 'shoulder-slot',context,shoulder_banks.ids[bank],slot
        end
    end
    if item.logical <= 66 and (context == 'gameplay' or context == 'native-chat') then return 'no-addon-claim',context end
    if context == 'sets' and item.logical <= 66 and item.logical ~= 59 and item.logical ~= 61 then return 'set-chooser-ignored',context end
    local captured = gamepad_state.capturing
    gamepad_state.capturing = true
    local handled = handle_controller_key(dik, pressed, 0, false, seq)
    gamepad_state.capturing = captured
    return handled and 'crossbar-handled' or 'state-only',context,gamepad_state.active_bar
end

local message_session='messages-'..os.time()..'-'..tostring({}):gsub('[^%w]','')
message_bridge=require('controller_messages').new({
    session=message_session,clock=profile_clock,wallclock=os.time,
    observe=function(message)
        if diagnostic and diagnostic:input_active() then diagnostic:record('DIRECTLINK',message) end
    end,
    event=route_controller_message,
    routed=function(seq,button,kind,reason,context,bank,slot)
        if not diagnostic or not diagnostic:input_active() then return end
        diagnostic:record('ROUTE',('seq=%d button=%d edge=%s context=%s decision=%s bank=%s slot=%s')
            :format(seq,button,kind,tostring(context),tostring(reason),tostring(bank),tostring(slot)))
    end,
    capture=function() end,
    cancel=function()
        ui:clear_slot_pulses()
        transport:reset()
        controller_bridge.menu.held={}
        gamepad_state.capturing=false
        gamepad_state.left_trigger=false;gamepad_state.right_trigger=false
        gamepad_state.left_trigger_doublepress=false;gamepad_state.right_trigger_doublepress=false
        gamepad_state.minus_button=false;gamepad_state.plus_button=false
        gamepad_state.active_bar=0
        close_left_doublepress_window()
        close_right_doublepress_window()
        set_chooser_button_down=false
        action_binder:clear_controller_input()
        if action_binder.chooser_active then finish_set_chooser(true) end
        ui_dirty=true
    end,
})
local next_message_poll=0
local function poll_directlink()
    local enabled = native_mode == 'guard' and native_receiving and windower.has_focus()
        and not restart_pending and (xivcrossbar.ready or gamepad_mapper.is_showing)
    if not enabled then
        message_bridge:context('', false)
        message_lease:close()
        return
    end
    local pid = native_gamepad.process_id
    local shoulders = native_gamepad.shoulder_slots or shoulder_banks.requested(settings.ShoulderBanks, settings.ControllerProfile)
    local key = settings.ControllerProfile..':'..settings.ControllerDevice..':'..tostring(shoulders)
    message_bridge:context(key, true, shoulders)
    if message_bridge:watchdog() then message_bridge:context(key, true, shoulders) end
    local directory=windower.addon_path..'data/directlink/'
    local now=profile_clock()
    if now>=next_message_poll then
        next_message_poll=now+.02
        local f=io.open(directory..pid..'.buttons','rb')
        if f then
            local contents=f:read(8193);f:close()
            message_bridge:accept(contents)
        end
    end
    local info = windower.ffxi.get_info()
    local actor = windower.ffxi.get_player()
    local gameplay = xivcrossbar.ready and not crossbar_menu_open() and info and not info.chat_open
        and not info.menu_open and actor and actor.status ~= 4 and not controller_bridge.menu.token
    message_lease:update(directory,pid,settings.ControllerProfile,settings.ControllerDevice,message_bridge.token,
        message_bridge.ack,shoulders,{movement=controller_bridge.mode(settings,'movement'),
            ps=controller_bridge.mode(settings,'ps'),gameplay=gameplay})
end

local frame = 0

-- Clear local controller ownership without submitting or discarding menu drafts.
local function clear_controller_input()
    ui:clear_slot_pulses()
    set_chooser_button_down=false
    menu_escape_down=false
    if action_binder.chooser_active then finish_set_chooser(true) end
    text_input_guard:reset_confirmation()
    transport:reset()
    if message_bridge then message_bridge:reset('focus') end
    message_lease:close()
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
windower.register_event('lose focus', function()
    review_keyboard:reset()
    clear_controller_input()
    text_input_guard:update(false, windower.send_command, false)
end)
windower.register_event('gain focus', function() clear_controller_input() end)

-- Native filtering and DirectLink have one active profile per client.
do
    local generation, next_wrapper_check, last_polls, last_native_poll, guard_selection, attempted
    local function say(message) chat_format.say(207, '[XIVCrossbar] Native pad: '..message) end
    native_stop=function(detach, retry)
        local active = native_mode~=nil
        native_mode,native_receiving,native_filtering=nil,false,false
        gamepad_state.trust_menu_live=false
        gamepad_state.shoulder_targeting=false
        gamepad_state.shoulder_slots=false
        native_attach_failure = nil
        if retry then attempted=nil end
        if not native_gamepad then return end
        native_gamepad.stop()
        if active then clear_controller_input() end
        if detach and not native_gamepad.detach() then
            chat_format.say(123, '[XIVCrossbar] Native hooks could not detach. Filtering is off.')
        end
    end
    native_command=function(command, dll_name, device)
        if command=='off' or command=='auto' then
            native_stop()
            settings.NativeControllerGuard=command=='auto'
            config.save(settings)
            attempted=nil
            return say(command=='auto' and 'automatic guard enabled' or 'native pass-through enabled')
        end
        if command==nil or command=='status' then
            if native_attach_failure then
                return say('Hook Unavailable. FFXI input is unfiltered. '..native_attach_failure)
            end
            if not native_gamepad then return say('Pass-Through | Bridge Inactive') end
            local phase = native_filtering and 'filtering'
                or native_mode=='probe' and 'probe'
                or native_mode=='guard' and 'waiting (pass-through)'
                or 'pass-through'
            return say(phase..' | '..native_gamepad.hook_status()..' | '..native_gamepad.status())
        end
        if command~='probe' and command~='guard' then
            return say('//xb nativepad [status|auto|off|probe [XInput DLL] [device]]')
        end
        local profile=settings.ControllerProfile
        local xbox=controller_profiles.profiles[profile].backend=='xinput'
        device=tonumber(device or settings.ControllerDevice)
        if not device or device%1~=0 or device<1 or device>(xbox and 4 or 16) then
            return say('Invalid device number.')
        end
        local module = xbox and (dll_name or 'auto') or 'dinput8.dll'
        local layout = profile=='fightpadpro-directinput' and 1 or profile=='xinput-r1-chooser' and 2 or 0
        if not native_gamepad then
            local ok, result=pcall(function()
                return require('native_gamepad').open(windower.addon_path..'native/xb_gamepad_messages.dll')
            end)
            if not ok then
                native_attach_failure = tostring(result)
                return say('Hook Unavailable. '..native_attach_failure)
            end
            native_gamepad=result
        end
        if native_mode then native_stop() end
        local result, operation, code = native_gamepad.begin(xbox and 1 or 2,device-1,
            command=='probe' and 1 or 3,layout,module)
        if result~=1 then
            if result==2 then
                native_attach_failure = 'Restart FFXI after changing the controller backend or DirectInput device.'
            elseif operation and code then
                native_attach_failure = ('%s failed (0x%08X).'):format(operation, code % 4294967296)
            else
                native_attach_failure = 'The native DLL returned no attachment detail. Check that it matches this build.'
            end
            return say('Hook Unavailable. FFXI input is unfiltered. '..native_attach_failure)
        end
        native_attach_failure = nil
        native_mode=command
        generation=nil
        last_polls,last_native_poll,native_receiving,native_filtering=0,nil,false,false
        if command=='probe' then say('Probe active. Check //xb nativepad status, then restore with //xb nativepad auto.') end
    end
    native_poll=function()
        local now=profile_clock()
        if now>=(next_wrapper_check or 0) then
            next_wrapper_check=now+.25
            local wrapper=controller_status()
            local ready = wrapper and wrapper.state=='ready'
                and controller_profiles.matches(wrapper,settings.ControllerProfile,settings.ControllerDevice,controller_modifier)
            local selection = ready and (settings.ControllerProfile..':'..settings.ControllerDevice..':'..wrapper.pid) or nil
            if native_mode=='guard' and selection~=guard_selection then native_stop() end
            if not selection then attempted=nil end
            if not native_mode and selection and settings.NativeControllerGuard~=false and attempted~=selection
                and windower.has_focus() and (xivcrossbar.ready or gamepad_mapper.is_showing) and not restart_pending then
                attempted=selection
                native_command('guard')
                if native_mode=='guard' then guard_selection=selection end
            end
        end
        if not native_mode then return end
        local info=windower.ffxi.get_info()
        local context=0
        if windower.has_focus() and info and not restart_pending and (xivcrossbar.ready or gamepad_mapper.is_showing) then
            local lease_alive = message_bridge.last_beat and now-message_bridge.last_seen < .35
            if native_mode=='guard' and not lease_alive then
                context=4 -- observe only until the reader has joined this PID
            else
                context=(gamepad_mapper.is_showing or crossbar_menu_open()) and 2 or (info.chat_open and 3 or 1)
            end
        end
        if native_filtering and context==4 then clear_controller_input() end
        local trust_slots = context == 1 and native_mode == 'guard' and native_gamepad.trust_menu
            and controller_bridge and controller_bridge.menu:mask(buttonmapping) or 0
        local actor = context == 1 and trust_slots == 0 and message_bridge.extended
            and (native_gamepad.shoulder_slots or settings.ShoulderBanks.Targeting) and windower.ffxi.get_player()
        local targeting = native_gamepad.tap_tab and actor and not info.menu_open and actor.status ~= 4
            and shoulder_banks.targeting(settings.ShoulderBanks, settings.ControllerProfile, true)
        local banks = native_gamepad.shoulder_slots and shoulder_banks.slot_context(info, actor, settings.EventBars)
            and shoulder_banks.capture_mask(settings.ShoulderBanks, settings.ControllerProfile) or 0
        local binding = context == 2 and message_bridge.extended and native_gamepad.shoulder_slots
            and action_binder:is_binding_combo()
        generation=native_gamepad.poll(context + (targeting and 0x100 or 0) + banks*0x200
            + (binding and 0x1000 or 0) + trust_slots*0x10000, function()
            if generation and message_bridge.token then clear_controller_input() end
        end, function() end, generation)
        gamepad_state.shoulder_targeting = targeting and message_bridge.extended
        gamepad_state.shoulder_slots = banks ~= 0 and message_bridge.extended
        if diagnostic and diagnostic:input_active() and native_gamepad.snapshot then
            local sample=native_gamepad.snapshot()
            local signature=('%d:%d:%04x:%04x:%d'):format(sample.generation,context,sample.raw,sample.masked,trust_slots)
            if signature~=diagnostic.last_native then
                diagnostic.last_native=signature
                diagnostic:record('NATIVE',('generation=%d context=%d raw=0x%04x masked=0x%04x trust=0x%02x polls=%d')
                    :format(sample.generation,context,sample.raw,sample.masked,trust_slots,sample.polls))
            end
        end
        local polls=native_gamepad.poll_count()
        if context~=0 and polls~=last_polls then last_native_poll=now end
        last_polls=polls
        native_receiving=context~=0 and native_gamepad.armed() and last_native_poll and now-last_native_poll<.5
        native_filtering=native_receiving and context~=4 and message_bridge.last_beat~=nil
        gamepad_state.trust_menu_live = native_filtering and trust_slots ~= 0
    end
end

-- ON PRERENDER
local next_identity_retry = 0
windower.register_event('prerender',function()
    -- Frames, rather than repeated native getters, control caption settling.
    require('ui/text_measure').begin_frame()
    -- Diagnostic timing is observed before rendering/transport work begins.
    diagnostic:tick(input_context())
    if not restart_pending and profile_clock() >= next_identity_retry then
        next_identity_retry = profile_clock() + .25
        check_profile_ready()
    end
    local menu_mode = controller_bridge.mode(settings,'menu')
    local path, id
    if menu_mode ~= 'off' and xivcrossbar.ready and not restart_pending and windower.has_focus()
        and not crossbar_menu_open() then
        local info, actor = windower.ffxi.get_info(), windower.ffxi.get_player()
        if actor and actor.id and info and info.server and not info.chat_open then
            id = actor.id
            path = windower.windower_path..'addons/trust/data/controller-menu-'..info.server..'-'..id..'.txt'
        end
    end
    controller_bridge.menu:update(menu_mode,path,id)
    native_poll()
    poll_directlink()
    controller_bridge.menu:tick(gamepad_state.trust_menu_live)
    local bank, bank_visible
    if gamepad_state.shoulder_slots and native_filtering then
        local info = windower.ffxi.get_info()
        local eligible = info and not info.chat_open and input_context() == 'gameplay'
        bank, bank_visible = shoulder_banks.select(settings.ShoulderBanks, settings.ControllerProfile,
            transport.down, eligible)
    end
    if bank ~= gamepad_state.shoulder_bank or bank_visible ~= gamepad_state.shoulder_bank_visible then
        gamepad_state.shoulder_bank, gamepad_state.shoulder_bank_visible = bank, bank_visible
        ui_dirty = true
        diagnostic:record('BANK', ('selected=%s visible=%s'):format(tostring(bank), tostring(bank_visible)))
    end
    gamepad_state.shoulder_display = bank_visible and shoulder_banks.ids[bank] or nil
    local focused = windower.has_focus()
    action_binder:tick_navigation(profile_clock(), focused)
    local keyboard_context = focused and not restart_pending
    local navigation = keyboard_context and (gamepad_mapper.is_showing or action_binder:is_keyboard_review()
        or gamepad_mapper:has_owned_key() or review_keyboard:has_owned_key()
        or (menu_escape_down and text_input_guard.navigation)) or false
    text_input_guard:update(keyboard_context and (action_binder:is_capturing_text() or env_chooser.capturing),
        windower.send_command, navigation)
    if ui.is_setup then ui:set_chooser_open(env_chooser:is_showing()) end
    -- Elapsed-time fades must keep progressing even when recast frames skip.
    if ui.geometry then ui.geometry:tick() end
    if ui.is_setup then ui:tick_recast_flashes() end
    -- allow settings to skip rendering frames
    frame = (frame + 1)  % (theme_options.frame_skip + 1)
    if (frame > 0 and not ui_dirty) then
        return
    end

    skillchains.prerender()
    if xivcrossbar.ready == false or restart_pending then
        return
    end

    local visibility_mode = visibility.event_mode(settings.VisibilityMode, xivcrossbar.hide_hotbars, settings.EventBars)
    if ui.is_setup and visibility_mode ~= 'hidden' and (not xivcrossbar.hide_hotbars or visibility_mode == 'oninput')
        and (gamepad_state.left_trigger or gamepad_state.right_trigger) then
        ui.geometry:interrupt_startup_reveal()
    end
    local menu_open = crossbar_menu_open()
    local trigger_scale = settings.Animation.TriggerScale and not settings.Animation.Enabled
    if trigger_scale and ui.is_setup and ui.geometry.load_fade_state then
        if ui.geometry.startup_reveal then ui.geometry:interrupt_startup_reveal() end
        ui.geometry.load_fade_state.claimed = true
    end
    local visible = (menu_open and not xivcrossbar.hide_hotbars) or visibility.should_show(visibility_mode,
        gamepad_state.left_trigger or gamepad_state.right_trigger or gamepad_state.shoulder_display ~= nil, xivcrossbar.hide_hotbars,
        ui.is_setup and ui.geometry:is_startup_reveal_pending())
        or action_binder:is_moving_crossbars() or env_chooser:is_showing()
    if not visible then crossbar_drag:finish() end
    local display_bank
    if ui.is_setup then
        local autohide = visibility_mode == 'oninput'
        local active_bank = gamepad_state.active_bar ~= 0 and gamepad_state.active_bar or gamepad_state.shoulder_display or 0
        local grace_enabled = autohide and not menu_open and gamepad_state.left_trigger ~= gamepad_state.right_trigger
        display_bank = ui:select_display_bank(visible and not menu_open and active_bank or 0, grace_enabled, profile_clock())
        ui:update_trigger_scale(settings.Animation.TriggerScale, settings.Animation.SmallScale,
            display_bank, visible, autohide, menu_open)
    end
    if ui.is_setup and ui.public_visible ~= visible then
        if visible then
            ui.public_visible = ui:show(player.hotbar, player.hotbar_settings.active_environment) == true
        else ui:hide(); ui.public_visible = false end
    end

    if visible and ui.feedback.is_active then
        ui:show_feedback()
    end

    if ui.is_setup then
        local lockout_visible = visibility_mode ~= 'hidden' and
            (visible or (visibility_mode == 'oninput' and not xivcrossbar.hide_hotbars))
        ui:display_gcd_indicator(lockout_visible)
    end

    if visible and ui.is_setup then
        local dim_default_slots = not action_binder.is_hidden        
        ui:check_recasts(player.hotbar, player.vitals, player.hotbar_settings.active_environment, player.current_spells, gamepad_state, skillchains, consumables, dim_default_slots, xivcrossbar.in_battle, menu_open,
            action_binder:get_binding_preview_bank(), action_binder:get_tentative_binding_slot(), display_bank)
        ui:show_slot_pulse(menu_open)
    end

    ui_dirty = false
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
    -- Presentation is resolved on render so held triggers can override Event
    -- hiding in Auto without showing inactive bars on a status transition.
    xivcrossbar.hide_hotbars = new_status_id == 4
    ui_dirty = true

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
    aa_set_engaged(new_status_id == 1 or new_status_id == 3)
end)

-- Auto-attack swing timer: pause/unpause when disabling debuffs come and go.
-- Buff IDs: 2=Sleep, 6=Petrification, 10=Stun, 17=Terror, 19=Sleep II, 28=Charm.
local AA_PAUSING_BUFFS = {
    [2]  = 'sleep',
    [6]  = 'petrify',
    [10] = 'stun',
    [17] = 'terror',
    [19] = 'sleep2',
    [28] = 'charm',
}

windower.register_event('gain buff', function(buff_id)
    if not ui.aa_enabled then return end
    local src = AA_PAUSING_BUFFS[buff_id]
    if (src ~= nil) then
        aa_add_pause_source(src)
    end
end)

windower.register_event('lose buff', function(buff_id)
    if not ui.aa_enabled then return end
    local src = AA_PAUSING_BUFFS[buff_id]
    if (src ~= nil) then
        aa_remove_pause_source(src)
    end
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

    -- Windower supplies one action table; refresh spell availability after
    -- this character's job ability, including arts/addendum transitions.
    if act.category == CATEGORY_JOB_ABILITY and act.actor_id == player:get_id() then
        player:update_current_spells()
    end

    if ui.aa_enabled and (act.category == CATEGORY_MELEE and act.actor_id == player.id) then
        aa_record_swing()
    end

    if ui.aa_enabled and (act.category == CATEGORY_WEAPONSKILL and act.actor_id == player.id) then
        aa_add_pause_source('ws')
        aa_clear_pause_after('ws', 2.0)
    end
    if ui.aa_enabled and (act.category == CATEGORY_JOB_ABILITY and act.actor_id == player.id) then
        aa_add_pause_source('ja')
        aa_clear_pause_after('ja', 2.0)
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
    if player.cancel_summon_swap then player:cancel_summon_swap() end
    skillchains.zone_change()
end)
