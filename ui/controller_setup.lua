local ui_resources = require('ui/resources')
texts = require('texts')

local gamepad_mapper = {}

local states = {
    ['HIDDEN'] = 0,
    ['INTRO_SCREEN'] = 1,
    ['SELECT_GAMEPAD_TYPE'] = 2,
    ['INPUT_CONFIRM_BUTTON'] = 3,
    ['INPUT_CANCEL_BUTTON'] = 4,
    ['INPUT_MAINMENU_BUTTON'] = 5,
    ['INPUT_ACTIVEWINDOW_BUTTON'] = 6,
    ['CONFIRMATION_SCREEN'] = 7,
    ['COMPLETE'] = 8,
    ['SELECT_INPUT_PROFILE'] = 9,
    ['START_INPUT_PROFILE'] = 10
}

local icon_pack = nil

local get_icon_pathbase = function()
    return 'icons/' .. icon_pack
end

function gamepad_mapper:setup(buttonmapping, start_controller_wrappers_func, theme_options, base_x, base_y, max_width, max_height, profile_options)
    ui_resources.clear(self.images); ui_resources.clear(self.hints)
    for _, name in ipairs({'title','subtitle','intro','subintro','welcome_prompt','welcome_glow'}) do
        if self[name] then self[name]:destroy() end
    end
    self.is_showing = false
    self.buttonmapping = buttonmapping
    self.start_controller_wrappers = start_controller_wrappers_func
    self.profile_options = profile_options
    for _, choice in ipairs(self.profile_buttons or {}) do
        choice.caption:destroy()
        windower.prim.delete(choice.background)
    end
    if self.profile_status then self.profile_status:destroy() end
    self.profile_generation = (self.profile_generation or 0) + 1
    self.profile_buttons = {}
    self.theme_options = theme_options
    -- A: setup is an independent, unscaled panel. The old 150-pixel
    -- insets produced a negative inner height at 960x540.
    local screen = windower.get_windower_settings()
    self.width = math.min(800, screen.ui_x_res - 32)
    self.height = math.min(420, screen.ui_y_res - 32)
    self.base_x = (screen.ui_x_res - self.width) / 2
    self.base_y = (screen.ui_y_res - self.height) / 2
    base_x, base_y = self.base_x, self.base_y
    self.state = states.HIDDEN
    self.title = self:create_text('', base_x + 50, base_y + 30)
    self.title:size(18)
    self.title:hide()
    self.subtitle = self:create_text('', base_x + 50, base_y + 60)
    self.subtitle:size(14)
    self.subtitle:hide()
    self.intro = self:create_text('', base_x + 50, base_y + 30)
    self.intro:size(18)
    self.intro:hide()
    self.subintro = self:create_text('', base_x + 50, base_y + 30)
    self.subintro:size(12)
    self.subintro:hide()

    self.welcome_prompt = self:create_text('', base_x + 50, base_y + 30)
    self.welcome_prompt:size(12)
    self.welcome_prompt:hide()
    self.welcome_glow = self:create_text('', base_x + 50, base_y + 30)
    self.welcome_glow:size(12)
    self.welcome_glow:color(255,255,255)
    self.welcome_glow:alpha(55)
    self.welcome_glow:stroke_color(255,255,255)
    self.welcome_glow:stroke_width(1.5)
    self.welcome_glow:stroke_alpha(55)
    self.welcome_glow:hide()
    self.profile_status = self:create_text('', base_x + 40, base_y + 330)
    self.profile_status:size(12)
    self.profile_status:hide()
    self.controller_choices = {}

    self.playstation_hint = nil
    self.nintendo_hint = nil
    self.xbox_hint = nil
    self.gamecube_hint = nil

    icon_pack = theme_options.iconpack

    self.images = L{}
    self.hints = L{}

    self.trigger_left_pressed = false
    self.trigger_right_pressed = false

    self.button_layout = nil
    self.confirm_button = nil
    self.cancel_button = nil
    self.mainmenu_button = nil
    self.activewindow_button = nil

    windower.prim.create('gamepad_dialog_bg')
    windower.prim.set_color('gamepad_dialog_bg', 150, 0, 0, 0)
    windower.prim.set_position('gamepad_dialog_bg', self.base_x, self.base_y)
    windower.prim.set_size('gamepad_dialog_bg', self.width, self.height)
    windower.prim.set_visibility('gamepad_dialog_bg', false)

    windower.prim.create('button_mapping_bg')
    windower.prim.set_color('button_mapping_bg', 150, 0, 0, 0)
    windower.prim.set_position('button_mapping_bg', self.base_x + 16, self.base_y + 16)
    windower.prim.set_size('button_mapping_bg', self.width - 32, self.height - 32)
    windower.prim.set_visibility('button_mapping_bg', false)
end

function gamepad_mapper:reset_state()
    ui_resources.clear(self.images); ui_resources.clear(self.hints)
    self.state = states.HIDDEN

    self.images = L{}
    self.hints = L{}
    self.trigger_left_pressed = false
    self.trigger_right_pressed = false
end

function gamepad_mapper:hide()
    self.profile_generation = (self.profile_generation or 0) + 1
    self.is_showing = false
    windower.prim.set_visibility('gamepad_dialog_bg', false)
    windower.prim.set_visibility('button_mapping_bg', false)
    self:hide_text()
    self:hide_images()

    self:reset_state()
end

function gamepad_mapper:hide_text()
    self.title:hide()
    self.subtitle:hide()
    self.intro:hide()
    self.subintro:hide()
    self.welcome_prompt:hide()
    self.welcome_glow:hide()
    if self.profile_status then self.profile_status:hide() end
    for _, choice in ipairs(self.profile_buttons or {}) do
        choice.caption:hide()
        windower.prim.set_visibility(choice.background, false)
    end
    ui_resources.clear(self.hints); self.hints = L{}
end

function gamepad_mapper:hide_images()
    ui_resources.clear(self.images); self.images = L{}
end

function gamepad_mapper:show(is_first_time)
    self:hide()
    self.is_showing = true
    windower.prim.set_visibility('gamepad_dialog_bg', true)
    if (self.state == states.HIDDEN and is_first_time) then
        self.state = states.INTRO_SCREEN
        self:display_gamepad_intro_screen()
    elseif (self.state == states.HIDDEN) then
        self.state = states.SELECT_INPUT_PROFILE
        self:display_profile_selector()
    end
    self.title:show()
end

function gamepad_mapper:is_within_dialog(x, y)
    local valid_x = (self.base_x <= x) and (x <= (self.base_x + self.width))
    local valid_y = (self.base_y <= y) and (y <= (self.base_y + self.height))

    return valid_x and valid_y
end

function gamepad_mapper:create_text(caption, x, y)
    local text_field = ui_resources.text({flags = {draggable = false}})
    text_field:bg_alpha(0)
    text_field:bg_visible(false)
    text_field:font(self.theme_options.font)
    text_field:size(self.theme_options.font_size)
    text_field:color(self.theme_options.font_color_red, self.theme_options.font_color_green, self.theme_options.font_color_blue)
    text_field:stroke_alpha(self.theme_options.font_stroke_alpha)
    text_field:stroke_color(self.theme_options.font_stroke_color_red, self.theme_options.font_stroke_color_green, self.theme_options.font_stroke_color_blue)
    text_field:stroke_width(self.theme_options.font_stroke_width)
    text_field:text(caption)
    text_field:pos(x, y)
    text_field:show()
    return text_field
end

function gamepad_mapper:display_gamepad_intro_screen()
    windower.prim.set_visibility('gamepad_dialog_bg', true)
    windower.prim.set_visibility('button_mapping_bg', true)
    self:hide_text()
    self:hide_images()

    self.intro:text('Welcome to XIVCrossbar!')
    self.intro:pos(self.base_x + (self.width / 2) - 150, self.base_y + (self.height / 2) - 100)
    self.intro:show()
    self.subintro:text('It looks like this is your first time using XIVCrossbar. We\'ll need to perform a few short steps\nto set up your gamepad; it will take less than a minute.\n\n To start, please install AutoHotkey (www.autohotkey.com) if you have not already done so.\nThis is needed in order to pass gamepad information to the addon.')
    self.subintro:pos(self.base_x + (self.width / 2) - 350, self.base_y + (self.height / 2) - 45)
    self.subintro:show()
    local caption = 'Once AutoHotkey has been installed, please click this dialog to continue.'
    self.welcome_prompt:text(caption)
    self.welcome_glow:text(caption)
    self.welcome_x = self.base_x + self.width / 2 - 350
    self.welcome_y = self.base_y + self.height / 2 + 65
    self.welcome_prompt:pos(self.welcome_x, self.welcome_y)
    self.welcome_prompt:show()
    self.welcome_glow:hide()
end

-- A: select a physical reader before artwork or controller-only confirmation.
function gamepad_mapper:display_profile_selector(message)
    windower.prim.set_visibility('button_mapping_bg', true)
    self:hide_text()
    self:hide_images()
    self.title:text('Choose Controller Profile')
    self.title:show()
    self.subtitle:text('Click your controller input profile. Other profiles are experimental.')
    self.subtitle:pos(self.base_x + 40, self.base_y + 75)
    self.subtitle:show()
    local options = {
        {id='ps5-directinput', label='PS5 - DirectInput'},
        {id='xinput', label='Xbox / XInput (experimental)'},
        {id='f710-directinput', label='F710 - DirectInput (experimental)'},
        {id='fightpadpro-directinput', label='FightPadPro - DirectInput (experimental)'},
    }
    -- A: a personal fresh install must not silently replace its default with
    -- ordinary PS5 during setup. Public builds retain the original choices.
    if self.profile_options and self.profile_options.default_profile == 'ps5-extended' then
        options[1] = {id='ps5-extended', label='PS5 Extended - personal default'}
        options[2] = {id='xinput-extended', label='Xbox Extended - messages / banks'}
    end
    local width = (self.width - 96) / 2
    for i, option in ipairs(options) do
        local choice = self.profile_buttons[i]
        if not choice then
            local background = 'gamepad_profile_' .. i
            windower.prim.create(background)
            choice = {id=option.id, background=background, caption=self:create_text('', 0, 0)}
            choice.caption:size(12)
            self.profile_buttons[i] = choice
        end
        choice.id = option.id
        choice.x = self.base_x + 36 + ((i-1) % 2) * (width+24)
        choice.y = self.base_y + 132 + math.floor((i-1)/2) * 88
        choice.width, choice.height = width, 58
        choice.caption:text(option.label)
        choice.caption:pos(choice.x+14, choice.y+19)
        choice.caption:color(255,255,255)
        choice.caption:show()
        windower.prim.set_position(choice.background, choice.x, choice.y)
        windower.prim.set_size(choice.background, width, choice.height)
        windower.prim.set_color(choice.background, 190, 24, 41, 69)
        windower.prim.set_visibility(choice.background, true)
    end
    self.profile_status:text(message or 'Button artwork is chosen next, separately from the input profile.')
    self.profile_status:pos(self.base_x+40, self.base_y+330)
    self.profile_status:show()
end

function gamepad_mapper:profile_at(x, y)
    for _, choice in ipairs(self.profile_buttons or {}) do
        if x >= choice.x and x <= choice.x+choice.width and y >= choice.y and y <= choice.y+choice.height then
            return choice
        end
    end
end

function gamepad_mapper:hover_profile(x, y)
    local hovered = self:profile_at(x, y)
    for _, choice in ipairs(self.profile_buttons or {}) do
        local lift = choice == hovered and self.state == states.SELECT_INPUT_PROFILE and -2 or 0
        choice.caption:pos(choice.x+14+lift, choice.y+19+lift)
        windower.prim.set_position(choice.background, choice.x+lift, choice.y+lift)
        if lift ~= 0 then windower.prim.set_color(choice.background, 210, 101, 70, 41)
        else windower.prim.set_color(choice.background, 190, 24, 41, 69) end
    end
end

function gamepad_mapper:choose_profile(id)
    if self.state ~= states.SELECT_INPUT_PROFILE then return end
    self.state = states.START_INPUT_PROFILE
    self.profile_generation = self.profile_generation + 1
    local generation = self.profile_generation
    self:display_profile_selector('Starting the selected reader... release all controller buttons.')
    if not self.profile_options or not self.profile_options.select then
        self.state = states.SELECT_INPUT_PROFILE
        self:display_profile_selector('Profile selection is unavailable. Reload XIVCrossbar.')
        return
    end
    self.profile_options.select(id, function(ok, detail)
        -- Closing/restarting setup invalidates callbacks from an earlier attempt.
        if generation ~= self.profile_generation or not self.is_showing then return end
        if ok and detail.connected == '1' then
            self.state = states.SELECT_GAMEPAD_TYPE
            self:display_gamepad_type_selector()
        else
            self.state = states.SELECT_INPUT_PROFILE
            local message = ok and 'No controller detected. Choose another profile, or check //xb controller status.'
                or tostring(detail)
            self:display_profile_selector(message)
        end
    end)
end

function gamepad_mapper:display_gamepad_type_selector()
    windower.prim.set_visibility('button_mapping_bg', true)
    self:hide_text()
    self:hide_images()

    local midpoint_x = self.base_x + (self.width / 2)
    local midpoint_y = self.base_y + (self.height / 2)

    self.title:text('Choose Button Artwork')
    self.title:show()
    self.subtitle:text('Click the button labels you want the addon to display')
    self.subtitle:pos(midpoint_x - 280, self.base_y + 85)
    self.subtitle:show()

    local playstation_x = midpoint_x - 360
    local nintendo_x = midpoint_x - 160
    local xbox_x = midpoint_x + 40
    local gamecube_x = midpoint_x + 240

    local image_y = midpoint_y - 30
    local hint_y = midpoint_y + 80

    local playstation_image = self:create_image('ui/binding_icons/playstation.png', playstation_x, image_y)
    local nintendo_image = self:create_image('ui/binding_icons/nintendo.png', nintendo_x, image_y)
    local xbox_image = self:create_image('ui/binding_icons/xbox.png', xbox_x, image_y)
    local gamecube_image = self:create_image('ui/binding_icons/gamecube.png', gamecube_x, image_y)

    self.playstation_hint = self:create_hint('Playstation', playstation_x + 15, hint_y)
    self.nintendo_hint = self:create_hint('Nintendo', nintendo_x + 22, hint_y)
    self.xbox_hint = self:create_hint('Xbox', xbox_x + 40, hint_y)
    self.gamecube_hint = self:create_hint('   Glorious\n Gamecube\nMaster Race', gamecube_x + 10, hint_y - 15)

    self.controller_choices = {
        {image=playstation_image,hint=self.playstation_hint,x=playstation_x,y=image_y,hx=playstation_x+15,hy=hint_y},
        {image=nintendo_image,hint=self.nintendo_hint,x=nintendo_x,y=image_y,hx=nintendo_x+22,hy=hint_y},
        {image=xbox_image,hint=self.xbox_hint,x=xbox_x,y=image_y,hx=xbox_x+40,hy=hint_y},
        {image=gamecube_image,hint=self.gamecube_hint,x=gamecube_x,y=image_y,hx=gamecube_x+10,hy=hint_y-15},
    }
    self.playstation_hint:hide()
    self.nintendo_hint:hide()
    self.xbox_hint:hide()
    self.gamecube_hint:hide()
end

function gamepad_mapper:display_button_mapper()
    windower.prim.set_visibility('button_mapping_bg', true)
    self:hide_text()
    self:hide_images()

    local midpoint_x = self.base_x + (self.width / 2)
    local icons_y = self.base_y + self.height - 50

    self.title:text('Map Buttons')
    self.title:show()

    if (self.state == states.INPUT_CONFIRM_BUTTON) then
        self.subtitle:text('Hold the right trigger, then press the button you want to map to Confirm/Submit')
        self.subtitle:pos(midpoint_x - 330, self.base_y + 190)
    elseif (self.state == states.INPUT_CANCEL_BUTTON) then
        self.subtitle:text('Hold the right trigger, then press the button you want to map to Cancel')
        self.subtitle:pos(midpoint_x - 330, self.base_y + 190)
    elseif (self.state == states.INPUT_MAINMENU_BUTTON) then
        self.subtitle:text('Hold the right trigger, then press the button you want to map to Main Menu')
        self.subtitle:pos(midpoint_x - 330, self.base_y + 190)
    elseif (self.state == states.INPUT_ACTIVEWINDOW_BUTTON) then
        self.subtitle:text('Hold the right trigger, then press the button you want to map to Active Window')
        self.subtitle:pos(midpoint_x - 330, self.base_y + 190)
    end

    self.subtitle:show()

    self:display_mapped_icons()
end

function gamepad_mapper:display_confirmation_dialog()
    windower.prim.set_visibility('button_mapping_bg', true)
    self:hide_text()
    self:hide_images()

    local midpoint_x = self.base_x + (self.width / 2)
    local midpoint_y = self.base_y + (self.height / 2)

    self.title:text('Save Changes')
    self.title:show()

    self:create_hint('To confirm these settings, hold the right trigger and press ', midpoint_x - 330, midpoint_y - 60)
    self:build_confirm_icon(midpoint_x + 160, midpoint_y - 69)

    self:create_hint('To remap your buttons, hold the right trigger and press ', midpoint_x - 330, midpoint_y - 20)
    self:build_cancel_icon(midpoint_x + 140, midpoint_y - 29)

    self:create_hint('You can remap your buttons at any time by entering "xb remap" in your\nWindower console.', midpoint_x - 330, midpoint_y + 20)

    self:display_mapped_icons()
end

function gamepad_mapper:display_mapped_icons()
    local midpoint_x = self.base_x + (self.width / 2)
    local icons_y = self.base_y + self.height - 100

    if (self.confirm_button) then
        self:build_confirm_icon(midpoint_x - 330, icons_y)
        self:create_hint('= Confirm', midpoint_x - 285, icons_y + 9)
    end
    if (self.cancel_button) then
        self:build_cancel_icon(midpoint_x - 180, icons_y)
        self:create_hint('= Cancel', midpoint_x - 135, icons_y + 9)
    end
    if (self.mainmenu_button) then
        self:build_mainmenu_icon(midpoint_x - 40, icons_y)
        self:create_hint('= Main Menu', midpoint_x + 5, icons_y + 9)
    end
    if (self.activewindow_button) then
        self:build_activewindow_icon(midpoint_x + 130, icons_y)
        self:create_hint('= Active Window', midpoint_x + 175, icons_y + 9)
    end
end

function gamepad_mapper:display_completion_dialog()
    windower.prim.set_visibility('button_mapping_bg', true)
    self:hide_text()
    self:hide_images()

    local midpoint_x = self.base_x + (self.width / 2)
    local midpoint_y = self.base_y + (self.height / 2)

    self.title:text('Finished')
    self.title:show()

    -- A: separate rows avoid glyph overlap and space-padded inline icons.
    local left = midpoint_x - 330
    self:create_hint('Success! Your button mapping has been configured.', left, midpoint_y - 85)

    self:build_minus_icon(left, midpoint_y - 49)
    self:create_hint('Open the action-binding menu.', left + 70, midpoint_y - 40)
    self:build_plus_icon(left, midpoint_y - 2)
    self:create_hint('Choose a crossbar set.', left + 70, midpoint_y + 7)

    self:create_hint('Use //xb new <name> to create a crossbar set.', left, midpoint_y + 55)
    self:create_hint('Press                          to exit.', left, midpoint_y + 105)
    self:build_right_trigger_icon(left + 55, midpoint_y + 96)
    self:show_connector_plus(left + 95, midpoint_y + 96)
    self:build_confirm_icon(left + 135, midpoint_y + 96)

end

function gamepad_mapper:is_over_playstation_buttons(x, y)
    if (self.width == nil or self.height == nil or self.base_x == nil or self.base_y == nil) then
        return false
    end

    local midpoint_x = self.base_x + (self.width / 2)
    local midpoint_y = self.base_y + (self.height / 2)
    local buttons_x = midpoint_x - 360
    local buttons_y = midpoint_y - 30
    local button_width_height = 120

    local valid_x = (buttons_x <= x) and (x <= (buttons_x + button_width_height))
    local valid_y = (buttons_y <= y) and (y <= (buttons_y + button_width_height))

    return valid_x and valid_y
end

function gamepad_mapper:is_over_nintendo_buttons(x, y)
    if (self.width == nil or self.height == nil or self.base_x == nil or self.base_y == nil) then
        return false
    end

    local midpoint_x = self.base_x + (self.width / 2)
    local midpoint_y = self.base_y + (self.height / 2)
    local buttons_x = midpoint_x - 160
    local buttons_y = midpoint_y - 30
    local button_width_height = 120

    local valid_x = (buttons_x <= x) and (x <= (buttons_x + button_width_height))
    local valid_y = (buttons_y <= y) and (y <= (buttons_y + button_width_height))

    return valid_x and valid_y
end

function gamepad_mapper:is_over_xbox_buttons(x, y)
    if (self.width == nil or self.height == nil or self.base_x == nil or self.base_y == nil) then
        return false
    end

    local midpoint_x = self.base_x + (self.width / 2)
    local midpoint_y = self.base_y + (self.height / 2)
    local buttons_x = midpoint_x + 40
    local buttons_y = midpoint_y - 30
    local button_width_height = 120

    local valid_x = (buttons_x <= x) and (x <= (buttons_x + button_width_height))
    local valid_y = (buttons_y <= y) and (y <= (buttons_y + button_width_height))

    return valid_x and valid_y
end

function gamepad_mapper:is_over_gamecube_buttons(x, y)
    if (self.width == nil or self.height == nil or self.base_x == nil or self.base_y == nil) then
        return false
    end

    local midpoint_x = self.base_x + (self.width / 2)
    local midpoint_y = self.base_y + (self.height / 2)
    local buttons_x = midpoint_x + 240
    local buttons_y = midpoint_y - 30
    local button_width_height = 120

    local valid_x = (buttons_x <= x) and (x <= (buttons_x + button_width_height))
    local valid_y = (buttons_y <= y) and (y <= (buttons_y + button_width_height))

    return valid_x and valid_y
end

function gamepad_mapper:create_image(path, x, y)
    local image = ui_resources.image({draggable = false})

    local image_path = windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/' .. path
    setup_image(image, image_path)
    image:pos(x, y)
    self.images:append(image)
    return image
end

function gamepad_mapper:create_hint(hint_text, x, y)
    local hint = self:create_text(hint_text, x, y)
    hint:size(14)
    self.hints:append(hint)
    return hint
end

-- Hover offsets always use the original coordinates; hitboxes never move.
function gamepad_mapper:hover_controller(x, y)
    for _,choice in ipairs(self.controller_choices) do
        local hovered = x >= choice.x and x <= choice.x+120 and y >= choice.y and y <= choice.y+120
        local offset = hovered and -2 or 0
        choice.image:pos(choice.x+offset, choice.y+offset)
        choice.hint:pos(choice.hx+offset, choice.hy+offset)
        if hovered then choice.hint:show() else choice.hint:hide() end
    end
end

function gamepad_mapper:hover_welcome(x, y)
    local width, height = self.welcome_prompt:extents()
    local hovered = x >= self.welcome_x and x <= self.welcome_x+width
        and y >= self.welcome_y and y <= self.welcome_y+height
    local offset = hovered and -2 or 0
    self.welcome_prompt:pos(self.welcome_x+offset, self.welcome_y+offset)
    self.welcome_glow:pos(self.welcome_x+offset, self.welcome_y+offset)
    if hovered then self.welcome_glow:show() else self.welcome_glow:hide() end
end

function gamepad_mapper:handle_button_press(button_name)
    if (self.state == states.INPUT_CONFIRM_BUTTON) then
        self.confirm_button = button_name
        self.state = states.INPUT_CANCEL_BUTTON
        self:display_button_mapper()
    elseif (self.state == states.INPUT_CANCEL_BUTTON) then
        self.cancel_button = button_name
        self.state = states.INPUT_MAINMENU_BUTTON
        self:display_button_mapper()
    elseif (self.state == states.INPUT_MAINMENU_BUTTON) then
        self.mainmenu_button = button_name
        self.state = states.INPUT_ACTIVEWINDOW_BUTTON
        self:display_button_mapper()
    elseif (self.state == states.INPUT_ACTIVEWINDOW_BUTTON) then
        self.activewindow_button = button_name
        self.state = states.CONFIRMATION_SCREEN
        self:display_confirmation_dialog()
    elseif (self.state == states.CONFIRMATION_SCREEN) then
        if (self.confirm_button == button_name) then
            self.buttonmapping.button_layout = self.button_layout
            self.buttonmapping.confirm_button = self.confirm_button
            self.buttonmapping.cancel_button = self.cancel_button
            self.buttonmapping.mainmenu_button = self.mainmenu_button
            self.buttonmapping.activewindow_button = self.activewindow_button
            if (self.buttonmapping:write()) then
                self.state = states.COMPLETE
                self:display_completion_dialog()
            else
                windower.send_command('input /echo [XIVCrossbar] An error occurred. Configuration file not saved.')
            end
        elseif (self.cancel_button == button_name) then
            self.confirm_button = nil
            self.cancel_button = nil
            self.mainmenu_button = nil
            self.activewindow_button = nil
            self.state = states.INPUT_CONFIRM_BUTTON
            self:display_button_mapper()
        end
    elseif (self.state == states.COMPLETE) then
        if (self.confirm_button == button_name) then
            self:hide()
            self.state = states.HIDDEN
            windower.send_command('lua reload xivcrossbar')
        end
    end
end

local PLAYSTATION_TO_GAMECUBE = {
    ['cross'] = 'a',
    ['square'] = 'b',
    ['circle'] = 'x',
    ['triangle'] = 'y'
}

local XBOX_TO_GAMECUBE = {
    ['a'] = 'a',
    ['x'] = 'b',
    ['b'] = 'x',
    ['y'] = 'y'
}

local NINTENDO_TO_GAMECUBE = {
    ['b'] = 'a',
    ['y'] = 'b',
    ['a'] = 'x',
    ['x'] = 'y'
}

function gamepad_mapper:get_standardized_button_name(button_name)
    if (self.button_layout == 'gamecube') then
        return button_name
    elseif (self.button_layout == 'playstation') then
        return PLAYSTATION_TO_GAMECUBE[button_name]
    elseif (self.button_layout == 'xbox') then
        return XBOX_TO_GAMECUBE[button_name]
    elseif (self.button_layout == 'nintendo') then
        return NINTENDO_TO_GAMECUBE[button_name]
    end
end

function gamepad_mapper:build_button_icon(button_name, x, y)
    local button = self:get_standardized_button_name(button_name)
    local path = 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_' .. button .. '.png'
    self:create_image(path, x, y)
end

function gamepad_mapper:build_confirm_icon(x, y)
    self:build_button_icon(self.confirm_button, x, y)
end

function gamepad_mapper:build_cancel_icon(x, y)
    self:build_button_icon(self.cancel_button, x, y)
end

function gamepad_mapper:build_mainmenu_icon(x, y)
    self:build_button_icon(self.mainmenu_button, x, y)
end

function gamepad_mapper:build_activewindow_icon(x, y)
    self:build_button_icon(self.activewindow_button, x, y)
end

function gamepad_mapper:build_minus_icon(x, y)
    local path = 'ui/binding_icons/minus_' .. self.button_layout .. '.png'
    self:create_image(path, x, y)
end

function gamepad_mapper:build_plus_icon(x, y)
    local path = 'ui/binding_icons/plus_' .. self.button_layout .. '.png'
    self:create_image(path, x, y)
end

function gamepad_mapper:build_left_trigger_icon(x, y)
    local path = 'ui/binding_icons/trigger_' .. self.button_layout .. '_left.png'
    self:create_image(path, x, y)
end

function gamepad_mapper:build_right_trigger_icon(x, y)
    local path = 'ui/binding_icons/trigger_' .. self.button_layout .. '_right.png'
    self:create_image(path, x, y)
end

function gamepad_mapper:show_connector_plus(x, y)
    local path = 'ui/binding_icons/plus.png'
    self:create_image(path, x, y)
end

function gamepad_mapper:button_a(pressed)
    if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
        local button_name = ''
        if (self.button_layout == 'gamecube') then
            button_name = 'a'
        elseif (self.button_layout == 'playstation') then
            button_name = 'cross'
        elseif (self.button_layout == 'xbox') then
            button_name = 'a'
        elseif (self.button_layout == 'nintendo') then
            button_name = 'b'
        end

        self:handle_button_press(button_name)
    end
end

function gamepad_mapper:button_b(pressed)
    if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
        local button_name = ''
        if (self.button_layout == 'gamecube') then
            button_name = 'b'
        elseif (self.button_layout == 'playstation') then
            button_name = 'square'
        elseif (self.button_layout == 'xbox') then
            button_name = 'x'
        elseif (self.button_layout == 'nintendo') then
            button_name = 'y'
        end

        self:handle_button_press(button_name)
    end
end

function gamepad_mapper:button_x(pressed)
    if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
        local button_name = ''
        if (self.button_layout == 'gamecube') then
            button_name = 'x'
        elseif (self.button_layout == 'playstation') then
            button_name = 'circle'
        elseif (self.button_layout == 'xbox') then
            button_name = 'b'
        elseif (self.button_layout == 'nintendo') then
            button_name = 'a'
        end

        self:handle_button_press(button_name)
    end
end

function gamepad_mapper:button_y(pressed)
    if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
        local button_name = ''
        if (self.button_layout == 'gamecube') then
            button_name = 'y'
        elseif (self.button_layout == 'playstation') then
            button_name = 'triangle'
        elseif (self.button_layout == 'xbox') then
            button_name = 'y'
        elseif (self.button_layout == 'nintendo') then
            button_name = 'x'
        end

        self:handle_button_press(button_name)
    end
end

function gamepad_mapper:trigger_left(pressed)
    self.trigger_left_pressed = pressed
end

function gamepad_mapper:trigger_right(pressed)
    self.trigger_right_pressed = pressed
end

local click_x = nil
local click_y = nil
local mouse_handler = windower.register_event('mouse', function(type, x, y, delta, blocked)
    if blocked then
        return
    end

    if (not gamepad_mapper.is_hidden and gamepad_mapper.state == states.INTRO_SCREEN) then
        -- Mouse left click
        if type == 0 then
            gamepad_mapper:hover_welcome(x, y)
        elseif type == 1 then
            click_x = x
            click_y = y
        -- Mouse left release
        elseif type == 2 then
            if (click_x ~= nil and click_y ~= nil and gamepad_mapper:is_within_dialog(click_x, click_y) and gamepad_mapper:is_within_dialog(x, y)) then
                click_x = nil
                click_y = nil
                gamepad_mapper.state = states.SELECT_INPUT_PROFILE
                gamepad_mapper:display_profile_selector()
            end
        end
    elseif gamepad_mapper.is_showing and (gamepad_mapper.state == states.SELECT_INPUT_PROFILE or gamepad_mapper.state == states.START_INPUT_PROFILE) then
        if type == 0 then gamepad_mapper:hover_profile(x, y)
        elseif type == 1 then click_x, click_y = x, y
        elseif type == 2 then
            local previous = click_x and gamepad_mapper:profile_at(click_x, click_y)
            local current = gamepad_mapper:profile_at(x, y)
            click_x, click_y = nil, nil
            if previous and previous == current then gamepad_mapper:choose_profile(current.id) end
        end
    elseif (not gamepad_mapper.is_hidden and gamepad_mapper.state == states.SELECT_GAMEPAD_TYPE) then
        -- Mouse hover
        if type == 0 then
            gamepad_mapper:hover_controller(x, y)
        -- Mouse left click
        elseif type == 1 then
            click_x = x
            click_y = y
        -- Mouse left release
        elseif type == 2 then
            if (click_x ~= nil and click_y ~= nil) then
                if (gamepad_mapper:is_over_playstation_buttons(click_x, click_y) and
                    gamepad_mapper:is_over_playstation_buttons(x, y)) then
                    gamepad_mapper.button_layout = 'playstation'
                end
                if (gamepad_mapper:is_over_nintendo_buttons(click_x, click_y) and
                    gamepad_mapper:is_over_nintendo_buttons(x, y)) then
                    gamepad_mapper.button_layout = 'nintendo'
                end
                if (gamepad_mapper:is_over_xbox_buttons(click_x, click_y) and
                    gamepad_mapper:is_over_xbox_buttons(x, y)) then
                    gamepad_mapper.button_layout = 'xbox'
                end
                if (gamepad_mapper:is_over_gamecube_buttons(click_x, click_y) and
                    gamepad_mapper:is_over_gamecube_buttons(x, y)) then
                    gamepad_mapper.button_layout = 'gamecube'
                end

                click_x = nil
                click_y = nil

                if (gamepad_mapper.button_layout ~= nil) then
                    gamepad_mapper.state = states.INPUT_CONFIRM_BUTTON
                    gamepad_mapper:display_button_mapper()
                end
            end
        end
    end
end)

return gamepad_mapper
