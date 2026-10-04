local stub = dofile('tests/helpers/windower_stub.lua')
local binder = stub.binder()
-- Exercise the exact icon-picker data shapes that used to lack target_type.
io.popen = function(command)
    local entries = command:find('/a:d ', 1, true) and {'ui'} or {'custom_actions.png'}
    return {lines = function()
        local i = 0; return function() i = i + 1; return entries[i] end
    end, close = function() end}
end
binder.state = 16 -- EDIT_CUSTOM_ACTION_PICK
binder:display_custom_actions_picker('Edit')
stub.pick(binder, 'CA_Test')
assert(binder.state == 17)
binder:on_custom_action_field_set('alias', 'Target')
binder:on_custom_action_field_set('name', 'Target Sync')
binder:on_custom_action_field_set('command', 'input //sat alltargetreport')
stub.pick(binder, 'CHANGE_ICON')
stub.pick(binder, 'DIR_ui')
stub.pick(binder, 'FILE_ui/custom_actions')
assert(binder.custom_action_draft.icon == 'ui/custom_actions')
stub.pick(binder, 'REMOVE_ICON')
stub.pick(binder, 'CHANGE_LINKED')
stub.pick(binder, 1) -- Job Ability, from the real selector/resource table.
stub.pick(binder, 35)
assert(binder.state == 17 and binder.custom_action_draft.linked_action == 'Provoke')
assert(binder.custom_action_draft.linked_type == 'ja')
stub.pick(binder, 'CHANGE_LINKED')
stub.pick(binder, 'SKIP_LINKED')
stub.pick(binder, 'REMOVE_LINKED')
stub.pick(binder, 'SAVE_EDIT')
assert(stub.updated[1] == 'Test' and stub.updated[2].name == 'Target Sync')
assert(stub.updated[2].command == 'input //sat alltargetreport')
print('PASS: existing custom-action text/icon/linked edits and save')
-- Empty iconpacks occur in the uploaded repo; navigating one must be harmless.
io.popen = function() return {lines = function() return function() end end, close = function() end} end
binder.state = 16
binder:display_custom_actions_picker('Edit')
stub.pick(binder, 'CA_Test')
stub.pick(binder, 'CHANGE_ICON')
local ok, err = xpcall(function()
    binder.selector:increment_row()
    binder:submit_selected_option()
end, debug.traceback)
if not ok then print('REPRO: empty icon-picker\n' .. err); os.exit(1) end
print('PASS: empty icon-picker navigation and confirm')
binder:go_back()
assert(binder.state == 17 and not binder.capturing_text)
binder:go_back()
binder:hide()
binder:reset_state()
assert(binder:new_custom_action('sat', 'Send All Target'))
assert(binder.custom_action_draft.command == '' and binder.custom_action_draft.icon == nil)
assert(binder.state == 17)
stub.pick(binder, 'CHANGE_COMMAND')
binder:on_custom_action_field_set('command', 'input //sat alltargetreport')
binder:submit_selected_option()
assert(binder.state == 17)
stub.pick(binder, 'CHANGE_LINKED')
stub.pick(binder, 'SKIP_LINKED')
assert(binder.state == 17)
stub.pick(binder, 'CHANGE_ICON')
binder:go_back()
assert(binder.state == 17)
stub.pick(binder, 'SAVE_EDIT')
assert(stub.saved.name == 'Send All Target')
assert(binder:new_custom_action('warp'))
assert(binder.custom_action_draft.name == 'warp')
stub.pick(binder, 'SAVE_EDIT')
assert(stub.saved.command == '')
assert(not binder:new_custom_action('Test'))
print('PASS: quick creation, editable review, optional icon/metadata, single-word and duplicate names')
-- A quick create must not inherit page 2 from another selector.
binder.selector:set_page(2)
assert(binder:new_custom_action('page'))
assert(binder.selector.current_page == 1 and binder.selector:has_selection())
binder:go_back()
-- Icon directory back-navigation must redraw the saved parent page.
io.popen = function(command)
    local entries = {}
    if command:find('/a:d ', 1, true) and not command:find('ui80', 1, true) then
        for i = 1, 80 do entries[i] = string.format('ui%02d', i) end
    end
    return {lines = function() local i=0; return function() i=i+1; return entries[i] end end, close=function() end}
end
binder.state = 16; binder:display_custom_actions_picker('Edit')
stub.pick(binder, 'CA_Test'); stub.pick(binder, 'CHANGE_ICON')
binder.selector:increment_page()
stub.pick(binder, 'DIR_ui80')
binder:go_back()
assert(binder.selector.current_page == 2)
local row = binder.selector.field_coords[binder.selector.selected_col]
assert(row[binder.selector.selected_row].id == 'DIR_ui80')
binder:go_back(); binder:go_back(); binder:hide(); binder:reset_state()
print('PASS: fresh review pagination and restored icon-directory pages')
-- Pick an icon on a later page, then save from the shorter review list.
io.popen = function(command)
    local entries = {}
    if not command:find('/a:d ', 1, true) then
        for i = 1, 160 do entries[i] = string.format('icon%03d.png', i) end
    end
    return {lines=function() local i=0; return function() i=i+1; return entries[i] end end, close=function() end}
end
assert(binder:new_custom_action('paged'))
stub.pick(binder, 'CHANGE_ICON')
binder.selector:increment_page()
binder.selector:increment_page()
stub.pick(binder, 'FILE_icon160')
assert(binder.state == 17 and binder.selector.current_page == 1 and binder.selector:has_selection())
stub.pick(binder, 'SAVE_EDIT')
assert(stub.saved.icon == 'icon160')
-- A stale saved page or empty page cannot trap D-pad Up in a search loop.
binder.selector:display_options(L{{id='ONLY', name='Only', icon='images/test.png'}})
binder.selector:import_selection_state({page=99,row=9,col=9})
assert(binder.selector.current_page == 1 and binder.selector:has_selection())
binder.selector.field_coords = {[1] = {[binder.selector.max_row+1] = {id='PREV'}}}
binder.selector.selected_col, binder.selector.selected_row = 1, binder.selector.max_row+1
binder.selector:decrement_row()
binder:hide(); binder:reset_state()
print('PASS: later-page icon returns to usable review and stale/empty page navigation stays bounded')
-- Exercise the real addon command parser and persistence callbacks.
for _, name in ipairs({'libs/xml2', 'buttonmapping', 'keyboard_mapper', 'gamepad', 'ui',
    'environment_chooser', 'enchanted_items', 'variables', 'libs/skillchain/skillchains',
    'consumables', 'gamepad_mapper', 'gamepad_converter', 'function_key_bindings'}) do
    package.loaded[name] = {}
end
package.loaded.resource_generator = {generate_outdated_resources = function() end}
dofile('./xivcrossbar.lua')
custom_action_field_command({'new', 'sat', 'Send', 'All', 'Target'})
assert(binder.custom_action_draft.alias == 'sat' and binder.custom_action_draft.name == 'Send All Target')
custom_action_field_command({'c', 'input', '//sat', 'alltargetreport'})
stub.pick(binder, 'SAVE_EDIT')
assert(stub.saved.command == 'input //sat alltargetreport')
custom_action_field_command({'new', 'warp'})
assert(binder.custom_action_draft.name == 'warp')
custom_action_field_command({'c'})
assert(binder.custom_action_draft.command == '')
binder:go_back()
local pl = stub.player
pl.hotbar = {basic={hotbar_1={slot_1={type='ex', action='sat alltargetreport', alias='Test'}}}}
pl.save_custom_actions_file = function() end
pl.save_hotbar = function() end
reload_hotbar = function() end
update_custom_action('Test', {name='Renamed', alias='Target', command='npcmirror interact'})
assert(pl.custom_actions.Test == nil and pl.custom_actions.Renamed.command == 'npcmirror interact')
assert(pl.hotbar.basic.hotbar_1.slot_1.action == 'npcmirror interact')
assert(pl.hotbar.basic.hotbar_1.slot_1.alias == 'Target')
print('PASS: real ca command parsing and edit callback refresh of bound buttons')
