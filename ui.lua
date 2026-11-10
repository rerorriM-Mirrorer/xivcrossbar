local shoulders = require('shoulder_banks')
local pet_policy = require('libs/pet_actions')
local trust_policy = require('libs/trust_actions')
local ui_resources = require('ui/resources')
local item_icons = require('ui/item_icons')
local kebab_casify = require('libs/kebab_casify')
local crossbar_abilities = require('resources/crossbar_abilities')
local crossbar_spells = require('resources/crossbar_spells')
local defaults = require('defaults')
settings = config.load(defaults)
local player = require('player')

local ui = {}
local geometry = require('ui_geometry').new()
local prim = geometry:prim()
ui.geometry = geometry
local function new_image(options)
    return geometry:surface(ui_resources.image(options), 'image', options)
end
local function new_text(options)
    -- Windower mutates the supplied settings in place on every text setter.
    local flags = options.flags
    return geometry:surface(ui_resources.text({flags={draggable=flags.draggable, right=flags.right}}), 'text', options)
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

local slot_glow_padding = 4

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
ui.slot_pulse_enabled = false
ui.pulse_views = {}
ui.glow_views = {}
ui.pulse_tracks = {}
ui.pulse_visible_bars = {}
ui.slot_pulse = nil
ui.recast_samples, ui.recast_flashes, ui.recast_flash_views = {}, {}, {}

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
local function prepare_image(image, path)
    image:path(path)
    image:repeat_xy(1, 1)
    image:draggable(false)
    image:fit(true)
    image:alpha(255)
end

-- The controller setup screen also uses this legacy helper.
function setup_image(image, path)
    prepare_image(image, path)
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
    if shoulders.labels[h] then h = 3 end
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

        if self.is_compact and self.display_palette then
            local inset = (5*self.slot_spacing-4)/2
            local toward_center = h == 1 and 20 or h == 2 and -20 or 0
            return base + inset + toward_center + 40*(column-1) + (column >= 4 and 4 or 0)
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

        if self.is_compact and self.display_palette then
            local span = h <= 2 and 9 or h <= 4 and 5 or 12
            local toward_center = h == 1 and 6 or h == 2 and -6 or 0
            return base + span*self.slot_spacing/2 + toward_center + 40*(column-1)
        end
        return base + ((40 + self.slot_spacing) * (column - 1))
    end
end

-- get y position for a given hotbar and slot
function ui:get_slot_y(h, i)
    if shoulders.labels[h] then h = 3 end
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
    if self.is_compact and self.display_palette then
        return base - spacing + (2-row)*22
    end
    return base - (((row - 1) * spacing))
end

local unpack = unpack or table.unpack
local amber_stroke = {255, 216, 112}
local slot_label_strokes = {black={20, 20, 20}, amber={143, 89, 30}}
local bank_captions = {'L2', 'R2', 'R2>L2', 'L2>R2', 'L2x2', 'R2x2', 'L1', 'R1', 'L1+R1'}

local function position_bank_label(self, bank)
    local left, right = self:get_slot_x(bank, 1), self:get_slot_x(bank, 7) + 40
    self.bank_labels[bank]:center((left + right) / 2 + self.bank_label_offset_x,
        self:get_slot_y(bank, 2) + 13 + self.bank_label_offset_y)
end

local function position_slot_label(self, bank, slot)
    local label = self.hotbars[bank].slot_text[slot]
    local x = self:get_slot_x(bank, slot) + self.slot_label_offset_x
    local y = self:get_slot_y(bank, slot) + 40 + self.slot_label_offset_y
    if self.slot_label_align == 'center' then label:center(x + 20, y)
    else label:pos(x - 2, y) end
end

local function position_slot_cost(self, bank, slot)
    local x = self:get_slot_x(bank, slot) - windower.get_windower_settings().ui_x_res + 46
    local y = self:get_slot_y(bank, slot) + 28
    self.hotbars[bank].slot_cost[slot]:pos(x + self.cost_offset_x, y + self.cost_offset_y)
end

-----------------------------
-- Setup UI
-----------------------------

-- setup ui
function ui:setup(theme_options, enchanted_items)
    self.public_visible = nil
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
    self.theme.lockout_opacity = theme_options.lockout_opacity
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
    self:set_autoattack_enabled(theme_options.aa_enabled)
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

    self.display_palette = theme_options.display_palette
    self.bank_labels_visible = theme_options.bank_labels_visible ~= false
    self.bank_label_offset_x = tonumber(theme_options.bank_label_offset_x) or 0
    self.bank_label_offset_y = tonumber(theme_options.bank_label_offset_y) or 0
    self.bank_label_opacity = tonumber(theme_options.bank_label_opacity) or 255
    self.slot_label_offset_x = tonumber(theme_options.slot_label_offset_x) or 0
    self.slot_label_offset_y = tonumber(theme_options.slot_label_offset_y) or 0
    self.slot_label_align = theme_options.slot_label_align
    self.cost_offset_x = tonumber(theme_options.cost_offset_x) or 0
    self.cost_offset_y = tonumber(theme_options.cost_offset_y) or 0
    self.slot_label_stroke = slot_label_strokes[theme_options.slot_label_stroke] or slot_label_strokes.black
    self.theme.mp_cost_color_red = theme_options.mp_cost_color_red
    self.theme.mp_cost_color_green = theme_options.mp_cost_color_green
    self.theme.mp_cost_color_blue = theme_options.mp_cost_color_blue
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
    self.hotbars = {}
    self.bank_labels = {}
    self.render_banks = {}
    for h=1,theme_options.hotbar_number do self.render_banks[h] = h end
    if theme_options.hotbar_number == 5 then self.render_banks[4], self.render_banks[5] = 5, 6 end
    if theme_options.shoulder_banks then
        for h=7,9 do self.render_banks[#self.render_banks+1] = h end
    end
    geometry:setup_bank_scales(theme_options.shoulder_banks and 9 or self.render_banks[#self.render_banks])
    self.recast_samples, self.recast_flashes, self.recast_flash_views = {}, {}, {}
    self.recast_flash_enabled = theme_options.recast_flash_enabled
    self.recast_flash_clock = require('socket').gettime
    self.scale_visible, self.scale_active_bar = false, 0
    self.display_bank, self.center_release_deadline = 0, nil
    -- load battle notice
    prepare_image(self.battle_notice, windower.addon_path .. '/themes/' .. (theme_options.battle_notice_theme:lower()) .. '/notice.png')
    self.battle_notice:pos(self.pos_x + self.hotbar_width - 90, self.pos_y - (theme_options.hotbar_spacing * (theme_options.hotbar_number)) - 24)
    self.battle_notice:hide()
    self.frame_image_path = windower.addon_path..'/themes/' .. (theme_options.frame_theme:lower()) .. '/frame.png'
    self.empty_frame_image_path = windower.addon_path..'themes/ffxiv/empty-frame.png'

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

    -- The lockout strip has its own visibility, while retaining HUD scaling.
    prim.create_rounded('gcd_indicator_bg', true)
    prim.set_color('gcd_indicator_bg', 150, 0, 0, 0)
    prim.set_position('gcd_indicator_bg', self:get_slot_x(1, 1) - 12, self:get_slot_y(1, 4) + 10)
    prim.set_size('gcd_indicator_bg', 604, 10)
    prim.set_visibility('gcd_indicator_bg', false)

    prim.create_rounded('gcd_indicator', true)
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
    self:update_trigger_field_art()
    self.bar_background:alpha(self.button_bg_alpha)
    self.bar_background_left:alpha(self.button_bg_alpha)
    self.bar_background_right:alpha(self.button_bg_alpha)

    self.button_hints, self.button_hints_visible = nil, false
    self.hint_theme = theme_options
    self:layout_button_hints()

    -- create ui elements for hotbars
    for _, h in ipairs(self.render_banks) do
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

            self.hotbars[h].slot_background[i] = new_image(images_setup)
            self.hotbars[h].slot_warmup[i] = new_image(images_setup)
            self.hotbars[h].slot_icon[i] = new_image(images_setup)
            self.hotbars[h].slot_recast[i] = new_image(images_setup)
            self.hotbars[h].slot_frame[i] = new_image(images_setup)
            self.hotbars[h].slot_element[i] = new_image(images_setup)
            self.hotbars[h].slot_text[i] = new_text(text_setup)
            self.hotbars[h].slot_cost[i] = new_text(right_text_setup)
            self.hotbars[h].slot_recast_text[i] = new_text(text_setup)
            self.hotbars[h].slot_icon[i]:size(40, 40)

            prepare_image(self.hotbars[h].slot_background[i], windower.addon_path..'/themes/' .. (theme_options.slot_theme:lower()) .. '/slot.png')
            prepare_image(self.hotbars[h].slot_icon[i], windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blank.png')
            prepare_image(self.hotbars[h].slot_frame[i], self.frame_image_path)
            prepare_image(self.hotbars[h].slot_element[i], windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blank.png')
            setup_text(self.hotbars[h].slot_text[i], theme_options, true)
            self.hotbars[h].slot_text[i]:stroke_color(unpack(self.slot_label_stroke))
            setup_text(self.hotbars[h].slot_cost[i], theme_options, true)
            setup_text(self.hotbars[h].slot_recast_text[i], theme_options, true)

            self.hotbars[h].slot_cost[i]:size(8)
            self.hotbars[h].slot_cost[i]:stroke_alpha(220)
            self.hotbars[h].slot_background[i]:alpha(theme_options.slot_opacity)
            self.hotbars[h].slot_background[i]:pos(slot_pos_x, slot_pos_y)
            self.hotbars[h].slot_icon[i]:pos(slot_pos_x, slot_pos_y)
            self.hotbars[h].slot_frame[i]:pos(slot_pos_x, slot_pos_y)
            self.hotbars[h].slot_element[i]:pos(slot_pos_x + 28, slot_pos_y - 4)

            position_slot_label(self, h, i)
            position_slot_cost(self, h, i)
            local timer = self.hotbars[h].slot_recast_text[i]
            timer:size(10)
            timer:color(255, 255, 255)
            timer:stroke_color(0, 0, 0)
            timer:center(slot_pos_x + 20, slot_pos_y + 13)
        end

        -- special stuff for dpad and face buttons icons
        self.hotbars[h].slot_recast[9] = new_image(images_setup)
        self.hotbars[h].slot_recast[10] = new_image(images_setup)
        for _, slots in pairs(self.hotbars[h]) do
            for _, surface in ipairs(slots) do geometry:assign_bank(surface, h) end
        end
    end

    local ordered = theme_options.hotbar_number == 4 or theme_options.hotbar_number == 6
    for _, h in ipairs(self.render_banks) do
        local label = new_text(text_setup)
        self.bank_labels[h] = label
        setup_text(label, theme_options, true)
        label:size(12 * .94)
        label:bold(true)
        label:color(255, 255, 255)
        label:stroke_color(unpack(amber_stroke))
        label:stroke_width(2)
        label:alpha(self.bank_label_opacity)
        label:stroke_alpha(self.bank_label_opacity)
        label:text(h == 3 and not ordered and 'R2+L2' or bank_captions[h])
        geometry:assign_bank(label, h, true)
        position_bank_label(self, h)
    end

    self.binding_tint = new_image(images_setup)
    prepare_image(self.binding_tint, windower.addon_path .. '/images/icons/iconpacks/default/ui/square.png')
    self.binding_tint:size(40, 40)
    self.binding_tint:color(75, 235, 126)
    self.binding_tint:alpha(105)
    self.binding_tint:hide()

    -- load feedback icon last so it stays above everything else
    self.feedback_icon = new_image(images_setup)
    prepare_image(self.feedback_icon, windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/feedback.png')
    self.feedback.max_opacity = theme_options.feedback_max_opacity
    self.feedback.speed = theme_options.feedback_speed
    self.feedback.current_opacity = self.feedback.max_opacity
    self.feedback_icon:hide()
    -- Eight independently owned physical slot directions. Each may occupy a
    -- different bar while the original single legacy flash stays untouched.
    self.slot_pulse = require('slot_pulse').new(require('socket').gettime)
    self.slot_pulse_enabled = theme_options.slot_pulse_enabled
    self.pulse_views,self.pulse_tracks,self.pulse_visible_bars = {},{},{}
    for slot=1,8 do
        local view=new_image(images_setup)
        prepare_image(view,windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/feedback.png')
        view:hide()
        self.pulse_views[slot]=view
    end
    self.glow_views = {}
    self:set_slot_glow_enabled(theme_options.slot_glow_enabled)
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
    return self:set_display_layout(self.display_palette, enabled)
end

function ui:set_display_layout(palette, enabled)
    if self.is_compact == enabled and self.display_palette == palette then return false end
    if not self.is_setup then
        self.display_palette, self.is_compact = palette, enabled
        return true
    end
    local old = {}
    for h, bar in pairs(self.hotbars) do
        old[h] = {}
        for i = 1, 8 do old[h][i] = {self:get_slot_x(h,i), self:get_slot_y(h,i)} end
    end
    local old_x, old_y = self:get_slot_x(1,1), self:get_slot_y(1,4)
    self.display_palette, self.is_compact = palette, enabled
    for h, bar in pairs(self.hotbars) do
        for i = 1, 8 do
            local dx,dy = self:get_slot_x(h,i)-old[h][i][1], self:get_slot_y(h,i)-old[h][i][2]
            for _, objects in pairs(bar) do
                if type(objects)=='table' then geometry:move_surface(objects[i],dx,dy) end
            end
        end
        position_bank_label(self, h)
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
    for slot,track in pairs(self.pulse_tracks or {}) do
        local x,y=self:get_slot_x(track.hotbar,track.slot),self:get_slot_y(track.hotbar,track.slot)
        self.pulse_views[slot]:pos(x,y)
        if self.glow_views[slot] then
            self.glow_views[slot]:pos(x-slot_glow_padding,y-slot_glow_padding)
        end
    end
    self:update_trigger_field_art()
    self:layout_button_hints()
    if self.public_visible then self:show_button_hints() end
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
    local bounds=geometry:rect(self:get_slot_x(2,5)-5,self:get_slot_y(1,4)-27,40,40)
    return bounds.x,bounds.y+bounds.height
end

function ui:get_drag_bounds()
    local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
    for _,bar in pairs(self.hotbars) do
        for slot=1,8 do
            local object=bar.slot_background[slot]
            local m=geometry.surfaces[object]
            if not m or not m.visible then m=geometry.surfaces[bar.slot_icon[slot]] end
            if m and m.visible and m.x then
                local b=geometry:rect(m.x,m.y,40,40,m.bank)
                left,top=math.min(left,b.x),math.min(top,b.y)
                right,bottom=math.max(right,b.x+b.width),math.max(bottom,b.y+b.height)
            end
        end
    end
    if left==math.huge then return nil end
    return {x=left,y=top,width=right-left,height=bottom-top}
end

-- Briefly keep the combined bank drawn while a two-trigger release settles.
-- Input routing still uses the live bank.
function ui:select_display_bank(active_bank, grace_enabled, now)
    local previous = self.display_bank
    if grace_enabled and (active_bank == 1 or active_bank == 2)
        and (previous == 3 or previous == 4) then
        local deadline = self.center_release_deadline or now + .075
        if now < deadline then
            self.center_release_deadline = deadline
            return previous
        end
    end

    self.display_bank, self.center_release_deadline = active_bank, nil
    return active_bank
end

function ui:update_trigger_scale(enabled, small, active_bar, visible, autohide, menu_open)
    enabled = enabled and not menu_open
    small = tonumber(small) or .95
    if small ~= small or small < .75 or small > 1 then small = .95 end
    local selected = enabled and visible and active_bar or 0
    local single = selected == 1 or selected == 2
    local returning = enabled and visible and self.scale_visible and self.scale_active_bar >= 3 and selected < 3
    local function centered(bar)
        return bar == 3 or bar == 4 or bar >= 7 or (bar >= 5 and self.AutoHideExtraBars)
    end
    local enter_center = enabled and visible and self.scale_visible
        and not centered(self.scale_active_bar) and centered(selected)
    local leave_center = enabled and visible and self.scale_visible
        and centered(self.scale_active_bar) and not centered(selected)
    local replace_center = leave_center and autohide
        and (self.scale_active_bar == 3 or self.scale_active_bar == 4)
    local revealing = enabled and autohide and visible and not self.scale_visible and geometry.opacity == 0
    local instant = not enabled or (not visible and not geometry.fade_enabled)
    for _, h in ipairs(self.render_banks) do
        local left, right = math.huge, -math.huge
        for slot=1,8 do
            local x = self:get_slot_x(h, slot)
            left, right = math.min(left, x), math.max(right, x+40)
        end
        local target = selected == h and 2-small or (single and h <= 2 and small or 1)
        local initial = returning and h <= 2 and small or revealing and 1 or nil
        local horizontal = h == 1 and 16 or h == 2 and -16 or nil
        if visible and (replace_center or not self.scale_visible) then
            geometry:set_bank_slide(h, nil, nil, false, true)
        elseif (enter_center or leave_center) and horizontal then
            geometry:set_bank_slide(h, horizontal, nil, leave_center, false)
        elseif enter_center and h == selected or leave_center and h == self.scale_active_bar then
            geometry:set_bank_slide(h, nil, 8, enter_center, false)
        elseif visible and (instant or selected >= 3 and h == selected and h ~= self.scale_active_bar) then
            geometry:set_bank_slide(h, nil, nil, false, true)
        end
        geometry:set_bank_scale(h, (left+right)/2,
            (self:get_slot_y(h, 2)+self:get_slot_y(h, 4)+40)/2, target, instant, initial)
    end
    self.scale_visible, self.scale_active_bar = visible, selected
end

-- hide all ui components
function ui:hide()
    self.display_bank, self.center_release_deadline = 0, nil
    self:clear_recast_flashes()
    geometry:transition(false)
    for _, name in ipairs({'skillchain_indicator_bg','skillchain_indicator',
        'gcd_indicator_bg','gcd_indicator','aa_indicator_bg','aa_indicator_red','aa_indicator_green'}) do
        prim.set_visibility(name, false)
    end
    self.battle_notice:hide()
    self.binding_tint:hide()
    self.feedback_icon:hide()
    self:clear_slot_pulses()

    self:hide_button_hints()

    for _, h in ipairs(self.render_banks) do
        local slide = geometry.banks[h].slide
        local outgoing = slide.target == 0
        -- Freeze the slide while the selected bank fades.
        slide.active = false
        self.bank_labels[h]:hide(outgoing)
        for _, slots in pairs(self.hotbars[h]) do
            for _, surface in ipairs(slots) do surface:hide(outgoing) end
        end
    end
    self.bar_background:hide()
    self.bar_background_left:hide()
    self.bar_background_right:hide()
end

function ui:set_bank_labels_visible(visible)
    self.bank_labels_visible = visible
    if not visible then
        for _, label in pairs(self.bank_labels or {}) do label:hide(true) end
    end
end

function ui:set_bank_label_offset(x, y)
    self.bank_label_offset_x, self.bank_label_offset_y = x, y
    for bank in pairs(self.bank_labels or {}) do position_bank_label(self, bank) end
end

function ui:set_bank_label_opacity(opacity)
    self.bank_label_opacity = opacity
    for _, label in pairs(self.bank_labels or {}) do
        label:alpha(opacity)
        label:stroke_alpha(opacity)
        if opacity == 0 then label:hide(true) end
    end
end

function ui:set_slot_label_layout(align, x, y)
    self.slot_label_align = align
    self.slot_label_offset_x, self.slot_label_offset_y = x, y
    for bank, bar in pairs(self.hotbars or {}) do
        for slot in ipairs(bar.slot_text) do position_slot_label(self, bank, slot) end
    end
end

function ui:set_cost_offset(x, y)
    self.cost_offset_x, self.cost_offset_y = x, y
    for bank, bar in pairs(self.hotbars or {}) do
        for slot in ipairs(bar.slot_cost) do position_slot_cost(self, bank, slot) end
    end
end

function ui:set_slot_label_stroke(mode)
    self.slot_label_stroke = slot_label_strokes[mode] or slot_label_strokes.black
    for _, bar in pairs(self.hotbars or {}) do
        for _, label in ipairs(bar.slot_text) do label:stroke_color(unpack(self.slot_label_stroke)) end
    end
end

function ui:layout_button_hints()
    local hints = self.button_hints
    if self.is_compact then
        if hints then
            for _, view in pairs(hints) do
                view:hide(true)
                view:destroy()
            end
        end
        self.button_hints, self.button_hints_visible = nil, false
        return
    end

    if not hints then
        local base = windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/ui/binding_icons/'
        local suffix = self.theme.button_layout .. '.png'
        hints = {}
        hints.binder_icon = new_image(images_setup)
        hints.binder_icon:path(base .. 'minus_' .. suffix)
        hints.binder_text = new_text(text_setup)
        setup_text(hints.binder_text, self.hint_theme, true)
        hints.binder_text:text('Bind an action')
        hints.chooser_icon = new_image(images_setup)
        hints.chooser_icon:path(base .. 'plus_' .. suffix)
        hints.chooser_text = new_text(text_setup)
        setup_text(hints.chooser_text, self.hint_theme, true)
        hints.chooser_text:text('Change crossbar sets')
        self.button_hints = hints
    end

    local x, y = self:get_slot_x(1,1), self:get_slot_y(1,4)
    local chooser_x = self:get_slot_x(2,5)
    hints.binder_icon:pos(x-10,y-27)
    hints.binder_text:pos(x+35,y-15)
    hints.chooser_icon:pos(chooser_x-5,y-27)
    hints.chooser_text:pos(chooser_x+40,y-15)
end

function ui:hide_button_hints()
    self.button_hints_visible = false
    if self.button_hints then
        for _, view in pairs(self.button_hints) do view:hide() end
    end
end

-- show ui components
function ui:show(player_hotbar, environment)
    -- A: the chooser's Add New Set entry has no hotbar to render.
    if not player_hotbar or not player_hotbar[environment] then return end
    geometry:transition(true)
    if self.theme.hide_battle_notice == false and environment == 'battle' then self.battle_notice:show() end

    self:show_button_hints()

    -- The render pass selects banks and reveals their slot surfaces.
    return true
end

function ui:show_button_hints()
    local hints = self.button_hints
    if not hints then return end
    self.button_hints_visible = true
    hints.binder_icon:show()
    hints.binder_text:show()
    hints.chooser_icon:show()
    if self.chooser_open then hints.chooser_text:hide(true)
    else hints.chooser_text:show() end
end

function ui:set_chooser_open(open)
    if self.chooser_open == open then return end
    self.chooser_open = open
    local hints = self.button_hints
    if not hints then return end
    if open then hints.chooser_text:hide(true)
    elseif self.button_hints_visible then hints.chooser_text:show() end
end

function ui:update_trigger_field_art()
    local base = windower.addon_path .. (self.display_palette and 'images/assets/xi-'
        or ('images/' .. get_icon_pathbase() .. '/ui/'))
    local name = self.is_compact and 'bar_bg_compact' or 'bar_bg'
    local height = self.is_compact and 180 or 220
    self.bar_background:path(base .. name .. '.png')
    self.bar_background:size(330,height)
    for _,field in ipairs({self.bar_background_left,self.bar_background_right}) do
        field:path(base .. name .. '_alt.png')
        field:size(self.is_compact and 330 or 40,self.is_compact and 180 or 40)
    end
end

local function fit_trigger_field(self, field, bank, first, last)
    local min_x,max_x,min_y,max_y = math.huge,-math.huge,math.huge,-math.huge
    for slot=first,last do
        local x,y=self:get_slot_x(bank,slot),self:get_slot_y(bank,slot)
        min_x,max_x=math.min(min_x,x),math.max(max_x,x+40)
        min_y,max_y=math.min(min_y,y),math.max(max_y,y+40)
    end
    field:pos(min_x-26,min_y-20)
    field:size(max_x-min_x+52,max_y-min_y+40)
    field:show()
end

function ui:show_bar_background(hotbar_number)
    self.background_hotbar = hotbar_number
    geometry:assign_bank(self.bar_background, hotbar_number)
    geometry:assign_bank(self.bar_background_left, hotbar_number)
    geometry:assign_bank(self.bar_background_right, hotbar_number)

    if self.display_palette then
        if self.UseAltLayout and hotbar_number ~= 3 and hotbar_number ~= 4 and not shoulders.labels[hotbar_number] then
            self.bar_background:hide()
            fit_trigger_field(self,self.bar_background_left,hotbar_number,1,4)
            fit_trigger_field(self,self.bar_background_right,hotbar_number,5,8)
        else
            self.bar_background_left:hide()
            self.bar_background_right:hide()
            fit_trigger_field(self,self.bar_background,hotbar_number,1,8)
        end
        return
    end

    self.bar_background:pos(self:get_slot_x(hotbar_number, 1) - 30, self:get_slot_y(hotbar_number, 4) - 35)
    self.bar_background_left:pos(self:get_slot_x(hotbar_number, 1) - 30, self:get_slot_y(hotbar_number, 4) - 35)

    if self.UseAltLayout then
        if hotbar_number == 3 or hotbar_number == 4 or shoulders.labels[hotbar_number] then
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
function ui:load_player_hotbar(player_hotbar, player_vitals, environment)
    self.resolved_slots = {}
    self:clear_recast_flashes()
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

    for _, h in ipairs(self.render_banks) do
        for slot=1,8,1 do
            local bar = shoulders.bar(player_hotbar, environment, h)
            local action = bar and bar['slot_' .. slot]
            self:load_action(player_hotbar, environment, h, slot, action, player_vitals, false)
        end
    end
end

function ui:should_show_element(element)
    return element ~= nil and element ~= 'None' and element ~= '0' and self.theme.hide_action_element == false
end

-- load action into a hotbar slot
function ui:load_action(player_hotbar, environment, hotbar, slot, action, player_vitals, show_when_ready)
    local is_disabled = false

    local player = windower.ffxi.get_player()
    local main_job_id = player.main_job_id

    local LV_1_SP_ABILITY_RECAST_ID = 0
    local LV_96_SP_ABILITY_RECAST_ID = 254

    self:clear_slot(hotbar, slot)

    local icon_overridden = false
    local blank_icon = '/images/' .. get_icon_pathbase() .. '/ui/blank.png'

    -- if slot is empty, check if there is an entry in the default crossbar
    if (action == nil or action.action == nil) then
        action = maybe_get_default_action(player_hotbar, environment, hotbar, slot)

        -- if default crossbar slot is empty, then hide the slot
        if (action == nil) then
            if self.theme.hide_empty_slots == true then
                self.hotbars[hotbar].slot_background[slot]:hide()
            end
            self.hotbars[hotbar].slot_icon[slot]:path(windower.addon_path .. blank_icon)
            self.hotbars[hotbar].slot_icon[slot]:hide()
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

                local mp_cost = tonumber(crossbar_action.mp_cost) or 0
                local tp_cost = tonumber(crossbar_action.tp_cost) or 0
                if mp_cost > 0 or tp_cost > 0 then
                    local kind = mp_cost > 0 and 'mp' or 'tp'
                    local cost = mp_cost > 0 and mp_cost or tp_cost
                    local insufficient = player_vitals[kind] < cost
                    self:set_action_cost_color(hotbar, slot, kind, insufficient)
                    self.hotbars[hotbar].slot_cost[slot]:text(settings.Hotbar.HideActionCost and '' or tostring(cost))
                    if insufficient then
                        self.disabled_slots.no_vitals[action.action] = true
                        is_disabled = true
                    end
                end
            end
        end

        -- Enchanted-item special handling uses the raw action, not the
        -- linked lookup — don't try linked_type='enchanteditem'
        if (action.type == 'enchanteditem') then
            self.enchanted_items:register(action.action, action.warmup, 2, action.cooldown)
            icon_path = '/images/' .. get_icon_pathbase() .. '/items/' .. kebab_casify(action.action) .. '.png'
        end

        self.hotbars[hotbar].slot_background[slot]:alpha(200)
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
    end

    -- Select the final texture before touching the native image.
    if not icon_overridden and action.icon and action.icon ~= '' then
        self.hotbars[hotbar].slot_background[slot]:alpha(200)
        -- Extracted item cache paths are derived data.
        if action.type ~= 'item' or not item_icons.is_extracted(action.icon) then
            if action.icon:match('^/?images/') then
                icon_path = '/' .. action.icon:gsub('^/', '')
            else
                icon_path = '/images/' .. get_icon_pathbase() .. '/' .. action.icon .. '.png'
            end
        end
    end

    local icon = self.hotbars[hotbar].slot_icon[slot]
    icon:path(windower.addon_path .. (icon_path or blank_icon))
    -- Geometry fits both native and custom artwork to the slot.
    icon:pos(self:get_slot_x(hotbar, slot), self:get_slot_y(hotbar, slot))
    if not icon_path then icon:hide()
    elseif show_when_ready then icon:show() end

    if action.type == 'item' then
        -- A 32-pixel extracted bitmap still fills the bound 40-pixel slot.
        self.hotbars[hotbar].slot_icon[slot]:size(40, 40)
        self.hotbars[hotbar].slot_icon[slot]:pos(self:get_slot_x(hotbar, slot), self:get_slot_y(hotbar, slot))
    end

    -- check if action is on cooldown
    if self.disabled_slots.on_cooldown[action.action] ~= nil then is_disabled = true end
    if self.disabled_slots.on_warmup[action.action] ~= nil then is_disabled = true end

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
        self.disabled_slots.actions[action.action] = true
    end
end

-- reset slot
function ui:clear_slot(hotbar, slot)
    self:clear_recast_flash(hotbar, slot)
    self.hotbars[hotbar].slot_background[slot]:alpha(self.theme.slot_opacity)
    self.hotbars[hotbar].slot_icon[slot]:alpha(255)
    self.hotbars[hotbar].slot_icon[slot]:color(255, 255, 255)
    self.hotbars[hotbar].slot_element[slot]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blank.png')
    self.hotbars[hotbar].slot_element[slot]:alpha(255)
    self.hotbars[hotbar].slot_element[slot]:hide()
    self.hotbars[hotbar].slot_text[slot]:text('')
    self.hotbars[hotbar].slot_cost[slot]:alpha(255)
    self.hotbars[hotbar].slot_cost[slot]:text('')
end

-----------------------------
-- Disabled Slots
-----------------------------

function ui:set_action_cost_color(hotbar, slot, kind, insufficient)
    local field = self.hotbars[hotbar].slot_cost[slot]
    local palette = self.display_palette
    if palette then
        local color = insufficient and palette.insufficient or palette[kind]
        field:color(color[1], color[2], color[3])
    else
        local prefix = kind .. '_cost_color_'
        field:color(self.theme[prefix .. 'red'], self.theme[prefix .. 'green'], self.theme[prefix .. 'blue'])
    end
end

-- check player vitals
function ui:check_vitals(player_hotbar, player_vitals, environment)
    local selected=player_hotbar and player_hotbar[environment]
    if not selected then return end
    for _, h in ipairs(self.render_banks) do
        for i=1,8,1 do
            local slot = i
            if slot == 10 then slot = 0 end

            local bar=shoulders.bar(player_hotbar, environment, h)
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
                elseif (lookup_type == 'ja' or lookup_type == 'ws' or lookup_type == 'pet') then
                    crossbar_action = crossbar_abilities[kebab_casify(lookup_name)]
                end

                if (crossbar_action ~= nil) then
                    local mp_cost = tonumber(crossbar_action.mp_cost) or 0
                    local tp_cost = tonumber(crossbar_action.tp_cost) or 0
                    local short_mp = mp_cost > 0 and player_vitals.mp < mp_cost
                    local short_tp = tp_cost > 0 and player_vitals.tp < tp_cost
                    if mp_cost > 0 then
                        self:set_action_cost_color(h, i, 'mp', short_mp)
                    elseif tp_cost > 0 then
                        self:set_action_cost_color(h, i, 'tp', short_tp)
                    end
                    if short_mp or short_tp then
                        self.disabled_slots.no_vitals[action.action] = true
                        is_disabled = true
                    else
                        self.disabled_slots.no_vitals[action.action] = nil
                    end

                    -- if it's not disabled by vitals nor cooldown, enable slot
                    if is_disabled == false and self.disabled_slots.actions[action.action] == true and self.disabled_slots.on_cooldown[action.action] == nil and self.disabled_slots.on_warmup[action.action] == nil then
                        self.disabled_slots.actions[action.action] = nil
                        self:toggle_slot(h, i, true)
                    end

                    -- if its disabled, disable slot
                    if is_disabled == true and self.disabled_slots.actions[action.action] == nil then
                        self.disabled_slots.actions[action.action] = true
                        self:toggle_slot(h, i, false)
                    end
                end
            end
        end
    end
end

gcd_start_time = 0
gcd_duration = 2.8
gcd_active = false
gcd_kind = 'spell' -- one of: 'spell' (3.0s, bluish-white → green at end),
                  --         'ws'    (2.0s, amber),
                  --         'ja'    (2.0s, red for first 1.0s then green)

-- Auto-attack swing timer state.
aa_last_swing_time = 0
aa_intervals = {}              -- up to 10 most recent inter-swing intervals (active seconds)
aa_estimate = nil              -- rolling average (nil until first swing recorded)
aa_engaged = false             -- whether the player is currently engaged
aa_pause_sources = {}          -- set: {ws=true, ja=true, petrify=true, ...}
aa_pause_start = 0             -- os.clock() when current pause began (0 if not paused)
aa_accumulated_pause = 0       -- total paused seconds since last swing
aa_fallback_total = 10         -- total bar duration when no data yet (seconds)

function aa_is_paused()
    return next(aa_pause_sources) ~= nil
end

function aa_add_pause_source(src)
    if ui.aa_enabled == false then return end
    if (not aa_is_paused()) then
        aa_pause_start = os.clock()
    end
    aa_pause_sources[src] = true
end

function aa_remove_pause_source(src)
    if ui.aa_enabled == false then return end
    if (aa_pause_sources[src] == nil) then return end
    aa_pause_sources[src] = nil
    if (not aa_is_paused()) then
        aa_accumulated_pause = aa_accumulated_pause + (os.clock() - aa_pause_start)
        aa_pause_start = 0
    end
end

function aa_clear_pauses()
    aa_pause_sources = {}
    aa_pause_start = 0
end

function aa_record_swing()
    if ui.aa_enabled == false then return end
    local now = os.clock()
    if (aa_last_swing_time > 0) then
        local interval = (now - aa_last_swing_time) - aa_accumulated_pause
        if (interval > 0) then
            table.insert(aa_intervals, interval)
            while (#aa_intervals > 10) do
                table.remove(aa_intervals, 1)
            end
            local sum = 0
            for _, v in ipairs(aa_intervals) do sum = sum + v end
            aa_estimate = sum / #aa_intervals
        end
    end
    aa_last_swing_time = now
    aa_accumulated_pause = 0
    aa_clear_pauses()
end

function aa_set_engaged(is_engaged)
    if ui.aa_enabled == false then return end
    if (is_engaged and not aa_engaged) then
        -- just engaged: reset timing state but KEEP the intervals history
        aa_last_swing_time = os.clock()
        aa_accumulated_pause = 0
        aa_clear_pauses()
    end
    aa_engaged = is_engaged
end

-- Schedule function for clearing a pause source after a fixed delay (2s for WS/JA).
-- Disabling/re-enabling invalidates callbacks from the prior tracking session.
function aa_clear_pause_after(src, delay_seconds)
    if ui.aa_enabled == false then return end
    local generation=ui.aa_generation
    coroutine.schedule(function()
        if ui.aa_enabled and ui.aa_generation==generation then aa_remove_pause_source(src) end
    end, delay_seconds)
end

function ui:combat_strip_left()
    if self.display_palette and self.is_compact then
        return (self:get_slot_x(1,1)+self:get_slot_x(2,7)+40)/2-300
    end
    return self:get_slot_x(1,1)-10
end

function ui:display_skillchain_indicator(player_vitals, skillchain_delay, skillchain_window)
    local opacity = self.theme.skillchain_window_opacity
    local target = opacity > 0 and windower.ffxi.get_mob_by_target('t', 'bt')
    if not target or target.hpp <= 0 or (skillchain_delay <= 0 and skillchain_window <= 0) then
        prim.set_visibility('skillchain_indicator', false)
        prim.set_visibility('skillchain_indicator_bg', false)
        return
    end

    local waiting = skillchain_delay > 0
    local fraction = waiting and (1 - skillchain_delay / 3) or skillchain_window / 7
    local width = math.round(600 * math.max(0, math.min(1, fraction)))
    local x = self:combat_strip_left() + math.round((600-width)/2)
    local palette = self.display_palette
    local y = self:get_slot_y(1, 4) - ((palette or waiting) and 27 or 30)
    local height = palette and (waiting and 3 or 5) or (waiting and 4 or 10)
    prim.set_rounding('skillchain_indicator', palette ~= nil, palette ~= nil)
    prim.set_rounding('skillchain_indicator_bg', palette ~= nil, palette ~= nil)
    local alpha, red, green, blue = opacity
    local border = math.min(150, opacity)

    if palette then
        border = math.min(230, opacity)
        if waiting then
            alpha = math.round(opacity * .57)
            local color = palette.skillchain_waiting
            red, green, blue = color[1], color[2], color[3]
        else
            -- Use the remaining window for a stable flash phase across render frames.
            local white = (1 + math.cos(skillchain_window * 2 * math.pi / .55)) / 2
            local tp = palette.tp
            red = math.round(tp[1] + (255-tp[1])*white)
            green = math.round(tp[2] + (255-tp[2])*white)
            blue = 255
        end
    elseif waiting then
        red, green, blue = self.theme.skillchain_waiting_color_red,
            self.theme.skillchain_waiting_color_green, self.theme.skillchain_waiting_color_blue
    else
        red, green, blue = self.theme.skillchain_open_color_red,
            self.theme.skillchain_open_color_green, self.theme.skillchain_open_color_blue
    end

    prim.set_color('skillchain_indicator_bg', border, 0, 0, 0)
    prim.set_size('skillchain_indicator_bg', width+4, height+4)
    prim.set_position('skillchain_indicator_bg', x-2, y-2)
    prim.set_visibility('skillchain_indicator_bg', width > 0)
    prim.set_color('skillchain_indicator', alpha, red, green, blue)
    prim.set_size('skillchain_indicator', width, height)
    prim.set_position('skillchain_indicator', x, y)
    prim.set_visibility('skillchain_indicator', width > 0)
end

local function lockout_tint(palette, kind, fraction)
    local start = palette.lockout_start
    local finish = kind == 'ws' and palette.ws or kind == 'ja' and palette.tp or palette.mp
    local remaining = math.max(0, math.min(1, fraction))
    return math.round(start[1] * remaining + finish[1] * (1 - remaining)),
        math.round(start[2] * remaining + finish[2] * (1 - remaining)),
        math.round(start[3] * remaining + finish[3] * (1 - remaining))
end

function ui:display_gcd_indicator(visible)
    if visible and gcd_active then
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

            local override = self.theme.lockout_opacity
            if override and override >= 0 then alpha = override end
            if alpha == 0 then
                -- Per-mode opacity 0 = hide this mode's bar entirely.
                prim.set_visibility('gcd_indicator', false)
                prim.set_visibility('gcd_indicator_bg', false)
                return
            end

            if self.display_palette then
                cr, cg, cb = lockout_tint(self.display_palette, gcd_kind, fraction)
            end

            prim.set_color('gcd_indicator', alpha, cr, cg, cb)
            prim.set_color('gcd_indicator_bg', math.min(150,alpha), 0, 0, 0)

            local effective_y_offset = self.gcd_offset_y
            if not self.is_compact then
                effective_y_offset = effective_y_offset + self.hotbar_spacing
            end

            local rounded = self.display_palette ~= nil
            local height = rounded and 4 or 6
            prim.set_rounding('gcd_indicator', rounded, rounded)
            prim.set_rounding('gcd_indicator_bg', rounded, rounded)
            prim.set_size('gcd_indicator', base_width, height)
            prim.set_position(
                'gcd_indicator',
                left_spacer + self:combat_strip_left() + self.gcd_offset_x,
                self:get_slot_y(1, 4) + effective_y_offset
            )
            prim.set_visibility('gcd_indicator', true)

            prim.set_size('gcd_indicator_bg', base_width + 4, height+4)
            prim.set_position(
                'gcd_indicator_bg',
                left_spacer + self:combat_strip_left() - 2 + self.gcd_offset_x,
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

-- Separate tracking from opacity, including stopping all recording when off.
-- Restart with a clean estimate on re-enable so stale timing never flashes.
function ui:set_autoattack_enabled(enabled)
    enabled = enabled ~= false
    if self.aa_enabled == enabled then return end
    self.aa_enabled = enabled
    self.aa_generation=(self.aa_generation or 0)+1
    aa_last_swing_time,aa_intervals,aa_estimate=0,{},nil
    aa_engaged,aa_pause_sources,aa_pause_start=false,{},0
    aa_accumulated_pause=0
    -- During initial setup the three primitives have not been created yet.
    if not enabled and self.is_setup then self:hide_aa_indicator() end
end

-- Hide all three auto-attack bar primitives.
function ui:hide_aa_indicator()
    prim.set_visibility('aa_indicator_red', false)
    prim.set_visibility('aa_indicator_green', false)
    prim.set_visibility('aa_indicator_bg', false)
end

function ui:display_aa_indicator()
    if self.aa_enabled == false then self:hide_aa_indicator();return end
    if (not aa_engaged or aa_last_swing_time == 0) then
        self:hide_aa_indicator()
        return
    end

    -- Opacity 0 is the AA bar's kill switch — bail before any rendering.
    if (self.theme.aa_opacity == 0) then
        self:hide_aa_indicator()
        return
    end

    -- Active elapsed time = wall-clock elapsed minus accumulated pauses
    -- (and minus any in-progress pause).
    local wall_elapsed = os.clock() - aa_last_swing_time
    local pause_so_far = aa_accumulated_pause
    if (aa_is_paused()) then
        pause_so_far = pause_so_far + (os.clock() - aa_pause_start)
    end
    local active_elapsed = wall_elapsed - pause_so_far
    if (active_elapsed < 0) then active_elapsed = 0 end

    -- Determine total bar duration and the estimate cutoff.
    local total_duration
    local estimate_cut
    if (aa_estimate == nil) then
        total_duration = aa_fallback_total
        estimate_cut = aa_fallback_total  -- entire bar is red when no data
    else
        total_duration = 1.5 * aa_estimate
        estimate_cut = aa_estimate
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
    local base_x = self:combat_strip_left() + self.aa_offset_x
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
    local alpha = aa_is_paused() and math.min(self.theme.aa_paused_opacity,self.theme.aa_opacity) or self.theme.aa_opacity
    local bg_alpha = aa_is_paused() and self.theme.aa_paused_background_opacity or self.theme.aa_background_opacity
    local palette = self.display_palette
    local before = palette and palette.ws
    local past = palette and palette.mp
    prim.set_color('aa_indicator_red', alpha,
        before and before[1] or self.theme.aa_before_red,
        before and before[2] or self.theme.aa_before_green,
        before and before[3] or self.theme.aa_before_blue)
    prim.set_color('aa_indicator_green', alpha,
        past and past[1] or self.theme.aa_past_red,
        past and past[2] or self.theme.aa_past_green,
        past and past[3] or self.theme.aa_past_blue)
    prim.set_color('aa_indicator_bg', math.min(bg_alpha,alpha), 0, 0, 0)
    local rounded = palette ~= nil
    local height = rounded and 4 or 6
    prim.set_rounding('aa_indicator_bg', rounded, rounded)
    prim.set_rounding('aa_indicator_red', rounded, rounded and green_px == 0)
    prim.set_rounding('aa_indicator_green', rounded and red_px == 0, rounded)

    if (red_px > 0) then
        prim.set_size('aa_indicator_red', red_px, height)
        prim.set_position('aa_indicator_red', red_x, base_y)
        prim.set_visibility('aa_indicator_red', true)
    else
        prim.set_visibility('aa_indicator_red', false)
    end

    if (green_px > 0) then
        prim.set_size('aa_indicator_green', green_px, height)
        prim.set_position('aa_indicator_green', green_x, base_y)
        prim.set_visibility('aa_indicator_green', true)
    else
        prim.set_visibility('aa_indicator_green', false)
    end

    prim.set_size('aa_indicator_bg', visible_px + 4, height+4)
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

local recast_flash_duration = .15
local recast_flash_alpha = 156

function ui:clear_recast_flash(hotbar, slot)
    local key = (hotbar-1)*8+slot
    self.recast_samples[key] = nil
    if self.recast_flashes[key] then
        self.recast_flash_views[key]:hide()
        self.recast_flashes[key] = nil
    end
end

function ui:clear_recast_flashes()
    for key in pairs(self.recast_flashes) do self.recast_flash_views[key]:hide() end
    self.recast_samples, self.recast_flashes = {}, {}
end

-- A newly visible or rebound slot must first be observed on cooldown.
function ui:observe_recast(hotbar, slot, action, remaining)
    if type(remaining) ~= 'number' then
        self:clear_recast_flash(hotbar,slot)
        return
    end
    local key = (hotbar-1)*8+slot
    local previous = self.recast_samples[key]
    if not previous or previous.action ~= action then
        if self.recast_flashes[key] then self:clear_recast_flash(hotbar,slot) end
        self.recast_samples[key] = {action=action, cooling=remaining > 0}
        return
    end
    if remaining > 0 then
        if self.recast_flashes[key] then
            self:clear_recast_flash(hotbar,slot)
            self.recast_samples[key] = previous
        end
        previous.cooling = true
        return
    end
    if not previous.cooling then return end
    previous.cooling = false
    local view = self.recast_flash_views[key]
    if not view then
        view = new_image(images_setup)
        view:path(windower.addon_path .. 'images/assets/recast-glow.png')
        view:size(40+2*slot_glow_padding,40+2*slot_glow_padding)
        geometry:assign_bank(view, hotbar)
        self.recast_flash_views[key] = view
    end
    view:pos(self:get_slot_x(hotbar,slot)-slot_glow_padding,
        self:get_slot_y(hotbar,slot)-slot_glow_padding)
    view:alpha(recast_flash_alpha)
    view:show()
    self.recast_flashes[key] = {hotbar=hotbar,slot=slot,started=self.recast_flash_clock()}
end

function ui:tick_recast_flashes()
    for key,flash in pairs(self.recast_flashes) do
        local view = self.recast_flash_views[key]
        local left = 1 - (self.recast_flash_clock()-flash.started)/recast_flash_duration
        if left <= 0 then
            view:hide()
            self.recast_flashes[key] = nil
        else
            view:pos(self:get_slot_x(flash.hotbar,flash.slot)-slot_glow_padding,
                self:get_slot_y(flash.hotbar,flash.slot)-slot_glow_padding)
            view:alpha(math.floor(recast_flash_alpha*left*left+.5))
        end
    end
end

-- check action recasts
function ui:check_recasts(player_hotbar, player_vitals, environment, spells, gamepad_state, skillchains, consumables, dim_default_slots, in_battle, menu_open, preview_bank, tentative_slot, display_bank)
    animation_frame_count = animation_frame_count + self.frame_skip + 1
    if (animation_frame_count > 40) then
        animation_frame_count = 1
    end

    dim_default_slots = dim_default_slots or false
    local observe_recasts = self.recast_flash_enabled and not menu_open
    if menu_open and next(self.recast_samples) then self:clear_recast_flashes() end

    local skillchain_delay, skillchain_window = skillchains.get_skillchain_window()
    self:display_skillchain_indicator(player_vitals, skillchain_delay, skillchain_window)
    self:display_aa_indicator()

    local active_bar = menu_open and (preview_bank or 0) or display_bank
        or (gamepad_state.active_bar ~= 0 and gamepad_state.active_bar or gamepad_state.shoulder_display or 0)
    if menu_open and preview_bank and preview_bank >= 1 and self.hotbars[preview_bank] ~= nil
        and tentative_slot and tentative_slot >= 1 and tentative_slot <= 8 then
        self.binding_tint:pos(self:get_slot_x(preview_bank, tentative_slot), self:get_slot_y(preview_bank, tentative_slot))
        self.binding_tint:show()
    else
        self.binding_tint:hide()
    end
    if active_bar ~= 0 then
        for _, field in ipairs({self.bar_background, self.bar_background_left, self.bar_background_right}) do
            if menu_open then
                field:color(unpack(amber_stroke))
                field:alpha(math.min(self.button_bg_alpha, 140))
            else
                field:color(255, 255, 255)
                field:alpha(self.button_bg_alpha)
            end
        end
        self:show_bar_background(active_bar)
    else
        self.bar_background:hide()
        self.bar_background_left:hide()
        self.bar_background_right:hide()
    end

    local pet_state
    self.resolved_slots = self.resolved_slots or {}
    for _, h in ipairs(self.render_banks) do
        local isThisBarActive = active_bar == h
        local isThisBarVisibleByDefault
        local shouldDrawDefaultVisibleBars
        if not self.AutoHideExtraBars then
            isThisBarVisibleByDefault = h < 3 or h > 4 and h < 7
            shouldDrawDefaultVisibleBars = active_bar < 3 or active_bar > 4 and active_bar < 7
        else
            isThisBarVisibleByDefault = h < 3
            shouldDrawDefaultVisibleBars = active_bar < 3
        end
        local shouldDrawThisBar = isThisBarActive or isThisBarVisibleByDefault and shouldDrawDefaultVisibleBars
        self.pulse_visible_bars[h]=shouldDrawThisBar
        local slide = geometry.banks[h].slide
        local outgoing = not menu_open and slide.active and slide.target == 0
        self.bank_labels[h]:visible(self.bank_labels_visible and self.bank_label_opacity > 0 and (shouldDrawThisBar or outgoing))
        if shouldDrawThisBar or outgoing then
            for i=1,8,1 do
                local slot = i
                if slot == 10 then slot = 0 end

                self.hotbars[h].slot_background[i]:show()
                local shade = menu_open and 205 or 255
                self.hotbars[h].slot_icon[i]:color(shade, shade, shade)
                self.hotbars[h].slot_icon[i]:show()
                self.hotbars[h].slot_frame[i]:show()
                self.hotbars[h].slot_element[i]:show()
                self.hotbars[h].slot_text[i]:show()

                local bar = shoulders.bar(player_hotbar, environment, h)
                local action = bar and bar['slot_' .. slot]

                if (action == nil or action.action == nil or (self.display_palette and action.action == '')) then
                    action = maybe_get_default_action(player_hotbar, environment, h, slot)
                end
                if self.display_palette and action and (not action.action or action.action == '') then
                    action = nil
                end

                local inherited_set = dim_default_slots and action and action.source_environment
                if inherited_set == environment then inherited_set = nil end

                local resolved, unavailable_reason
                if action and (action.type == 'ma' or action.type == 'ja' or action.type == 'pet') then
                    pet_state = pet_state or pet_policy.snapshot(windower.ffxi)
                    resolved = pet_policy.resolve(action, pet_state, crossbar_spells)
                    local effective = resolved or action
                    unavailable_reason = pet_policy.unavailable(effective, pet_state, crossbar_abilities)
                        or trust_policy.unavailable(effective, pet_state.trust, crossbar_spells)
                end
                local slot_key = h * 8 + i
                local previous = self.resolved_slots[slot_key]
                if resolved and (not previous or previous.type ~= resolved.type or previous.action ~= resolved.action
                    or previous.target ~= resolved.target or previous.alias ~= resolved.alias)
                    or previous and not resolved then
                    self:load_action(player_hotbar, environment, h, i, resolved or action, player_vitals, not inherited_set)
                    self.resolved_slots[slot_key] = resolved
                end
                action = resolved or action
                if not inherited_set then self.hotbars[h].slot_cost[i]:show() end

                local frame = self.hotbars[h].slot_frame[i]
                if self.display_palette and not action then
                    frame:path(self.empty_frame_image_path)
                    if self.theme.hide_empty_slots then
                        frame:hide()
                        self.hotbars[h].slot_background[i]:hide()
                    end
                elseif frame:path() == self.empty_frame_image_path then
                    frame:path(self.frame_image_path)
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

                local glow = self.slot_glow_enabled and self.pulse_tracks[i]
                if glow and glow.hotbar ~= h then glow = nil end
                local occupied = action and action.action and action.action ~= ''
                local unavailable = unavailable_reason or (glow and occupied and not action.type)

                -- Honor linked_type so an action that LINKS to a spell/ability/WS
                -- enters the recast-tracking branch below even though its own
                -- type is e.g. 'ex' (gear-swap command). Without this the gate
                -- bails before the recast code can look up the linked metadata.
                local effective_type = action and (action.linked_type or action.type) or nil
                -- In binding previews the source badge owns this overlay and
                -- replaces the cost and recast display for inherited slots.
                if inherited_set then
                    self.hotbars[h].slot_warmup[i]:hide()
                    self:mark_default_set_action(h, i, inherited_set)
                elseif action == nil or (effective_type ~= 'ma' and effective_type ~= 'ja' and effective_type ~= 'ws' and effective_type ~= 'pet' and effective_type ~= 'enchanteditem') then
                    self:clear_recast(h, i)
                    if observe_recasts then self:clear_recast_flash(h,i) end
                    if (action ~= nil and action.type == 'item') then
                        local item_count = consumables:get_item_count_by_name(action.action)
                        if glow and (tonumber(item_count) or 0) <= 0 then unavailable = true end
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
                else
                    local crossbar_action = nil
                    local skill_recasts = nil
                    local remaining
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
                                        if glow then unavailable = true end
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
                                            if glow then unavailable = true end
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
                        in_warmup = warmup_fraction < 1 or self.disabled_slots.on_warmup[action.action]

                        if in_warmup then
                            -- register first cooldown to calculate percentage
                            if self.disabled_slots.on_warmup[action.action] == nil then
                                self.disabled_slots.on_warmup[action.action] = self.enchanted_items:get_warmup_time(action.action)

                                -- setup recast elements
                                self.hotbars[h].slot_warmup[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/blue-square.png')
                            end
                        end

                        local cooldown_fraction = self.enchanted_items:get_cooldown_fraction(action.action)
                        remaining = cooldown_fraction
                        in_cooldown = cooldown_fraction > 0

                        if in_cooldown then
                            -- remove the warmup backdrop
                            self.disabled_slots.on_warmup[action.action] = nil
                            self.hotbars[h].slot_warmup[i]:hide()

                            -- register first cooldown to calculate percentage
                            if self.disabled_slots.on_cooldown[action.action] == nil then
                                self.disabled_slots.on_cooldown[action.action] = self.enchanted_items:get_cooldown_time(action.action)
                            end
                        end

                        is_in_seconds = true
                    end

                    -- check if skill is in cooldown
                    if has_spell and crossbar_action and skill_recasts then
                        remaining = skill_recasts[crossbar_action.recast_id]
                    end
                    if type(remaining)=='number' and remaining > 0 and crossbar_action then
                        -- register first cooldown to calculate percentage
                        if self.disabled_slots.on_cooldown[action.action] == nil then
                            self.disabled_slots.on_cooldown[action.action] = skill_recasts[crossbar_action.recast_id]
                        end

                        in_cooldown = true
                    end

                    if observe_recasts then
                        self:observe_recast(h,i,action,has_spell and not in_warmup and remaining or nil)
                    end

                    if glow and (in_cooldown or in_warmup or not has_spell or not crossbar_action) then
                        unavailable = true
                    end

                    -- if skill is in cooldown
                    if in_cooldown then
                        -- disable slot if it's not disabled
                        if self.disabled_slots.actions[action.action] == nil then
                            self.disabled_slots.actions[action.action] = true
                            self:toggle_slot(h, i, false)
                        end

                        if self.theme.hide_recast_animation then self.hotbars[h].slot_recast[i]:hide() end
                        -- show recast animation
                        if self.theme.hide_recast_animation == false or self.theme.hide_recast_text == false then
                            local time_remaining = 0

                            local new_height = 40
                            if (action.type == 'enchanteditem') then
                                time_remaining = self.enchanted_items:get_cooldown_fraction(action.action) * self.enchanted_items:get_cooldown_time(action.action)
                                new_height = 40 * self.enchanted_items:get_cooldown_fraction(action.action)
                            else
                                time_remaining = skill_recasts[crossbar_action.recast_id]
                                local full_recast = tonumber(self.disabled_slots.on_cooldown[action.action])
                                new_height = 40 * (time_remaining / full_recast)
                            end
                            if new_height > 40 then new_height = 40 end -- temporary bug fix
                            local recast_time = calc_recast_time(time_remaining, is_in_seconds)

                            -- show recast if settings allow it
                            if self.theme.hide_recast_animation == false then
                                self.hotbars[h].slot_recast[i]:path(windower.addon_path .. '/images/' .. get_icon_pathbase() .. '/ui/black-square.png')
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
                        self.hotbars[h].slot_recast[i]:hide()
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

                        if self.disabled_slots.on_cooldown[action.action] == true then
                            self.disabled_slots.on_cooldown[action.action] = nil
                        end

                        -- if it's not disabled by vitals nor cooldown, enable slot
                        if self.disabled_slots.actions[action.action] == true and self.disabled_slots.no_vitals[action.action] == nil then
                            self.disabled_slots.actions[action.action] = nil
                            self:toggle_slot(h, i, true)
                        end
                    end

                    -- Restore base frame even with a warmup or missing metadata;
                    -- never leave the prior skillchain animation attached to this slot.
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
                end
                if unavailable_reason then
                    self.hotbars[h].slot_icon[i]:color(130, 130, 130)
                end
                if glow then
                    if not occupied then glow.brightness = 145
                    elseif unavailable or self.hotbars[h].slot_icon[i]:alpha() < 255 then glow.brightness = 190
                    else glow.brightness = 250 end
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
                if observe_recasts then self:clear_recast_flash(h,i) end
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
        elseif h == 3 or h == 4 or shoulders.labels[h] then
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
    if shoulders.labels[hb] then return nil end
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

-- Optional companion-bank pulse layered above the existing white flash.
-- The pulse acknowledges a routed press, not a successful FFXI action.
function ui:clear_slot_pulses()
    if self.slot_pulse then self.slot_pulse:cancel() end
    self.pulse_tracks,self.pulse_visible_bars={},{}
    for _,view in ipairs(self.pulse_views) do view:hide() end
    for _,view in ipairs(self.glow_views) do view:hide() end
end

function ui:set_slot_pulse_enabled(enabled)
    self.slot_pulse_enabled = enabled == true
    if not self.slot_pulse_enabled then
        if self.slot_glow_enabled then
            for _,view in ipairs(self.pulse_views) do view:hide() end
        else
            self:clear_slot_pulses()
        end
    end
end

function ui:set_slot_glow_enabled(enabled)
    self.slot_glow_enabled = enabled == true
    if not self.slot_glow_enabled then
        if self.slot_pulse_enabled then
            for _,view in ipairs(self.glow_views) do view:hide() end
        else
            self:clear_slot_pulses()
        end
    elseif self.pulse_views[1] and not self.glow_views[1] then
        for slot=1,8 do
            local view = new_image(images_setup)
            prepare_image(view, windower.addon_path .. 'images/assets/slot-glow.png')
            view:size(40+2*slot_glow_padding,40+2*slot_glow_padding)
            view:hide()
            self.glow_views[slot] = view
        end
    end
end

function ui:press_slot_pulse(hotbar,slot)
    if not (self.slot_pulse_enabled or self.slot_glow_enabled) or not self.slot_pulse or not self.pulse_views[slot] then return end
    self.slot_pulse:press(slot,hotbar,slot)
    self.pulse_tracks[slot]={hotbar=hotbar,slot=slot}
    local x,y=self:get_slot_x(hotbar,slot),self:get_slot_y(hotbar,slot)
    local view=self.pulse_views[slot]
    geometry:assign_bank(view, hotbar)
    view:pos(x,y)
    local glow=self.glow_views[slot]
    if glow then
        geometry:assign_bank(glow, hotbar)
        glow:pos(x-slot_glow_padding,y-slot_glow_padding)
    end
end

function ui:release_slot_pulse(slot)
    if self.slot_pulse then self.slot_pulse:release(slot) end
end

function ui:show_slot_pulse(menu_open)
    if not (self.slot_pulse_enabled or self.slot_glow_enabled) or not self.slot_pulse then return end
    for slot,view in ipairs(self.pulse_views) do
        local track=self.pulse_tracks[slot]
        local alpha,held = 0,false
        if track then alpha,held = self.slot_pulse:alpha(track.hotbar,track.slot) end
        local visible = alpha > 0 and self.pulse_visible_bars[track.hotbar]
        if visible and self.slot_pulse_enabled then
            view:alpha(alpha)
            view:show()
        else
            view:hide()
        end
        local glow=self.glow_views[slot]
        if glow then
            if visible and held and track.brightness and self.slot_glow_enabled and not menu_open then
                glow:alpha(track.brightness)
                glow:show()
            else
                glow:hide()
            end
        end
        if alpha <= 0 then self.pulse_tracks[slot]=nil end
    end
end

-- trigger feedback visuals in given hotbar and slot
function ui:trigger_feedback(hotbar, slot)
    if slot == 0 then slot = 10 end    
    self.feedback.hotbar, self.feedback.slot = hotbar, slot
    geometry:assign_bank(self.feedback_icon, hotbar)
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
    if opacity > 0 then self.feedback_icon:show()
    else self.feedback_icon:hide(); self.feedback.is_active = false end
end

return ui
