dofile('tests/menu_resources.lua')
local binder = require('action_binder')
local zones = require('sw_zones')
function S(values)
    local set={}
    for _, value in ipairs(values) do set[value]=true end
    return set
end
for key, value in pairs(dofile('sw_zones.lua')) do zones[key] = value end
res = {zones = {
    {en='Bastok Markets'}, {en='Bastok Mines'}, {en="Northern San d'Oria"},
    {en='Port Windurst'}, {en='Kazham'}, {en='Lower Jeuno'},
}}
local theme = require('theme').apply(require('defaults'))
theme.button_layout = 'playstation'
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},
    function() end,function() end,theme,function() return {} end)

local function choose(name)
    for col, rows in pairs(binder.selector.field_coords) do
        for row, option in pairs(rows) do
            if option.text == name then
                binder.selector.selected_col, binder.selector.selected_row = col, row
                binder:submit_selected_option()
                return
            end
        end
    end
    error('Missing warp choice '..name)
end

local root = get_warp_zones()
assert(root[1].name=='Bastok' and root[2].name=="San d'Oria" and root[3].name=='Windurst')
assert(#root>3)
for i=4,#root do
    local command = root[i].data.command
    assert(command:find('Kazham',1,true) or command:find('Lower Jeuno',1,true))
end
local hp, sg = 0, 0
for i=1,3 do
    for _, choice in ipairs(get_warp_zones(root[i].name)) do
        if choice.data.command:find('^sw hp ') then
            assert(choice.data.command:match(' %d+$'))
            hp=hp+1
        else
            assert(choice.data.command:find('^sw sg '))
            sg=sg+1
        end
    end
end
assert(hp==38 and sg==3)
theme.enable_superwarp_all=true
assert(get_warp_zones('Bastok')[2].data.command=='sw hp all Bastok Markets 2')

binder.state, binder.action_type = 2, 44
binder:display_superwarp_selector()
choose('Bastok')
assert(binder.title:text()=='Bastok')
choose('Markets - Auction House')
assert(binder.state==5 and binder.action_command=='sw hp all Bastok Markets 2')
binder:go_back()
assert(binder.state==2 and binder.title:text()=='Bastok')
binder:go_back()
assert(binder.title:text()=='Select Warp Location' and binder.selector:get_selected_option().text=='Bastok')
require('ui/resources').destroy_all()
print('Superwarp: city-first order, 38 numbered points, 3 guides, scope, binder command and Back passed.')
