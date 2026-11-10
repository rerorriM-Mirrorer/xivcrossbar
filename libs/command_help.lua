local chat = require('libs/chat_help')
local status = require('libs/chat_status')

local M = {}

local topics = {
    sets = {
        title = 'Crossbar Sets',
        {'switch <name>', 'Select a set by name.'},
        {'bar <key>', 'Switch using a saved set key.'},
        {'new <name>', 'Create a crossbar set.'},
        {'rename <old> <new>', 'Rename a set (rn).'},
        {'deleteset <name>', 'Delete a set and its bindings.'},
        {'triggerbanks [3|4|5|6]', 'Set the trigger layout and reload. Five shares the combined bank and keeps both double taps.'},
        {'jobsets', 'Create missing category sets for the current job combination.'},
    },
    bindings = {
        title = 'Slot Bindings',
        {'set <env> <hb> <slot> <type> <action> [target] [alias] [icon]', 'Bind an action.'},
        {'clear <env> <hb> <slot>', 'Remove a binding.'},
        {'copy <env> <hb> <slot> <dest hb> <dest slot>', 'Copy a binding (cp).'},
        {'move <env> <hb> <slot> <dest hb> <dest slot>', 'Move a binding (mv).'},
        {'icon <env> <hb> <slot> <icon>', 'Change slot icon (ic).'},
        {'alias <env> <hb> <slot> <text>', 'Change slot label (al/caption).'},
        {'ca [name]', 'Open the Custom Action editor.'},
        {'ca <name|alias|command> <value>', 'Edit a field in the active Custom Action review.'},
    },
    display = {
        title = 'Display',
        {'display [legacy|xi|status]', 'Apply a saved appearance preset. XI also selects compact layout, trigger visibility and fades.'},
        {'status', 'Show current state and settings.'},
        {'scale <0.25-2>', 'Scale crossbar independently of menus.'},
        {'compact [on|off]', 'Switch layout immediately.'},
        {'hide', 'Hide bars without disabling actions.'},
        {'show', 'Show bars.'},
        {'auto', 'Show bars on controller trigger.'},
        {'eventbars [on|off|status]', 'Reveal held banks and allow shoulder slots during FFXI events.'},
        {'autohide [on|off]', 'Set trigger visibility.'},
        {'fade [on|off]', 'Enable/disable fades.'},
        {'recastflash [on|off|status]', 'Flash a slot when its recast reaches zero.'},
        {'slotglow [on|off|status]', 'Show a gold slot border while a button is held.'},
        {'triggerscale [on|off|status|0-25]', 'Set the size change when switching trigger banks.'},
        {'banklabels [on|off|status]', 'Show or hide the trigger labels on crossbars.'},
        {'banklabeloffset <x> <y>', 'Move bank labels in layout pixels.'},
        {'banklabelopacity [0-255|status]', 'Set the opacity of bank label text and outlines.'},
        {'slotlabeloffset <x> <y>', 'Move slot action names in layout pixels.'},
        {'costoffset <x> <y>', 'Move the slot cost and quantity text.'},
        {'slotlabelalign [left|center|status]', 'Align slot action names.'},
        {'slotlabelstroke [black|amber|status]', 'Set the outline color of slot action names.'},
        {'textfade [on|off|status]', 'Fade labels with bars. Defaults to on.'},
        {'textsettle [on|off|status]', 'Prevent caption flicker while widths settle.'},
        {'skillchain [on|off|status|0-255]', 'Set the skillchain strip opacity.'},
        {'lockout [on|off|status|0-255]', 'Set lockout strip opacity. On restores per-action values.'},
        {'autoattack [on|off|status|0-255]', 'Set swing strip opacity. Off also stops swing estimation.'},
    },
    controller = {
        title = 'Controller',
        {'controller [status|start|stop|profiles]', 'Inspect or control the shared controller reader.'},
        {'controller profile <name> [device]', 'Select controller and device.'},
        {'remap', 'Run controller setup.'},
        {'bank status', 'Show shoulder bank preferences.'},
        {'bank <l1|r1|both> <on|off|show|hide>', 'Enable shoulder banks or change their visibility.'},
        {'bank targeting [on|off|status]', 'Use R1 to acquire or cycle targets on supported profiles.'},
        {'bridge status', 'Show bridge modes and last decisions.'},
        {'bridge <movement|menu|ps|all> <off|test|on>', 'Control optional Trust and PS bridges.'},
    },
    diagnostics = {
        title = 'Diagnostics',
        {'diagnose [start [input|render|full]]', 'Record a 30-second capture. Bare diagnose records input.'},
        {'diagnose mark [note]', 'Add a marker to an active capture.'},
        {'diagnose <stop|status|snapshot>', 'Save, inspect, or take a state snapshot.'},
        {'inputtest [on|off|status]', 'Preview input using dummy actions.'},
        {'inputtrace [on|off|status]', 'Log live input events in chat.'},
        {'inputstatus', 'Report controller input configuration.'},
        {'nativepad status', 'Report the native hook and filter state.'},
        {'resources', 'Report live drawing objects.'},
        {'slotrumble [on|off]', 'Toggle the optional GripRumble test tap for this load.'},
        {'reload', 'Reload saved crossbar bindings.'},
        {'restart', 'Fade out then reload the addon.'},
        {'unload', 'Fade out and unload the addon.'},
        {'regenerate', 'Regenerate cached resource files.'},
    },
}

local topic_order = {'sets', 'bindings', 'display', 'controller', 'diagnostics'}

local default_controls = {binder = 'the mapped binder button', chooser = 'the mapped set button', triggers = 'a trigger'}
local controls = {
    playstation = {binder = 'Share', chooser = 'Options', triggers = 'L2/R2'},
    xbox = {binder = 'View (Back)', chooser = 'Menu (Start)', triggers = 'LT/RT'},
    nintendo = {binder = 'Minus', chooser = 'Plus', triggers = 'ZL/ZR'},
}

local function show_page(name)
    local page = topics[name]
    chat.heading('XIVCrossbar | '..page.title)
    for _, entry in ipairs(page) do
        chat.command(entry[1], entry[2])
    end
    if name == 'bindings' then
        chat.row('Hotbars', 'l / r / rl / lr / ll / rr (1-6)')
        chat.row('Slots', 'll / ld / lr / lu / rl / rd / rr / ru (1-8)')
    end
end

local function show_intro(layout, profile)
    local buttons = controls[layout] or default_controls
    local chooser = profile == 'xinput-r1-chooser' and 'RB' or buttons.chooser
    chat.heading('XIVCrossbar | Getting Started')
    chat.row('Use a slot', 'Hold '..buttons.triggers..' and press a D-pad or face button.')
    chat.row('Bind an action', 'Press '..buttons.binder..'. Use the D-pad to move and the triggers to page.')
    chat.row('Change sets', 'Hold '..chooser..', use D-pad Up/Down, then release to close.')
    chat.command('status', 'Show your active set, display, and controller.')
    chat.command('help <topic>', table.concat(topic_order, ' / ')..' / all')
end

function M.show(topic, layout, profile)
    topic = topic and topic:lower()
    if topics[topic] then
        return show_page(topic)
    end
    if topic == 'all' then
        for _, name in ipairs(topic_order) do show_page(name) end
        return
    end
    if topic and topic ~= '' then
        status.fail('Unknown help topic "'..topic..'".')
    end
    show_intro(layout, profile)
end

return M
