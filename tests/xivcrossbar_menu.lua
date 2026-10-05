-- Contributing author: Awake — cover the entry path used by a controller,
-- not just the command shortcut into the custom-action editor.
local stub = dofile('tests/helpers/windower_stub.lua')
local binder = stub.binder()
io.popen = function()
    return {lines=function() return function() end end, close=function() end}
end
local original_file = file.new
file.new = function(path)
    local f = original_file(path)
    f.readlines = function() return {} end
    return f
end
res.zones = {}
binder:show()
local selected
for col, rows in pairs(binder.selector.field_coords) do
    for row, option in pairs(rows) do
        if option.id == 37 then selected = {page=1,row=row,col=col} end
    end
end
assert(selected, 'Create Custom Action must be reachable from the main menu')
stub.pick(binder, 37)
assert(binder.custom_action_draft and binder.title:text() == 'Custom Action: Alias')
local saved = binder.selection_states[1]
assert(saved.row == selected.row and saved.col == selected.col)
binder:go_back()
assert(binder.state == 1 and binder.selector:has_selection())
for _, name in ipairs({'Execute Command', 'Superwarp', 'XIVCrossbar Credits'}) do
    local id
    for _, option in ipairs(binder.selector.current_options) do
        if option.name == name then id = option.id end
    end
    assert(id, name)
    stub.pick(binder, id)
    assert(binder.state ~= 1 and binder.title:text() ~= 'Select Action Type', name)
    binder:go_back()
    assert(binder.state == 1 and binder.selector:has_selection())
end
-- Repeated browsing must not retain every old page's native image objects.
local options = L{}
for i=1,160 do options:append({id=i,name='Icon '..i,icon='images/test.png'}) end
for i=1,30 do
    binder.selector:display_options(options)
    binder.selector:increment_page()
    assert(#binder.selector.images <= 2*binder.selector.max_row*binder.selector.max_col)
end
-- An absent asset is recoverable and reported once, without blocking confirm.
file.new = function(path)
    local f = original_file(path)
    f.exists = function() return not path:find('missing.png', 1, true) end
    return f
end
local before = #stub.messages
local missing = L{{id=1,name='Missing',icon='images/missing.png'}}
binder.selector:display_options(missing)
assert(binder.selector:has_selection() and #stub.messages == before + 1)
binder.selector:display_options(missing)
assert(#stub.messages == before + 1)
-- Fresh installations may lack the generated Execute Command icon catalogue.
file.new = function(path)
    local f = original_file(path)
    f.exists = function() return not path:find('icon_list.txt', 1, true) end
    return f
end
assert(#get_icons() == 1)
print('PASS: controller main-menu entry, restored selection, utility/credits screens and bounded page images')
