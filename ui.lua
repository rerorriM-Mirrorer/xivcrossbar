local ui_resources = require('ui/resources')
local item_icons = require('ui/item_icons')
local kebab_casify = require('libs/kebab_casify')
local crossbar_abilities = require('resources/crossbar_abilities')
local crossbar_spells = require('resources/crossbar_spells')
local defaults = require('defaults')
settings = config.load(defaults)
local player = require('player')

local ui = {}
local geometry = require('ui_geometry').new('crossbar')
local prim = geometry:prim()
ui.geometry = geometry
ui.autoattack = require('autoattack').new(os.clock)
local function new_image(options)
    return geometry:surface(ui_resources.image(options), 'image', options)
end
local function new_text(options)
    return geometry:surface(ui_resources.text(options), 'text', options)
end

local text_setup = {
    flags = {
        draggable = false
    }
}

local right_text_setup = {
    flags = {
        right = true,
        draggable = false
    }
}

local images_setup = {
    draggable = false
}

local spellsThatRequireJA = require('spells_that_require_ja')

-- ui metrics
ui.hotbar_width = 0
ui.hotbar_spacing = 0
ui.slot_spacing = 0
ui.pos_x = 700
ui.pos_y = 500
ui.gcd_offset_y = 130
ui.gcd_offset_x = 0
ui.aa_offset_y = 120 
ui.aa_offset_x = 0

-- ui variables
ui.battle_notice = new_image(images_setup)
ui.feedback_icon = nil
ui.hotbars = {}

-- ui theme options
ui.theme = {}

-- ui control
ui.feedback = {}
ui.feedback.is_active = false
ui.feedback.current_opacity = 0
ui.feedback.max_opacity = 0
ui.feedback.speed = 0

ui.disabled_slots = {}
ui.disabled_slots.actions = {}
ui.disabled_slots.no_vitals = {}
ui.disabled_slots.on_cooldown = {}
ui.disabled_slots.on_warmup = {}

local animation_frame_count = 0

ui.is_setup = false

-----------------------------
-- Buff caching
-----------------------------

-- Track WS relevant buffs
-- Check if Immanence / Azure Lore / Chain Affinity / Burst Affinity is active and if any runes are active that could be bursted with Swipe / Lunge

-- For better readability
local ACTION_IDS = {
    swipe = 344,
    lunge = 368,
}

local BUFF_BY_ID = {
    [163] = "azure_lore",
    [164] = "chain_affinity",
    [165] = "burst_affinity",
    [470] = "immanence",
}

local RUNE_BY_ID = {
    [523] = "ignis",
    [524] = "gelus",
    [525] = "flabra",
    [526] = "tellus",
    [527] = "sulpor",
    [528] = "unda",
    [529] = "lux",
    [530] = "tenebrae"
}

-- TODO: find a better way of doing this? (after the switch to Teal)
local RUNE_SKILL_INDEX = {
    ignis = 1,
    gelus = 2,
    flabra = 3,
    tellus = 4,
    sulpor = 5,
    unda = 6,
    lux = 7,
    tenebrae = 8,
}

local buff_active = {
    azure_lore = false,
    chain_affinity = false,
    burst_affinity = false,
    immanence = false,
}

local rune_active = {
    ignis = false,
    gelus = false,
    flabra = false,
    tellus = false,
    sulpor = false,
    unda = false,
    lux = false,
    tenebrae = false,
}

local last_active_rune = nil

-- Updates the Buff cache for a single given Buff ID
-- gained: boolean, true if the buff was gained, false if it was lost
local function update_buff_cache(buff_id, is_gained)
    local buff_name = BUFF_BY_ID[buff_id]

    if buff_name then
        buff_active[buff_name] = is_gained
        return
    end

    local rune_name = RUNE_BY_ID[buff_id]

    if rune_name then
        rune_active[rune_name] = is_gained

        if is_gained then
            last_active_rune = RUNE_SKILL_INDEX[rune_name]
        end
    end
end

-- Caches all buffs that are relevant for UI display
-- It only needs to be called once on first UI setup
-- Afterwards, Windower events for "gain buff" and "lose buff" update future changes
local function register_active_buffs()
	-- clear cache
    for key, _value in pairs(buff_active) do
        buff_active[key] = false
    end

    for key, _value in pairs(rune_active) do
        rune_active[key] = false
    end

    last_active_rune = nil

    local buffs = windower.ffxi.get_player().buffs

	for _key, buff in pairs(buffs) do
		update_buff_cache(buff, true)
	end
end

windower.register_event("gain buff", function(buff_id)
	update_buff_cache(buff_id, true)
end)

windower.register_event('lose buff', function(buff_id)
	update_buff_cache(buff_id, false)
end)

-----------------------------
-- Helpers
-----------------------------

-- setup images
function setup_image(image, path)
    image:path(path)
    image:repeat_xy(1, 1)
    image:draggable(false)
    image:fit(true)
    image:alpha(255)
    image:show()
end

-- setup text
local function setup_text(text, theme_options, hidden)
    text:bg_alpha(0)
    text:bg_visible(false)
    text:font(theme_options.font)
    text:size(theme_options.font_size)
    text:color(theme_options.font_color_red, theme_options.font_color_green, theme_options.font_color_blue)
    text:stroke_alpha(theme_options.font_stroke_alpha)
    text:stroke_color(theme_options.font_stroke_color_red, theme_options.font_stroke_color_green, theme_options.font_stroke_color_blue)
    text:stroke_width(theme_options.font_stroke_width)
    if not hidden then text:show() end
end

local icon_pack = nil

local get_icon_pathbase = function()
    return 'icons/iconpacks/' .. icon_pack
end

local maybe_get_custom_icon = function(default_icon, custom_icon)
    local pathbase = get_icon_pathbase()
    local icon_path = 'images/' .. pathbase .. '/' .. custom_icon
    local icon_file = file.new(icon_path)
    if (icon_file:exists()) then
        return icon_path, true
    else
        return default_icon, false
    end
end

-- get x position for a given hotbar and slot
function ui:get_slot_x(h, i)
    if not self.UseAltLayout then
        local base = self.pos_x - 50
        if (h == 2) then
            base = base + 300
        elseif (h == 3 or h == 4) then
            base = base + 150
        elseif (h == 5) then
            base = base + 50 -- left doublepress crossbar
        elseif (h == 6) then
            base = base + 250 -- right doublepress crossbar
        end

        if h == 3 then
            base = base + self.theme.alternate_press_offset_x
        elseif h == 4 then
            base = base - self.theme.alternate_press_offset_x
        elseif h == 5 then
            base = base - self.theme.double_press_offset_x
        elseif h == 6 then
            base = base + self.theme.double_press_offset_x
        end

        -- move the last icon in each group of 4 to the middle create the cross
        -- move icon 9 to the left cross's center to be the dpad icon
        -- move icon 10 to the right cross's center to be the face buttons icon
        local column = i
        if (i == 4) then
            column = 2
        elseif (i == 9) then
            column = 3
        elseif (i == 8 or i == 10) then
            column = 6
        end

        -- shift the two crosses closer to each other
        if (i > 4) then
            column = column - 1
        end

        return base + ((40 + self.slot_spacing) * (column - 1))
    else
        local base = self.pos_x - 50
        if (h == 2) then
            base = base + 140
        elseif (h == 3 or h == 4) then
            base = base + 150
        elseif (h == 5) then
            base = base - 70 -- left doublepress crossbar
        elseif (h == 6) then
            base = base + 70 -- right doublepress crossbar
        end

        -- Per-hotbar configurable X offsets (same as standard branch above).
        if h == 3 then
            base = base + self.theme.alternate_press_offset_x
        elseif h == 4 then
            base = base - self.theme.alternate_press_offset_x
        elseif h == 5 then
            base = base - self.theme.double_press_offset_x
        elseif h == 6 then
            base = base + self.theme.double_press_offset_x
        end

        -- move the last icon in each group of 4 to the middle create the cross
        -- move icon 9 to the left cross's center to be the dpad icon
        -- move icon 10 to the right cross's center to be the face buttons icon
        local column = i
        if (i == 4) then
            column = 2
        elseif (i == 9) then
            column = 3
        elseif (i == 8 or i == 10) then
            column = 6
        end

        -- shift the two crosses closer to each other
        if (i > 4) then
            if h ==1 or h == 2 then
                column = column + 3
            elseif h == 3 or h == 4 then
                column = column - 1
            else
                column = column + 6
            end
        end

        return base + ((40 + self.slot_spacing) * (column - 1))
    end
end

-- get y position for a given hotbar and slot
function ui:get_slot_y(h, i)
    local base = self.pos_y
    local spacing = self.hotbar_spacing
    if (self.is_compact) then
        spacing = spacing / 2
    end

    -- Per-hotbar configurable Y offsets (alternate-press / double-press
    -- pairs). Y is uniform within a pair (no left/right split). Y is in
    -- screen coordinates, so a NEGATIVE value moves the bar UP on screen.
    if h == 3 or h == 4 then
        base = base + self.theme.alternate_press_offset_y
    elseif h == 5 or h == 6 then
        base = base + self.theme.double_press_offset_y
    end

    -- move the second icon in each group of 4 to the top and move the
    -- fourth icon in each group of 4 to the bottom to create the cross
    local row = 2
    if (i == 2 or i == 6) then
        row = 1
    elseif (i == 4 or i == 8) then
        row = 3
    end
    return base - (((row - 1) * spacing))
end

-----------------------------
-- Setup UI
-----------------------------

-- setup ui
function ui:setup(theme_options, enchanted_items)
    geometry:configure_fade(theme_options.fade_enabled, theme_options.fade_in,
        theme_options.fade_out, theme_options.load_fade_in, {claimed=false})
    geometry:set_text_fade(theme_options.text_fade)
    geometry:set_opacity(0)
    register_active_buffs()

    self.enchanted_items = enchanted_items

    icon_pack = theme_options.iconpack

    self.frame_skip = theme_options.frame_skip

    self.theme.hide_empty_slots = theme_options.hide_empty_slots
    self.theme.hide_action_names = theme_options.hide_action_names
    self.theme.hide_action_cost = theme_options.hide_action_cost
    self.theme.hide_action_element = theme_options.hide_action_element
    self.theme.hide_recast_animation = theme_options.hide_recast_animation
    self.theme.hide_recast_text = theme_options.hide_recast_text
    self.theme.hide_battle_notice = theme_options.hide_battle_notice

    self.theme.skillchain_window_opacity = theme_options.skillchain_window_opacity
    self.theme.skillchain_waiting_color_red = theme_options.skillchain_waiting_color_red
    self.theme.skillchain_waiting_color_green = theme_options.skillchain_waiting_color_green
    self.theme.skillchain_waiting_color_blue = theme_options.skillchain_waiting_color_blue
    self.theme.skillchain_open_color_red = theme_options.skillchain_open_color_red
    self.theme.skillchain_open_color_green = theme_options.skillchain_open_color_green
    self.theme.skillchain_open_color_blue = theme_options.skillchain_open_color_blue

    self.theme.spell_lockout_duration = theme_options.spell_lockout_duration
    self.theme.spell_lockout_opacity = theme_options.spell_lockout_opacity
    self.theme.spell_lockout_primary_red = theme_options.spell_lockout_primary_red
    self.theme.spell_lockout_primary_green = theme_options.spell_lockout_primary_green
    self.theme.spell_lockout_primary_blue = theme_options.spell_lockout_primary_blue
    self.theme.spell_lockout_ending_red = theme_options.spell_lockout_ending_red
    self.theme.spell_lockout_ending_green = theme_options.spell_lockout_ending_green
    self.theme.spell_lockout_ending_blue = theme_options.spell_lockout_ending_blue

    self.theme.ws_lockout_opacity = theme_options.ws_lockout_opacity
    self.theme.ws_lockout_primary_red = theme_options.ws_lockout_primary_red
    self.theme.ws_lockout_primary_green = theme_options.ws_lockout_primary_green
    self.theme.ws_lockout_primary_blue = theme_options.ws_lockout_primary_blue

    self.theme.ja_lockout_opacity = theme_options.ja_lockout_opacity
    self.theme.ja_lockout_full_red = theme_options.ja_lockout_full_red
    self.theme.ja_lockout_full_green = theme_options.ja_lockout_full_green
    self.theme.ja_lockout_full_blue = theme_options.ja_lockout_full_blue
    self.theme.ja_lockout_partial_red = theme_options.ja_lockout_partial_red
    self.theme.ja_lockout_partial_green = theme_options.ja_lockout_partial_green
    self.theme.ja_lockout_partial_blue = theme_options.ja_lockout_partial_blue

    -- Auto-attack swing timer settings.
    self.autoattack:set_enabled(theme_options.aa_enabled)
    self.theme.aa_opacity = theme_options.aa_opacity
    self.theme.aa_paused_opacity = theme_options.aa_paused_opacity
    self.theme.aa_background_opacity = theme_options.aa_background_opacity
    self.theme.aa_paused_background_opacity = theme_options.aa_paused_background_opacity
    self.theme.aa_before_red = theme_options.aa_before_red
    self.theme.aa_before_green = theme_options.aa_before_green
    self.theme.aa_before_blue = theme_options.aa_before_blue
    self.theme.aa_past_red = theme_options.aa_past_red
    self.theme.aa_past_green = theme_options.aa_past_green
    self.theme.aa_past_blue = theme_options.aa_past_blue

    self.theme.slot_opacity = theme_options.slot_opacity
    self.theme.disabled_slot_opacity = theme_options.disabled_slot_opacity
    self.theme.hotbar_number = theme_options.hotbar_number
    self.AutoHideExtraBars = theme_options.AutoHideExtraBars
    self.UseAltLayout = theme_options.UseAltLayout

    self.theme.mp_cost_color_red = theme_options.mp_cost_color_red
    self.theme.mp_cost_color_green = theme_options.mp_cost_color_green
    self.theme.mp_cost_color_blue = theme_options.mp_cost_color_blue
    self.theme.mp_cost_insufficient_red = theme_options.mp_cost_insufficient_red
    self.theme.mp_cost_insufficient_green = theme_options.mp_cost_insufficient_green
    self.theme.mp_cost_insufficient_blue = theme_options.mp_cost_insufficient_blue
    self.theme.tp_cost_color_red = theme_options.tp_cost_color_red
    self.theme.tp_cost_color_green = theme_options.tp_cost_color_green
    self.theme.tp_cost_color_blue = theme_options.tp_cost_color_blue
    self.theme.button_layout = theme_options.button_layout
    self.is_compact = theme_options.is_compact
    self.button_bg_alpha = theme_options.button_background_alpha

    -- Per-hotbar position offsets. Applied as pure additive overrides in
    -- get_slot_x / get_slot_y. See defaults.lua for the sign convention.
    self.theme.alternate_press_offset_x = theme_options.alternate_press_offset_x
    self.theme.alternate_press_offset_y = theme_options.alternate_press_offset_y
    self.theme.double_press_offset_x = theme_options.double_press_offset_x
    self.theme.double_press_offset_y = theme_options.double_press_offset_y

    self:setup_metrics(theme_options)
    self:set_scale(tonumber(theme_options.crossbar_scale) or 1)
    self:load(theme_options)
    self.hotbar_width = (400 + theme_options.slot_spacing * 9)
    self.is_setup = true
end

-- load the images and text
function ui:load(theme_options)
    geometry:dispose_surfaces({[self.battle_notice]=true})
    -- load battle notice
    setup_image(self.battle_notice, windower.addon_path .. '/themes/' .. (theme_options.battle_notice_theme:lower()) .. '/notice.png')
    self.battle_notice:pos(self.pos_x + self.hotbar_width - 90, self.pos_y - (theme_options.hotbar_spacing * (theme_options.hotbar_number)) - 24)
    self.battle_notice:hide()
    self.frame_image_path = windower.addon_path..'/themes/' .. (theme_options.frame_theme:lower()) .. '/frame.png'

    prim.create_rounded('skillchain_indicator_bg')
    prim.set_color('skillchain_indicator_bg', 150, 0, 0, 0)
    prim.set_position('skillchain_indicator_bg', self:get_slot_x(1, 1) - 12, self:get_slot_y(1, 4) - 32)
    prim.set_size('skillchain_indicator_bg', 604, 14)
    prim.set_visibility('skillchain_indicator_bg', false)

    prim.create_rounded('skillchain_indicator')
    prim.set_color('skillchain_indicator', 220, 15, 205, 5)
    prim.set_position('skillchain_indicator', self:get_slot_x(1, 1) - 10, self:get_slot_y(1, 4) - 30)
    prim.set_size('skillchain_indicator', 600, 10)
    prim.set_visibility('skillchain_indicator', false)

    prim.create_rounded('gcd_indicator_bg')
    prim.set_color('gcd_indicator_bg', 150, 0, 0, 0)
    prim.set_position('gcd_indicator_bg', self:get_slot_x(1, 1) - 12, self:get_slot_y(1, 4) + 10)
    prim.set_size('gcd_indicator_bg', 604, 10)
    prim.set_visibility('gcd_indicator_bg', false)

    prim.create_rounded('gcd_indicator')
    prim.set_color('gcd_indicator', 220, 200, 200, 255) -- bluish/white
    prim.set_position('gcd_indicator', self:get_slot_x(1, 1) - 10, self:get_slot_y(1, 4) + 12)
    prim.set_size('gcd_indicator', 600, 6)
    prim.set_visibility('gcd_indicator', false)

    prim.create_rounded('aa_indicator_bg')
    prim.set_color('aa_indicator_bg', 150, 0, 0, 0)
    prim.set_size('aa_indicator_bg', 604, 10)
    prim.set_visibility('aa_indicator_bg', false)

    prim.create_rounded('aa_indicator_red')
    prim.set_color('aa_indicator_red', 220, 220, 30, 30)
    prim.set_size('aa_indicator_red', 300, 6)
    prim.set_visibility('aa_indicator_red', false)

    prim.create_rounded('aa_indicator_green')
    prim.set_color('aa_indicator_green', 220, 15, 205, 5)
    prim.set_size('aa_indicator_green', 300, 6)
    prim.set_visibility('aa_indicator_green', false)

    self.bar_background = new_image(images_setup)
    self.bar_background_left = new_image(images_setup)
    self.bar_background_right = new_image(images_setup)
    if (self.is_compact) then
            self.bar_background:size(330, 180)
            self.bar_background:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/bar_bg_compact.png')

            self.bar_background_left:size(330, 180)
            self.bar_background_left:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/bar_bg_compact_alt.png')

            self.bar_background_right:size(330, 180)
            self.bar_background_right:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/bar_bg_compact_alt.png')
    else
        self.bar_background:size(330, 220)
        self.bar_background:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/bar_bg.png')
        self.bar_background_left:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/bar_bg_alt.png')
        self.bar_background_right:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/bar_bg_alt.png')
    end
    self.bar_background:alpha(self.button_bg_alpha)
    self.bar_background_left:alpha(self.button_bg_alpha)
    self.bar_background_right:alpha(self.button_bg_alpha)

    -- setup button ui hints
    self.action_binder_icon = new_image(images_setup)
    self.action_binder_icon:size(40, 40)
    self.action_binder_icon:pos(self:get_slot_x(1, 1) - 10, self:get_slot_y(1, 4) - 27)
    self.action_binder_icon:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/binding_icons/minus_'..self.theme.button_layout..'.png')
    self.action_binder_icon:alpha(255)
    self.action_binder_text = new_text(text_setup)
    setup_text(self.action_binder_text, theme_options, self.is_compact)
    self.action_binder_text:pos(self:get_slot_x(1, 1) + 35, self:get_slot_y(1, 4) - 15)
    self.action_binder_text:text('Bind an action')
    self.environment_selector_icon = new_image(images_setup)
    self.environment_selector_icon:path(windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/binding_icons/plus_'..self.theme.button_layout..'.png')
    self.environment_selector_icon:size(40, 40)
    self.environment_selector_icon:pos(self:get_slot_x(2, 5) - 5, self:get_slot_y(1, 4) - 27)
    self.environment_selector_icon:alpha(255)
    self.environment_selector_text = new_text(text_setup)
    setup_text(self.environment_selector_text, theme_options, self.is_compact)
    self.environment_selector_text:pos(self:get_slot_x(2, 5) + 40, self:get_slot_y(1, 4) - 15)
    self.environment_selector_text:text('Change crossbar sets')
    if (not self.is_compact) then
        self:show_button_hints()
    else
        self:hide_button_hints()
    end

    -- create ui elements for hotbars
    for h=1,theme_options.hotbar_number,1 do
        self.hotbars[h] = {}
        self.hotbars[h].slot_background = {}
        self.hotbars[h].slot_icon = {}
        self.hotbars[h].slot_recast = {}
        self.hotbars[h].slot_warmup = {}
        self.hotbars[h].slot_frame = {}
        self.hotbars[h].slot_element = {}
        self.hotbars[h].slot_text = {}
        self.hotbars[h].slot_cost = {}
        self.hotbars[h].slot_recast_text = {}

        -- set up the highlighting background for when a hotbar is active
        for i=1,8,1 do
            local slot_pos_x = self:get_slot_x(h, i)
            local slot_pos_y = self:get_slot_y(h, i)
            local right_slot_pos_x = slot_pos_x - windower.get_windower_settings().ui_x_res + 16

            self.hotbars[h].slot_background[i] = new_image(images_setup)
            self.hotbars[h].slot_warmup[i] = new_image(images_setup)
            self.hotbars[h].slot_icon[i] = new_image(images_setup)
            self.hotbars[h].slot_recast[i] = new_image(images_setup)
            self.hotbars[h].slot_frame[i] = new_image(images_setup)
            self.hotbars[h].slot_element[i] = new_image(images_setup)
            self.hotbars[h].slot_text[i] = new_text(text_setup)
            self.hotbars[h].slot_cost[i] = new_text(right_text_setup)
            self.hotbars[h].slot_recast_text[i] = new_text(right_text_setup)
            local trace=require('ui/render_trace')
            trace.track(self.hotbars[h].slot_text[i],nil,'crossbar','bar'..h..'.slot'..i..'.caption')
            trace.track(self.hotbars[h].slot_cost[i],nil,'crossbar','bar'..h..'.slot'..i..'.cost')
            trace.track(self.hotbars[h].slot_recast_text[i],nil,'crossbar','bar'..h..'.slot'..i..'.recast')
            self.hotbars[h].slot_icon[i]:size(40, 40)

            setup_image(self.hotbars[h].slot_background[i], windower.addon_path..'/themes/' .. (theme_options.slot_theme:lower()) .. '/slot.png')
            setup_image(self.hotbars[h].slot_icon[i], windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blank.png')
            setup_image(self.hotbars[h].slot_frame[i], self.frame_image_path)
            setup_image(self.hotbars[h].slot_element[i], windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blank.png')
            setup_text(self.hotbars[h].slot_text[i], theme_options)
            setup_text(self.hotbars[h].slot_cost[i], theme_options)
            setup_text(self.hotbars[h].slot_recast_text[i], theme_options)

            self.hotbars[h].slot_cost[i]:size(8)
            self.hotbars[h].slot_cost[i]:stroke_alpha(220)
            self.hotbars[h].slot_background[i]:alpha(theme_options.slot_opacity)
            self.hotbars[h].slot_background[i]:pos(slot_pos_x, slot_pos_y)
            self.hotbars[h].slot_icon[i]:pos(slot_pos_x, slot_pos_y)
            self.hotbars[h].slot_frame[i]:pos(slot_pos_x, slot_pos_y)
            self.hotbars[h].slot_element[i]:pos(slot_pos_x + 28, slot_pos_y - 4)

            self.hotbars[h].slot_text[i]:pos(slot_pos_x - 2, slot_pos_y + 40)
            self.hotbars[h].slot_cost[i]:pos(right_slot_pos_x + 30, slot_pos_y + 28)
            self.hotbars[h].slot_recast_text[i]:pos(right_slot_pos_x + 20, slot_pos_y + 14)
            self.hotbars[h].slot_recast_text[i]:size(9)
        end

        -- special stuff for dpad and face buttons icons
        self.hotbars[h].slot_recast[9] = new_image(images_setup)
        self.hotbars[h].slot_recast[10] = new_image(images_setup)
    end

    -- load feedback icon last so it stays above everything else
    self.feedback_icon = new_image(images_setup)
    setup_image(self.feedback_icon, windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/feedback.png')
    self.feedback.max_opacity = theme_options.feedback_max_opacity
    self.feedback.speed = theme_options.feedback_speed
    self.feedback.current_opacity = self.feedback.max_opacity
    self.feedback_icon:hide()
    ui:update_offsets(settings.Style.OffsetX, settings.Style.OffsetY)
end

-- setup positions and dimensions for ui
function ui:setup_metrics(theme_options)
    self.hotbar_width = (400 + theme_options.slot_spacing * 9)
    self.pos_x = (windower.get_windower_settings().ui_x_res / 2) - (self.hotbar_width / 2)
    self.pos_y = (windower.get_windower_settings().ui_y_res - 120)

    self.slot_spacing = theme_options.slot_spacing

    if theme_options.hide_action_names == true then
        theme_options.hotbar_spacing = theme_options.hotbar_spacing - 10
        self.pos_y = self.pos_y + 10
    end

    self.hotbar_spacing = theme_options.hotbar_spacing
end

-- A: transform final drawing calls; saved offsets stay in screen pixels.
function ui:update_geometry_origin(move_contents)
    local screen = windower.get_windower_settings()
    local x = screen.ui_x_res / 2 - 240 * geometry.scale + (self.pos_x - (screen.ui_x_res / 2 - 240))
    local y = screen.ui_y_res - 120 * geometry.scale + (self.pos_y - (screen.ui_y_res - 120))
    geometry:set_origin(self.pos_x, self.pos_y, x, y, move_contents)
end
function ui:set_scale(scale)
    if scale ~= scale or scale == math.huge or scale == -math.huge then scale = 1 end
    geometry:set_scale(math.max(.25, math.min(2, scale)))
    self:update_geometry_origin()
end

-- A: compact is a layout change, not a reload. Keep the objects and their
-- recast crops/fade state; neither menus nor player bindings are rebuilt.
function ui:set_compact(enabled)
    if self.is_compact == enabled then return false end
    if not self.is_setup then self.is_compact = enabled; return true end
    local old = {}
    for h, bar in ipairs(self.hotbars) do
        old[h] = {}
        for i = 1, 8 do old[h][i] = {self:get_slot_x(h,i), self:get_slot_y(h,i)} end
    end
    local old_x, old_y = self:get_slot_x(1,1), self:get_slot_y(1,4)
    self.is_compact = enabled
    for h, bar in ipairs(self.hotbars) do
        for i = 1, 8 do
            local dx,dy = self:get_slot_x(h,i)-old[h][i][1], self:get_slot_y(h,i)-old[h][i][2]
            for _, objects in pairs(bar) do
                if type(objects)=='table' then geometry:move_surface(objects[i],dx,dy) end
            end
        end
        if enabled then
            bar.slot_recast[9]:hide(); bar.slot_recast[10]:hide()
        end
    end
    local dx,dy = self:get_slot_x(1,1)-old_x, self:get_slot_y(1,4)-old_y
    for name,p in pairs(geometry.primitives) do
        if p.x then prim.set_position(name,p.x+dx,p.y+dy) end
    end
    if self.feedback.is_active then
        self.feedback_icon:pos(self:get_slot_x(self.feedback.hotbar,self.feedback.slot),
            self:get_slot_y(self.feedback.hotbar,self.feedback.slot))
    end
    local base = windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/'
    self.bar_background:path(base .. (enabled and 'bar_bg_compact.png' or 'bar_bg.png'))
    self.bar_background_left:path(base .. (enabled and 'bar_bg_compact_alt.png' or 'bar_bg_alt.png'))
    self.bar_background_right:path(base .. (enabled and 'bar_bg_compact_alt.png' or 'bar_bg_alt.png'))
    self.bar_background:size(330,enabled and 180 or 220)
    -- Match a fresh layout's alternate background geometry, including upstream's
    -- noncompact size. Do not quietly redesign the alternate layout here.
    self.bar_background_left:size(enabled and 330 or 40,enabled and 180 or 40)
    self.bar_background_right:size(enabled and 330 or 40,enabled and 180 or 40)
    self.action_binder_icon:pos(self:get_slot_x(1,1)-10,self:get_slot_y(1,4)-27)
    self.action_binder_text:pos(self:get_slot_x(1,1)+35,self:get_slot_y(1,4)-15)
    self.environment_selector_icon:pos(self:get_slot_x(2,5)-5,self:get_slot_y(1,4)-27)
    self.environment_selector_text:pos(self:get_slot_x(2,5)+40,self:get_slot_y(1,4)-15)
    if enabled or not self.public_visible then self:hide_button_hints()
    else self:show_button_hints() end
    -- Background visibility is decided by the normal render; only move it now.
    local h = self.background_hotbar or 1
    self.bar_background:pos(self:get_slot_x(h,1)-30,self:get_slot_y(h,4)-35)
    self.bar_background_left:pos(self:get_slot_x(h,1)-30,self:get_slot_y(h,4)-35)
    self.bar_background_right:pos(self:get_slot_x(h,1)+(h>=5 and 430 or 290),self:get_slot_y(h,4)-35)
    geometry:refresh()
    return true
end

function ui:update_offsets(offset_x, offset_y)
    -- Every surface already belongs to geometry: move the whole bar once,
    -- including hints, recasts, costs, labels and background primitives.
    self:move_to(offset_x,offset_y)
end

function ui:move_to(offset_x,offset_y)
    local screen=windower.get_windower_settings()
    self.pos_x,self.pos_y=screen.ui_x_res/2-240+offset_x,screen.ui_y_res-120+offset_y
    -- Move every registered drawing surface, including recasts and primitives.
    self:update_geometry_origin(true)
end

function ui:get_set_chooser_anchor()
    local icon=geometry.surfaces[self.environment_selector_icon]
    local bounds=geometry:rect(icon.x,icon.y,icon.width or 40,icon.height or 40)
    return bounds.x,bounds.y+bounds.height
end

function ui:get_drag_bounds()
    local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
    for _,bar in ipairs(self.hotbars) do
        for slot=1,8 do
            local object=bar.slot_background[slot]
            local m=geometry.surfaces[object]
            if not m or not m.visible then m=geometry.surfaces[bar.slot_icon[slot]] end
            if m and m.visible and m.x then
                local b=geometry:rect(m.x,m.y,40,40)
                left,top=math.min(left,b.x),math.min(top,b.y)
                right,bottom=math.max(right,b.x+b.width),math.max(bottom,b.y+b.height)
            end
        end
    end
    if left==math.huge then return nil end
    return {x=left,y=top,width=right-left,height=bottom-top}
end

-- hide all ui components
function ui:hide()
    geometry:transition(false)
    for _, name in ipairs({'skillchain_indicator_bg','skillchain_indicator',
        'gcd_indicator_bg','gcd_indicator','aa_indicator_bg','aa_indicator_red','aa_indicator_green'}) do
        prim.set_visibility(name, false)
    end
    self.battle_notice:hide()
    self.feedback_icon:hide()

    self:hide_button_hints()

    for h=1,self.theme.hotbar_number,1 do
        for i=1,8,1 do
            self.hotbars[h].slot_background[i]:hide()
            self.hotbars[h].slot_warmup[i]:hide()
            self.hotbars[h].slot_icon[i]:hide()
            self.hotbars[h].slot_frame[i]:hide()
            self.hotbars[h].slot_recast[i]:hide()
            self.hotbars[h].slot_element[i]:hide()
            self.hotbars[h].slot_text[i]:hide()
            self.hotbars[h].slot_cost[i]:hide()
            self.hotbars[h].slot_recast_text[i]:hide()
            -- self.hotbars[h].slot_key[i]:hide()
        end

        local dpadSlot = 9;
        local faceSlot = 10;
        self.hotbars[h].slot_recast[dpadSlot]:hide()
        self.hotbars[h].slot_recast[faceSlot]:hide()
    end
    self.bar_background:hide()
    self.bar_background_left:hide()
    self.bar_background_right:hide()
end

function ui:hide_button_hints()
    self.button_hints_visible=false
    -- Hints excluded by layout must not survive a closing crossbar fade.
    self.action_binder_icon:hide(self.is_compact)
    self.action_binder_text:hide(self.is_compact)
    self.environment_selector_icon:hide(self.is_compact)
    self.environment_selector_text:hide(self.is_compact)
end

-- show ui components
function ui:show(player_hotbar, environment)
    -- A: the chooser's Add New Set entry has no hotbar to render.
    if not player_hotbar or not player_hotbar[environment] then return end
    geometry:transition(true)
    if self.theme.hide_battle_notice == false and environment == 'battle' then self.battle_notice:show() end

    self:maybe_show_button_hints()

    for h=1,self.theme.hotbar_number,1 do
        for i=1,8,1 do
            local slot = i
            if slot == 10 then slot = 0 end

            local bar = player_hotbar[environment]['hotbar_' .. h]
            local action = bar and bar['slot_' .. slot]

            if (action == nil or action.action == nil) then
                action = maybe_get_default_action(player_hotbar, environment, h, slot)
            end

            if self.theme.hide_empty_slots == false then self.hotbars[h].slot_background[i]:show() end
            self.hotbars[h].slot_icon[i]:show()
            if action ~= nil then self.hotbars[h].slot_frame[i]:show() end
            if self.theme.hide_recast_animation == false then self.hotbars[h].slot_recast[i]:show() end
            if self.theme.hide_recast_animation == false then self.hotbars[h].slot_warmup[i]:show() end
            if self.theme.hide_action_element == false then self.hotbars[h].slot_element[i]:show() end
            if self.theme.hide_action_names == false then self.hotbars[h].slot_text[i]:show() end
            if self.theme.hide_action_cost == false then self.hotbars[h].slot_cost[i]:show() end
            if self.theme.hide_recast_text == false then self.hotbars[h].slot_recast_text[i]:show() end
        end
    end
    return true
end

function ui:maybe_show_button_hints()
    if (not self.is_compact) then
        self:show_button_hints()
    else
        self:hide_button_hints()
    end
end

function ui:show_button_hints()
    if self.is_compact then self:hide_button_hints(); return end
    self.button_hints_visible=true
    self.action_binder_icon:show()
    self.action_binder_text:show()
    self.environment_selector_icon:show()
    self.environment_selector_text:show()
    if self.chooser_open then self.environment_selector_text:hide() end
end

function ui:set_chooser_open(open)
    if self.chooser_open==open then return end
    self.chooser_open=open
    if open then self.environment_selector_text:hide()
    elseif self.button_hints_visible then self.environment_selector_text:show() end
end

function ui:show_bar_background(hotbar_number)
    self.background_hotbar = hotbar_number

    self.bar_background:pos(self:get_slot_x(hotbar_number, 1) - 30, self:get_slot_y(hotbar_number, 4) - 35)
    self.bar_background_left:pos(self:get_slot_x(hotbar_number, 1) - 30, self:get_slot_y(hotbar_number, 4) - 35)

    if self.UseAltLayout then
        if hotbar_number == 3 or hotbar_number == 4 then
            self.bar_background:show()
            self.bar_background_left:hide()
            self.bar_background_right:hide()
        elseif hotbar_number == 5 or hotbar_number == 6 then
            self.bar_background_right:pos(self:get_slot_x(hotbar_number, 1) + 430, self:get_slot_y(hotbar_number, 4) - 35)
            self.bar_background:hide()
            self.bar_background_left:show()
            self.bar_background_right:show()
        elseif hotbar_number == 1 or hotbar_number == 2 then
            self.bar_background_right:pos(self:get_slot_x(hotbar_number, 1) + 290, self:get_slot_y(hotbar_number, 4) - 35)
            self.bar_background:hide()
            self.bar_background_left:show()
            self.bar_background_right:show()
        end
    else
        self.bar_background:show()
    end
end

-----------------------------
-- Actions UI
-----------------------------

-- load player hotbar
function ui:load_player_hotbar(player_hotbar, player_vitals, environment, gamepad_state)
    -- A rebuilt bar must reapply the visibility policy on the next render.
    self.public_visible = nil
    if environment == 'battle' and self.theme.hide_battle_notice == false then
        self.battle_notice:show()
    else
        self.battle_notice:hide()
    end

    -- reset disabled slots
    self.disabled_slots.actions = {}
    self.disabled_slots.no_vitals = {}
    self.disabled_slots.on_cooldown = {}
    self.disabled_slots.on_warmup = {}

    for h=1,self.theme.hotbar_number,1 do
        local isThisBarActive = gamepad_state.active_bar == h
        local isThisBarVisibleByDefault = h < 3 
        local shouldDrawDefaultVisibleBars = gamepad_state.active_bar < 3
        local shouldDrawThisBar = isThisBarActive or isThisBarVisibleByDefault and shouldDrawDefaultVisibleBars
        for slot=1,8,1 do
            local action = nil

            if (player_hotbar[environment] and player_hotbar[environment]['hotbar_' .. h] and
                player_hotbar[environment]['hotbar_' .. h]['slot_' .. slot]) then
                action = player_hotbar[environment]['hotbar_' .. h]['slot_' .. slot]
            end

            self:load_action(player_hotbar, environment, h, slot, action, player_vitals, shouldDrawThisBar)
        end
    end
end

function ui:should_show_element(element)
    return element ~= nil and element ~= 'None' and element ~= '0' and self.theme.hide_action_element == false
end

-- load action into a hotbar slot
function ui:load_action(player_hotbar, environment, hotbar, slot, action, player_vitals, show_when_ready)
    local disable_key = hotbar .. ":" .. slot
    local is_disabled = false

    local player = windower.ffxi.get_player()
    local main_job_id = player.main_job_id

    local LV_1_SP_ABILITY_RECAST_ID = 0
    local LV_96_SP_ABILITY_RECAST_ID = 254

    -- A: replace a populated caption directly. Blanking it first needlessly
    -- invalidates native glyphs even when two sets share the same action.
    self:clear_slot(hotbar, slot, true)

    local icon_overridden = false

    -- if slot is empty, check if there is an entry in the default crossbar
    if (action == nil or action.action == nil) then
        action = maybe_get_default_action(player_hotbar, environment, hotbar, slot)

        -- if default crossbar slot is empty, then hide the slot
        if (action == nil) then
            self.hotbars[hotbar].slot_text[slot]:text('')
            if self.theme.hide_empty_slots == true then
                self.hotbars[hotbar].slot_background[slot]:hide()
            else
                self.hotbars[hotbar].slot_background[slot]:show()
            end

            return
        end
    end

    local icon_path = nil

    -- Metadata lookup keys. When action.linked_type / linked_action are set
    -- (e.g. a type='ex' gear-swap command linking to a real spell), these
    -- override action.type / action.action for the purposes of deciding
    -- which resource table to query and what name to look up — so MP/TP
    -- cost, element indicator, and recast timer render as if the linked
    -- spell/ability was directly bound, while the actual command that
    -- fires (action.action) remains the user's raw command.
    local lookup_type = action.linked_type or action.type
    local lookup_name = action.linked_action or action.action

    if lookup_type == 'ma' or lookup_type == 'ja' or lookup_type == 'ws' or lookup_type == 'enchanteditem' or lookup_type == 'pet' then
        local crossbar_action = nil

        -- if slot has a skill (ma, ja, pet or ws) — or is linked to one
        if (lookup_type == 'ma' or lookup_type == 'ja' or lookup_type == 'pet' or lookup_type == 'ws') then
            if (lookup_type == 'ma') then
                crossbar_action = crossbar_spells[kebab_casify(lookup_name)]
            else
                crossbar_action = crossbar_abilities[kebab_casify(lookup_name)]
            end

            -- Guard against a typo or unknown linked_action name — without
            -- this, accessing fields on a nil crossbar_action below would
            -- crash the render loop for that slot.
            if crossbar_action ~= nil then
                icon_path, icon_overridden = maybe_get_custom_icon(crossbar_action.default_icon, crossbar_action.custom_icon)

                -- display element
                if self:should_show_element(crossbar_action.element) then
                    self.hotbars[hotbar].slot_element[slot]:path(windower.addon_path .. '/images/icons/elements/' .. crossbar_action.element .. '.png')
                    if (show_when_ready) then
                        self.hotbars[hotbar].slot_element[slot]:show()
                    end
                end

                -- display mp cost
                if crossbar_action.mp_cost ~= nil and crossbar_action.mp_cost ~= 0 then
                    self:set_mp_cost_color(hotbar,slot,player_vitals.mp < crossbar_action.mp_cost)
                    
                    if(settings.Hotbar.HideActionCost == true) then
                        self.hotbars[hotbar].slot_cost[slot]:text("")
                    else    
                        self.hotbars[hotbar].slot_cost[slot]:text(tostring(crossbar_action.mp_cost))
                    end

                    if player_vitals.mp < crossbar_action.mp_cost then
                        self.disabled_slots.no_vitals[disable_key] = true
                        is_disabled = true
                    end
                -- display tp cost
                elseif crossbar_action.tp_cost ~= nil and crossbar_action.tp_cost ~= 0 then
                    self.hotbars[hotbar].slot_cost[slot]:color(self.theme.tp_cost_color_red, self.theme.tp_cost_color_green, self.theme.tp_cost_color_blue)

                    if(settings.Hotbar.HideActionCost == true) then
                        self.hotbars[hotbar].slot_cost[slot]:text("")
                    else
                        self.hotbars[hotbar].slot_cost[slot]:text(tostring(crossbar_action.tp_cost))
                    end

                    if player_vitals.tp < crossbar_action.tp_cost then
                        self.disabled_slots.no_vitals[disable_key] = true
                        is_disabled = true
                    end
                end
            end
        end

        -- Enchanted-item special handling uses the raw action, not the
        -- linked lookup — don't try linked_type='enchanteditem'
        if (action.type == 'enchanteditem') then
            self.enchanted_items:register(action.action, action.warmup, 2, action.cooldown)
            self.hotbars[hotbar].slot_icon[slot]:pos(self:get_slot_x(hotbar, slot), self:get_slot_y(hotbar, slot))
            self.hotbars[hotbar].slot_icon[slot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/items/' .. kebab_casify(action.action) .. '.png')
        end

        self.hotbars[hotbar].slot_background[slot]:alpha(200)
        if (show_when_ready) then
            self.hotbars[hotbar].slot_icon[slot]:show()
        end
    -- if action is an item
    elseif action.type == 'item' then
        local custom_icon = 'items/' ..  kebab_casify(action.action) .. '.png'
        icon_path, icon_overridden = maybe_get_custom_icon(nil, custom_icon)
        if (icon_path == nil) then
            local item_id
            for id, item in pairs(res.items) do
                if item.en == action.action then item_id = id; break end
            end
            local extracted = item_id and item_icons.resolve(item_id)
            if extracted then
                icon_path = '/' .. extracted
            elseif (action.usable ~= nil or action.target == 'me') then
                icon_path = '/images/' .. get_icon_pathbase() .. '/usable-item.png'
            else
                icon_path = '/images/' .. get_icon_pathbase() .. '/item.png'
            end
        end

        if (show_when_ready) then
            self.hotbars[hotbar].slot_icon[slot]:show()
        end
    elseif (action.type == 'mount') then
        local default_icon = '/images/' .. get_icon_pathbase() .. '/mount.png'
        local custom_icon = 'mounts/' ..  kebab_casify(action.action) .. '.png'
        icon_path = maybe_get_custom_icon(default_icon, custom_icon)
        icon_overridden = true
    end

    -- Raw/custom commands without explicit or linked artwork get a visual
    -- blue-slot default only. Never fill the XML icon field just to render this fallback.
    if not icon_path and action.type == 'ex' and (not action.icon or action.icon == '') then
        icon_path = '/images/' .. get_icon_pathbase() .. '/none.png'
        icon_overridden = true
        self.hotbars[hotbar].slot_icon[slot]:size(40,40)
        if show_when_ready then self.hotbars[hotbar].slot_icon[slot]:show() end
    end

    if (icon_path ~= nil) then
        self.hotbars[hotbar].slot_icon[slot]:path(windower.addon_path .. icon_path)
    else
        self.hotbars[hotbar].slot_icon[slot]:hide()
    end
    -- Geometry already fits native and custom artwork to the 40px slot.
    -- The old 4px inset for native 32px icons would push it outside the frame.
    self.hotbars[hotbar].slot_icon[slot]:pos(self:get_slot_x(hotbar, slot), self:get_slot_y(hotbar, slot))

    -- if action is custom
    if (not icon_overridden and action.icon ~= nil and action.icon ~= '') then
        self.hotbars[hotbar].slot_background[slot]:alpha(200)
        self.hotbars[hotbar].slot_icon[slot]:pos(self:get_slot_x(hotbar, slot), self:get_slot_y(hotbar, slot))
        -- Old extracted cache paths are derived data: reuse the newly resolved
        -- item image/fallback instead of treating a BMP path as an iconpack stem.
        if action.type == 'item' and item_icons.is_extracted(action.icon) then
            if icon_path then self.hotbars[hotbar].slot_icon[slot]:path(windower.addon_path .. icon_path) end
        elseif action.icon:match('^/?images/') then
            self.hotbars[hotbar].slot_icon[slot]:path(windower.addon_path .. '/' .. action.icon:gsub('^/', ''))
        else
            self.hotbars[hotbar].slot_icon[slot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/' .. action.icon .. '.png')
        end
        if (show_when_ready) then
            self.hotbars[hotbar].slot_icon[slot]:show()
        end
    end

    if action.type == 'item' then
        -- A 32-pixel extracted bitmap still fills the bound 40-pixel slot.
        self.hotbars[hotbar].slot_icon[slot]:size(40, 40)
        self.hotbars[hotbar].slot_icon[slot]:pos(self:get_slot_x(hotbar, slot), self:get_slot_y(hotbar, slot))
    end

    -- check if action is on cooldown
    if self.disabled_slots.on_cooldown[disable_key] ~= nil then is_disabled = true end
    if self.disabled_slots.on_warmup[disable_key] ~= nil then is_disabled = true end

    if (show_when_ready) then
        self.hotbars[hotbar].slot_frame[slot]:show()
    end
    self.hotbars[hotbar].slot_text[slot]:text(action.alias)

    -- hide elements according to settings
    if self.theme.hide_action_names == true then
        self.hotbars[hotbar].slot_text[slot]:hide()
    elseif (show_when_ready) then
        self.hotbars[hotbar].slot_text[slot]:show()
    end
    if self.theme.hide_action_cost == true then
        self.hotbars[hotbar].slot_cost[slot]:hide()
    elseif (show_when_ready) then
        self.hotbars[hotbar].slot_cost[slot]:show()
    end

    -- if slot is disabled, disable it
    if is_disabled == true then
        self:toggle_slot(hotbar, slot, false)
        self.disabled_slots.actions[disable_key] = true
    end
end

-- reset slot
function ui:clear_slot(hotbar, slot, preserve_caption)
    self.hotbars[hotbar].slot_background[slot]:alpha(self.theme.slot_opacity)
    -- Slot surfaces outlive the action occupying them. Do not let a previous
    -- hint/recast survive a set replacement, even before the next recast pass.
    self.hotbars[hotbar].slot_frame[slot]:path(self.frame_image_path)
    self.hotbars[hotbar].slot_frame[slot]:alpha(255)
    self.hotbars[hotbar].slot_frame[slot]:hide()
    self:clear_recast(hotbar, slot)
    self.hotbars[hotbar].slot_icon[slot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blank.png')
    self.hotbars[hotbar].slot_icon[slot]:hide()
    self.hotbars[hotbar].slot_icon[slot]:alpha(255)
    self.hotbars[hotbar].slot_icon[slot]:color(255, 255, 255)
    self.hotbars[hotbar].slot_element[slot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blank.png')
    self.hotbars[hotbar].slot_element[slot]:alpha(255)
    self.hotbars[hotbar].slot_element[slot]:hide()
    if not preserve_caption then self.hotbars[hotbar].slot_text[slot]:text('') end
    self.hotbars[hotbar].slot_cost[slot]:alpha(255)
    self.hotbars[hotbar].slot_cost[slot]:text('')
end

-----------------------------
-- Disabled Slots
-----------------------------

-- check player vitals
function ui:set_mp_cost_color(hotbar,slot,insufficient)
    local prefix = insufficient and 'mp_cost_insufficient_' or 'mp_cost_color_'
    self.hotbars[hotbar].slot_cost[slot]:color(self.theme[prefix..'red'],
        self.theme[prefix..'green'],self.theme[prefix..'blue'])
end

function ui:check_vitals(player_hotbar, player_vitals, environment)
    local selected=player_hotbar and player_hotbar[environment]
    if not selected then return end
    for h=1,self.theme.hotbar_number,1 do
        for i=1,8,1 do
            local disable_key = h .. ":" .. i
            local slot = i
            if slot == 10 then slot = 0 end

            local bar=selected['hotbar_' .. h]
            local action=bar and bar['slot_' .. slot]

            -- use the default action if this slot is otherwise empty
            if (action == nil or action.action == nil) then
                action = maybe_get_default_action(player_hotbar, environment, h, slot)
            end

            if action ~= nil then
                local crossbar_action = nil
                local is_disabled = false

                -- Honor linked_type / linked_action for the metadata lookup
                -- (MP/TP affordability, recast keying). See display_slot for
                -- the full rationale.
                local lookup_type = action.linked_type or action.type
                local lookup_name = action.linked_action or action.action

                -- if its magic, look for it in spells
                if (lookup_type == 'ma') then
                    crossbar_action = crossbar_spells[kebab_casify(lookup_name)]
                elseif (lookup_type == 'ja' or lookup_type == 'ws') then
                    crossbar_action = crossbar_abilities[kebab_casify(lookup_name)]
                end

                if (crossbar_action ~= nil) then
                    local can_afford_mp = crossbar_action.mp_cost ~= nil and crossbar_action.mp_cost ~= '0' and player_vitals.mp < crossbar_action.mp_cost
                    local can_afford_tp = crossbar_action.tp_cost ~= nil and crossbar_action.tp_cost ~= '0' and player_vitals.tp < crossbar_action.tp_cost
                    -- A: color depends specifically on MP, not every reason an
                    -- icon is dimmed. MP recovery restores green during recast.
                    if crossbar_action.mp_cost and crossbar_action.mp_cost > 0 then
                        self:set_mp_cost_color(h,i,can_afford_mp)
                    end
                    if (can_afford_mp or can_afford_tp) then
                        self.disabled_slots.no_vitals[disable_key] = true
                        is_disabled = true
                    else
                        self.disabled_slots.no_vitals[disable_key] = nil
                    end

                    -- if it's not disabled by vitals nor cooldown, enable slot
                    if is_disabled == false and self.disabled_slots.actions[disable_key] == true and self.disabled_slots.on_cooldown[disable_key] == nil and self.disabled_slots.on_warmup[disable_key] == nil then
                        self.disabled_slots.actions[disable_key] = nil
                        self:toggle_slot(h, i, true)
                    end

                    -- if its disabled, disable slot
                    if is_disabled == true and self.disabled_slots.actions[disable_key] == nil then
                        self.disabled_slots.actions[disable_key] = true
                        self:toggle_slot(h, i, false)
                    end
                end
            end
        end
    end
end

local skillchain_indicator_state = ''
gcd_start_time = 0
gcd_duration = 2.8
gcd_active = false
gcd_kind = 'spell' -- one of: 'spell' (3.0s, bluish-white → green at end),
                  --         'ws'    (2.0s, amber),
                  --         'ja'    (2.0s, red for first 1.0s then green)

function ui:display_skillchain_indicator(player_vitals, skillchain_delay, skillchain_window)
    -- A: opacity zero disables the entire indicator, including its backing.
    if self.theme.skillchain_window_opacity == 0 then
        prim.set_visibility('skillchain_indicator',false)
        prim.set_visibility('skillchain_indicator_bg',false)
        return
    end
    local target = windower.ffxi.get_mob_by_target('t', 'bt')
    if (target and target.hpp > 0) then
        if (skillchain_delay > 0) then
            local fraction = skillchain_delay / 3.0
            local base_width = math.round(600 * (1 - fraction))
            local left_spacer = math.round(300 * fraction)

            if (skillchain_indicator_state ~= 'waiting') then
                skillchain_indicator_state = 'waiting'
                prim.set_color('skillchain_indicator',
                    self.theme.skillchain_window_opacity,
                    self.theme.skillchain_waiting_color_red,
                    self.theme.skillchain_waiting_color_green,
                    self.theme.skillchain_waiting_color_blue)
            end
            prim.set_size('skillchain_indicator', base_width, 4)
            prim.set_position('skillchain_indicator', left_spacer + self:get_slot_x(1, 1) - 10, self:get_slot_y(1, 4) - 27)
            prim.set_visibility('skillchain_indicator', true)

            prim.set_size('skillchain_indicator_bg', base_width + 4, 8)
            prim.set_position('skillchain_indicator_bg', left_spacer + self:get_slot_x(1, 1) - 12, self:get_slot_y(1, 4) - 29)
            prim.set_visibility('skillchain_indicator_bg', true)
        elseif (skillchain_window > 0) then
            local fraction = skillchain_window / 7.0
            local base_width = math.round(600 * fraction)
            local left_spacer = math.round(300 * (1 - fraction))

            if (skillchain_indicator_state ~= 'open') then
                skillchain_indicator_state = 'open'
                prim.set_color('skillchain_indicator',
                    self.theme.skillchain_window_opacity,
                    self.theme.skillchain_open_color_red,
                    self.theme.skillchain_open_color_green,
                    self.theme.skillchain_open_color_blue)
            end
            prim.set_size('skillchain_indicator', base_width, 10)
            prim.set_position('skillchain_indicator', left_spacer + self:get_slot_x(1, 1) - 10, self:get_slot_y(1, 4) - 30)
            prim.set_visibility('skillchain_indicator', true)

            prim.set_size('skillchain_indicator_bg', base_width + 4, 14)
            prim.set_position('skillchain_indicator_bg', left_spacer + self:get_slot_x(1, 1) - 12, self:get_slot_y(1, 4) - 32)
            prim.set_visibility('skillchain_indicator_bg', true)
        else
            prim.set_visibility('skillchain_indicator', false)
            prim.set_visibility('skillchain_indicator_bg', false)
        end
    else
        prim.set_visibility('skillchain_indicator', false)
        prim.set_visibility('skillchain_indicator_bg', false)
    end
end

function ui:display_gcd_indicator()
    if gcd_active then
        local elapsed = os.clock() - gcd_start_time
        local remaining = gcd_duration - elapsed

        if remaining > 0 then
            local fraction = remaining / gcd_duration
            local base_width = math.round(600 * fraction)
            local left_spacer = math.round(300 * (1 - fraction))

            local alpha, cr, cg, cb
            if gcd_kind == 'ws' then
                alpha = self.theme.ws_lockout_opacity
                cr = self.theme.ws_lockout_primary_red
                cg = self.theme.ws_lockout_primary_green
                cb = self.theme.ws_lockout_primary_blue
            elseif gcd_kind == 'ja' then
                alpha = self.theme.ja_lockout_opacity
                if elapsed < 1.0 then
                    cr = self.theme.ja_lockout_full_red
                    cg = self.theme.ja_lockout_full_green
                    cb = self.theme.ja_lockout_full_blue
                else
                    cr = self.theme.ja_lockout_partial_red
                    cg = self.theme.ja_lockout_partial_green
                    cb = self.theme.ja_lockout_partial_blue
                end
            else
                alpha = self.theme.spell_lockout_opacity
                if fraction < 0.15 then
                    cr = self.theme.spell_lockout_ending_red
                    cg = self.theme.spell_lockout_ending_green
                    cb = self.theme.spell_lockout_ending_blue
                else
                    cr = self.theme.spell_lockout_primary_red
                    cg = self.theme.spell_lockout_primary_green
                    cb = self.theme.spell_lockout_primary_blue
                end
            end

            if alpha == 0 then
                -- Per-mode opacity 0 = hide this mode's bar entirely.
                prim.set_visibility('gcd_indicator', false)
                prim.set_visibility('gcd_indicator_bg', false)
                return
            end

            prim.set_color('gcd_indicator', alpha, cr, cg, cb)

            local effective_y_offset = self.gcd_offset_y
            if not self.is_compact then
                effective_y_offset = effective_y_offset + self.hotbar_spacing
            end

            prim.set_size('gcd_indicator', base_width, 6)
            prim.set_position(
                'gcd_indicator',
                left_spacer + self:get_slot_x(1, 1) - 10 + self.gcd_offset_x,
                self:get_slot_y(1, 4) + effective_y_offset
            )
            prim.set_visibility('gcd_indicator', true)

            prim.set_size('gcd_indicator_bg', base_width + 4, 10)
            prim.set_position(
                'gcd_indicator_bg',
                left_spacer + self:get_slot_x(1, 1) - 12 + self.gcd_offset_x,
                self:get_slot_y(1, 4) + effective_y_offset - 2
            )
            prim.set_visibility('gcd_indicator_bg', true)
        else
            gcd_active = false
            prim.set_visibility('gcd_indicator', false)
            prim.set_visibility('gcd_indicator_bg', false)
        end
    else
        prim.set_visibility('gcd_indicator', false)
        prim.set_visibility('gcd_indicator_bg', false)
    end
end

-- Hide all three auto-attack bar primitives.
function ui:hide_aa_indicator(immediate)
    prim.set_visibility('aa_indicator_red', false, immediate)
    prim.set_visibility('aa_indicator_green', false, immediate)
    prim.set_visibility('aa_indicator_bg', false, immediate)
end

function ui:set_autoattack_enabled(enabled)
    self.autoattack:set_enabled(enabled)
    if not enabled and self.is_setup then self:hide_aa_indicator(true) end
end

function ui:display_aa_indicator()
    local tracker = self.autoattack
    if not tracker.enabled or not tracker.engaged then
        self:hide_aa_indicator()
        return
    end

    -- A: opacity zero skips drawing; Enabled is the independent processing switch.
    if (self.theme.aa_opacity == 0) then
        self:hide_aa_indicator()
        return
    end

    -- Active elapsed time = wall-clock elapsed minus accumulated pauses
    -- (and minus any in-progress pause).
    local active_elapsed = tracker:elapsed()

    -- Determine total bar duration and the estimate cutoff.
    local total_duration
    local estimate_cut
    if (tracker.estimate == nil) then
        total_duration = 10
        estimate_cut = 10  -- fallback: entire bar is red until two hits
    else
        total_duration = 1.5 * tracker.estimate
        estimate_cut = tracker.estimate
    end

    if (active_elapsed >= total_duration) then
        -- Timer has run beyond the visible window (stuck, no swings happening).
        self:hide_aa_indicator()
        return
    end

    -- How much of the original red/green portions remains (in seconds).
    local red_remaining = estimate_cut - active_elapsed
    if (red_remaining < 0) then red_remaining = 0 end
    local green_total = total_duration - estimate_cut  -- original green segment length
    local green_shrink = active_elapsed - estimate_cut  -- how much of the green has been "consumed" if we're past the estimate
    if (green_shrink < 0) then green_shrink = 0 end
    local green_remaining = green_total - green_shrink
    if (green_remaining < 0) then green_remaining = 0 end

    -- Width in pixels (600 total, matches GCD/skillchain bar scale).
    local red_px = math.round(600 * (red_remaining / total_duration))
    local green_px = math.round(600 * (green_remaining / total_duration))
    local visible_px = red_px + green_px
    if (visible_px <= 0) then
        self:hide_aa_indicator()
        return
    end

    -- Symmetric contraction: compute left edge so the combined bar is centered.
    local left_spacer = math.round((600 - visible_px) / 2)
    local base_x = self:get_slot_x(1, 1) - 10 + self.aa_offset_x
    local effective_y_offset = self.aa_offset_y
    if not self.is_compact then
        effective_y_offset = effective_y_offset + self.hotbar_spacing
    end
    local base_y = self:get_slot_y(1, 4) + effective_y_offset
    local red_x = left_spacer + base_x
    local green_x = red_x + red_px

    -- Alpha and color come from settings. PausedOpacity / PausedBackgroundOpacity
    -- apply when WS/JA/debuff freezes the timer (gives a dimmed look so the
    -- user can tell at a glance that the bar is frozen).
    local alpha = tracker:is_paused() and self.theme.aa_paused_opacity or self.theme.aa_opacity
    local bg_alpha = tracker:is_paused() and self.theme.aa_paused_background_opacity or self.theme.aa_background_opacity
    prim.set_color('aa_indicator_red', alpha,
        self.theme.aa_before_red, self.theme.aa_before_green, self.theme.aa_before_blue)
    prim.set_color('aa_indicator_green', alpha,
        self.theme.aa_past_red, self.theme.aa_past_green, self.theme.aa_past_blue)
    prim.set_color('aa_indicator_bg', bg_alpha, 0, 0, 0)

    -- A: round only the combined bar's outer ends; its two colors meet flush.
    prim.set_rounding('aa_indicator_red', true, green_px == 0)
    prim.set_rounding('aa_indicator_green', red_px == 0, true)

    if (red_px > 0) then
        prim.set_size('aa_indicator_red', red_px, 6)
        prim.set_position('aa_indicator_red', red_x, base_y)
        prim.set_visibility('aa_indicator_red', true)
    else
        prim.set_visibility('aa_indicator_red', false)
    end

    if (green_px > 0) then
        prim.set_size('aa_indicator_green', green_px, 6)
        prim.set_position('aa_indicator_green', green_x, base_y)
        prim.set_visibility('aa_indicator_green', true)
    else
        prim.set_visibility('aa_indicator_green', false)
    end

    prim.set_size('aa_indicator_bg', visible_px + 4, 10)
    prim.set_position('aa_indicator_bg', red_x - 2, base_y - 2)
    prim.set_visibility('aa_indicator_bg', true)
end

local last_log = os.clock()

function ui:mark_default_set_action(h, i, environment)
    if (environment ~= nil) then
        self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/' .. environment ..'.png')
        self.hotbars[h].slot_recast[i]:alpha(255)
        self.hotbars[h].slot_recast[i]:size(40, 40)
        self.hotbars[h].slot_recast[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
        self.hotbars[h].slot_recast[i]:show()
        self.hotbars[h].slot_recast_text[i]:hide()
        self.hotbars[h].slot_cost[i]:hide()
    end
end

-- check action recasts
function ui:check_recasts(player_hotbar, player_vitals, environment, spells, gamepad_state, skillchains, consumables, dim_default_slots, in_battle)
    animation_frame_count = animation_frame_count + self.frame_skip + 1
    if (animation_frame_count > 40) then
        animation_frame_count = 1
    end

    dim_default_slots = dim_default_slots or false

    local skillchain_delay, skillchain_window = skillchains.get_skillchain_window()
    self:display_skillchain_indicator(player_vitals, skillchain_delay, skillchain_window)
    self:display_gcd_indicator()
    if self.autoattack.enabled then self:display_aa_indicator() end

    if (gamepad_state.active_bar ~= 0) then
        self:show_bar_background(gamepad_state.active_bar)
    else
        self.bar_background:hide()
        self.bar_background_left:hide()
        self.bar_background_right:hide()
    end

    for h=1,self.theme.hotbar_number,1 do
        local isThisBarActive = gamepad_state.active_bar == h
        local isThisBarVisibleByDefault
        local shouldDrawDefaultVisibleBars
        if not self.AutoHideExtraBars then
            isThisBarVisibleByDefault = h < 3 or h > 4
            shouldDrawDefaultVisibleBars = gamepad_state.active_bar < 3 or gamepad_state.active_bar > 4
        else
            isThisBarVisibleByDefault = h < 3
            shouldDrawDefaultVisibleBars = gamepad_state.active_bar < 3
        end
        local shouldDrawThisBar = isThisBarActive or isThisBarVisibleByDefault and shouldDrawDefaultVisibleBars
        if (shouldDrawThisBar) then
            for i=1,8,1 do
                local slot = i
                if slot == 10 then slot = 0 end

                -- The overlay is shared by SC hints and item warmup. Only the
                -- current action may reveal it below (a burst uses just a frame).
                self.hotbars[h].slot_warmup[i]:hide()
                self.hotbars[h].slot_background[i]:show()
                self.hotbars[h].slot_icon[i]:show()
                self.hotbars[h].slot_frame[i]:show()
                self.hotbars[h].slot_element[i]:show()
                self.hotbars[h].slot_text[i]:show()
                self.hotbars[h].slot_cost[i]:show()

                local disable_key = h .. ":" .. i
                local action = nil
                if (player_hotbar[environment] and player_hotbar[environment]['hotbar_' .. h]) then
                    action = player_hotbar[environment]['hotbar_' .. h]['slot_' .. slot]
                end

                if (action == nil or action.action == nil) then
                    action = maybe_get_default_action(player_hotbar, environment, h, slot)
                end

                if (action ~= nil and action.type == 'a' and action.action == 'a' and action.alias == 'Attack') then
                    if (in_battle) then
                        self.hotbars[h].slot_icon[i]:path(windower.addon_path..'/images/' .. get_icon_pathbase() .. '/disengage.png')
                        self.hotbars[h].slot_text[i]:text('Disengage')
                    else
                        self.hotbars[h].slot_icon[i]:path(windower.addon_path..'/images/' .. get_icon_pathbase() .. '/attack.png')
                        self.hotbars[h].slot_text[i]:text('Attack')
                    end
                    self.hotbars[h].slot_icon[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
                elseif (action ~= nil and action.type == 'ta' and action.action == 'Switch Target' and action.alias == 'Switch Target') then
                    if (in_battle) then
                        self.hotbars[h].slot_icon[i]:path(windower.addon_path..'/images/' .. get_icon_pathbase() .. '/switchtarget.png')
                        self.hotbars[h].slot_text[i]:text('Switch Target')
                    else
                        self.hotbars[h].slot_icon[i]:path(windower.addon_path..'/images/' .. get_icon_pathbase() .. '/targetnpc.png')
                        self.hotbars[h].slot_text[i]:text('Target NPC')
                    end
                    self.hotbars[h].slot_icon[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
                elseif (action ~= nil and action.type == 'map') then
                    self.hotbars[h].slot_icon[i]:path(windower.addon_path..'/images/' .. get_icon_pathbase() .. '/map.png')
                    self.hotbars[h].slot_icon[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
                end

                -- Honor linked_type so an action that LINKS to a spell/ability/WS
                -- enters the recast-tracking branch below even though its own
                -- type is e.g. 'ex' (gear-swap command). Without this the gate
                -- bails before the recast code can look up the linked metadata.
                local effective_type = action and (action.linked_type or action.type) or nil
                if action == nil or (effective_type ~= 'ma' and effective_type ~= 'ja' and effective_type ~= 'ws' and effective_type ~= 'pet' and effective_type ~= 'enchanteditem') then
                    self.hotbars[h].slot_frame[i]:path(self.frame_image_path)
                    self.hotbars[h].slot_frame[i]:alpha(255)
                    self:clear_recast(h, i)
                    if (action ~= nil and action.type == 'item') then
                        local item_count = consumables:get_item_count_by_name(action.action)
                        if (item_count ~= nil) then
                            local display_count = item_count .. ''
                            self.hotbars[h].slot_cost[i]:text(display_count)
                            if (item_count > 1) then
                                self.hotbars[h].slot_cost[i]:color(0, 255, 0)
                            else
                                self.hotbars[h].slot_cost[i]:color(255, 0, 0)
                                has_spell = false
                            end
                            self.hotbars[h].slot_cost[i]:show()
                        else
                            self.hotbars[h].slot_cost[i]:hide()
                        end
                    end

                    -- Mark which actions came from a default set, if any, when the gamepad assigner is open
                    if (action ~= nil and action.source_environment ~= environment and dim_default_slots) then
                        self:mark_default_set_action(h, i, action.source_environment)
                    end
                else
                    local crossbar_action = nil
                    local skill_recasts = nil
                    local in_cooldown = false
                    local in_warmup = false
                    local is_in_seconds = false
                    local has_spell = true
                    local spell_requires_ja = false

                    local skillchain_prop = nil
                    local property_type = nil

                    -- Honor linked_type / linked_action for metadata lookup.
                    -- action.action still drives the ninja-tool / COR-gun
                    -- special cases below because those are tied to the
                    -- actual command text, not the linked reference.
                    local lookup_type = action.linked_type or action.type
                    local lookup_name = action.linked_action or action.action

                    -- if its magic, look for it in spells
                    if lookup_type == 'ma' then
                        crossbar_action = crossbar_spells[kebab_casify(lookup_name)]
                        if (crossbar_action ~= nil) then
                            skill_recasts = windower.ffxi.get_spell_recasts()
                            has_spell = crossbar_action.category ~= "blue magic" or spells[(lookup_name):lower()]

                            if (player.main_job == 'NIN' or player.sub_job == 'NIN') then
                                local tool_info = consumables:get_ninja_spell_info(crossbar_action.id)
                                -- if (tool_info ~= nil and tool_info.tool_count ~= nil and tool_info.master_tool_count ~= nil) then
                                if (tool_info ~= nil) then
                                    local total_tool_count
                                    if player.main_job == 'NIN' then
                                        total_tool_count = tool_info.tool_count + tool_info.master_tool_count
                                    else
                                        total_tool_count = tool_info.tool_count
                                    end
                                    local display_count = total_tool_count .. ''
                                    if (total_tool_count > 99) then
                                        display_count = '99+'
                                    end
                                    self.hotbars[h].slot_cost[i]:text(display_count)
                                    if (tool_info.tool_count > 50) then
                                        self.hotbars[h].slot_cost[i]:color(0, 255, 0)
                                    elseif (total_tool_count > 50) then
                                        self.hotbars[h].slot_cost[i]:color(255, 255, 0)
                                    else
                                        self.hotbars[h].slot_cost[i]:color(255, 0, 0)
                                    end
                                    self.hotbars[h].slot_cost[i]:show()

                                    if (total_tool_count == 0) then
                                        -- set up "Xed-out" element
                                        self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/red-x.png')
                                        self.hotbars[h].slot_recast[i]:alpha(150)
                                        self.hotbars[h].slot_recast[i]:size(40, 40)
                                        self.hotbars[h].slot_recast[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
                                        self.hotbars[h].slot_recast[i]:show()
                                        self.hotbars[h].slot_recast_text[i]:hide()
                                    end
                                end
                            end

                            -- If it is Blue Magic, check if Azure Lore / Chain Affinity / Burst Affinity is active
                            -- and if the spell is Skillchain / Magic Burst eligible
                            if crossbar_action.category == "blue magic" then
                                if buff_active["chain_affinity"] and not buff_active["burst_affinity"] then
                                    skillchain_prop, property_type = skillchains.get_skillchain_result(crossbar_action.id, 'blue_chain_spells')
                                elseif not buff_active["chain_affinity"] and buff_active["burst_affinity"] then
                                    skillchain_prop, property_type = skillchains.get_skillchain_result(crossbar_action.id, 'blue_burst_spells')
                                elseif (buff_active["chain_affinity"] and buff_active["burst_affinity"]) or buff_active["azure_lore"] then
                                    -- Those will never override each other. A single blue magic spell is always either chain or burst eligible
                                    local property_1, property_type_1 = skillchains.get_skillchain_result(crossbar_action.id, 'blue_chain_spells')
                                    local property_2, property_type_2 = skillchains.get_skillchain_result(crossbar_action.id, 'blue_burst_spells')

                                    if property_1 then
                                        skillchain_prop = property_1
                                        property_type = property_type_1
                                    elseif property_2 then
                                        skillchain_prop = property_2
                                        property_type = property_type_2
                                    end
                                end
                            -- If it's not Blue Magic, look for Magic Burst properties. If Immanence is active, look for Skillchain properties instead
                            else
                                if buff_active["immanence"] then
                                    skillchain_prop, property_type = skillchains.get_skillchain_result(crossbar_action.id, 'immanence_spells')
                                else
                                    skillchain_prop, property_type = skillchains.get_skillchain_result(crossbar_action.id, 'spells')
                                end
                            end
                        end
                    elseif (lookup_type == 'ja' or lookup_type == 'ws' or lookup_type == 'pet') then
                        crossbar_action = crossbar_abilities[kebab_casify(lookup_name)]
                        if (crossbar_action ~= nil) then
                            if (lookup_type == 'ws') then
                                skillchain_prop, property_type = skillchains.get_skillchain_result(crossbar_action.id, 'weapon_skills')
                            elseif (lookup_type == 'ja' or lookup_type == 'pet') then
                                -- Check if Swipe / Lunge are able to Magic Burst
                                if crossbar_action.id == ACTION_IDS["swipe"] then
                                    if last_active_rune then
                                        skillchain_prop, property_type = skillchains.get_skillchain_result(last_active_rune, 'runes')
                                    end
                                elseif crossbar_action.id == ACTION_IDS["lunge"] then
                                    -- Iterate over all active runes to see if one of them is able to Magic Burst.
                                    -- As soon as one is found, break the loop. There is no need to check the others as the UI display is always the same.
                                    for rune_name, is_active in pairs(rune_active) do
                                        if is_active then
                                            skillchain_prop, property_type = skillchains.get_skillchain_result(RUNE_SKILL_INDEX[rune_name], 'runes')
                                            if skillchain_prop then
                                                break
                                            end
                                        end
                                    end
                                else
                                    skillchain_prop, property_type = skillchains.get_skillchain_result(crossbar_action.id, 'job_abilities')
                                end

                                if (player.main_job == 'COR' or player.sub_job == 'COR') then
                                    local tool_info = consumables:get_ability_info_by_name(kebab_casify(action.action))
                                    if (tool_info ~= nil and tool_info.tool_count ~= nil and tool_info.master_tool_count ~= nil) then

                                        local total_tool_count = tool_info.tool_count + tool_info.master_tool_count
                                        local display_count = total_tool_count .. ''
                                        if (total_tool_count > 99) then
                                            display_count = '99+'
                                        end
                                        self.hotbars[h].slot_cost[i]:text(display_count)
                                        if (tool_info.tool_count > 50) then
                                            self.hotbars[h].slot_cost[i]:color(0, 255, 0)
                                        elseif (total_tool_count > 50) then
                                            self.hotbars[h].slot_cost[i]:color(255, 255, 0)
                                        else
                                            self.hotbars[h].slot_cost[i]:color(255, 0, 0)
                                        end
                                        self.hotbars[h].slot_cost[i]:show()

                                        if (total_tool_count == 0) then
                                            -- set up "Xed-out" element
                                            self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/red-x.png')
                                            self.hotbars[h].slot_recast[i]:alpha(150)
                                            self.hotbars[h].slot_recast[i]:size(40, 40)
                                            self.hotbars[h].slot_recast[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
                                            self.hotbars[h].slot_recast[i]:show()
                                            self.hotbars[h].slot_recast_text[i]:hide()
                                        end
                                    end
                                end

                                if (player.main_job == 'SCH' or player.sub_job == 'SCH') then
                                    -- Stratagem charges scale with SCH level: 1 charge at 10, then
                                    -- +1 every 20 levels through 99 (5 max). +1 gift unlocks at 550 JP.
                                    -- The map's keys correspond to total-charges values; indexing it with
                                    -- 0 or a value outside [1,6] yields nil and crashes the divide below.
                                    local strat_charge_time = {[1]=240,[2]=120,[3]=80,[4]=60,[5]=48,[6]=33}
                                    local level = nil
                                    if player.main_job == 'SCH' then
                                        level = player.main_job_level
                                    elseif player.sub_job == 'SCH' then
                                        level = player.sub_job_level
                                    end

                                    -- If you login as a SCH, or if you switch into a low-level SCH that 
                                    -- has no stratagem count, the addon would have crashed previously.
                                    if (level ~= nil and level >= 10) then
                                        local max = math.floor(((level - 10) / 20) + 1)
                                        local gift = 0
                                        local jp_spent = player.sch_jp_spent or 0
                                        if (player.main_job == 'SCH' and jp_spent >= 550) then
                                            gift = 1
                                        end
                                        -- Clamp the final lookup index to the valid range as a
                                        -- final safety net (e.g. unexpected levels above 99).
                                        local idx = math.max(1, math.min(6, max + gift))
                                        local charge_time = strat_charge_time[idx]
                                        if (charge_time ~= nil and charge_time > 0) then
                                            local recastTime = windower.ffxi.get_ability_recasts()[231] or 0
                                            local used = (recastTime / charge_time):ceil()
                                            local display_count = tostring(max - used)
                                            if consumables:get_strategem_required(action.action) then
                                                self.hotbars[h].slot_cost[i]:text(display_count)
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        skill_recasts = windower.ffxi.get_ability_recasts()
                        is_in_seconds = true
                    elseif (action.type == 'enchanteditem') then
                        local warmup_fraction = self.enchanted_items:get_warmup_fraction(action.action)
                        in_warmup = warmup_fraction < 1 or self.disabled_slots.on_warmup[disable_key]

                        if in_warmup then
                            -- register first cooldown to calculate percentage
                            if self.disabled_slots.on_warmup[disable_key] == nil then
                                self.disabled_slots.on_warmup[disable_key] = self.enchanted_items:get_warmup_time(action.action)

                                -- setup recast elements
                                self.hotbars[h].slot_warmup[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blue-square.png')
                            end
                        end

                        local cooldown_fraction = self.enchanted_items:get_cooldown_fraction(action.action)
                        in_cooldown = cooldown_fraction > 0

                        if in_cooldown then
                            -- remove the warmup backdrop
                            self.disabled_slots.on_warmup[disable_key] = nil
                            self.hotbars[h].slot_warmup[i]:hide()

                            -- register first cooldown to calculate percentage
                            if self.disabled_slots.on_cooldown[disable_key] == nil then
                                self.disabled_slots.on_cooldown[disable_key] = self.enchanted_items:get_cooldown_time(action.action)

                                -- setup recast elements
                                self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/black-square.png')
                            end
                        end

                        is_in_seconds = true
                    end

                    -- check if skill is in cooldown
                    if (has_spell and crossbar_action ~= nil and skill_recasts[crossbar_action.recast_id] ~= nil and skill_recasts[crossbar_action.recast_id] > 0) then
                        -- register first cooldown to calculate percentage
                        if self.disabled_slots.on_cooldown[disable_key] == nil then
                            self.disabled_slots.on_cooldown[disable_key] = skill_recasts[crossbar_action.recast_id]

                            -- setup recast elements
                            self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/black-square.png')
                        end

                        in_cooldown = true
                    end

                    -- if skill is in cooldown
                    if in_cooldown then
                        -- disable slot if it's not disabled
                        if self.disabled_slots.actions[disable_key] == nil then
                            self.disabled_slots.actions[disable_key] = true
                            self:toggle_slot(h, i, false)
                        end

                        -- show recast animation
                        if self.theme.hide_recast_animation == false or self.theme.hide_recast_text == false then
                            local time_remaining = 0

                            local new_height = 40
                            if (action.type == 'enchanteditem') then
                                time_remaining = self.enchanted_items:get_cooldown_fraction(action.action) * self.enchanted_items:get_cooldown_time(action.action)
                                new_height = 40 * self.enchanted_items:get_cooldown_fraction(action.action)
                            else
                                time_remaining = skill_recasts[crossbar_action.recast_id]
                                local full_recast = tonumber(self.disabled_slots.on_cooldown[disable_key])
                                new_height = 40 * (time_remaining / full_recast)
                            end
                            if new_height > 40 then new_height = 40 end -- temporary bug fix
                            local recast_time = calc_recast_time(time_remaining, is_in_seconds)

                            -- show recast if settings allow it
                            if self.theme.hide_recast_animation == false then
                                self.hotbars[h].slot_recast[i]:alpha(150)
                                self.hotbars[h].slot_recast[i]:size(40, new_height)
                                self.hotbars[h].slot_recast[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i) + (40 - new_height))
                                self.hotbars[h].slot_recast[i]:show()
                            end

                            if (has_spell and self.theme.hide_recast_text == false) then
                                self.hotbars[h].slot_recast_text[i]:text(recast_time)
                                self.hotbars[h].slot_recast_text[i]:show()
                            else
                                self.hotbars[h].slot_recast_text[i]:hide()
                            end
                        end
                    elseif in_warmup then
                        self.disabled_slots.actions[disable_key] = true
                        self:toggle_slot(h, i, false)
                        -- show recast animation
                        if self.theme.hide_recast_animation == false then
                            local new_height = 40 * self.enchanted_items:get_warmup_fraction(action.action)
                            if new_height > 40 then new_height = 40 end -- temporary bug fix

                            -- show recast if settings allow it
                            if self.theme.hide_recast_animation == false then
                                self.hotbars[h].slot_warmup[i]:alpha(255)
                                self.hotbars[h].slot_warmup[i]:size(40, new_height)
                                self.hotbars[h].slot_warmup[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i) + (40 - new_height))
                                self.hotbars[h].slot_warmup[i]:show()
                            end
                        end
                    elseif not has_spell then
                        if (action.source_environment == environment or not dim_default_slots) then
                            if spellsThatRequireJA:contains((action.action):lower()) then
                                -- set up "needs JA" element
                                self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/needs_job_ability.png')
                            else
                                -- set up "Xed-out" element
                                self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/red-x.png')
                            end
                            self.hotbars[h].slot_recast[i]:alpha(150)
                            self.hotbars[h].slot_recast[i]:size(40, 40)
                            self.hotbars[h].slot_recast[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
                            self.hotbars[h].slot_recast[i]:show()
                            self.hotbars[h].slot_recast_text[i]:hide()
                        end
                    else
                        -- clear recast animation
                        self:clear_recast(h, i)

                        if self.disabled_slots.on_cooldown[disable_key] ~= nil then
                            self.disabled_slots.on_cooldown[disable_key] = nil
                        end

                        -- if it's not disabled by vitals nor cooldown, enable slot
                        if self.disabled_slots.actions[disable_key] == true and self.disabled_slots.no_vitals[disable_key] == nil then
                            self.disabled_slots.actions[disable_key] = nil
                            self:toggle_slot(h, i, true)
                        end
                    end

                    -- Restore even during an item warmup or missing metadata.
                    -- Do not switch to the base texture and back every frame
                    -- while a valid animated hint is still active.
                    if skillchain_prop == nil then
                        self.hotbars[h].slot_frame[i]:path(self.frame_image_path)
                        self.hotbars[h].slot_frame[i]:alpha(255)
                    end
                    -- Show skillchain indicator if WS has a compatible skillchain property
                    if (skillchain_prop ~= nil) then
                        local frame_step = 1
                        if (animation_frame_count > 35) then
                            frame_step = 8
                        elseif (animation_frame_count > 30) then
                            frame_step = 7
                        elseif (animation_frame_count > 25) then
                            frame_step = 6
                        elseif (animation_frame_count > 20) then
                            frame_step = 5
                        elseif (animation_frame_count > 15) then
                            frame_step = 4
                        elseif (animation_frame_count > 10) then
                            frame_step = 3
                        elseif (animation_frame_count > 5) then
                            frame_step = 2
                        end

                        if (property_type == "burst") then
							self.hotbars[h].slot_warmup[i]:alpha(255)
                            self.hotbars[h].slot_frame[i]:alpha(255)
						elseif ((player_vitals.tp >= 1000) and (property_type == "skillchain")) then
                            self.hotbars[h].slot_warmup[i]:alpha(255)
                            self.hotbars[h].slot_frame[i]:alpha(255)
                            self.hotbars[h].slot_icon[i]:hide()
                            self.hotbars[h].slot_cost[i]:hide()
                        else
                            self.hotbars[h].slot_warmup[i]:alpha(75)
                            self.hotbars[h].slot_frame[i]:alpha(150)
                            self.hotbars[h].slot_icon[i]:hide()
                            self.hotbars[h].slot_cost[i]:show()
                        end

                        self.hotbars[h].slot_frame[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/frame_step' .. frame_step .. '.png')

                        if (property_type == "skillchain") then
                            self.hotbars[h].slot_warmup[i]:path(windower.addon_path..'/images/' .. get_icon_pathbase() .. '/skillchain/' .. skillchain_prop:lower() .. '.png')
                            self.hotbars[h].slot_warmup[i]:size(40, 40)
                            self.hotbars[h].slot_warmup[i]:pos(self:get_slot_x(h, i), self:get_slot_y(h, i))
                            self.hotbars[h].slot_warmup[i]:show()
                            self.hotbars[h].slot_icon[i]:hide()
                        end
                    elseif (not in_warmup) then
                        self.hotbars[h].slot_frame[i]:path(self.frame_image_path)
                        self.hotbars[h].slot_icon[i]:show()
                        self.hotbars[h].slot_warmup[i]:hide()
                        if (action.type == 'ws' or action.linked_type == 'ws' or action.type == "ma" or action.linked_type == "ma") then
                            self.hotbars[h].slot_cost[i]:show()
                        end
                    end

                    -- Mark which actions came from a default set, if any, when the gamepad assigner is open
                    if (action ~= nil and action.source_environment ~= environment and dim_default_slots) then
                        self:mark_default_set_action(h, i, action.source_environment)
                    end
                end
            end

            if (not self.is_compact) then
                self:show_controller_icons(h)
            end
        else
            for i=1,8,1 do
                self.hotbars[h].slot_background[i]:hide()
                self.hotbars[h].slot_warmup[i]:hide()
                self.hotbars[h].slot_icon[i]:hide()
                self.hotbars[h].slot_frame[i]:hide()
                self.hotbars[h].slot_recast[i]:hide()
                self.hotbars[h].slot_element[i]:hide()
                self.hotbars[h].slot_text[i]:hide()
                self.hotbars[h].slot_cost[i]:hide()
                self.hotbars[h].slot_recast_text[i]:hide()
                self:clear_recast(h, i)
            end

            self:hide_controller_icons(h)
        end
    end
end

-- show the dpad and face button icons
function ui:show_controller_icons(h)
    if not self.UseAltLayout then
        -- set up dpad element
        local dpadSlot = 9
        self.hotbars[h].slot_recast[dpadSlot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/dpad_'..self.theme.button_layout..'.png')
        self.hotbars[h].slot_recast[dpadSlot]:alpha(255)
        self.hotbars[h].slot_recast[dpadSlot]:size(40, 40)
        self.hotbars[h].slot_recast[dpadSlot]:pos(self:get_slot_x(h, dpadSlot), self:get_slot_y(h, dpadSlot) + 5)
        self.hotbars[h].slot_recast[dpadSlot]:show()

        -- set up face buttons element
        local faceSlot = 10
        self.hotbars[h].slot_recast[faceSlot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/facebuttons_'..self.theme.button_layout..'.png')
        self.hotbars[h].slot_recast[faceSlot]:alpha(255)
        self.hotbars[h].slot_recast[faceSlot]:size(40, 40)
        self.hotbars[h].slot_recast[faceSlot]:pos(self:get_slot_x(h, faceSlot), self:get_slot_y(h, faceSlot) + 5)
        self.hotbars[h].slot_recast[faceSlot]:show()
    else
        -- set up dpad element
        local dpadSlot = 9
        self.hotbars[h].slot_recast[dpadSlot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/dpad_'..self.theme.button_layout..'.png')
        self.hotbars[h].slot_recast[dpadSlot]:alpha(255)
        self.hotbars[h].slot_recast[dpadSlot]:size(40, 40)
        -- set up face buttons element
        local faceSlot = 10
        self.hotbars[h].slot_recast[faceSlot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/facebuttons_'..self.theme.button_layout..'.png')
        self.hotbars[h].slot_recast[faceSlot]:alpha(255)
        self.hotbars[h].slot_recast[faceSlot]:size(40, 40)

        if h == 1 then
            self.hotbars[h].slot_recast[dpadSlot]:pos(self:get_slot_x(h, dpadSlot - 5.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[dpadSlot]:show()
            self.hotbars[h].slot_recast[faceSlot]:pos(self:get_slot_x(h, faceSlot - 2.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[faceSlot]:show()
        elseif h == 3 or h == 4 then
            self.hotbars[h].slot_recast[dpadSlot]:pos(self:get_slot_x(h, dpadSlot - 8.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[dpadSlot]:show()
            self.hotbars[h].slot_recast[faceSlot]:pos(self:get_slot_x(h, faceSlot - 2.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[faceSlot]:show()
        elseif h ==5 and self.AutoHideExtraBars then
            self.hotbars[h].slot_recast[dpadSlot]:pos(self:get_slot_x(h, dpadSlot - 5.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[dpadSlot]:show()
            self.hotbars[h].slot_recast[faceSlot]:pos(self:get_slot_x(h, faceSlot - 2.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[faceSlot]:show()
        elseif h == 6 and self.AutoHideExtraBars then
            self.hotbars[h].slot_recast[dpadSlot]:pos(self:get_slot_x(h, dpadSlot - 8.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[dpadSlot]:show()
            self.hotbars[h].slot_recast[faceSlot]:pos(self:get_slot_x(h, faceSlot - 5.5), self:get_slot_y(h, 2) + 20)
            self.hotbars[h].slot_recast[faceSlot]:show()

        end
    end
end

-- hide the dpad and face button icons
function ui:hide_controller_icons(h)
    -- set up dpad element
    local dpadSlot = 9
    self.hotbars[h].slot_recast[dpadSlot]:hide()
    local dpadSlot = 3
    self.hotbars[h].slot_recast[dpadSlot]:hide()

    -- set up face buttons element
    local faceSlot = 10
    self.hotbars[h].slot_recast[faceSlot]:hide()
    local faceSlot = 5
    self.hotbars[h].slot_recast[faceSlot]:hide()
end

-- clear recast from a slot
function ui:clear_recast(hotbar, slot)
    self.hotbars[hotbar].slot_warmup[slot]:hide()
    self.hotbars[hotbar].slot_recast[slot]:hide()
    self.hotbars[hotbar].slot_recast_text[slot]:alpha(255)
    self.hotbars[hotbar].slot_recast_text[slot]:color(255, 255, 255)
    self.hotbars[hotbar].slot_recast_text[slot]:text('')
end

-- calculate recast time
function calc_recast_time(time, in_seconds)
    local recast = time / 60

    if in_seconds then
        if recast >= 60 then
            recast = string.format("%dh", recast / 60)
        elseif recast >= 1 then
            recast = string.format("%dm", recast)
        else
            recast = string.format("%ds", recast * 60)
        end
    else
        if recast >= 60 then
            recast = string.format("%dm", recast / 60)
        else
            recast = string.format("%ds", math.round(recast * 10)*0.1)
        end
    end

    return recast
end

-- disable slot
function ui:toggle_slot(hotbar, slot, is_enabled)
    local opacity = self.theme.disabled_slot_opacity

    if is_enabled == true then
        opacity = 255
    end

    self.hotbars[hotbar].slot_element[slot]:alpha(opacity)
    self.hotbars[hotbar].slot_cost[slot]:alpha(opacity)
    self.hotbars[hotbar].slot_icon[slot]:alpha(opacity)
end

-----------------------------
-- Enchanted Item Usage UI
-----------------------------
function ui:maybe_use_enchanted_item(hotbar, slot)
    local action = hotbar['hotbar_' .. h]['slot_' .. slot]
end

function maybe_get_default_action(hotbar, environment, hb, slot)
    if (environment == 'shared') then return nil end

    local h = 'hotbar_' .. hb
    local i = 'slot_' .. slot
    local action = nil

    if (environment ~= 'job-default' and environment ~= 'all-jobs-default' and
        hotbar['default'] and hotbar['default'][h] and hotbar['default'][h][i]) then
        action = hotbar['default'][h][i]
        action.source_environment = 'default'
    elseif (environment ~= 'all-jobs-default' and hotbar['job-default'] and hotbar['job-default'][h] and hotbar['job-default'][h][i]) then
        action = hotbar['job-default'][h][i]
        action.source_environment = 'job-default'
    elseif (hotbar['all-jobs-default'] and hotbar['all-jobs-default'][h] and hotbar['all-jobs-default'][h][i]) then
        action = hotbar['all-jobs-default'][h][i]
        action.source_environment = 'all-jobs-default'
    end

    return action
end

-----------------------------
-- Feedback UI
-----------------------------

-- trigger feedback visuals in given hotbar and slot
function ui:trigger_feedback(hotbar, slot)
    if slot == 0 then slot = 10 end    
    self.feedback.hotbar, self.feedback.slot = hotbar, slot
    self.feedback_icon:pos(self:get_slot_x(hotbar, slot), self:get_slot_y(hotbar, slot))
    self.feedback.current_opacity = self.feedback.max_opacity
    self.feedback.is_active = true
end

-- show feedback
function ui:show_feedback()
    if not self.feedback.is_active then return end
    local step = math.max(1, tonumber(self.feedback.speed) or 1)
    local opacity = math.max(0, math.min(255, self.feedback.current_opacity - step))
    self.feedback.current_opacity = opacity
    self.feedback_icon:alpha(opacity)
    if opacity > 0 then
        self.feedback_icon:show()
    else
        self.feedback_icon:hide()
        self.feedback.current_opacity = self.feedback.max_opacity
        self.feedback.is_active = false
    end
end

return ui
