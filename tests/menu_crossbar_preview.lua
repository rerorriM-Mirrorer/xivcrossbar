-- Exercise the renderer with the normal fixture and all destination bank IDs.
dofile('tests/pet_render.lua')
local ui=require('ui/crossbar')
ui.theme.hotbar_number=6
ui.geometry:set_opacity(1)
local tracker={get_skillchain_window=function()return 0,0 end,get_skillchain_result=function()end}
local function draw()
    ui:check_recasts({test={}}, {mp=100,tp=0}, 'test', {}, {active_bar=2}, tracker, {}, false, false)
end
ui:set_menu_presentation(true,nil)
draw()
assert(ui.geometry.presentation_opacity==.78 and not ui.hotbars[2].menu_highlight)
assert(not ui.hotbars[2].slot_recast[10]:visible())
for _,bank in ipairs({1,2,3,4,5,6}) do
    ui:set_menu_presentation(true,bank)
    draw()
    for h=1,6 do assert(ui.hotbars[h].menu_highlight==(h==bank)) end
    local r,g,b=ui.hotbars[bank].slot_frame[1]:color()
    assert(r==255 and g==216 and b==112)
end
ui:set_menu_presentation(false,nil)
draw()
assert(ui.geometry.presentation_opacity==1 and not ui.hotbars[6].menu_highlight)
print('Menu preview dims the crossbar, hides trigger hints and marks the resolved bank.')
