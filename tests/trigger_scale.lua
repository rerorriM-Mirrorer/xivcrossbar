-- Exercise the real bank layout against mocked Windower drawing objects.
dofile('tests/compact.lua')
local now = 0
package.loaded.socket = {gettime=function() return now end}
local defaults = require('defaults')
defaults.Hotbar.Number = 6
local options = require('theme').apply(defaults)
options.fade_enabled = false
options.button_layout = 'playstation'
local ui = require('ui')
ui:setup(options, {})
local g = ui.geometry
local left, right = g.banks[1], g.banks[2]
local icon = g.surfaces[ui.hotbars[1].slot_icon[1]]
local timer = g.surfaces[ui.hotbars[1].slot_recast_text[1]]
local special = g.surfaces[ui.hotbars[5].slot_icon[1]]
local function pose(active, visible, auto, menu)
    ui:update_trigger_scale(true, .90, active, visible, auto, menu)
end
local function step(delta)
    now = now + delta
    g:tick()
end
local function near(a,b)
    assert(math.abs(a-b)<.0001, tostring(a)..' ~= '..tostring(b))
end
pose(0, false, true)
near(left.value,1); near(right.value,1)
pose(1, true, true)
near(left.value,1); near(right.value,1)
assert(left.active and right.active)
ui:show_bar_background(1)
local field = g.surfaces[ui.bar_background]
assert(field.bank==left and timer.bank==left and special.bank==g.banks[5])
step(.03)
near(left.value,1.05); near(right.value,.95)
near(icon.draw_width,40*g.scale*1.05)
local x,y=g:point(left.x,left.y)
local sx,sy=g:point(left.x,left.y,false,left)
near(x,sx); near(y,sy)
step(.04)
near(left.value,1.10); near(right.value,.90)
pose(0, false, true)
ui:hide()
near(left.value,1)
assert(not left.active and not icon.visible and g.opacity==0)
pose(2, true, true)
near(right.value,1)
step(.13)
near(right.value,1.10); near(left.value,.90)
for _, bank in ipairs({3,4,5,6}) do
    pose(bank, true, true)
    ui:show_bar_background(bank)
    step(.13)
    near(left.value,1); near(right.value,1)
    near(g.banks[bank].value,1.10)
    local bank_icon = g.surfaces[ui.hotbars[bank].slot_icon[1]]
    assert(field.bank==g.banks[bank] and bank_icon.bank==g.banks[bank])
    near(bank_icon.draw_width,40*g.scale*1.10)
    pose(0,true,false)
    near(left.value,.90); near(right.value,.90)
    step(.03)
    near(left.value,.95); near(right.value,.95)
    step(.04)
    near(left.value,1); near(right.value,1)
    near(g.banks[bank].value,1)
end
pose(5,true,true)
step(.07)
pose(0,false,true)
near(left.value,1);near(right.value,1);near(g.banks[5].value,1)
pose(1, true, false)
step(.13)
near(left.value,1.10); near(right.value,.90)
pose(0, true, false)
assert(left.active)
step(.13)
near(left.value,1); near(right.value,1)
pose(1, true, false, true)
near(left.value,1); near(right.value,1)

g:configure_fade(true,.1,.5)
g.load_fade_state.claimed=true
g:transition(true)
ui:update_trigger_scale(true, .99, 1, true, false, false)
step(.03)
near(left.value,1.005); near(right.value,.995)
assert(g.opacity>0 and g.opacity<1)
step(.04)
near(left.value,1.01); near(right.value,.99)
assert(g.opacity<1)
step(.04)
near(g.opacity,1)
g:transition(false)
pose(0, false, true)
step(.03)
assert(g.opacity<1 and left.value>1)
step(.04)
near(left.value,1); near(right.value,1)
g.fade:to(2,0)
near(g.fade.value,1)
print('Trigger scaling: symmetric shifts, centered pivots, saved values, opacity fades, special-bank enlargement and return bounce passed.')

options.hotbar_number=5
ui:setup(options,{})
assert(ui.hotbars[3] and not ui.hotbars[4] and ui.hotbars[5] and ui.hotbars[6])
pose(1,true,false)
step(.10)
pose(3,true,false)
assert(g.banks[1].slide.target==0 and g.banks[3].slide.target==1)
step(.045)
near(g.banks[1].slide.value,.5)
near(g.banks[3].slide.value,.5)
pose(1,true,false)
near(g.banks[1].slide.value,.5)
assert(g.banks[1].slide.target==1 and g.banks[3].slide.target==0)
step(.10)
near(g.banks[1].slide.value,1)
near(g.banks[3].slide.value,0)
print('Five-bank surfaces, center crossfade and interruption continuity passed.')

-- Drive the same display selection, animation, and draw order as prerender.
local hotbar={basic={}}
local skillchains={get_skillchain_window=function() return 0,0 end}
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end

options.hotbar_number=6
for _, fade in ipairs({true,false}) do
    local center_bank=fade and 3 or 4
    for _, scale in ipairs({true,false}) do
        options.fade_enabled=fade
        ui:setup(options,{})
        g.load_fade_state.claimed=true
        local function draw(active, menu)
            local visible=active~=0 or menu
            local grace=not menu and (active==1 or active==2)
            local displayed=ui:select_display_bank(menu and 0 or active,grace,now)
            ui:update_trigger_scale(scale,.90,displayed,visible,true,menu)
            if visible then
                if not ui.public_visible then ui.public_visible=ui:show(hotbar,'basic') end
                ui:check_recasts(hotbar,{},'basic',{}, {active_bar=active},skillchains,{},false,false,
                    menu,nil,nil,displayed)
            else
                ui:hide()
                ui.public_visible=false
            end
            return displayed
        end

        local side=g.surfaces[ui.hotbars[1].slot_background[1]]
        local center=g.surfaces[ui.hotbars[center_bank].slot_background[1]]
        assert(draw(1)==1)
        step(.11)
        assert(draw(center_bank)==center_bank and center.visible)
        step(.025)
        assert(draw(2)==center_bank,'first release should keep the center bank')
        step(.050)
        assert(draw(2)==center_bank,'center should remain inside grace period')
        local last_pose=g.banks[center_bank].slide.value
        assert(draw(0)==0 and not side.draw_visible and not side.defer_visible,
            'the side pair joined a center fade')
        assert((center.defer_visible==true)==fade and center.draw_visible==fade)
        step(.02)
        near(g.banks[center_bank].slide.value,last_pose)
        step(.51)
        assert(not center.draw_visible)

        assert(draw(center_bank)==center_bank)
        step(.11)
        assert(draw(1)==center_bank)
        step(.0751)
        assert(draw(1)==1 and side.draw_visible and not center.draw_visible,
            'the side pair should replace the center when the grace expires')
        if scale then near(g.banks[1].value,.90) end
        assert(draw(0)==0 and not center.defer_visible)
        assert((side.defer_visible==true)==fade)
        step(.51)

        assert(draw(center_bank)==center_bank)
        assert(draw(2)==center_bank and ui.center_release_deadline)
        assert(draw(center_bank)==center_bank and not ui.center_release_deadline,'repress should cancel the grace')
        assert(draw(2)==center_bank and ui.center_release_deadline)
        assert(draw(2,true)==0 and not ui.center_release_deadline,'menu should cancel the grace')

        assert(draw(center_bank)==center_bank)
        step(.11)
        assert(draw(0)==0 and not side.draw_visible and not side.defer_visible,
            'same-frame release should skip the side pair')
        assert((center.defer_visible==true)==fade)
        step(.51)
    end
end
print('75 ms center release grace, exclusive fade or replacement, and cancellation passed with fades and scaling on/off.')
