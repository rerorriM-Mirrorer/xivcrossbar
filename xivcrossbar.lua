-- Addon description
_addon.name = 'XIVCrossbar' -- based on Edeon's XIV Hotbar
_addon.author = 'Aliekber, various friendly neighborhood modders'
-- Credit goes to: Aeliya, BlueSummersC, FionaBrightgrass, GrayFox2510, Icydeath, qEagleStrikerp, Sylvebits, XerevNonori
_addon.version = '0.4.0-a.20261024.directlink1-trustmerge1'
_addon.language = 'english'
_addon.commands = {'xivcrossbar', 'xb', 'xcb'}

-- Libs
require('libs/module_paths').install()
require('chat')
res = require 'resources'
config = require('config')
file = require('files')
texts = require('texts')
images = require('images')
tables = require('tables')
resources = require('resources')
xml = require('libs/xml2')   -- TODO: REMOVE

-- User settings
local defaults = require('libs/defaults')
local input_timing=require('libs/controller/timing_trace').new({clock=require('socket').gettime,
    write=function(path,contents)
        local f,err=io.open(path,'ab');if not f then return nil,err end
        local ok,write_error=f:write(contents);local closed,close_error=f:close()
        return ok and closed,write_error or close_error
    end,
    say=function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] '..message)) end})
local render_trace = require('ui/render_trace')
-- Register before UI modules so their existing measurements share this frame ID.
windower.register_event('prerender',function()
    require('ui/text_measure').begin_frame()
    if render_trace.enabled then render_trace.begin_frame(require('socket').gettime()) end
end)
-- Import every saved character before loading the main settings map, so config
-- never reintroduces the retired bank sections. Recovery copies stay in data/.
windower.create_dir(windower.addon_path..'data')
local bank_backend=require('libs/windows_file').new()
local bank_storage=require('libs/banks/storage').new({
    path=windower.addon_path..'data/companion_banks.xml',main=windower.addon_path..'data/settings.xml',
    parse=xml.parse,lock=bank_backend.lock,replace=bank_backend.replace,
    read=function(path)
        local f,err,code=io.open(path,'rb')
        if not f then if code==2 then return nil end;return nil,err end
        local raw,read_error=f:read('*a');local closed,close_error=f:close()
        if not raw or not closed then return nil,read_error or close_error or 'Could not read bank settings.' end
        return raw
    end,
    say=function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] '..message)) end})
bank_storage:prepare()
local bank_settings=bank_storage.state
local settings = config.load(defaults)
local client_registry
-- A: profile selection replaces the independent legacy backend flags. Existing
-- unused XML fields remain harmless; only one shared reader can be active.
local controller_profiles = require('libs/controller/profiles')
local personal_profile = require('libs/controller/personal_profile')
local function normalize_controller_settings()
    require('ui/text_measure').enabled=settings.TextSettling~=false
    local changed,notice = personal_profile.normalize(settings,defaults,controller_profiles)
    local info=windower.ffxi.get_info()
    local character=info.logged_in and windower.ffxi.get_player()
    bank_storage:refresh(nil,character and character.name)
    if notice then windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] '..notice)) end
    if changed then config.save(settings) end
    if client_registry then client_registry:register(settings.on_unload_killahk) end
end
normalize_controller_settings()
-- Windower reparses per-character settings on load/login/logout. Run the same
-- migration after each parse so an older character section cannot revert it.
config.register(settings,normalize_controller_settings)
-- A: last-client shutdown uses process registrations; explicit controller stop
-- still stops the shared transport regardless of other registered clients.

-- A: immutable for this load; changing one client cannot safely reconfigure
-- the wrapper shared by every client. Reload all clients after stopping it.
local controller_modifier = tostring(settings.ControllerModifier or 'apps'):lower()
if controller_modifier ~= 'apps' and controller_modifier ~= 'ctrl' then
    controller_modifier = 'apps'
    windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Invalid ControllerModifier; using apps.'))
end
local controller_capture_dik = controller_modifier == 'ctrl' and 29 or 221
local controller_bind_prefix = controller_modifier == 'ctrl' and '^' or '#'

-- Load theme options according to settings
local character_identity = require('libs/character_identity')
local profile_gate = require('libs/controller/profile_gate').new(require('socket').gettime)
local theme = require('ui/theme')
local theme_options = theme.apply(settings)
local buttonmapping = require('libs/controller/buttonmapping')
local resource_generator = require('libs/resource_generator')
resource_generator.generate_outdated_resources()

-- Addon Dependencies
local action_manager = require('libs/action_manager')
local keyboard = require('libs/controller/keyboard_mapper')
local gamepad = require('libs/controller/gamepad')
local transport = require('libs/controller/transport')
local text_input_guard = require('libs/controller/text_input_guard')
local personal_controls = require('libs/controller/personal_controls').new()
local publish_personal_context
local controller_message_bridge
local message_capture, message_button, message_cancel, message_menu
local companion_banks,companion_context
local trust_menu
local message_epoch=0
local visibility = require('libs/visibility')
local storage = require('libs/storage')
local player = require('libs/player')
local ui = require('ui/crossbar')
local env_chooser = require('ui/environment_chooser')
local action_binder = require('ui/action_binder')
local enchanted_items = require('libs/enchanted_items')
local xivcrossbar = require('libs/variables')
local skillchains = require('libs/skillchain/skillchains')
local consumables = require('libs/consumables')
local gamepad_mapper = require('ui/controller_setup')
local gamepad_converter = require('libs/controller/gamepad_converter')
local function_key_bindings = require('libs/controller/function_key_bindings')

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

-- A: companion state lives in this client's settings, never in the shared
-- wrapper. The sequenced bridge cannot replay across focus/menu transitions.
local l1_clock=require('socket').gettime
local l1_bank=require('libs/banks/legacy').new({settings=bank_settings,clock=l1_clock,
    save=function() bank_storage:save() end,
    execute=function(command) windower.send_command(command) end,
    say=function(message) windower.add_to_chat(0,require('libs/chat_status').notice(message)) end,
    help=function(syntax,description) require('libs/chat_help').command(syntax,description) end})
local l1_bridge=require('libs/banks/legacy_transport').new({session=require('libs/windows_file').new().session_id,
    event=function(kind,slot) l1_bank:event(kind,slot) end,cancel=function() l1_bank.held=false end})
local l1_view=require('ui/bank_view').new({bank=l1_bank,resources=require('ui/resources'),path=windower.addon_path,settings=settings})
companion_banks=require('libs/banks/banks').new({settings=bank_settings,clock=l1_clock,
    ordinary=function(button,pressed) if message_button then message_button(require('libs/controller/messages').diks[button],pressed,0,false) end end,
    context=function() if companion_context then return companion_context() end;return false,false end,
    execute=function(command) windower.send_command(command) end,
    save=function() bank_storage:save() end,
    say=function(message) windower.add_to_chat(0,message) end,
    help=function(syntax,description) require('libs/chat_help').command(syntax,description) end})
local companion_left,companion_right=companion_banks:panel('Left'),companion_banks:panel('Right')
local r1_view=require('ui/bank_view').new({bank=companion_right,resources=require('ui/resources'),path=windower.addon_path,settings=settings,owner='r1-companion'})
controller_message_bridge=require('libs/controller/messages').new({session=require('libs/windows_file').new().session_id,
    clock=l1_clock,wallclock=os.time,
    trace=function(message) input_timing:record(message) end,
    capture=function(pressed) if message_capture then message_capture(pressed) end end,
    event=function(dik,pressed) if message_button then message_button(dik,pressed,0,false) end end,
    menu=function(button) if message_menu then message_menu(button) end end,
    physical=function(button,pressed)
        if trust_menu and trust_menu:edge(button,pressed,buttonmapping,companion_banks.down[14]) then return end
        companion_banks:edge(button,pressed)
    end,
    can_recover=function() return companion_context and companion_context() end,
    resume=function(button)
        if companion_context and companion_context() then companion_banks:resume(button) end
    end,
    ready=function() companion_banks.active=true end,
    key_ack=function(ack) companion_banks.output:accept(ack) end,
    cancel=function() if message_cancel then message_cancel() end end})
trust_menu=require('libs/controller/trust_menu').new({clock=l1_clock,
    execute=function(command) windower.send_command(command) end,
    changed=function()
        companion_banks:cancel()
        if release_gameplay_keys then release_gameplay_keys() end
    end})
local l1_epoch,l1_last_tick,l1_next_read=0,0,0
local l1_drag=require('ui/drag').new({
    enabled=function() return l1_view.opacity>.01 and not l1_view.options.bank:settings().Locked end,
    bounds=function() return l1_view:bounds() end,
    offsets=function() local d=l1_view.options.bank:settings();return d.X,d.Y end,
    move=function(x,y) local d=l1_view.options.bank:settings();d.X,d.Y=x,y end,
    save=function() bank_storage:save() end,
})
local r1_drag=require('ui/drag').new({
    enabled=function() return r1_view.opacity>.01 and not companion_right:settings().Locked end,
    bounds=function() return r1_view:bounds() end,
    offsets=function() local d=companion_right:settings();return d.X,d.Y end,
    move=function(x,y) local d=companion_right:settings();d.X,d.Y=x,y end,
    save=function() bank_storage:save() end})

local function move_crossbars(x,y)
    ui:move_to(x,y)
    env_chooser:set_anchor(ui:get_set_chooser_anchor())
end

local crossbar_drag = require('ui/drag').new({
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

local function set_crossbar_position(args)
    if #args==0 then
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Copy position: //xb pos '..tostring(settings.Style.OffsetX)..' '..tostring(settings.Style.OffsetY)))
        return
    end
    local x,y=tonumber(args[1]),tonumber(args[2])
    if #args~=2 or not x or not y or x~=x or y~=y or math.abs(x)==math.huge or math.abs(y)==math.huge then
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Use //xb pos <offset x> <offset y>.'));return
    end
    if not ui.is_setup then windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Finish setup before positioning crossbars.'));return end
    crossbar_drag:finish()
    settings.Style.OffsetX,settings.Style.OffsetY=x,y
    theme_options.offset_x,theme_options.offset_y=x,y
    move_crossbars(x,y);config.save(settings);ui_dirty=true
end

local function set_compact_mode(mode)
    mode = mode and mode:lower()
    if mode and mode ~= 'on' and mode ~= 'off' then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] //xb compact [on|off]'))
        return
    end
    local enabled = mode == 'on' or (not mode and not settings.iscompact)
    crossbar_drag:finish()
    settings.iscompact, theme_options.is_compact = enabled, enabled
    ui:set_compact(enabled)
    if ui.is_setup then env_chooser:set_anchor(ui:get_set_chooser_anchor()) end
    ui_dirty = true
    config.save(settings)
        windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Compact: ' .. (enabled and 'ON' or 'OFF')))
end
windower.register_event('mouse',function(kind,x,y,delta,blocked)
    if r1_drag:mouse(kind,x,y,blocked) then return true end
    if l1_drag:mouse(kind,x,y,blocked) then return true end
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
function set_hotkey(hotbar, slot, action_type, action, target, command, icon, linked_action, linked_type, explicit_alias, catalog_origin)
    if player.hotbar_load_ok == false then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Reload successfully before binding. Existing files were not changed.'))
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
    if is_custom_action and not require('ui/custom_action_review').nonempty(alias) then alias = action end
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

    if is_custom_action and action_type == 'ex' and not require('ui/custom_action_review').nonempty(command) then
        -- Preserve the blank catalog command; materialize only the slot's
        -- executable action using its explicit alias, then catalog name.
        action = require('ui/custom_action_review').nonempty(alias) and alias or action
    elseif (command ~= nil and command ~= '') then
        -- If no explicit alias was provided, fall back to the human-readable
        -- action name being replaced by the raw command (existing behavior).
        if (alias == nil) then alias = action end
        action = command
    end

    local new_action = action_manager:build(action_type, action, target, alias, icon, nil, nil, nil, nil, linked_action, linked_type)
    if catalog_origin then
        local bindings=require('libs/catalog_bindings')
        local record=bindings.find(player.catalog_sources[catalog_origin.scope],catalog_origin.id)
        if record then bindings.attach(new_action,record,catalog_origin.scope) end
    end
    player:add_action(new_action, environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
    local feedback=require('ui/binding_feedback')
    windower.add_to_chat(207, feedback.bound(alias or action, feedback.set_name(player.hotbar,environment), hotbar, slot))
end

-- command to set a crossbar action in action_binder
function delete_hotkey(hotbar, slot)
    if player.hotbar_load_ok == false then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Reload successfully before clearing a binding. Existing files were not changed.'))
        return false
    end
    local environment = player.hotbar_settings.active_environment

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
    local feedback=require('ui/binding_feedback')
    windower.add_to_chat(207, feedback.cleared(feedback.set_name(player.hotbar,environment), hotbar, slot))
end

function get_crossbar_sets()
    return require('ui/crossbar_destinations').build(player.hotbar)
end

function create_new_set(name)
    if not player:create_new_environment(name) then return false end
    player:save_hotbar()
    reload_hotbar()
    windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Created crossbar set: ' .. name))
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
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Change Icon: no action bound at the selected slot.'))
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
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Global Icon Set: missing name or icon.'))
        return
    end

    player.shared_icons[name] = icon
    player:save_shared_icons_file()
    reload_hotbar()
    set_active_environment(player.hotbar_settings.active_environment)

    windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Global icon set: "' .. name .. '" -> ' .. icon))
end

-- A: one entry per locked save; never replace a catalog from a stale client.
local function save_catalog_change(original,record,verb)
    local ok,saved,detail=pcall(player.save_catalog_edit,player,original,record)
    if not ok or not saved then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Custom action was not '..verb..'. '..tostring(ok and detail or saved)))
        return false
    end
    local name=record and record.name or original
    windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Custom action '..verb..': "'..tostring(name)..'"'..
        (record and ' ['..record._scope..']' or '. Existing bound copies remain usable.')))
    return true
end
function save_custom_action(record) return save_catalog_change(nil,record,'saved') end
function update_custom_action(original,record) return save_catalog_change(original,record,'updated') end
function delete_custom_action(name) return save_catalog_change(name,nil,'deleted') end

-- A: the saved selection is per client; the running wrapper is shared.
local controller_switcher
local function controller_status()
    return controller_profiles.read_status(windower.addon_path .. 'data/controller-status.ini')
end
local function save_diagnostics()
    local character=tostring(player.name or 'prelogin'):gsub('[^%w_-]','_')
    local path=windower.addon_path..'data/diagnostics-'..character..'.log'
    local snapshot={version=_addon.version,time=os.date('!%Y-%m-%dT%H:%M:%SZ'),
        character=character,ready=xivcrossbar.ready,controller=controller_status() or {},
        selected={profile=settings.ControllerProfile,device=settings.ControllerDevice,
            messages=settings.ControllerMessages,legacy_modifier=controller_modifier,
            dpad=settings.GameplayDPad,ahk_ijkl=settings.ControllerRealKeys,
            target_r2=settings.ControllerTargetR2,target_r3=settings.ControllerTargetR3},
        receiver={ack=controller_message_bridge.ack,received=controller_message_bridge.received,
            rejected=controller_message_bridge.rejected,last_reset=controller_message_bridge.last_reason,
            recovering=controller_message_bridge.recovering},
        trust_menu=trust_menu and {mode=trust_menu.mode,sent=trust_menu.sent} or {},
        trace={lua=input_timing.active},bank_settings=companion_banks:settings(),
        bank_runtime={active=companion_banks.active,layer=companion_banks.layer,menu=companion_banks.menu,
            native_ack=companion_banks.output.ack,native_seq=companion_banks.output.seq,
            executed=companion_banks.executed,empty=companion_banks.empty},
        set=player.hotbar_settings and player.hotbar_settings.active_environment,
        storage={catalog=storage.identity_valid and storage.directory or 'Awaiting character login',
            bank_file=bank_storage.source,bank_character=bank_storage.character,
            registered=client_registry and client_registry.loaded,
            stop_after_last_client=settings.on_unload_killahk},
        editor={state=action_binder.state,page=action_binder.page,
            setup=gamepad_mapper.is_showing,text_entry=text_input_guard.active},
        autoattack=settings.AutoAttackIndicator,
        legacy_bridge={received=l1_bridge.received,rejected=l1_bridge.rejected,ack=l1_bridge.ack}}
    windower.create_dir(windower.addon_path..'data')
    local ok,err=require('libs/controller/diagnostics').save(path,snapshot)
    local format=require('libs/chat_status')
    windower.add_to_chat(0,format.notice(ok and ('Diagnostics saved: '..path) or
        ('Could not save diagnostics: '..tostring(err)),ok and 207 or 167))
    return ok
end
local function report_controller_status(details,embedded)
    if details then return save_diagnostics() end
    local status=controller_status()
    local lines=require('libs/chat_status').controller({settings=settings,status=status,
        bridge=controller_message_bridge,modifier=controller_modifier,banks_active=companion_banks.active,
        hide_hint=embedded,embedded=embedded,lua_trace=input_timing.active,pending=controller_switcher and controller_switcher.pending and controller_switcher.pending.phase,
        mismatch=status and status.running and not controller_profiles.matches(status,settings.ControllerProfile,settings.ControllerDevice,controller_modifier)},details)
    for _,line in ipairs(lines) do windower.add_to_chat(0,line) end
end
function start_controller_wrappers(profile, device, modifier)
    profile = profile or settings.ControllerProfile
    device = device or settings.ControllerDevice
    modifier = modifier or controller_modifier
    local status = controller_status()
    if status and status.running then
        if not controller_profiles.matches(status, profile, device, modifier) then
            local format=require('libs/chat_status')
            windower.add_to_chat(0,format.notice('Controller already running: '..format.value(format.profile(status.profile)..
                ' / Device '..tostring(status.device))..'. Use //xb controller profile '..
                controller_profiles.short_name(profile)..' '..tostring(device)..'.',140))
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
            windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Stop is pending. Wait two seconds, then start again.'))
            return false
        end
        os.remove(stop_path)
    end
    windower.create_dir(windower.addon_path .. 'data')
    local written, err = controller_profiles.write_launch(windower.addon_path .. 'data/controller-launch.ini',
        profile, device, modifier)
    if not written then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Could not save wrapper startup selection: ' .. tostring(err)))
        return false
    end
    windower.send_command('run addons/xivcrossbar/ffxi_directinput.ahk ' .. modifier ..
        ' ' .. profile .. ' ' .. device)
    local format=require('libs/chat_status')
    windower.add_to_chat(0,format.notice('Wrapper start requested: '..format.value(format.profile(profile)..' / Device '..device)))
    return true
end
local function stop_controller_wrapper()
    windower.create_dir(windower.addon_path .. 'data')
    local f = io.open(windower.addon_path .. 'data/input-stop.request', 'w')
    if not f then windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Could not write wrapper stop request.')); return false end
    f:write(tostring(os.time())); f:close()
    windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Shared wrapper stop requested for all clients.'))
    return true
end
local function request_controller_trace(mode)
    if mode~='on' and mode~='off' then
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] //xb controller trace on|off'));return false
    end
    local current=controller_status()
    if not current or not current.running then
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Start the current controller wrapper before requesting a trace.'));return false
    end
    local f=io.open(windower.addon_path..'data/controller-trace.request','w')
    if not f then windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Could not write controller trace request.'));return false end
    local written=f:write(mode);local closed=f:close()
    if not written or not closed then
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Controller trace request failed.'));return false
    end
    if mode=='on' then
        local name=windower.ffxi.get_player()
        input_timing:start(windower.addon_path..'data/controller-lua-trace-'..(name and name.name or 'login')..'.log',_addon.version)
    else input_timing:stop('manual') end
    windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Lua trace '..mode..'; data/controller-lua-trace-<character>.log'))
    windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Wrapper trace '..mode..' requested'..
        (mode=='on' and ' for 30 seconds.' or '.')..' Log: data/controller-input-trace.log'))
    return true
end
controller_switcher = require('libs/controller/switch').new({
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
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] ' .. result))
        if done then done(false, result) end
        return false
    end
    settings.ControllerProfile, settings.ControllerDevice = profile, result
    settings.PersonalProfileMigrated = true
    config.save(settings)
    local format=require('libs/chat_status')
    windower.add_to_chat(0,format.notice('Selecting '..format.value(format.profile(profile)..' / Device '..result)..
        (controller_profiles.profiles[profile].experimental and format.ink(' (Experimental)',140) or '')))
    return controller_switcher:request(profile, result, controller_modifier, function(ok, detail)
        if ok then
            windower.add_to_chat(0,format.notice('Controller: '..format.value(format.profile(profile))..' / '..format.state(detail.state)))
        elseif detail ~= 'Controller change cancelled.' and detail ~= 'Replaced by another controller selection.' then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] ' .. tostring(detail)))
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
    -- Calls without a settled identity request observation; the pre-login
    -- controller wrapper remains independent and available at the lobby.
    if not server_id or not server or info.server ~= server_id or not info.zone or info.zone <= 0 or
        windower_player.name ~= expected_name or windower_player.id ~= expected_id or
        not entity or entity.id ~= expected_id or entity.name ~= expected_name then
        xivcrossbar.ready = false
        storage.identity_valid = false
        player.identity_confirmed = false
        xivcrossbar.pending_initialize = info and info.logged_in == true
        if not server_id then profile_gate.loaded = nil end
        return false, 'identity'
    end
    xivcrossbar.pending_initialize = false
    player.identity_confirmed = true
    player.custom_action_save_scope = settings.CustomActionSaveScope

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
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] No crossbar sets are available. Check the XML files and reload.'))
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
    return true
end

-- A: recover the earlier personal branch's world/stability gate. Continue
-- observing after success: a valid but stale lobby server can correct later.
local function check_profile_ready()
    local info = windower.ffxi.get_info()
    local current_player = windower.ffxi.get_player()
    local entity = current_player and current_player.id and windower.ffxi.get_mob_by_id(current_player.id)
    local server_record = info and resources.servers[info.server]
    local server_id, name, id = profile_gate:observe(info, current_player, entity, server_record)
    if not server_id then return end
    if xivcrossbar.ready then
        -- Rebuild through normal unload so drawing objects are not stacked.
        xivcrossbar.ready = false
        storage.identity_valid = false
        player.identity_confirmed = false
        restart_pending = true
        crossbar_drag:finish()
        if ui.is_setup then ui:hide() end
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Character/server changed; reloading for '..server_record.en..'/'..name..'.'))
        windower.send_command('lua r xivcrossbar')
        return
    end
    local ok, reason = initialize(server_id, name, id)
    if not ok and reason == 'identity' then profile_gate.loaded = nil end
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
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] No crossbar sets are available. Check the XML files and reload.'))
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

-- Switch to a named set, accepting display names containing spaces.
-- Normalize once so validation and selection use the same stored key.
function switch_environment_command(args)
    if not args[1] then
        print('XIVCROSSBAR: Invalid arguments: switch <crossbar_set>')
        return
    end

    local name = table.concat(args, ' ')
    local environment = kebab_casify(name)
    if is_valid_environment(environment) then
        set_active_environment(environment)
    else
        print('XIVCROSSBAR: "' .. name .. '" is not a valid crossbar set.')
    end
end

-- command to set an action in a hotbar
function set_action_command(args)
    if not args[5] then
        print('XIVCROSSBAR: Invalid arguments: set <mode> <hotbar> <slot> <action_type> <action> <target (optional)> <alias (optional)> <icon (optional)>')
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

    if hotbar < 1 or hotbar > theme_options.hotbar_number or to_hotbar < 1 or to_hotbar > theme_options.hotbar_number then
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

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
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

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
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
    local kind, value, field_value = require('ui/custom_action_review').route(args)
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
    windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Created crossbar set: ' .. environment))
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
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Usage: //xcb rename <old name> <new name>'))
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
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Use a set name starting with a letter, with letters, numbers, spaces, hyphens or underscores.'))
        return
    end

    if (PROTECTED_ENV_KEYS[old_key]) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Crossbar set "' .. old_name .. '" is reserved and cannot be renamed.'))
        return
    end
    if (PROTECTED_ENV_KEYS[new_key]) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Crossbar set name "' .. new_name .. '" is reserved.'))
        return
    end
    if (old_key == new_key) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] New name resolves to the same key as the old name. Nothing to do.'))
        return
    end
    if (player.hotbar[old_key] == nil) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] No crossbar set named "' .. old_name .. '" found in the current job.'))
        return
    end
    if (player.hotbar[new_key] ~= nil) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] A crossbar set named "' .. new_name .. '" already exists.'))
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

    windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Crossbar set renamed: "' .. old_name .. '" -> "' .. new_name .. '".'))
    if (orphan_count > 0) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) still reference the old name and will no longer work until updated.'))
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
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Usage: //xcb deleteset <name>'))
        return
    end

    -- Allow multi-word names by joining argv.
    local target_name = table.concat(args, ' ')
    local target_key = kebab_casify(target_name)

    if (PROTECTED_ENV_KEYS[target_key]) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Crossbar set "' .. target_name .. '" is reserved and cannot be deleted.'))
        return
    end
    if (player.hotbar[target_key] == nil) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] No crossbar set named "' .. target_name .. '" found in the current job.'))
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

    windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Crossbar set deleted: "' .. target_name .. '" (and all its slot bindings).'))
    if (orphan_count > 0) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) referenced the deleted set and will no longer work.'))
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
    local help=require('libs/chat_help')
    help.heading('XIVCrossbar commands')
    help.command('help','Show this command list.')
    help.command('status [details]','Show addon state; details saves a diagnostic file.')
    help.command('reload','Re-read crossbar files without unloading the addon.')
    help.command('restart','Fade out, clean up, then reload the addon.')
    help.command('unload','Fade out and unload; shared wrapper follows last-client policy.')
    help.command('new <name>','Create a crossbar set.')
    help.command('rename <old> <new>','Rename a crossbar set (rn).')
    help.command('deleteset <name>','Delete a set and its bindings.')
    help.command('set <env> <hb> <slot> <type> <action> [target] [alias] [icon]','Bind an action.')
    help.command('clear <env> <hb> <slot>','Remove a binding.')
    help.command('copy <env> <hb> <slot> <dest env> <dest hb> <dest slot>','Copy a binding (cp).')
    help.command('move <env> <hb> <slot> <dest env> <dest hb> <dest slot>','Move a binding (mv).')
    help.command('icon <env> <hb> <slot> <icon>','Change a slot icon (ic).')
    help.command('alias <env> <hb> <slot> <text>','Change a slot label (al/caption).')
    help.command('ca [name]','Create or edit one custom-action review.')
    help.command('ca name <name>','Set the name in the active draft (n).')
    help.command('ca alias <label>','Set the alias in the active draft (a).')
    help.command('ca command <command>','Set the command in the active draft (c).')
    help.command('catalog [global|character|status]','Choose where new actions save; both catalogs are read.')
    help.command('bank <layer> [help|status]','Edit L1, L1L2, R1 or R1R2; separate menu entries, shared side panels.')
    help.command('r1|r1r2|l1l2 [bank arguments]','Short bank editors; bare shows status. Use default/defaults to restore.')
    help.command('l1 [help|status]','Compatibility editor for L1L2; bank l1 edits bare L1.')
    help.command('controller target [r2|r3|both] [on|off]','F8 before unmodified R2/R3; personal default R3 only.')
    help.command('messages [on|off|status]','Experimental controller message stream; bare toggles.')
    help.command('x [device]','Personal shortcut: select PS5 Extended.')
    help.command('r2|r3|both [on|off|status]','Personal F8 shortcuts; bare toggles the named button(s).')
    help.command('controller status [details]','Show controller readiness; details saves a diagnostic file.')
    help.command('controller start|stop|profiles','Control the shared wrapper or list profiles.')
    help.command('diagnostics','Save controller and addon diagnostics to a file.')
    help.command('controller profile <name> [device]','Select a controller reader and optional device.')
    help.command('controller trace on|off','Capture 30 seconds of wrapper input routing for diagnosis.')
    help.command('dpad [arrows|ijkl]','Choose gameplay D-pad output; bare toggles.')
    help.command('realkeys [on|off|status]','Test AHK keyboard IJKL in ordinary gameplay; default OFF, bare toggles.')
    help.command('scale <0.25-2>','Scale crossbars independently of menus.')
    help.command('pos [<offset x> <offset y>]','Report copyable main-bar coordinates, or set them.')
    help.command('compact [on|off]','Switch layout immediately; bare toggles.')
    help.command('show','Show crossbars.')
    help.command('hide','Hide crossbars; bindings remain active.')
    help.command('auto','Show crossbars on trigger input.')
    help.command('autohide [on|off]','Set trigger visibility; bare toggles.')
    help.command('fade [on|off]','Enable/disable gameplay fades; bare toggles.')
    help.command('textfade [on|off|status]','Fade labels with bars or show them at fade endpoints.')
    help.command('textsettle [on|off|status]','Settle centered captions before reveal; default ON, bare toggles.')
    help.command('autoattack [on|off|status]','Enable/stop swing estimation independently of opacity.')
    help.command('inputtest [on|off]','Enable input test messages; bare toggles.')
    help.command('inputtrace [on|off]','Enable input diagnostics; bare toggles.')
    help.command('resources',"Report this addon's live UI objects and creation/deletion totals.")
    help.command('rendertrace [on|mark|save|off|status]','Quiet bounded layout capture; off saves and stops.')
    help.command('inputstatus','Report input settings.')
    help.command('remap','Open controller setup.')
    help.command('regenerate','Rebuild generated resources.')
    help.heading('Identifiers')
    windower.add_to_chat(0,'Hotbars: l/r/rl/lr/ll/rr (1–6). Slots: ll/ld/lr/lu/rl/rd/rr/ru (1–8).')
end

-----------------------------
-- Bind Events
-----------------------------

local function set_text_fade(mode)
    mode = mode and mode:lower()
    if mode and mode~='on' and mode~='off' and mode~='status' then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] //xb textfade [on|off|status]'))
        return
    end
    if mode~='status' then
        local enabled = mode=='on' or (not mode and not settings.Animation.TextFade)
        settings.Animation.TextFade = enabled
        theme_options.text_fade = enabled
        ui.geometry:set_text_fade(enabled)
        config.save(settings)
    end
    windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Text fade: '..
        (settings.Animation.TextFade and 'ON (with crossbar)' or 'OFF (endpoint visibility)')))
end

local function set_autoattack(mode)
    mode = mode and mode:lower()
    if mode and mode~='on' and mode~='off' and mode~='status' then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] //xb autoattack [on|off|status]'))
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
    windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Autoattack estimate: '..
        (settings.AutoAttackIndicator.Enabled and 'ON' or 'OFF')..
        ' | Display opacity: '..tostring(settings.AutoAttackIndicator.Opacity)))
end

-- A: Lua teardown cannot finish an animation. Close first, then ask Windower
-- for the same full reload as lua r; the shared controller process stays alive.
local function graceful_restart(unload)
    if restart_pending then return end
    restart_pending = true
    xivcrossbar.ready = false
    crossbar_drag:finish()
    controller_message_bridge:reset()
    l1_drag:finish();r1_drag:finish();l1_bridge:reset()
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
    windower.add_to_chat(0,require('libs/chat_status').notice(unload and 'Unloading.' or 'Restarting.',140))
    coroutine.schedule(function() windower.send_command(unload and 'lua u xivcrossbar' or 'lua r xivcrossbar') end, delay)
end

-- ON LOAD
windower.register_event('load',function()
    local ok,registry=pcall(require('libs/controller/clients').new,{directory=windower.addon_path..'data/controller-clients/'})
    if ok then
        client_registry=registry
        local registered,err=registry:register(settings.on_unload_killahk)
        if not registered then windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Client registration failed: '..tostring(err))) end
    else windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Last-client shutdown unavailable: '..tostring(registry))) end
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
    profile_gate:reset()
    initialize()
    skillchains.login()
end)

-- ON LOGOUT
windower.register_event('logout', function()
    controller_message_bridge:reset()
    l1_drag:finish();r1_drag:finish();l1_bridge:reset();l1_view:destroy();r1_view:destroy();personal_controls:close()
    profile_gate:reset()
    xivcrossbar.ready = false
    xivcrossbar.initialized = false
    xivcrossbar.pending_initialize = false
    player.identity_confirmed = false
    storage.identity_valid = false
    if action_binder.selector then action_binder:hide();action_binder:reset_state() end
    if env_chooser.is_setup then env_chooser:close() end
    if gamepad_mapper.is_showing then gamepad_mapper:hide() end
    transport:reset()
    gamepad_state.left_trigger,gamepad_state.right_trigger,gamepad_state.active_bar=false,false,0
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
    if client_registry then client_registry:close(settings.on_unload_killahk) end
    ui.autoattack:set_enabled(false)
    personal_controls:close()
    if trust_menu then trust_menu:cancel() end
    controller_message_bridge:reset()
    l1_drag:finish();r1_drag:finish();l1_bridge:reset();l1_view:destroy();r1_view:destroy()
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
    if ui.geometry then ui.geometry:shutdown() end
    require('ui/resources').destroy_all()

end)

-- ON COMMAND
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    -- A: the binding consumes native input without echoing or executing
    -- an action; the keyboard router independently handles the actual slot.
    if command == 'inputconsume' then
        return
    elseif command == 'rendertrace' then
        local name=tostring(player.name or 'prelogin'):gsub('[^%w_-]','_')
        return render_trace.command((...),windower.addon_path..'data/render-trace-'..name..'.log',
            function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] '..message)) end)
    elseif command == 'diagnostics' or command == 'diagnose' then
        return save_diagnostics()
    elseif command == 'bank' or command == 'l1' or require('libs/banks/banks').aliases[command] then
        local args={...}
        if require('libs/banks/banks').aliases[command] then table.insert(args,1,command);command='bank' end
        local operation=args[1] or 'help'
        if command=='bank' then operation=(args[2]=='menu' and args[3] or args[2]) or 'status' end
        if not xivcrossbar.ready and operation~='help' and operation~='status' then
            windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Log in and finish setup before changing companion banks.'));return
        end
        l1_drag:finish();r1_drag:finish()
        if command=='bank' then companion_banks:command(args) else companion_banks:legacy(args) end
        l1_epoch=l1_epoch+1
        if publish_personal_context then publish_personal_context() end
        return
    elseif command == 'textsettle' then
        require('ui/text_measure').command(settings,(...),
            function() config.save(settings) end,
            function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] '..message)) end)
        return
    elseif command == 'realkeys' then
        local changed=require('libs/controller/realkeys').command(settings,(...),
            function() config.save(settings) end,
            function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] '..message)) end)
        if changed then
            release_gameplay_keys()
            message_epoch=message_epoch+1
            controller_message_bridge:reset()
            if publish_personal_context then publish_personal_context() end
        end
        return
    elseif command == 'messages' then
        local changed=require('libs/controller/messages').command(settings,(...),
            function() config.save(settings) end,
            function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] '..message)) end)
        if changed then
            message_epoch=message_epoch+1
            controller_message_bridge:reset()
            if publish_personal_context then publish_personal_context() end
        end
        return
    elseif command == 'x' then
        select_controller_profile('x', (...))
        return
    elseif command == 'r2' or command == 'r3' or command == 'both' then
        local changed=require('libs/controller/target').shortcut(settings,command,(...),
            function() config.save(settings) end,
            function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] '..message)) end)
        if changed then
            l1_epoch=l1_epoch+1
            if publish_personal_context then publish_personal_context() end
        end
        return
    elseif command == 'controller' then
        local mode, name, device = ...
        mode = type(mode) == 'string' and mode:lower() or 'status'
        if mode == 'stop' then controller_switcher:cancel(); stop_controller_wrapper()
        elseif mode == 'start' then
            if controller_switcher.pending then report_controller_status() else start_controller_wrappers() end
        elseif mode == 'profile' then select_controller_profile(name, device)
        elseif mode == 'status' then
            if name and name~='details' then require('libs/chat_help').command('controller status [details]','Show controller readiness and optional diagnostics.');return end
            report_controller_status(name=='details')
        elseif mode == 'trace' then request_controller_trace(name)
        elseif mode == 'target' then
            local changed=require('libs/controller/target').command(settings,name,device,
                function() config.save(settings) end,
                function(message) windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] '..message)) end)
            if changed then
                l1_epoch=l1_epoch+1
                if publish_personal_context then publish_personal_context() end
            end
        elseif mode == 'profiles' then
            for _, id in ipairs(controller_profiles.order) do
                local profile = controller_profiles.profiles[id]
                windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] ' .. controller_profiles.short_name(id) .. (profile.experimental and ' (experimental)' or ' (default)')))
            end
        else windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] //xb controller status|start|stop|profiles|profile <name> [device]')) end
        return
    elseif command == 'inputtest' or command == 'inputtrace' then
        local mode = (...)
        local key = command == 'inputtest' and 'InputTest' or 'InputTrace'
        if mode == 'on' then settings[key] = true
        elseif mode == 'off' then settings[key] = false
        else settings[key] = not settings[key] end
        config.save(settings)
        windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] ' .. key .. ' ' .. (settings[key] and 'ON' or 'OFF')))
        return
    elseif command == 'dpad' then
        local mode = (...)
        mode = mode and mode:lower()
        if mode and mode ~= 'arrows' and mode ~= 'ijkl' then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] //xb dpad [arrows|ijkl]')); return
        end
        -- Release the old output before changing mapping; require another press.
        release_gameplay_keys()
        settings.GameplayDPad = mode or (settings.GameplayDPad == 'ijkl' and 'arrows' or 'ijkl')
        config.save(settings)
        windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Gameplay D-pad: ' .. settings.GameplayDPad))
        return
    elseif command == 'inputstatus' then
        local format=require('libs/chat_status')
        windower.add_to_chat(0,format.heading('XIVCrossbar | Input'))
        windower.add_to_chat(0,format.row('Version',_addon.version))
        windower.add_to_chat(0,format.row('Profile',settings.ControllerProfile..' | key fallback '..controller_modifier))
        windower.add_to_chat(0,format.row('Diagnostics','dummy actions '..format.toggle(settings.InputTest)..' | chat trace '..format.toggle(settings.InputTrace)..' | Lua timing trace '..format.toggle(input_timing.active)))
        return
    end
    local args = {...}
    if command=='pos' then return set_crossbar_position(args) end
    if command == 'textfade' or (command == 'ui' and args[1] == 'textfade') then
        return set_text_fade(command == 'textfade' and args[1] or args[2])
    end
    if command == 'autoattack' then return set_autoattack(args[1]) end
    if command == 'fade' or command == 'scale' or command == 'hide' or command == 'show' or command == 'auto' then
        table.insert(args, 1, command)
        command = 'ui'
    end

    if command == 'catalog' then
        local mode=args[1] and args[1]:lower() or 'status'
        if mode=='global' or mode=='character' or mode=='personal' then
            settings.CustomActionSaveScope=mode=='personal' and 'character' or mode
            player.custom_action_save_scope=settings.CustomActionSaveScope
            config.save(settings)
        elseif mode~='status' then
            windower.add_to_chat(0,('//xb'):color(200)..(' catalog [global|character|status]'):color(207)..(' -> '):color(200)..('Choose where new custom actions save; both catalogs are listed.'):color(0))
            return
        end
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] New custom actions save to '..player:catalog_save_scope()..'; global and character catalogs remain readable.'))
        return
    end
    if command == 'unload' then return graceful_restart(true) end
    if command == 'resources' then
        local resources=require('ui/resources')
        local r=resources.snapshot()
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] UI cleanup helper: '..tostring(resources.version or 'older/unmarked')))
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] UI live: '..r.text..' text, '..r.image..' images | Created/deleted: '..r.created_text..'/'..r.destroyed_text..' text, '..r.created_image..'/'..r.destroyed_image..' images.'))
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Counts cover this addon only; compare the same screen after repeating edits.'))
        return
    end
    if command == 'status' then
        if args[1] and args[1]~='details' then require('libs/chat_help').command('status [details]','Show addon state and optional diagnostics.');return end
        if args[1]=='details' then return save_diagnostics() end
        local details=false
        local format=require('libs/chat_status')
        local function row(label,value) windower.add_to_chat(0,format.row(label,value)) end
        windower.add_to_chat(0,format.heading('XIVCrossbar | Status'))
        row('Version',_addon.version)
        row('Addon',format.state(xivcrossbar.ready and 'ready' or 'initializing'))
        local active=player.hotbar_settings and player.hotbar_settings.active_environment
        local active_set=active and player.hotbar and player.hotbar[active]
        row('Current Set',active_set and active_set.name or active or 'Awaiting character login')
        windower.add_to_chat(0,format.heading('Crossbars'))
        row('Layout',(settings.iscompact and 'Compact' or 'Full')..' | Scale: '..tostring(settings.CrossbarScale)..' | Visibility: '..
            (({oninput='On Input',always='Always',hidden='Hidden'})[settings.VisibilityMode] or tostring(settings.VisibilityMode)))
        row('Position','//xb pos '..tostring(settings.Style.OffsetX)..' '..tostring(settings.Style.OffsetY))
        row('Animation','Fades: '..format.toggle(settings.Animation.Enabled)..' | Text Fade: '..format.toggle(settings.Animation.TextFade))
        row('D-pad',settings.GameplayDPad=='ijkl' and 'IJKL' or 'Arrow Keys')
        windower.add_to_chat(0,format.heading('Companion Banks'))
        for _,layer in ipairs({'l1','l1l2','r1','r1r2'}) do companion_banks:summary(layer) end
        report_controller_status(details,true)
        return
    end

    if command == 'compact' or (command == 'ui' and args[1] == 'compact') then
        return set_compact_mode(command == 'compact' and args[1] or args[2])
    end

    if command == 'ui' and args[1] == 'fade' then
        local mode = args[2] and args[2]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] //xb fade [on|off]')); return
        end
        local enabled = mode == 'on' or (not mode and not settings.Animation.Enabled)
        settings.Animation.Enabled = enabled
        theme_options.fade_enabled = enabled
        ui.geometry.deferring_hide = false
        ui.geometry:configure_fade(enabled, settings.Animation.FadeIn, settings.Animation.FadeOut)
        ui.public_visible = nil
        config.save(settings)
        windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Fades: ' .. (enabled and 'ON' or 'OFF')))
        return
    end

    if command == 'ui' and args[1] == 'scale' then
        local scale = tonumber(args[2])
        if not scale or scale ~= scale or scale < .25 or scale > 2 then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] //xb ui scale <0.25-2>')); return
        end
        settings.CrossbarScale = scale
        theme_options.crossbar_scale = scale
        ui:set_scale(scale)
        env_chooser:set_anchor(ui:get_set_chooser_anchor())
        config.save(settings)
        windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Crossbar scale: ' .. tostring(scale)))
        return
    end

    if command == 'autohide' then
        local mode = args[1] and args[1]:lower()
        if mode and mode ~= 'on' and mode ~= 'off' then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] //xb autohide [on|off]')); return
        end
        if mode == 'off' or (not mode and settings.VisibilityMode == 'oninput') then
            settings.VisibilityMode = 'always'
        else settings.VisibilityMode = 'oninput' end
        config.save(settings)
        windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Visibility: ' .. settings.VisibilityMode))
        return
    elseif command == 'ui' and (args[1] == 'hide' or args[1] == 'show' or args[1] == 'auto') then
        settings.VisibilityMode = ({hide='hidden',show='always',auto='oninput'})[args[1]]
        ui.public_visible = nil
        config.save(settings)
        windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] Visibility: ' .. settings.VisibilityMode))
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
    elseif command == 'sw' or command == 'switch' then
        switch_environment_command(args)
    elseif command == 'remap' then
        remap()
    elseif command == 'regenerate' then
        regenerate_resources()
    elseif command == '?' or command == 'help' then
        display_help_menu()
    else
        windower.add_to_chat(0,require('libs/chat_status').legacy(0,'[XIVCrossbar] Unknown command: '..tostring(command)))
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
            windower.add_to_chat(0,require('libs/chat_status').notice('Crossbar set name "'..env_chooser:get_new_set_name()..'" is reserved. Unable to create.',167))
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
local function trace_controller_state(context)
    if not input_timing.active then return end
    local owned={}
    for _,key in pairs(gameplay_down) do owned[#owned+1]=key end
    table.sort(owned)
    local info=windower.ffxi.get_info()
    local character=windower.ffxi.get_player()
    input_timing:state('context='..context..' profile='..tostring(settings.ControllerProfile)..
        ' messages_setting='..tostring(settings.ControllerMessages)..' ready='..tostring(xivcrossbar.ready)..
        ' restarting='..tostring(restart_pending==true)..' focus='..tostring(windower.has_focus())..
        ' logged_in='..tostring(info.logged_in)..' character_status='..tostring(character and character.status)..
        ' lua_route='..(controller_message_bridge.token and 'messages' or 'keys')..
        ' gameplay_owned='..(#owned>0 and table.concat(owned,',') or 'none'))
end
release_gameplay_keys = function()
    for dik, key in pairs(gameplay_down) do
        input_timing:record('native request '..key..' up cleanup')
        windower.send_command('setkey ' .. key .. ' up')
        gameplay_down[dik] = nil
    end
end
local function input_context()
    if gamepad_mapper.is_showing then return 'setup' end
    if not xivcrossbar.ready then return 'login' end
    if env_chooser.capturing then return 'text' end
    if env_chooser:is_showing() then return 'sets' end
    if action_binder:is_capturing_text() then return 'text' end
    if not action_binder.is_hidden then return 'menu:' .. tostring(action_binder.state) end
    if trust_menu and trust_menu.token then return 'trust' end
    if gamepad_state.left_trigger or gamepad_state.right_trigger then return 'crossbar' end
    return 'gameplay'
end
companion_context=function()
    local info=windower.ffxi.get_info();local character=windower.ffxi.get_player();local context=input_context()
    local cutscene=character~=nil and character.status==4
    return not restart_pending and xivcrossbar.ready and require('libs/controller/profiles').is_extended(settings.ControllerProfile)
        and settings.ControllerMessages and not settings.InputTest and windower.has_focus() and info.logged_in
        and not info.chat_open and character~=nil and (not cutscene or (companion_banks and companion_banks:cutscene_enabled()))
        and (context=='gameplay' or context=='crossbar'),info.menu_open==true,cutscene
end
-- A: both transports call this router. The source determines how a physical
-- edge arrives; menu ownership, native translation and slot execution stay here.
message_capture = function(pressed)
    if not pressed then
        release_gameplay_keys()
        transport:reset()
        gamepad_state.left_trigger=false;gamepad_state.right_trigger=false
        gamepad_state.minus_button=false;gamepad_state.plus_button=false
        gamepad_state.active_bar=0
    end
    handle_controller_key(controller_capture_dik,pressed,0,false)
end
message_button = function(dik,pressed,flags,blocked)
    local signal=transport.signals[dik]
    if not signal then return end
    -- The wizard bootstraps button configuration and can be visible before
    -- hotbar initialization finishes. Gameplay still requires readiness.
    if restart_pending then return true end
    if blocked and pressed and input_context() ~= 'text' and not action_binder.chooser_active then
        if settings.InputTrace then windower.add_to_chat(123, '[XIVCrossbar test] BLOCKED ' .. signal.name .. ' DIK=' .. dik .. ' by another input handler') end
        return true
    end
    local context = input_context()
    input_timing:record('router dik='..dik..' pressed='..tostring(pressed)..' context='..context)
    local item, edge, owner = transport:edge(dik, pressed, context)
    if edge == 'repeat' then return true end
    if settings.InputTrace then
        local role = item.name
        if transport:face_name(item,buttonmapping) == buttonmapping.confirm_button then role = role .. ' / Confirm' end
        if transport:face_name(item,buttonmapping) == buttonmapping.cancel_button then role = role .. ' / Back' end
        windower.add_to_chat(207, '[XIVCrossbar test] ' .. role .. ' ' .. edge .. ' DIK=' .. dik .. ' context=' .. tostring(owner or context))
    end
    if gameplay_down[dik] and not pressed then
        input_timing:record('native request '..gameplay_down[dik]..' up dik='..dik)
        windower.send_command('setkey ' .. gameplay_down[dik] .. ' up')
        gameplay_down[dik] = nil
    end
    -- Triggers and menu buttons must finish their transition even when the
    -- menu opens/closes between edges. Slots keep their original owner.
    local transition = item.logical >= 67
    if not pressed and owner ~= context and not transition then return true end
    -- The chooser's handler consumes every face/D-pad edge and recognizes the
    -- configured Cancel button. Do not discard faces before it can see Cancel.
    if context == 'login' then
        local key=transport:login_key(item,buttonmapping)
        if key and pressed then
            gameplay_down[dik]=key
            input_timing:record('native request '..key..' down dik='..dik)
            windower.send_command('setkey '..key..' down')
        end
        return true
    end
    if item.logical <= 66 and context == 'gameplay' then
        local key = transport:gameplay_key(item, buttonmapping, settings.GameplayDPad)
        if settings.InputTest then
            if pressed then windower.add_to_chat(207, '[XIVCrossbar test] Gameplay ' .. item.name .. ' -> ' .. tostring(key) .. ' — dummy action') end
        elseif key and pressed then
            gameplay_down[dik] = key
            input_timing:record('native request '..key..' down dik='..dik)
            windower.send_command('setkey ' .. key .. ' down')
        end
        return true
    end
    if pressed and transition then release_gameplay_keys() end
    handle_controller_key(item.logical, pressed, flags, blocked)
    return true
end
-- A: two deliberate personal commands share the acknowledged button stream.
-- Trust owns its own menu/editor policy; native FFXI menus may remain open.
message_menu = function(button)
    if restart_pending or not xivcrossbar.ready or not require('libs/controller/profiles').is_extended(settings.ControllerProfile)
        or not settings.ControllerMessages or settings.InputTest or not windower.has_focus()
        or input_context()~='gameplay' then return false end
    local info=windower.ffxi.get_info()
    local character=windower.ffxi.get_player()
    if not info.logged_in or info.chat_open or not character or character.status==4 then return false end
    local command=button==6 and 'trust menu close' or button==8 and 'trust menu open' or nil
    if not command then return false end
    windower.send_command(command)
    return true
end

message_cancel = function()
    if trust_menu then trust_menu:reset() end
    input_timing:record("router cancel")
    if companion_banks then companion_banks:cancel();companion_banks.active=false end
    local chooser_held=set_chooser_button_down or action_binder.chooser_active
    release_gameplay_keys();transport:reset()
    for _,key in ipairs({'capturing','left_trigger','right_trigger','minus_button','plus_button',
        'left_trigger_doublepress','right_trigger_doublepress'}) do gamepad_state[key]=false end
    gamepad_state.active_bar=0
    close_left_doublepress_window();close_right_doublepress_window()
    if action_binder.chooser_active then finish_set_chooser(true) end
    set_chooser_button_down=false
    action_binder:clear_controller_input()
    if chooser_held and env_chooser:is_showing() and not env_chooser.capturing then env_chooser:close() end
    ui_dirty=true
end

publish_personal_context = function()
    -- Trust's lease is read only for this character in this focused client.
    -- The receiver validates freshness again when the queued action arrives.
    if trust_menu then
        local character=windower.ffxi.get_player()
        local eligible=character and windower.has_focus() and xivcrossbar.ready and not restart_pending
            and require('libs/controller/profiles').is_extended(settings.ControllerProfile) and settings.ControllerMessages and not settings.InputTest
            and action_binder.is_hidden and not env_chooser:is_showing() and not env_chooser.capturing
            and not gamepad_mapper.is_showing
        local contents
        if eligible then
            local f=io.open(windower.windower_path..'addons/trust/data/controller-menu-'..tostring(windower.ffxi.get_info().server)..'-'..character.id..'.txt','rb')
            if f then contents=f:read(513);f:close() end
        end
        trust_menu:update(contents,eligible and character.id or -1)
    end
    input_timing:tick(input_context())
    if input_timing.active then trace_controller_state(input_context()) end
    if companion_banks then companion_banks:refresh() end
    if not require('libs/controller/profiles').is_extended(settings.ControllerProfile) or not windower.ffxi.get_info().logged_in then
        l1_bridge:reset();controller_message_bridge:reset();personal_controls:close();return
    end
    local context = (restart_pending or not xivcrossbar.ready) and 'setup' or input_context()
    local info=windower.ffxi.get_info()
    local character=windower.ffxi.get_player()
    if info.chat_open then context='text' end
    if character and character.status==4 and (context=='gameplay' or context=='crossbar') then context='cutscene' end
    local now=l1_clock()
    if l1_last_tick>0 and now-l1_last_tick>.5 then
        l1_epoch=l1_epoch+1;controller_message_bridge:reset('stall')
    end
    l1_last_tick=now
    local eligible=(context=='gameplay' or context=='crossbar') and windower.has_focus() and not info.chat_open and not info.menu_open
        and character and character.status~=4
    -- Ordinary trigger transitions share one play session: releasing L2 while
    -- holding L1 can reveal the companion without a forced neutral rearm.
    local key=table.concat({player.server or '',player.name or '',eligible and 'play' or context,tostring(l1_epoch)},':')
    l1_bridge:context(key,eligible)
    if l1_bridge.token and not (companion_banks and companion_banks.active) and now>=l1_next_read then
        l1_next_read=now+.02
        local f=io.open(windower.addon_path..'data/personal-controls/'..player.name..'.l1','rb')
        if f then
            local contents=f:read(4097);f:close();l1_bridge:accept(contents)
        end
    end
    local message_enabled=settings.ControllerMessages==true and xivcrossbar.ready and not restart_pending
        and windower.has_focus() and character and (character.status~=4 or (companion_banks and companion_banks:cutscene_enabled()))
    local message_key=table.concat({player.server or '',player.name or '',settings.ControllerProfile,
        tostring(settings.ControllerDevice or 1),tostring(message_epoch)},':')
    controller_message_bridge:context(message_key,message_enabled)
    if controller_message_bridge.token then
        -- Check the heartbeat before accepting a replacement file. A recovered
        -- writer must rearm, rather than reviving an expired held gesture.
        if controller_message_bridge:watchdog() then
            -- Advertise the replacement directly; publishing an intermediate
            -- keyboard route would destroy the writer's held-control snapshot.
            controller_message_bridge:context(message_key,message_enabled)
        else
            local f=io.open(windower.addon_path..'data/personal-controls/'..player.name..'.buttons','rb')
            if f then local contents=f:read(8193);f:close();controller_message_bridge:accept(contents) end
            if not controller_message_bridge.token and controller_message_bridge.recover_key then
                controller_message_bridge:context(message_key,message_enabled)
            end
        end
    end
    if trust_menu and controller_message_bridge.token then trust_menu:tick() end
    context=(restart_pending or not xivcrossbar.ready) and 'setup' or input_context()
    if info.chat_open then context='text' end
    if character and character.status==4 and (context=='gameplay' or context=='crossbar') then context='cutscene' end
    local native_token,native,native_base
    if companion_banks then
        if companion_banks.output:stale() then
            -- An unacknowledged native request cannot become a late action.
            controller_message_bridge:reset('output-stall');companion_banks:cancel()
            controller_message_bridge:context(message_key,message_enabled)
        end
        native_token,native,native_base=companion_banks.output:payload(controller_message_bridge.token)
    end
    personal_controls:update(windower.addon_path..'data/personal-controls/',player.name,
        settings.ControllerProfile,context,{token=l1_bridge.token,mode=l1_bank:mode(),ack=l1_bridge.ack,
            target_r2=settings.ControllerTargetR2==true,target_r3=settings.ControllerTargetR3==true,
            realkeys=not (trust_menu and trust_menu.token) and require('libs/controller/realkeys').enabled(settings,controller_message_bridge.token),
            r1_menus=controller_message_bridge.token~=nil and not settings.InputTest,
            banks=controller_message_bridge.token~=nil and not settings.InputTest,native_token=native_token,native=native,native_base=native_base,
            messages=controller_message_bridge.token~=nil,button_token=controller_message_bridge.token,button_ack=controller_message_bridge.ack,
            button_recover=controller_message_bridge.recovering,button_reason=controller_message_bridge.last_reason})
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
        if controller_message_bridge.token then return false end
        message_capture(pressed)
        publish_personal_context()
        return true
    end
    local signal = transport.signals[dik]
    -- Consume owned releases even if capture was lost; no orphan game key-ups.
    if not controller_message_bridge.token and signal and (gamepad_state.capturing or transport.down[dik]) then
        message_button(dik,pressed,flags,blocked)
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
    -- Preserve these before reset(): DirectLink cancellation releases and
    -- clears gameplay_down. A background release may need retry on regain.
    for _, key in pairs(gameplay_down) do focus_release_keys[key] = true end
    input_timing:record('focus '..(regained and 'gained' or 'lost'))
    message_epoch=message_epoch+1;controller_message_bridge:reset()
    l1_epoch=l1_epoch+1;l1_bridge:reset();l1_bank:cancel();l1_drag:finish();r1_drag:finish()
    set_chooser_button_down=false
    menu_escape_down=false
    if action_binder.chooser_active then finish_set_chooser(true) end
    text_input_guard:reset_confirmation()
    release_gameplay_keys()
    if regained then
        for key in pairs(focus_release_keys) do
            input_timing:record('native request '..key..' up focus-retry')
            windower.send_command('setkey ' .. key .. ' up')
        end
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

local catalog_clock=require('socket').gettime
local next_catalog_refresh=0
local next_identity_retry=0
-- ON PRERENDER
windower.register_event('prerender',function()
    if not restart_pending and catalog_clock()>=next_identity_retry then
        next_identity_retry=catalog_clock()+.25
        check_profile_ready()
    end
    publish_personal_context()
    local l1_info=windower.ffxi.get_info()
    local l1_character=windower.ffxi.get_player()
    local l1_display=xivcrossbar.ready and not restart_pending and require('libs/controller/profiles').is_extended(settings.ControllerProfile)
        and action_binder.is_hidden and not env_chooser:is_showing() and not gamepad_mapper.is_showing
        and l1_character and (l1_character.status~=4 or (companion_banks and companion_banks:cutscene_enabled())) and not l1_info.chat_open
    local viewport=windower.get_windower_settings()
    if render_trace.enabled then
        render_trace.context(gamepad_state.active_bar,player.hotbar_settings and player.hotbar_settings.active_environment,
            input_context(),action_binder.state,action_binder.selector and action_binder.selector.current_page,
            env_chooser:is_showing(),l1_info.menu_open,l1_info.chat_open,
            viewport.ui_x_res or viewport.x_res,viewport.ui_y_res or viewport.y_res,
            settings.CrossbarScale,ui_dirty,companion_banks.active and companion_banks.layer or l1_bank:mode(),controller_message_bridge.ack)
    end
    l1_view.options.bank=(companion_banks.active or companion_banks:previewing('Left')) and companion_left or l1_bank
    -- The retired fallback view retains its native-menu guard. New panels own
    -- their per-bank drawing policy independently from action context.
    l1_view:tick(l1_display and (l1_view.options.bank==companion_left or not l1_info.menu_open),viewport.ui_x_res or viewport.x_res,viewport.ui_y_res or viewport.y_res)
    r1_view:tick(l1_display and (companion_banks.active or companion_banks:previewing('Right')),viewport.ui_x_res or viewport.x_res,viewport.ui_y_res or viewport.y_res)
    if not l1_display then l1_drag:finish();r1_drag:finish() end
    if xivcrossbar.ready and action_binder.is_hidden and catalog_clock()>=next_catalog_refresh then
        next_catalog_refresh=catalog_clock()+1
        local ok,changed=player:refresh_custom_catalogs()
        if ok and changed and ui.is_setup then
            ui:load_player_hotbar(player.hotbar,player.vitals,player.hotbar_settings.active_environment,gamepad_state)
            ui_dirty=true
        end
    end
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

    if ui.is_setup and settings.VisibilityMode ~= 'hidden' and (not xivcrossbar.hide_hotbars or settings.VisibilityMode == 'oninput')
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

    -- Windower supplies one action table; refresh spell availability after
    -- this character's job ability, including arts/addendum transitions.
    if act.category == CATEGORY_JOB_ABILITY and act.actor_id == player:get_id() then
        player:update_current_spells()
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

windower.register_event('unload',function() input_timing:stop('unload') end)
