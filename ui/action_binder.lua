local ui_resources = require('ui/resources')
require("lists")
require("strings")
require("tables")

local mount_roulette = require('libs/mountroulette/mountroulette')
local item_icons = require('ui/item_icons')
local kebab_casify = require('libs/kebab_casify')
local crossbar_abilities = require('resources/crossbar_abilities')
local crossbar_spells = require('resources/crossbar_spells')
local player_data = require('libs/player')
texts = require('texts')
local defaults = require('libs/defaults')
settings = config.load(defaults)
local action_binder = {}
local review = require('ui/custom_action_review')
local caption_layout = require('ui/text_layout').new()
local theme = require('ui/theme')
local theme_options = theme.apply(settings)
local icon_pack = nil
local sw_zones = require('libs/sw_zones')

local WYVERN_ABILITIES_TO_FILTER = {
        ['1151'] = true,
        ['1152'] = true,
        ['1153'] = true,
        ['1154'] = true,
        ['1155'] = true,
        ['1156'] = true,
        ['1157'] = true,
        ['1158'] = true,
        ['1159'] = true,
        ['1160'] = true,
        ['1161'] = true,
        ['1162'] = true,
        ['1163'] = true,
        ['1164'] = true,
        ['1165'] = true,
        ['1166'] = true
    }

local get_icon_pathbase = function()
    return 'icons/' .. icon_pack
end

-- Assumes a kebab_casify'd string
-- TODO: Test if this works properly
-- TODO: Rewrite this to be more readable (and maybe also works for non-kebab_casify'd strings)
local get_base_spell_for_higher_level_spells = function(icon_path)
	if not icon_path then
        return ""
    end

    local suffixes = {
        II = true,
        III = true,
        IV = true,
        V = true,
        VI = true,
        VII = true,
    }

    -- Extract the last "-" separated part
    local suffix = icon_path:match("([^%-]+)$")

    -- If it's one of the higher spell level Roman numerals, remove it and the preceding "-"
    if suffix and suffixes[suffix:upper()] then
        return icon_path:gsub("%-[^%-]+$", "")
    end

    return icon_path
end

-- TODO: Test if this works properly
-- TODO: Rewrite this to be more readable
function get_spirit_by_element(icon_path, element_name)
    local elements = res.elements

    for _key, entry in pairs(res.spells) do
        if entry.type == 'SummonerPact' and entry.en:contains('Spirit') then
            if entry.element == elements:with('en', element_name).id then
                local new_icon_path = icon_path:gsub("([^/]+)%.png$", string.format("%05d", entry.id) .. ".png")
                return true, new_icon_path
            end
        end
    end

    return false, nil
end

-- TODO: The references to this function currently don't fill "category", it's always nil. So update the references.
-- TODO: Are there other cases where a non-spell might be named "something-ii" or similar? In that case, expand the guard for those cases.
-- TODO: Maybe split this into sub-versions, like maybe_get_custom_icon_default, maybe_get_custom_icon_bloodpact etc.
-- That would also get rid of category and element for the default version
local maybe_get_custom_icon = function(default_icon, custom_icon, category, element)
    local pathbase = get_icon_pathbase()
    local icon_path = 'images/' .. pathbase .. '/' .. custom_icon
    local icon_file = require('ui/assets').exists(icon_path)

    if (icon_file) then
        return icon_path, true
    else
        -- TODO: Remove the redundancy
        -- TODO: Check if the fallback actually works if only e.g. curing-waltz.png is available,
        -- but not curing-waltz-iii
        -- TODO: Also check if the fallback maybe is already implemented elsewhere to avoid doing a redundant fallback check
        if category == "spell" then
            local fallback_icon_path = get_base_spell_for_higher_level_spells(icon_path)
            local fallback_icon_file = require('ui/assets').exists(fallback_icon_path)
            
            if (fallback_icon_file) then
                return fallback_icon_path, true
            else
                return default_icon, false
            end
        elseif category~= nil and string.contains(category, "blood_pact") and element ~= nil then
            local fallback_found, fallback_icon_path = get_spirit_by_element(icon_path, element)
            
            if not fallback_found then
                return default_icon, false
            end
            
            local fallback_icon_file = require('ui/assets').exists(fallback_icon_path)
            
            if (fallback_icon_file) then
                return fallback_icon_path, true
            else
                return default_icon, false
            end
        else
            return default_icon, false
        end
    end
end

local left_trigger_lifted_during_doublepress_window = false
local right_trigger_lifted_during_doublepress_window = false
local is_left_doublepress_window_open = false
local is_right_doublepress_window_open = false

local function close_left_doublepress_window()
    is_left_doublepress_window_open = false
    left_trigger_lifted_during_doublepress_window = false
end

local function close_right_doublepress_window()
    is_right_doublepress_window_open = false
    right_trigger_lifted_during_doublepress_window = false
end

local states = {
    ['HIDDEN'] = 0,
    ['SELECT_ACTION_TYPE'] = 1,
    ['SELECT_ACTION'] = 2,
    ['SELECT_ACTION_TARGET'] = 3,
    ['SELECT_PLAYER_BINDING'] = 4,
    ['SELECT_BUTTON_ASSIGNMENT'] = 5,
    ['CONFIRM_BUTTON_ASSIGNMENT'] = 6,
    ['SHOW_CREDITS'] = 7,
    ['SELECT_ICON'] = 8,
    ['ENTER_CUSTOM_ACTION_ALIAS'] = 10,
    ['ENTER_CUSTOM_ACTION_NAME'] = 11,
    ['ENTER_CUSTOM_ACTION_COMMAND'] = 12,
    ['SELECT_CUSTOM_ACTION_ICON_CHOICE'] = 13,
    ['SELECT_LINKED_TYPE'] = 14,
    ['CONFIRM_CUSTOM_ACTION'] = 15,
    ['EDIT_CUSTOM_ACTION_PICK'] = 16,
    ['EDIT_CUSTOM_ACTION_REVIEW'] = 17,
    ['DELETE_CUSTOM_ACTION_PICK'] = 18,
    ['DELETE_CUSTOM_ACTION_CONFIRM'] = 19,
    ['ENTER_SET_NAME'] = 20,
    ['ENTER_SET_ALIAS'] = 21,
}

local action_types = {
    ['DELETE'] = 0,
    ['JOB_ABILITY'] = 1,
    ['WEAPONSKILL'] = 2,
    ['PET_COMMAND'] = 3,
    ['WHITE_MAGIC'] = 4,
    ['BLACK_MAGIC'] = 5,
    ['SONG'] = 6,
    ['READY'] = 7,
    ['NINJUTSU'] = 8,
    ['SUMMON'] = 9,
    ['BP_RAGE'] = 10,
    ['BP_WARD'] = 11,
    ['BLUE_MAGIC'] = 12,
    ['PHANTOM_ROLL'] = 13,
    ['QUICK_DRAW'] = 14,
    ['STRATAGEMS'] = 15,
    ['DANCES'] = 16,
    ['RUNE_ENCHANTMENT'] = 17,
    ['WARD'] = 18,
    ['EFFUSION'] = 19,
    ['GEOMANCY'] = 20,
    ['TRUST'] = 21,
    ['MOUNT'] = 22,
    ['USABLE_ITEM'] = 23,
    ['TRADABLE_ITEM'] = 24,
    ['RANGED_ATTACK'] = 25,
    ['ATTACK'] = 26,
    ['ASSIST'] = 27,
    ['MAP'] = 28,
    ['LAST_SYNTH'] = 29,
    ['SWITCH_TARGET'] = 30,
    ['SWITCH_CROSSBARS'] = 31,
    ['MOVE_CROSSBARS'] = 32,
    ['SHOW_CREDITS'] = 33,
    ['CUSTOM_ACTION'] = 34,
    ['CHANGE_ICON'] = 35,
    ['GLOBAL_ICON_SET'] = 36,
    ['CREATE_CUSTOM_ACTION'] = 37,
    ['EDIT_CUSTOM_ACTION'] = 38,
    ['DELETE_CUSTOM_ACTION'] = 39,
    ['QUICK_SWITCH_CROSSBARS'] = 40,
    ['GS_MACRO'] = 41,
    ['CREATE_NEW_SET'] = 42,
	['EXECUTE_COMMAND'] = 43,
	['SUPERWARP'] = 44,
    ['CHECK'] = 45,
}

local prefix_lookup = {
    [action_types.DELETE] = '',
    [action_types.JOB_ABILITY] = 'ja',
    [action_types.WEAPONSKILL] = 'ws',
    [action_types.PET_COMMAND] = 'pet',
    [action_types.WHITE_MAGIC] = 'ma',
    [action_types.BLACK_MAGIC] = 'ma',
    [action_types.SONG] = 'ma',
    [action_types.READY] = 'pet',
    [action_types.NINJUTSU] = 'ma',
    [action_types.SUMMON] = 'ma',
    [action_types.BP_RAGE] = 'pet',
    [action_types.BP_WARD] = 'pet',
    [action_types.BLUE_MAGIC] = 'ma',
    [action_types.PHANTOM_ROLL] = 'ja',
    [action_types.QUICK_DRAW] = 'ja',
    [action_types.STRATAGEMS] = 'ja',
    [action_types.DANCES] = 'ja',
    [action_types.RUNE_ENCHANTMENT] = 'ja',
    [action_types.WARD] = 'ja',
    [action_types.EFFUSION] = 'ja',
    [action_types.GEOMANCY] = 'ma',
    [action_types.TRUST] = 'ma',
    [action_types.MOUNT] = 'mount',
    [action_types.USABLE_ITEM] = 'item',
    [action_types.TRADABLE_ITEM] = 'item',
    [action_types.RANGED_ATTACK] = 'ct',
    [action_types.ATTACK] = 'a',
    [action_types.CHECK] = 'ct',
    [action_types.ASSIST] = 'assist',
    [action_types.MAP] = 'map',
    [action_types.LAST_SYNTH] = 'ct',
    [action_types.SWITCH_CROSSBARS] = 'ex',
    [action_types.SWITCH_TARGET] = 'ta',
    [action_types.CUSTOM_ACTION] = 'ex',
    [action_types.CHANGE_ICON] = '',         -- meta action, doesn't write a binding type
    [action_types.GLOBAL_ICON_SET] = '',     -- meta action, writes to SharedIcons.xml not a slot
    [action_types.CREATE_CUSTOM_ACTION] = '', -- meta action, writes to CustomActions.xml not a slot
    [action_types.EDIT_CUSTOM_ACTION]   = '', -- meta action, edits CustomActions.xml entries
    [action_types.DELETE_CUSTOM_ACTION] = '', -- meta action, removes a CustomActions.xml entry
    [action_types.QUICK_SWITCH_CROSSBARS] = 'switch', -- temp-switch to another set; auto-reverts after one action
    [action_types.GS_MACRO] = 'gs',
    [action_types.CREATE_NEW_SET] = 'ex',
	[action_types.EXECUTE_COMMAND] = 'ex',
	[action_types.SUPERWARP] = 'ex',
}

-- Reverse-display lookup for stored linked_type prefixes. Used by the Edit
-- review screen so users see "Magic" / "Job Ability" rather than the raw
-- "ma" / "ja" prefix that's persisted in CustomActions.xml. 
local linked_type_display = {
    ['ma']     = 'Magic',
    ['ja']     = 'Job Ability',
    ['ws']     = 'Weaponskill',
    ['pet']    = 'Pet Command',
    ['mount']  = 'Mount',
    ['item']   = 'Item',
    ['ct']     = 'Chat Command',
    ['a']      = 'Auto Attack',
    ['ra']     = 'Ranged',
    ['ta']     = 'Target Action',
    ['assist'] = 'Assist',
    ['map']    = 'Map',
    ['ex']     = 'Custom',
}

local action_targets = {
    ['NONE'] = '',
    ['SELF'] = 'me',
    ['CURRENT_TARGET'] = 't',
    ['BATTLE_TARGET'] = 'bt',
    ['SELECT_TARGET'] = 'st',
    ['SELECT_PLAYER'] = 'stpc',
    ['SELECT_NPC'] = 'stnpc',
    ['SELECT_PARTY'] = 'stpt',
    ['SELECT_ALLIANCE'] = 'stal'
}

local SPELL_TYPE_LOOKUP = {
    ['BardSong'] = 'songs',
    ['BlackMagic'] = 'black magic',
    ['BlueMagic'] = 'blue magic',
    ['WhiteMagic'] = 'white magic',
    ['SummonerPact'] = 'summoning magic',
	['Geomancy'] = 'geomancy',
}

function action_binder:setup(buttonmapping, save_binding_func, delete_binding_func, theme_options, get_crossbar_sets_func, base_x, base_y, max_width, max_height,
change_slot_icon_func, save_global_icon_func, save_custom_action_func, update_custom_action_func, delete_custom_action_func, create_new_set_func)
    ui_resources.clear(self.images); ui_resources.clear(self.hints)
    if self.title then self.title:destroy() end
    -- A single centered panel owns the background, title and selector. Style
    -- offsets move the crossbar only; applying them here displaced the backdrop.
    local screen = windower.get_windower_settings()
    base_x, base_y, max_width, max_height = require('ui/menu_layout').fit(screen.ui_x_res, screen.ui_y_res)
    self.button_layout = buttonmapping.button_layout
    self.confirm_button = buttonmapping.confirm_button
    self.cancel_button = buttonmapping.cancel_button
    self.mainmenu_button = buttonmapping.mainmenu_button
    self.activewindow_button = buttonmapping.activewindow_button
    self.save_binding = save_binding_func
    self.delete_binding = delete_binding_func
    self.get_crossbar_sets_binding = get_crossbar_sets_func
    self.change_slot_icon = change_slot_icon_func
    self.save_global_icon = save_global_icon_func
    self.save_custom_action = save_custom_action_func
    self.update_custom_action = update_custom_action_func
    self.delete_custom_action = delete_custom_action_func
    self.create_new_set_binding = create_new_set_func
    self.is_hidden = true
    self:set_capturing_text(false)
    self.text_entry_buffer = ''
    self.new_set_name = nil
    self.new_set_alias = nil
    self.selector = require('ui/selectablelist')
    self.theme_options = theme_options
    self.title = self:create_text('Select Action Type', base_x + 50, base_y + 30)
    self.title:size(18)
    self.title:hide()
    self.base_x = base_x
    self.base_y = base_y
    self.width =  max_width or (windower.get_windower_settings().ui_x_res - 300)
    self.height = max_height or (windower.get_windower_settings().ui_y_res - 300)
    self.state = states.HIDDEN
    self.action_type = nil
    self.action_name = nil
    self.target_type = nil
    self.action_target = nil
    self.active_crossbar = nil
    self.action_command = nil
    self.action_icon = nil
    self.hotkey = nil
    self.selection_states = {}
    self.images = L{}
    self.hints = L{}
    self.dpad_left_pressed = false
    self.dpad_right_pressed = false
    self.dpad_down_pressed = false
    self.dpad_up_pressed = false
    self.button_a_pressed = false
    self.button_b_pressed = false
    self.button_x_pressed = false
    self.button_y_pressed = false
    self.trigger_left_pressed = false
    self.trigger_right_pressed = false

    icon_pack = theme_options.iconpack

    require('ui/menu_background').create(windower.prim, 'dialog_bg')
    require('ui/menu_background').set_color(windower.prim, 'dialog_bg', 150, 0, 0, 0)
    require('ui/menu_background').set_position(windower.prim, 'dialog_bg', self.base_x, self.base_y)
    require('ui/menu_background').set_size(windower.prim, 'dialog_bg', self.width, self.height)
    require('ui/menu_background').set_visibility(windower.prim, 'dialog_bg', false)

    windower.prim.create('button_entry_bg')
    windower.prim.set_color('button_entry_bg', 150, 0, 0, 0)
    windower.prim.set_position('button_entry_bg', self.base_x + 150, self.base_y + 150)
    windower.prim.set_size('button_entry_bg', self.width - 300, self.height - 300)
    windower.prim.set_visibility('button_entry_bg', false)
    -- Create selection primitives/cursor after the backdrop so review's more
    -- opaque background cannot cover them.
    self.selector:setup(theme_options, base_x + 50, base_y + 75, max_width - 100, max_height - 175)
    self.selector.normal_base_x = base_x + (max_width - self.selector.width) / 2
    self.selector.base_x = self.selector.normal_base_x
    self:reload()
end

function action_binder:reset_state()
    ui_resources.clear(self.images); ui_resources.clear(self.hints)
    self.inline_entry_text = nil
    self.custom_action_value_texts = nil
    self.custom_action_name_required = false
    self.page_gesture = nil
    self.menu_buttons_down = {}
    self.state = states.HIDDEN
    self.action_type = nil
    self.action_name = nil
    self.target_type = nil
    self.action_target = nil
    self.active_crossbar = nil
    self.action_command = nil
    self.action_icon = nil
    self.icon_picker_return = nil
    self.action_linked_action = nil
    self.action_linked_type = nil
    self.action_alias = nil
    self.action_catalog = nil
    self.hotkey = nil
    self.selection_states = {}
    self.selector:reset_state()
    self.images = L{}
    self.hints = L{}
    self.icon_picker_stack = {}
    self.icon_picker_path = ''
    self.global_icon_source_name = nil
    self.custom_action_draft = nil
    self.custom_action_review_field = nil
    self.binding_custom_action_review = false
    self.custom_action_entry_origin = nil
    self.is_linking_for_custom_action = false
    self.editing_custom_action = false
    self.custom_action_original_name = nil
    self.custom_action_delete_target = nil
    self:set_capturing_text(false)
    self.text_entry_buffer = ''
    self.new_set_name = nil
    self.new_set_alias = nil
end

function action_binder:reset_gamepad()
    self:reset_gamepad_dpad()
    self:reset_gamepad_face_buttons()
    self:reset_gamepad_triggers()
end

function action_binder:reset_gamepad_dpad()
    self.dpad_left_pressed = false
    self.dpad_right_pressed = false
    self.dpad_down_pressed = false
    self.dpad_up_pressed = false
end

function action_binder:reset_gamepad_face_buttons()
    self.button_a_pressed = false
    self.button_b_pressed = false
    self.button_x_pressed = false
    self.button_y_pressed = false
end

function action_binder:reset_gamepad_triggers()
    self.trigger_left_pressed = false
    self.trigger_left_doublepressed = false
    self.trigger_right_pressed = false
    self.trigger_right_doublepressed = false
end

function action_binder:clear_controller_input()
    self:reset_gamepad()
    close_left_doublepress_window()
    close_right_doublepress_window()
    -- Cancel a pending turn without treating focus changes as button presses.
    self.page_gesture = nil
    if self.selector then self.selector:page_highlight(nil) end
end

-- A: gamepad's a/b/x/y are physical slot names, not the printed Xbox labels.
-- Share this interpretation with the Options chooser; honor every saved layout.
function action_binder:is_cancel_button(button)
    local labels = {
        gamecube={a='a',b='b',x='x',y='y'},
        playstation={a='cross',b='square',x='circle',y='triangle'},
        xbox={a='a',b='x',x='b',y='y'},
        nintendo={a='b',b='y',x='a',y='x'},
    }
    local layout = labels[self.button_layout]
    return layout ~= nil and layout[button] ~= nil and layout[button] == self.cancel_button
end

function action_binder:create_text(caption, x, y)
    local text_field = ui_resources.text({flags = {draggable = false}})
    require('ui/render_trace').track(text_field,nil,'binder','caption')
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

function action_binder:set_ui_offset_callback(update_offsets)
    self.update_offsets = update_offsets
end

function action_binder:update_active_crossbar(left_trigger_just_pressed, right_trigger_just_pressed)
    if (self.trigger_left_pressed and self.trigger_right_pressed) then
        if (self.theme_options.hotbar_number > 3) then
            if (left_trigger_just_pressed) then
                -- R -> L = bar 3
                self.active_crossbar = 3
            elseif (right_trigger_just_pressed) then
                -- L -> R = bar 4
                self.active_crossbar = 4
            end
        else
            self.active_crossbar = 3
        end
    elseif (self.trigger_left_pressed) then
        if (self.theme_options.hotbar_number > 4 and self.trigger_left_doublepressed) then
            self.active_crossbar = 5
        else
            self.active_crossbar = 1
        end
    elseif (self.trigger_right_pressed) then
        if (self.theme_options.hotbar_number > 4 and self.trigger_right_doublepressed) then
            self.active_crossbar = 6
        else
            self.active_crossbar = 2
        end
    else
        self.active_crossbar = nil
    end
end

function action_binder:dpad_left(pressed)
    self:menu_input('left',pressed)
    if self.capturing_text then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_left_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 1
            self:submit_selected_option()
        end
    elseif (pressed and self.state == states.MOVE_CROSSBARS) then
        self.theme_options.offset_x = self.theme_options.offset_x - 10
        self.update_offsets(self.theme_options.offset_x, self.theme_options.offset_y)
    elseif (pressed) then
        self:decrement_col()
    end
end

function action_binder:dpad_right(pressed)
    self:menu_input('right',pressed)
    if self.capturing_text then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_right_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 3
            self:submit_selected_option()
        end
    elseif (pressed and self.state == states.MOVE_CROSSBARS) then
        self.theme_options.offset_x = self.theme_options.offset_x + 10
        self.update_offsets(self.theme_options.offset_x, self.theme_options.offset_y)
    elseif (pressed) then
        self:increment_col()
    end
end

function action_binder:dpad_down(pressed)
    self:menu_input('down',pressed)
    if self.capturing_text then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_down_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 2
            self:submit_selected_option()
        end
    elseif (pressed and self.state == states.MOVE_CROSSBARS) then
        self.theme_options.offset_y = self.theme_options.offset_y + 10
        self.update_offsets(self.theme_options.offset_x, self.theme_options.offset_y)
    elseif (pressed) then
        self:increment_row()
    end
end

function action_binder:dpad_up(pressed)
    self:menu_input('up',pressed)
    if self.capturing_text then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_up_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 4
            self:submit_selected_option()
        end
    elseif (pressed and self.state == states.MOVE_CROSSBARS) then
        self.theme_options.offset_y = self.theme_options.offset_y - 10
        self.update_offsets(self.theme_options.offset_x, self.theme_options.offset_y)
    elseif (pressed) then
        self:decrement_row()
    end
end

function action_binder:button_a(pressed)
    self:menu_input('a',pressed)
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.trigger_left_pressed and not self.trigger_right_pressed and (self.button_layout == 'gamecube' and self.cancel_button == 'a' or
            self.button_layout == 'playstation' and self.cancel_button == 'cross' or
            self.button_layout == 'xbox' and self.cancel_button == 'a' or
            self.button_layout == 'nintendo' and self.cancel_button == 'b') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_a_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 6
            self:submit_selected_option()
        end
    elseif (pressed) then
        if (self.button_layout == 'gamecube' and self.confirm_button == 'a' or
            self.button_layout == 'playstation' and self.confirm_button == 'cross' or
            self.button_layout == 'xbox' and self.confirm_button == 'a' or
            self.button_layout == 'nintendo' and self.confirm_button == 'b') then
            self:submit_selected_option()
        elseif (self.button_layout == 'gamecube' and self.cancel_button == 'a' or
            self.button_layout == 'playstation' and self.cancel_button == 'cross' or
            self.button_layout == 'xbox' and self.cancel_button == 'a' or
            self.button_layout == 'nintendo' and self.cancel_button == 'b') then
            self:go_back()
        end
    end
end

function action_binder:button_b(pressed)
    self:menu_input('b',pressed)
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.trigger_left_pressed and not self.trigger_right_pressed and (self.button_layout == 'gamecube' and self.cancel_button == 'b' or
            self.button_layout == 'playstation' and self.cancel_button == 'square' or
            self.button_layout == 'xbox' and self.cancel_button == 'x' or
            self.button_layout == 'nintendo' and self.cancel_button == 'y') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_b_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 5
            self:submit_selected_option()
        end
    elseif (pressed) then
        if (self.button_layout == 'gamecube' and self.confirm_button == 'b' or
            self.button_layout == 'playstation' and self.confirm_button == 'square' or
            self.button_layout == 'xbox' and self.confirm_button == 'x' or
            self.button_layout == 'nintendo' and self.confirm_button == 'y') then
            self:submit_selected_option()
        elseif (self.button_layout == 'gamecube' and self.cancel_button == 'b' or
            self.button_layout == 'playstation' and self.cancel_button == 'square' or
            self.button_layout == 'xbox' and self.cancel_button == 'x' or
            self.button_layout == 'nintendo' and self.cancel_button == 'y') then
            self:go_back()
        end
    end
end

function action_binder:button_x(pressed)
    self:menu_input('x',pressed)
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.trigger_left_pressed and not self.trigger_right_pressed and (self.button_layout == 'gamecube' and self.cancel_button == 'x' or
            self.button_layout == 'playstation' and self.cancel_button == 'circle' or
            self.button_layout == 'xbox' and self.cancel_button == 'b' or
            self.button_layout == 'nintendo' and self.cancel_button == 'a') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_x_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 7
            self:submit_selected_option()
        end
    elseif (pressed) then
        if (self.button_layout == 'gamecube' and self.confirm_button == 'x' or
            self.button_layout == 'playstation' and self.confirm_button == 'circle' or
            self.button_layout == 'xbox' and self.confirm_button == 'b' or
            self.button_layout == 'nintendo' and self.confirm_button == 'a') then
            self:submit_selected_option()
        elseif (self.button_layout == 'gamecube' and self.cancel_button == 'x' or
            self.button_layout == 'playstation' and self.cancel_button == 'circle' or
            self.button_layout == 'xbox' and self.cancel_button == 'b' or
            self.button_layout == 'nintendo' and self.cancel_button == 'a') then
            self:go_back()
        end
    end
end

function action_binder:button_y(pressed)
    self:menu_input('y',pressed)
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.trigger_left_pressed and not self.trigger_right_pressed and (self.button_layout == 'gamecube' and self.cancel_button == 'y' or
            self.button_layout == 'playstation' and self.cancel_button == 'triangle' or
            self.button_layout == 'xbox' and self.cancel_button == 'y' or
            self.button_layout == 'nintendo' and self.cancel_button == 'x') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_y_pressed = pressed
        if (pressed and (self.trigger_left_pressed or self.trigger_right_pressed)) then
            self:show_pressed_buttons()
            self.hotkey = 8
            self:submit_selected_option()
        end
    elseif (pressed) then
        if (self.button_layout == 'gamecube' and self.confirm_button == 'y' or
            self.button_layout == 'playstation' and self.confirm_button == 'triangle' or
            self.button_layout == 'xbox' and self.confirm_button == 'y' or
            self.button_layout == 'nintendo' and self.confirm_button == 'x') then
            self:submit_selected_option()
        elseif (self.button_layout == 'gamecube' and self.cancel_button == 'y' or
            self.button_layout == 'playstation' and self.cancel_button == 'triangle' or
            self.button_layout == 'xbox' and self.cancel_button == 'y' or
            self.button_layout == 'nintendo' and self.cancel_button == 'x') then
            self:go_back()
        end
    end
end

function action_binder:is_in_selector_state()
    return not self.capturing_text and self.selector and self.selector.is_showing and (self.state == states.SELECT_ACTION_TYPE
        or self.state == states.SELECT_ACTION
        or self.state == states.SELECT_ACTION_TARGET
        or self.state == states.SELECT_PLAYER_BINDING
        or self.state == states.SELECT_ICON
        or self.state == states.SELECT_LINKED_TYPE
        or self.state == states.EDIT_CUSTOM_ACTION_PICK
        or self.state == states.DELETE_CUSTOM_ACTION_PICK
        or self.state == states.EDIT_CUSTOM_ACTION_REVIEW)
end

-- A held trigger previews a page turn; another menu press consumes it.
function action_binder:menu_input(key,pressed)
    if pressed and self.page_gesture then
        self.page_gesture.used=true
        self.selector:page_highlight(nil)
    end
end

function action_binder:menu_trigger(side,pressed)
    local field='trigger_' .. side .. '_pressed'
    local other=side=='left' and 'trigger_right_pressed' or 'trigger_left_pressed'
    local just_pressed=pressed and not self[field]
    local just_released=not pressed and self[field]
    self[field]=pressed
    if just_pressed then
        if self[other] and self.page_gesture then
            self.page_gesture.next_page=side=='right'
        else self.page_gesture={state=self.state,next_page=side=='right',used=self[other]} end
    elseif just_released and self.page_gesture then
        local gesture=self.page_gesture
        if not gesture.used and gesture.state==self.state and self:is_in_selector_state() then
            gesture.used=true
            if gesture.next_page and self.selector.is_next_button_showing then self.selector:increment_page()
            elseif not gesture.next_page and self.selector.is_prev_button_showing then self.selector:decrement_page() end
        end
    end
    if self.page_gesture and not self.page_gesture.used then self.selector:page_highlight(self.page_gesture.next_page)
    else self.selector:page_highlight(nil) end
    if not self.trigger_left_pressed and not self.trigger_right_pressed then self.page_gesture=nil end
end

function action_binder:trigger_left(pressed)
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        local just_pressed = pressed and not self.trigger_left_pressed
        local just_released = self.trigger_left_pressed and not pressed
        local only_left_trigger_just_pressed = just_pressed and not self.trigger_right_pressed

        if (not is_left_doublepress_window_open and only_left_trigger_just_pressed) then
            is_left_doublepress_window_open = true
            is_right_doublepress_window_open = false
            coroutine.schedule(close_left_doublepress_window, 0.5)
        end
        local only_left_trigger_just_released = just_released and not self.trigger_right_pressed
        if (is_left_doublepress_window_open and only_left_trigger_just_released) then
            left_trigger_lifted_during_doublepress_window = true
        end
        if (only_left_trigger_just_pressed and is_left_doublepress_window_open and left_trigger_lifted_during_doublepress_window) then
            self.trigger_left_doublepressed = true
            close_left_doublepress_window()
        end
        if (just_released and self.trigger_left_doublepressed) then
            self.trigger_left_doublepressed = false
        end

        self.trigger_left_pressed = pressed
        self:update_active_crossbar(just_pressed, false)
        self:show_pressed_buttons()
    elseif (self:is_in_selector_state()) then
        self:menu_trigger('left',pressed)
    else
        self.trigger_left_pressed = pressed
    end
end

function action_binder:trigger_right(pressed)
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        local just_pressed = pressed and not self.trigger_right_pressed
        local just_released = self.trigger_right_pressed and not pressed
        local only_right_trigger_just_pressed = just_pressed and not self.trigger_left_pressed

        if (not is_right_doublepress_window_open and only_right_trigger_just_pressed) then
            is_right_doublepress_window_open = true
            is_left_doublepress_window_open = false
            coroutine.schedule(close_right_doublepress_window, 0.5)
        end
        local only_right_trigger_just_released = just_released and not self.trigger_left_pressed
        if (is_right_doublepress_window_open and only_right_trigger_just_released) then
            right_trigger_lifted_during_doublepress_window = true
        end
        if (only_right_trigger_just_pressed and is_right_doublepress_window_open and right_trigger_lifted_during_doublepress_window) then
            self.trigger_right_doublepressed = true
            close_right_doublepress_window()
        end
        if (just_released and self.trigger_right_doublepressed) then
            self.trigger_right_doublepressed = false
        end

        self.trigger_right_pressed = pressed
        self:update_active_crossbar(false, just_pressed)
        self:show_pressed_buttons()
    elseif (self:is_in_selector_state()) then
        self:menu_trigger('right',pressed)
    else
        self.trigger_right_pressed = pressed
    end
end

function action_binder:increment_row()
    self.selector:increment_row()
end

function action_binder:decrement_row()
    self.selector:decrement_row()
end

function action_binder:increment_col()
    self.selector:increment_col()
end

function action_binder:decrement_col()
    self.selector:decrement_col()
end

function action_binder:submit_selected_option()
    if self.custom_action_review_field then self:send_enter(); return end
    if self.selector.is_showing and self.selector.get_selected_option then
        local selected = self.selector:get_selected_option()
        if not selected then return end
        if selected.disabled then
            if selected.disabled_focusable then
                windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] No custom actions saved. Choose Create Custom Action to add one.'))
            end
            return
        end
    end
    if (self.state == states.SELECT_ACTION_TYPE) then
        self.selection_states[states.SELECT_ACTION_TYPE] = self.selector:export_selection_state()
        self.action_type = self.selector:submit_selected_option().id

        if (self.action_type == action_types.SHOW_CREDITS) then
            self.state = states.SHOW_CREDITS
            self:display_credits()
        elseif (self.action_type == action_types.CREATE_NEW_SET) then
            self.state = states.ENTER_SET_NAME
            self:set_capturing_text(true)
            self.text_entry_buffer = ''
            self:display_text_entry('Enter New Set Name', '<Type set name, press Enter>')
        elseif (self.action_type == action_types.MOVE_CROSSBARS) then
            self.state = states.MOVE_CROSSBARS
            self:display_crossbar_mover()
        elseif (self.action_type == action_types.DELETE) then
            self.state = states.SELECT_BUTTON_ASSIGNMENT
            self:display_button_assigner()
        elseif (self.action_type == action_types.ASSIST) then
            self.state = states.SELECT_PLAYER_BINDING
            self:display_player_selector(false)
        elseif self.action_type == action_types.CHECK then
            self.action_name, self.action_target = 'Check', 't'
            self.state = states.SELECT_BUTTON_ASSIGNMENT
            self:display_button_assigner()
        elseif (self.action_type == action_types.ATTACK or self.action_type == action_types.RANGED_ATTACK) then
            if (self.action_type == action_types.ATTACK) then
                self.action_name = 'Attack'
            elseif (self.action_type == action_types.RANGED_ATTACK) then
                self.action_name = 'Ranged Attack'
            end
            self.state = states.SELECT_ACTION_TARGET
            self.target_type = {['Enemy'] = true}
            self:display_target_selector()
        elseif (self.action_type == action_types.SWITCH_TARGET) then
            self.action_name = 'Switch Target'
            self.action_target = 'stnpc'
            self.state = states.SELECT_BUTTON_ASSIGNMENT
            self:display_button_assigner()
        elseif (self.action_type == action_types.MAP or self.action_type == action_types.LAST_SYNTH) then
            if (self.action_type == action_types.LAST_SYNTH) then
                self.action_name = 'Last Synth'
            elseif (self.action_type == action_types.MAP) then
                self.action_name = 'View Map'
            end
            self.action_target = nil
            self.state = states.SELECT_BUTTON_ASSIGNMENT
            self:display_button_assigner()
        elseif (self.action_type == action_types.CHANGE_ICON) then
            self.state = states.SELECT_ICON
            self.icon_picker_stack, self.icon_picker_path = {}, ''
            self:display_icon_selector('')
        elseif (self.action_type == action_types.GLOBAL_ICON_SET) then
            self.state = states.SELECT_BUTTON_ASSIGNMENT
            self:display_button_assigner()
        elseif (self.action_type == action_types.CREATE_CUSTOM_ACTION) then
            self:new_custom_action('', 'menu')
        elseif (self.action_type == action_types.EDIT_CUSTOM_ACTION) then
            self.state = states.EDIT_CUSTOM_ACTION_PICK
            self:display_custom_actions_picker('Edit Custom Action: Pick Entry')
        elseif (self.action_type == action_types.DELETE_CUSTOM_ACTION) then
            self.state = states.DELETE_CUSTOM_ACTION_PICK
            self:display_custom_actions_picker('Delete Custom Action: Pick Entry')
        else
            self.state = states.SELECT_ACTION
            self:display_action_selector()
        end
    elseif (self.state == states.MOVE_CROSSBARS or self.state == states.SHOW_CREDITS) then
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        self:display_action_type_selector()
        self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
        self.selection_states[states.SELECT_ACTION_TYPE] = nil
    elseif (self.state == states.SELECT_PLAYER_BINDING) then
        self.action_name = 'Assist ' .. self.selector:submit_selected_option().text
        self.state = states.SELECT_BUTTON_ASSIGNMENT
        self:display_button_assigner()
    elseif (self.state == states.SELECT_ACTION) then
        self.selection_states[states.SELECT_ACTION] = self.selector:export_selection_state()
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        elseif (self.is_linking_for_custom_action) then
            self.custom_action_draft.linked_action = option.text
            self.is_linking_for_custom_action = false
            if (self.editing_custom_action) then
                self.action_type = action_types.EDIT_CUSTOM_ACTION
                self.state = states.EDIT_CUSTOM_ACTION_REVIEW
                self:display_edit_custom_action_review()
            else
                self.state = states.EDIT_CUSTOM_ACTION_REVIEW
                self:display_edit_custom_action_review()
            end
        else
            self.action_catalog = option.data.catalog_id and {scope=option.data.catalog_scope,id=option.data.catalog_id} or nil
            self.action_name = option.data.action_name or option.data.catalog_name or option.text
            self.target_type = option.data.target_type

            -- A new choice replaces nullable metadata too. Going Back from a
            -- switch/custom action must not carry its alias/command to a spell.
            self.action_command = option.data.command
            self.action_icon = option.data.icon_path
            self.action_linked_action = option.data.linked_action
            self.action_linked_type = option.data.linked_type
            self.action_alias = option.data.alias

            if (self.target_type['Self'] and not (self.theme_options.allow_stpc_for_self_targeted_actions or
                    self.target_type['NPC'] or
                    self.target_type['Enemy'] or
                    self.target_type['Party'] or
                    self.target_type['Player'] or
                    self.target_type['Ally'])) then
                self.action_target = action_targets.SELF
                self.state = states.SELECT_BUTTON_ASSIGNMENT
                self:display_button_assigner()
            elseif (self.target_type['None']) then
                if self.action_type == action_types.EXECUTE_COMMAND or self.action_type == action_types.SUPERWARP then
					self.icon = option.icon
				end

                self.action_target = nil
                self.state = states.SELECT_BUTTON_ASSIGNMENT
                self:display_button_assigner()
            else
                self.state = states.SELECT_ACTION_TARGET
                self:display_target_selector()
            end
        end
    elseif (self.state == states.SELECT_ACTION_TARGET) then
        self.selection_states[states.SELECT_ACTION_TARGET] = self.selector:export_selection_state()
        self.action_target = action_targets[self.selector:submit_selected_option().id]
        self.state = states.SELECT_BUTTON_ASSIGNMENT
        self:display_button_assigner()
    elseif (self.state == states.SELECT_ICON and self.action_type == action_types.CREATE_NEW_SET) then
        self.selection_states[states.SELECT_ICON] = self.selector:export_selection_state()
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        else
            self.action_icon = option.data.icon_path
            self.state = states.SELECT_BUTTON_ASSIGNMENT
            self:display_button_assigner()
        end
    elseif (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self.state = states.CONFIRM_BUTTON_ASSIGNMENT
        self:display_button_confirmer()
    elseif (self.state == states.CONFIRM_BUTTON_ASSIGNMENT) then
        if (self.action_type == action_types.DELETE) then
            self:delete_action()
        elseif (self.action_type == action_types.CHANGE_ICON) then
            local valid, warning = self:check_slot_bound_in_active_env()
            if not valid then
                windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] ' .. warning))
                self.state=states.SELECT_BUTTON_ASSIGNMENT
                self:display_button_assigner()
                return
            end
            self:apply_icon_change()
            self:hide()
            self:reset_state()
        elseif (self.action_type == action_types.GLOBAL_ICON_SET) then
            local name = self:capture_global_icon_source_name()
            if (name == nil) then
                windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] No action bound at the selected slot.'))
                self:return_to_action_type_menu()
                return
            end
            self.global_icon_source_name = name

            self:clear_button_entry_ui()
            self.state = states.SELECT_ICON
            self.icon_picker_stack = {}
            self.icon_picker_path = ''
            self:display_icon_selector('')
        else
            self:assign_action()
        end
    elseif (self.state == states.SELECT_ICON) then
        self.selection_states[states.SELECT_ICON] = self.selector:export_selection_state()
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        elseif option.id == 'CLEAR_ICON' then
            self.custom_action_draft.icon = nil
            self.icon_picker_return = nil
            self.state = states.EDIT_CUSTOM_ACTION_REVIEW
            self:display_edit_custom_action_review()
        elseif (option.data ~= nil and option.data.is_dir) then
            table.insert(self.icon_picker_stack, {
                path = self.icon_picker_path,
                selection_state = self.selection_states[states.SELECT_ICON],
            })
            self.selection_states[states.SELECT_ICON] = nil
            self.icon_picker_path = option.data.path
            self:display_icon_selector(self.icon_picker_path)
        elseif (option.data ~= nil and option.data.icon_path ~= nil) then
            self.action_icon = option.data.icon_path
            if self.icon_picker_return == 'custom_review' then
                self.custom_action_draft.icon = option.data.icon_path
                self.icon_picker_return = nil
                self.icon_picker_path, self.icon_picker_stack = '', {}
                self.state = states.EDIT_CUSTOM_ACTION_REVIEW
                self:display_edit_custom_action_review()
            elseif self.action_type == action_types.CHANGE_ICON then
                self.icon_picker_path, self.icon_picker_stack = '', {}
                self.state=states.SELECT_BUTTON_ASSIGNMENT
                self:display_button_assigner()
            elseif (self.action_type == action_types.GLOBAL_ICON_SET) then
                self:apply_global_icon()
                self:hide()
                self:reset_state()
            elseif (self.action_type == action_types.CREATE_CUSTOM_ACTION) then
                self.custom_action_draft.icon = option.data.icon_path
                self.icon_picker_path = ''
                self.icon_picker_stack = {}
                self.state = states.EDIT_CUSTOM_ACTION_REVIEW
                self:display_edit_custom_action_review()
            elseif (self.action_type == action_types.EDIT_CUSTOM_ACTION) then
                self.custom_action_draft.icon = option.data.icon_path
                self.icon_picker_path = ''
                self.icon_picker_stack = {}
                self.state = states.EDIT_CUSTOM_ACTION_REVIEW
                self:display_edit_custom_action_review()
            else
                self:apply_icon_change()
                self:hide()
                self:reset_state()
            end
        end
    elseif (self.state == states.ENTER_CUSTOM_ACTION_ALIAS) then
        if (self.custom_action_draft.alias == nil or self.custom_action_draft.alias == '') then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Set the alias first: //xivcrossbar ca a <value>'))
            return
        end
        self.state = states.ENTER_CUSTOM_ACTION_NAME
        self:display_custom_action_field_review('Catalog Name', 'n', self.custom_action_draft.name, '(unique key in CustomActions.xml)')
    elseif (self.state == states.ENTER_CUSTOM_ACTION_NAME) then
        if (self.custom_action_draft.name == nil or self.custom_action_draft.name == '') then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Set the catalog name first: //xivcrossbar ca n <value>'))
            return
        end
        self.state = states.ENTER_CUSTOM_ACTION_COMMAND
        self:display_custom_action_field_review('Command', 'c', self.custom_action_draft.command, '(raw command this action will fire)')
    elseif (self.state == states.ENTER_CUSTOM_ACTION_COMMAND) then
        if (self.custom_action_draft.command == nil or self.custom_action_draft.command == '') then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Set the command first: //xivcrossbar ca c <value>'))
            return
        end
        self.state = states.SELECT_CUSTOM_ACTION_ICON_CHOICE
        self:display_icon_choice_selector()
    elseif (self.state == states.SELECT_CUSTOM_ACTION_ICON_CHOICE) then
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        elseif (option.id == 'SET_ICON') then
            self.state = states.SELECT_ICON
            self.icon_picker_stack = {}
            self.icon_picker_path = ''
            self:display_icon_selector('')
        elseif (option.id == 'SKIP_ICON') then
            self.custom_action_draft.icon = nil
            self.state = states.SELECT_LINKED_TYPE
            self:display_linked_type_selector()
        end
    elseif (self.state == states.SELECT_LINKED_TYPE) then
        self.selection_states[states.SELECT_LINKED_TYPE] = self.selector:export_selection_state()
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        elseif (option.id == 'SKIP_LINKED') then
            self.custom_action_draft.linked_action = nil
            self.custom_action_draft.linked_type = nil
            if (self.editing_custom_action) then
                self.action_type = action_types.EDIT_CUSTOM_ACTION
                self.state = states.EDIT_CUSTOM_ACTION_REVIEW
                self:display_edit_custom_action_review()
            else
                self.state = states.EDIT_CUSTOM_ACTION_REVIEW
                self:display_edit_custom_action_review()
            end
        else
            self.custom_action_draft.linked_type = prefix_lookup[option.id]
            self.action_type = option.id
            self.is_linking_for_custom_action = true
            self.state = states.SELECT_ACTION
            self:display_action_selector()
        end
    elseif (self.state == states.CONFIRM_CUSTOM_ACTION) then
        self:apply_custom_action_save()
        self:hide()
        self:reset_state()
    elseif (self.state == states.EDIT_CUSTOM_ACTION_PICK) then
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        else
            local name = option.text
            local record = player_data.custom_actions and player_data.custom_actions[name]
            if (record == nil) then
                windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Edit Custom Action: entry "' .. tostring(name) .. '" not found.'))
                return
            end
            self.custom_action_draft = {
                alias         = record.alias,
                name          = record.name,
                _scope        = record._scope,
                _expected     = require('libs/custom_catalog').copy(record),
                id            = record.id,
                command       = record.command,
                icon          = record.icon,
                linked_action = record.linked_action,
                linked_type   = record.linked_type,
            }
            self.custom_action_original_name = name
            self.editing_custom_action = true
            self.action_type = action_types.EDIT_CUSTOM_ACTION
            self.state = states.EDIT_CUSTOM_ACTION_REVIEW
            self:display_edit_custom_action_review()
        end
    elseif (self.state == states.EDIT_CUSTOM_ACTION_REVIEW) then
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        elseif option.id == 'CHANGE_NAME' or option.id == 'CHANGE_ALIAS' or option.id == 'CHANGE_COMMAND' then
            self.custom_action_review_field = ({CHANGE_NAME='name',CHANGE_ALIAS='alias',CHANGE_COMMAND='command'})[option.id]
            self.text_entry_buffer = self.custom_action_draft[self.custom_action_review_field] or ''
            self:set_capturing_text(true)
            self:display_inline_custom_action_entry()
        elseif (option.id == 'CHANGE_ICON') then
            self.icon_picker_return = 'custom_review'
            self.action_type = self.editing_custom_action and action_types.EDIT_CUSTOM_ACTION or action_types.CREATE_CUSTOM_ACTION
            self.state = states.SELECT_ICON
            self.icon_picker_stack = {}
            self.icon_picker_path = ''
            self:display_icon_selector('')
        elseif (option.id == 'REMOVE_ICON') then
            self.custom_action_draft.icon = nil
            self:display_edit_custom_action_review()
        elseif (option.id == 'CHANGE_LINKED') then
            self.action_type = action_types.EDIT_CUSTOM_ACTION
            self.state = states.SELECT_LINKED_TYPE
            self:display_linked_type_selector()
        elseif (option.id == 'REMOVE_LINKED') then
            self.custom_action_draft.linked_action = nil
            self.custom_action_draft.linked_type = nil
            self:display_edit_custom_action_review()
        elseif option.id == 'SAVE_EDIT' or option.id == 'SAVE_BIND' then
            local saved
            if self.editing_custom_action then saved = self:apply_custom_action_update()
            else saved = self:apply_custom_action_save() end
            if not saved then return end
            if option.id == 'SAVE_BIND' then
                local d = self.custom_action_draft
                self.editing_custom_action = true
                self.custom_action_original_name = d._key or d.name
                self.binding_custom_action_review = true
                self.action_type = action_types.CUSTOM_ACTION
                self.action_catalog = {scope=d._scope,id=d.id}
                self.action_name,self.action_alias = d.name,review.alias(d)
                self.action_command,self.action_icon = d.command,d.icon
                self.action_linked_action,self.action_linked_type = d.linked_action,d.linked_type
                self.action_target = nil
                self.state = states.SELECT_BUTTON_ASSIGNMENT
                self:display_button_assigner()
            else
                local d=self.custom_action_draft
                local selected={key=d._key or d.name,scope=d._scope,id=d.id}
                self:reset_state()
                self.action_type=action_types.EDIT_CUSTOM_ACTION
                self.state=states.EDIT_CUSTOM_ACTION_PICK
                self:display_custom_actions_picker('Edit Custom Action: Pick Entry',selected)
            end
        end
    elseif (self.state == states.DELETE_CUSTOM_ACTION_PICK) then
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        else
            local name = option.text
            if (player_data.custom_actions == nil or player_data.custom_actions[name] == nil) then
                windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Delete Custom Action: entry "' .. tostring(name) .. '" not found.'))
                return
            end
            self.custom_action_delete_target = name
            self.state = states.DELETE_CUSTOM_ACTION_CONFIRM
            self:display_delete_custom_action_confirm()
        end
    elseif (self.state == states.DELETE_CUSTOM_ACTION_CONFIRM) then
        self:apply_custom_action_delete()
        self:hide()
        self:reset_state()
    end
end

function action_binder:go_back()
    if self.custom_action_review_field then
        self.custom_action_review_field=nil; self:set_capturing_text(false)
        if self.custom_action_name_required then
            self.custom_action_name_required=false
            self:go_back()
        else self:display_edit_custom_action_review() end
        return
    end
    if self.binding_custom_action_review and self.state == states.SELECT_BUTTON_ASSIGNMENT then
        self.binding_custom_action_review=false
        self.state=states.EDIT_CUSTOM_ACTION_REVIEW
        self:clear_button_entry_ui()
        self:display_edit_custom_action_review(); return
    end
    if self.custom_action_draft and (self.state == states.SELECT_LINKED_TYPE or
        (self.state == states.SELECT_ICON and (not self.icon_picker_stack or #self.icon_picker_stack == 0))) then
        self.is_linking_for_custom_action=false
        self.icon_picker_return=nil
        self.state=states.EDIT_CUSTOM_ACTION_REVIEW
        self:display_edit_custom_action_review(); return
    end
    if (self.state == states.SELECT_ACTION_TYPE) then
        self:hide()
        self:reset_state()
        self.selector:reset_state()
    elseif (self.state == states.SHOW_CREDITS) then
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        self:display_action_type_selector()
        self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
        self.selection_states[states.SELECT_ACTION_TYPE] = nil
    elseif (self.state == states.ENTER_SET_NAME) then
        self:set_capturing_text(false)
        self.text_entry_buffer = ''
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        self:display_action_type_selector()
        self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
        self.selection_states[states.SELECT_ACTION_TYPE] = nil
    elseif (self.state == states.ENTER_SET_ALIAS) then
        self:set_capturing_text(true)
        self.text_entry_buffer = ''
        self.new_set_name = nil
        self.state = states.ENTER_SET_NAME
        self:display_text_entry('Enter New Set Name', '<Type set name, press Enter>')
    elseif (self.state == states.SELECT_ICON and self.action_type == action_types.CREATE_NEW_SET) then
        -- Go back to alias entry
        self:set_capturing_text(true)
        self.text_entry_buffer = self.new_set_alias or ''
        self.state = states.ENTER_SET_ALIAS
        self:display_text_entry('Enter Button Alias', '<Type alias, press Enter>')
        if (self.new_set_alias and self.new_set_alias ~= '') then
            self:update_text_entry_display()
        end
    elseif (self.state == states.MOVE_CROSSBARS) then
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        self:display_action_type_selector()
        self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
        self.selection_states[states.SELECT_ACTION_TYPE] = nil
    elseif (self.state == states.SELECT_ACTION) then
        if (self.is_linking_for_custom_action) then
            self.is_linking_for_custom_action = false
            self.state = states.SELECT_LINKED_TYPE
            self:display_linked_type_selector()
            return
        end
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        self:display_action_type_selector()
        self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
        self.selection_states[states.SELECT_ACTION_TYPE] = nil
    elseif (self.state == states.SELECT_PLAYER_BINDING) then
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        self:display_action_type_selector()
        self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
        self.selection_states[states.SELECT_ACTION_TYPE] = nil
    elseif (self.state == states.SELECT_ACTION_TARGET) then
        if (self.action_type == action_types.ATTACK or self.action_type == action_types.RANGED_ATTACK) then
            self.state = states.SELECT_ACTION_TYPE
            self.action_type = nil
            self.target_type = nil
            self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
            self:display_action_type_selector()
            self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
            self.selection_states[states.SELECT_ACTION_TYPE] = nil
        else
            self.state = states.SELECT_ACTION
            self.action_name = nil
            self.selector:set_page(self.selection_states[states.SELECT_ACTION].page)
            self:display_action_selector()
            self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION])
            self.selection_states[states.SELECT_ACTION] = nil
        end
    elseif (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        if (self.action_type == action_types.CREATE_NEW_SET) then
            -- Go back to icon selection
            self.state = states.SELECT_ICON
            self.action_icon = nil
            if (self.selection_states[states.SELECT_ICON] ~= nil) then
                self.selector:set_page(self.selection_states[states.SELECT_ICON].page)
                self:display_icon_selector_sylvebits()
                self.selector:import_selection_state(self.selection_states[states.SELECT_ICON])
                self.selection_states[states.SELECT_ICON] = nil
            else
                self:display_icon_selector_sylvebits()
            end
        elseif self.action_type == action_types.CHANGE_ICON then
            self:clear_button_entry_ui()
            self.state=states.SELECT_ICON
            self.icon_picker_path, self.icon_picker_stack = '', {}
            self:display_icon_selector('')
        elseif (self.action_type == action_types.GLOBAL_ICON_SET) then
            self.state = states.SELECT_ACTION_TYPE
            self.action_type = nil
            if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
                self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
            end
            self:display_action_type_selector()
            if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
                self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
                self.selection_states[states.SELECT_ACTION_TYPE] = nil
            end
        elseif (self.selection_states[states.SELECT_ACTION_TARGET] == nil and
            self.selection_states[states.SELECT_ACTION] == nil) then
            -- A: direct actions never opened an action or target list.
            -- Switch Target, View Map, Last Synth and Remove Binding return home.
            self.action_name = nil
            self.action_target = nil
            self:return_to_action_type_menu()
        -- check if we skipped target selection due to "Self" being the only option
        elseif (self.selection_states[states.SELECT_ACTION_TARGET] == nil) then
            self.state = states.SELECT_ACTION
            self.action_name = nil
            self.action_target = nil
            self.selector:set_page(self.selection_states[states.SELECT_ACTION].page)
            self:display_action_selector()
            self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION])
            self.selection_states[states.SELECT_ACTION] = nil
        else
            self.state = states.SELECT_ACTION_TARGET
            self.action_target = nil
            self.selector:set_page(self.selection_states[states.SELECT_ACTION_TARGET].page)
            self:display_target_selector()
            self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TARGET])
            self.selection_states[states.SELECT_ACTION_TARGET] = nil
        end
    elseif (self.state == states.CONFIRM_BUTTON_ASSIGNMENT) then
        self.state = states.SELECT_BUTTON_ASSIGNMENT
        self.active_crossbar = nil
        self.hotkey = nil
        self:display_button_assigner()
    elseif (self.state == states.SELECT_ICON) then
        if (self.icon_picker_stack ~= nil and #self.icon_picker_stack > 0) then
            local frame = table.remove(self.icon_picker_stack)
            self.icon_picker_path = frame.path
            self:display_icon_selector(self.icon_picker_path)
            if (frame.selection_state ~= nil) then
                self.selector:import_selection_state(frame.selection_state)
            end
        elseif self.icon_picker_return == 'custom_review' or self.action_type == action_types.CREATE_CUSTOM_ACTION then
            self.icon_picker_return = nil
            self.icon_picker_path, self.icon_picker_stack = '', {}
            self.state = states.EDIT_CUSTOM_ACTION_REVIEW
            self:display_edit_custom_action_review()
        elseif (self.action_type == action_types.EDIT_CUSTOM_ACTION) then
            self.icon_picker_path = ''
            self.icon_picker_stack = {}
            self.state = states.EDIT_CUSTOM_ACTION_REVIEW
            self:display_edit_custom_action_review()
        else
            self.icon_picker_path = ''
            self.icon_picker_stack = {}
            self.state = states.SELECT_ACTION_TYPE
            self.action_type = nil
            self.active_crossbar = nil
            self.hotkey = nil
            if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
                self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
            end
            self:display_action_type_selector()
            if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
                self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
                self.selection_states[states.SELECT_ACTION_TYPE] = nil
            end
        end
    elseif (self.state == states.ENTER_CUSTOM_ACTION_ALIAS) then
        self.custom_action_draft = nil
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
            self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        end
        self:display_action_type_selector()
        if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
            self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
            self.selection_states[states.SELECT_ACTION_TYPE] = nil
        end
    elseif (self.state == states.ENTER_CUSTOM_ACTION_NAME) then
        self.state = states.ENTER_CUSTOM_ACTION_ALIAS
        self:display_custom_action_field_review('Alias', 'a', self.custom_action_draft.alias, '(display label shown on the slot)')
    elseif (self.state == states.ENTER_CUSTOM_ACTION_COMMAND) then
        self.state = states.ENTER_CUSTOM_ACTION_NAME
        self:display_custom_action_field_review('Catalog Name', 'n', self.custom_action_draft.name, '(unique key in CustomActions.xml)')
    elseif (self.state == states.SELECT_CUSTOM_ACTION_ICON_CHOICE) then
        self.state = states.ENTER_CUSTOM_ACTION_COMMAND
        self:display_custom_action_field_review('Command', 'c', self.custom_action_draft.command, '(raw command this action will fire)')
    elseif (self.state == states.SELECT_LINKED_TYPE) then
        self.is_linking_for_custom_action = false
        self.state = states.EDIT_CUSTOM_ACTION_REVIEW
        self:display_edit_custom_action_review()
    elseif (self.state == states.CONFIRM_CUSTOM_ACTION) then
        self.custom_action_draft.linked_action = nil
        self.custom_action_draft.linked_type = nil
        self.state = states.SELECT_LINKED_TYPE
        self:display_linked_type_selector()
    elseif (self.state == states.EDIT_CUSTOM_ACTION_PICK) then
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
            self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        end
        self:display_action_type_selector()
        if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
            self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
            self.selection_states[states.SELECT_ACTION_TYPE] = nil
        end
    elseif (self.state == states.EDIT_CUSTOM_ACTION_REVIEW) then
        local origin=self.custom_action_entry_origin
        self.custom_action_draft=nil; self.custom_action_original_name=nil
        self.editing_custom_action=false
        if origin == 'command' then self:hide(); self:reset_state()
        elseif origin == 'menu' then self:return_to_action_type_menu()
        else self.state=states.EDIT_CUSTOM_ACTION_PICK; self:display_custom_actions_picker('Edit Custom Action: Pick Entry') end
    elseif (self.state == states.DELETE_CUSTOM_ACTION_PICK) then
        self.state = states.SELECT_ACTION_TYPE
        self.action_type = nil
        if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
            self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
        end
        self:display_action_type_selector()
        if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
            self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
            self.selection_states[states.SELECT_ACTION_TYPE] = nil
        end
    elseif (self.state == states.DELETE_CUSTOM_ACTION_CONFIRM) then
        self.custom_action_delete_target = nil
        self.state = states.DELETE_CUSTOM_ACTION_PICK
        self:display_custom_actions_picker('Delete Custom Action: Pick Entry')
    end
end

-- Preserve live objects/page/draft while the set chooser owns drawing/input.
-- Keep the inactive menu readable underneath; snapshot exact opacity for return.
function action_binder:set_chooser_active(active, gamepad_state)
    if self.chooser_active == active then return end
    self.chooser_active = active
    self.selector.suspended = active
    if active then
        self.chooser_visibility = {}
        local seen = {}
        local function suspend(object)
            if not object or seen[object] or ui_resources.is_disposed(object) then return end
            seen[object] = true
            local alpha = object:alpha()
            self.chooser_visibility[#self.chooser_visibility+1] = {object=object, visible=object:visible(), alpha=alpha}
            if object == self.title then self.chooser_title_alpha=alpha end
            object:alpha(math.floor(alpha*0.45))
        end
        suspend(self.title)
        suspend(self.inline_entry_text)
        for _,objects in ipairs({self.images,self.hints,self.selector.images,self.selector.fields}) do
            for _,object in ipairs(objects or {}) do suspend(object) end
        end
        for _,objects in ipairs({self.selector.page_backgrounds or {},self.selector.page_trigger_icons or {}}) do
            for _,object in pairs(objects) do suspend(object) end
        end
        if self.selector.cursor then self.selector.cursor:hide() end
        for _,id in ipairs({'selectablelist_selection_highlight','prev_page_button','next_page_button'}) do
            windower.prim.set_visibility(id,false)
        end
        self:reset_gamepad()
        self.page_gesture = nil
    else
        for _,entry in ipairs(self.chooser_visibility or {}) do
            -- Job/UI reconstruction can replace the screen while Options is up.
            if not ui_resources.is_disposed(entry.object) then
                entry.object:alpha(entry.alpha)
                if entry.visible then entry.object:show() else entry.object:hide() end
            end
        end
        self.chooser_visibility = nil
        self.chooser_title_alpha = nil
        if not self.is_hidden then
            require('ui/menu_background').set_visibility(windower.prim, 'dialog_bg',true)
            local entry = self.state==states.SELECT_BUTTON_ASSIGNMENT or self.state==states.CONFIRM_BUTTON_ASSIGNMENT or
                self.state==states.ENTER_SET_NAME or self.state==states.ENTER_SET_ALIAS
            windower.prim.set_visibility('button_entry_bg',entry)
            if self.selector.is_showing then self.selector:highlight_selection() end
            if gamepad_state then
                if gamepad_state.left_trigger then self:trigger_left(true) end
                if gamepad_state.right_trigger then self:trigger_right(true) end
                if self.page_gesture then self.page_gesture.used=true end
            end
            self:refresh_set_title()
        end
    end
end

function action_binder:hide()
    self.is_hidden = true
    require('ui/menu_background').set_visibility(windower.prim, 'dialog_bg', false)
    windower.prim.set_visibility('button_entry_bg', false)
    self.title:hide()
    self.selector:hide()
    for i, image in ipairs(self.images) do
        image:hide()
    end
    for i, hint in ipairs(self.hints) do
        hint:hide()
    end
end

function action_binder:show()
    self.is_hidden = false
    if (self.state == states.HIDDEN) then
        self.state = states.SELECT_ACTION_TYPE
        self:display_action_type_selector()
    end
    require('ui/menu_background').set_visibility(windower.prim, 'dialog_bg', true)
    self.title:show()
    self.selector:show()
end

function action_binder:display_action_type_selector()
    require('ui/menu_background').set_color(windower.prim, 'dialog_bg',150,0,0,0)
    self.title:text('Select Action Type')
    self.title:show()

    local player = windower.ffxi.get_player()
    local main_job = player.main_job
    local sub_job = player.sub_job

    local pet_jobs = {BST = true, SMN = true, DRG = true, PUP = true}
    local white_magic_jobs = {WHM = true, RDM = true, PLD = true, SCH = true, RUN = true}
    local black_magic_jobs = {BLM = true, RDM = true, DRK = true, SCH = true, GEO = true, RUN = true}

    local action_type_list = L{}
    local empty_catalog = player_data.custom_actions == nil or next(player_data.custom_actions) == nil
    local custom_icon = 'images/' .. get_icon_pathbase() .. '/custom_actions.png'
    action_type_list:append({id = action_types.CREATE_CUSTOM_ACTION, name = 'Create Custom Action', icon = custom_icon})
    action_type_list:append({id = action_types.CUSTOM_ACTION, name = 'Custom Action', icon = custom_icon, disabled = empty_catalog, disabled_focusable = true})
    action_type_list:append({id = action_types.EDIT_CUSTOM_ACTION, name = 'Edit Custom Action', icon = custom_icon, disabled = empty_catalog, disabled_focusable = true})
    action_type_list:append({id = action_types.DELETE_CUSTOM_ACTION, name = 'Delete Custom Action', icon = 'images/' .. get_icon_pathbase() .. '/ui/red-x.png', disabled = empty_catalog, disabled_focusable = true})
    action_type_list:append({id = action_types.JOB_ABILITY, name = 'Job Ability', icon = 'images/icons/abilities/00001.png', icon_offset = 4})
    action_type_list:append({id = action_types.WEAPONSKILL, name = 'Weaponskill', icon = 'images/icons/weapons/sword.png', icon_offset = 4})

    if (pet_jobs[main_job] or pet_jobs[sub_job]) then
        action_type_list:append({id = action_types.PET_COMMAND, name = 'Pet Command', icon = 'images/' ..get_icon_pathbase() .. '/mounts/crab.png'})
    end
    if (white_magic_jobs[main_job] or white_magic_jobs[sub_job]) then
        action_type_list:append({id = action_types.WHITE_MAGIC, name = 'White Magic', icon = 'images/' ..get_icon_pathbase() .. '/jobs/WHM.png'})
    end
    if (black_magic_jobs[main_job] or black_magic_jobs[sub_job]) then
        action_type_list:append({id = action_types.BLACK_MAGIC, name = 'Black Magic', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BLM.png'})
    end
    if (main_job == 'BRD' or sub_job == 'BRD') then
        action_type_list:append({id = action_types.SONG, name = 'Song', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BRD.png'})
    end
    if (main_job == 'BST' or sub_job == 'BST') then
        action_type_list:append({id = action_types.READY, name = 'Ready', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BST.png'})
    end
    if (main_job == 'NIN' or sub_job == 'NIN') then
        action_type_list:append({id = action_types.NINJUTSU, name = 'Ninjutsu', icon = 'images/' ..get_icon_pathbase() .. '/jobs/NIN.png'})
    end
    if (main_job == 'SMN' or sub_job == 'SMN') then
        action_type_list:append({id = action_types.SUMMON, name = 'Summon', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SMN.png'})
        action_type_list:append({id = action_types.BP_RAGE, name = 'Blood Pact: Rage', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SMN.png'})
        action_type_list:append({id = action_types.BP_WARD, name = 'Blood Pact: Ward', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SMN.png'})
    end
    if (main_job == 'BLU' or sub_job == 'BLU') then
        action_type_list:append({id = action_types.BLUE_MAGIC, name = 'Blue Magic', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BLU.png'})
    end
    if (main_job == 'COR' or sub_job == 'COR') then
        action_type_list:append({id = action_types.PHANTOM_ROLL, name = 'Phantom Roll', icon = 'images/' ..get_icon_pathbase() .. '/jobs/COR.png'})
        action_type_list:append({id = action_types.QUICK_DRAW, name = 'Quick Draw', icon = 'images/' ..get_icon_pathbase() .. '/jobs/COR.png'})
    end
    if (main_job == 'SCH' or sub_job == 'SCH') then
        action_type_list:append({id = action_types.STRATAGEMS, name = 'Stratagem', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SCH.png'})
    end
    if (main_job == 'DNC' or sub_job == 'DNC') then
        action_type_list:append({id = action_types.DANCES, name = 'Dance', icon = 'images/' ..get_icon_pathbase() .. '/jobs/DNC.png'})
    end
    if (main_job == 'RUN' or sub_job == 'RUN') then
        action_type_list:append({id = action_types.RUNE_ENCHANTMENT, name = 'Rune Enchantment', icon = 'images/' ..get_icon_pathbase() .. '/jobs/RUN.png'})
        action_type_list:append({id = action_types.WARD, name = 'Ward', icon = 'images/' ..get_icon_pathbase() .. '/jobs/RUN.png'})
        action_type_list:append({id = action_types.EFFUSION, name = 'Effusion', icon = 'images/' ..get_icon_pathbase() .. '/jobs/RUN.png'})
    end
    if (main_job == 'GEO' or sub_job == 'GEO') then
        action_type_list:append({id = action_types.GEOMANCY, name = 'Geomancy', icon = 'images/' ..get_icon_pathbase() .. '/jobs/GEO.png'})
    end

    action_type_list:append({id = action_types.TRUST, name = 'Call Trust', icon = 'images/' ..get_icon_pathbase() .. '/trust/yoran-oran.png'})
    action_type_list:append({id = action_types.MOUNT, name = 'Call Mount', icon = 'images/' ..get_icon_pathbase() .. '/mount.png'})
    action_type_list:append({id = action_types.USABLE_ITEM, name = 'Use Item', icon = 'images/' ..get_icon_pathbase() .. '/usable-item.png'})
    action_type_list:append({id = action_types.TRADABLE_ITEM, name = 'Trade Item', icon = 'images/' ..get_icon_pathbase() .. '/item.png'})
    action_type_list:append({id = action_types.RANGED_ATTACK, name = 'Ranged Attack', icon = 'images/' ..get_icon_pathbase() .. '/ranged.png'})
    action_type_list:append({id = action_types.ATTACK, name = 'Attack', icon = 'images/' ..get_icon_pathbase() .. '/attack.png'})
    action_type_list:append({id = action_types.CHECK, name = 'Check', icon = 'images/' ..get_icon_pathbase() .. '/check.png'})
    action_type_list:append({id = action_types.ASSIST, name = 'Assist', icon = 'images/' ..get_icon_pathbase() .. '/assist.png'})
    action_type_list:append({id = action_types.SWITCH_TARGET, name = 'Switch Target', icon = 'images/' ..get_icon_pathbase() .. '/targetnpc.png'})
    action_type_list:append({id = action_types.MAP, name = 'View Map', icon = 'images/' ..get_icon_pathbase() .. '/map.png'})
    action_type_list:append({id = action_types.LAST_SYNTH, name = 'Repeat Last Synth', icon = 'images/' ..get_icon_pathbase() .. '/synth.png'})
	action_type_list:append({id = action_types.SUPERWARP, name = 'Superwarp', icon = 'images/' .. get_icon_pathbase() .. '/home-point.png'})
    action_type_list:append({id = action_types.SWITCH_CROSSBARS, name = 'Switch Crossbars', icon = 'images/' ..get_icon_pathbase() .. '/ui/facebuttons_ps.png'})
    action_type_list:append({id = action_types.QUICK_SWITCH_CROSSBARS, name = 'Quick XB Switch', icon = 'images/' ..get_icon_pathbase() .. '/ui/facebuttons_ps.png'})
    action_type_list:append({id = action_types.CREATE_NEW_SET, name = 'Create New Set', icon = 'images/' ..get_icon_pathbase() .. '/ui/dpad_' .. self.button_layout .. '.png'})
    action_type_list:append({id = action_types.MOVE_CROSSBARS, name = 'Move Crossbar', icon = 'images/' ..get_icon_pathbase() .. '/ui/dpad_ps.png'})
	action_type_list:append({id = action_types.CHANGE_ICON, name = 'Change Slot Icon', icon = 'images/' ..get_icon_pathbase() .. '/icon-set.png'})
    action_type_list:append({id = action_types.GLOBAL_ICON_SET, name = 'Change Action Icon', icon = 'images/' ..get_icon_pathbase() .. '/icon-set.png'})
    action_type_list:append({id = action_types.DELETE, name = 'Remove a Binding', icon = 'images/' ..get_icon_pathbase() .. '/ui/red-x.png'})

    action_type_list:append({id = action_types.SHOW_CREDITS, name = 'XIVCrossbar Credits', icon = 'images/credit_avatars/xiv.png'})
    self.selector:display_options(action_type_list)
    self:show_control_hints('Confirm', 'Exit')
end

function action_binder:display_action_selector()
    if (self.action_type == action_types.JOB_ABILITY) then
        self:display_ability_selector()
    elseif (self.action_type == action_types.WEAPONSKILL) then
        self:display_weaponskill_selector()
    elseif (self.action_type == action_types.PET_COMMAND) then
        self:display_pet_command_selector()
    elseif (self.action_type == action_types.WHITE_MAGIC) then
        self:display_white_magic_selector()
    elseif (self.action_type == action_types.BLACK_MAGIC) then
        self:display_black_magic_selector()
    elseif (self.action_type == action_types.SONG) then
        self:display_song_selector()
    elseif (self.action_type == action_types.READY) then
        self:display_ready_selector()
    elseif (self.action_type == action_types.NINJUTSU) then
        self:display_ninjutsu_selector()
    elseif (self.action_type == action_types.SUMMON) then
        self:display_summoning_selector()
    elseif (self.action_type == action_types.BP_RAGE) then
        self:display_bp_rage_selector()
    elseif (self.action_type == action_types.BP_WARD) then
        self:display_bp_ward_selector()
    elseif (self.action_type == action_types.BLUE_MAGIC) then
        self:display_blue_magic_selector()
    elseif (self.action_type == action_types.PHANTOM_ROLL) then
        self:display_phantom_roll_selector()
    elseif (self.action_type == action_types.QUICK_DRAW) then
        self:display_quick_draw_selector()
    elseif (self.action_type == action_types.STRATAGEMS) then
        self:display_stratagem_selector()
    elseif (self.action_type == action_types.DANCES) then
        self:display_dance_selector()
    elseif (self.action_type == action_types.RUNE_ENCHANTMENT) then
        self:display_rune_enchantment_selector()
    elseif (self.action_type == action_types.WARD) then
        self:display_ward_selector()
    elseif (self.action_type == action_types.EFFUSION) then
        self:display_effusion_selector()
    elseif (self.action_type == action_types.GEOMANCY) then
        self:display_geomancy_selector()
    elseif (self.action_type == action_types.TRUST) then
        self:display_trust_selector()
    elseif (self.action_type == action_types.MOUNT) then
        self:display_mount_selector()
    elseif (self.action_type == action_types.USABLE_ITEM) then
        self:display_usable_item_selector()
    elseif (self.action_type == action_types.TRADABLE_ITEM) then
        self:display_tradable_item_selector()
    elseif (self.action_type == action_types.RANGED_ATTACK) then
        self:display_tradable_item_selector()
    elseif (self.action_type == action_types.SWITCH_CROSSBARS) then
        self:display_crossbar_sets_selector()
    elseif (self.action_type == action_types.QUICK_SWITCH_CROSSBARS) then
        self:display_crossbar_sets_selector()
    elseif (self.action_type == action_types.CUSTOM_ACTION) then
        self:display_custom_actions_selector()
    elseif (self.action_type == action_types.EXECUTE_COMMAND) then
        self:display_execute_command_selector()
	elseif (self.action_type == action_types.SUPERWARP) then
        self:display_superwarp_selector()
    end
end

function action_binder:display_target_selector()
    self.title:text('Select Action Target')
    self.title:show()

    local target_options = L(require('ui/target_choices').build(self.target_type,
        self.theme_options.allow_stpc_for_self_targeted_actions,
        'images/' .. get_icon_pathbase() .. '/mappoint.png'))

    self.selector:display_options(target_options)
end

-- Center captions using measured glyph widths rather than character counts.
function action_binder:center_caption(caption, y)
    caption_layout:center(caption, self.base_x + self.width / 2, y, self.width - 80)
end

-- A: the destination is the current set, even when a draft spans switches.
function action_binder:show_set_title(label)
    self.set_title_base = label
    local key = player_data.hotbar_settings.active_environment
    local bar = player_data.hotbar[key]
    local name = require('ui/set_labels').display(key,bar and bar.name)
    local defaults = {default=true, ['job-default']=true, ['all-jobs-default']=true, shared=true}
    local color = defaults[key] and '\\cs(0,128,255)' or '\\cs(255,255,255)'
    local scope = self.state == states.EDIT_CUSTOM_ACTION_REVIEW and self.custom_action_draft and
        (' ['..(self.custom_action_draft._scope or player_data:catalog_save_scope())..' catalog]') or ''
    self.title:text(label .. ' — ' .. color .. name .. ' Crossbar\\cr' .. scope)
    self:center_caption(self.title, self.base_y + 30)
    self.title:show()
    if self.chooser_active then self.title:alpha(math.floor((self.chooser_title_alpha or 255)*0.45)) end
end

function action_binder:refresh_set_title()
    if not self.title or self.is_hidden then return end
    if self.state == states.SELECT_BUTTON_ASSIGNMENT or self.state == states.CONFIRM_BUTTON_ASSIGNMENT or
        self.state == states.EDIT_CUSTOM_ACTION_REVIEW then
        if self.set_title_base then self:show_set_title(self.set_title_base) end
    end
end

function action_binder:display_button_assigner()
    self:show_set_title('Enter Button Combo')

    self:reset_gamepad()

    self.selector:hide()

    windower.prim.set_position('button_entry_bg', self.base_x+30, self.base_y+self.height/2-60)
    windower.prim.set_size('button_entry_bg',self.width-60,120)
    windower.prim.set_color('button_entry_bg',150,0,0,0)
    windower.prim.set_visibility('button_entry_bg', true)

    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}

    local caption_x = self.base_x + self.width / 2
    local caption_y = self.base_y + self.height / 2 - 40
    local caption_text = ''
    local secondary_text = nil
    if (self.action_type == action_types.DELETE) then
        caption_text = 'Press a button combo to remove its bound action'
    elseif (self.action_type == action_types.CHANGE_ICON) then
        caption_text = 'Press the button combo for the slot to change icon.'
    elseif (self.action_type == action_types.GLOBAL_ICON_SET) then
        caption_text = 'Press the button combo for the action to change icon.'
        secondary_text = 'Matches action names or aliases across your sets; slot icons take precedence.'
    else
        caption_text = 'Press a button combo to bind it to this action'
    end

    self:show_control_hints('Confirm', 'Go Back')
    local caption = self:create_text(caption_text, caption_x, caption_y)
    caption:size(14)
    self:center_caption(caption, caption_y)
    self.hints:append(caption)
    if (secondary_text ~= nil) then
        local secondary = self:create_text(secondary_text, caption_x, caption_y + 25)
        secondary:size(11)
        self:center_caption(secondary, caption_y + 25)
        self.hints:append(secondary)
    end
end

function action_binder:display_button_confirmer()
    self:show_set_title('Enter Button Combo')

    self.selector:hide()

    ui_resources.clear(self.hints); self.hints = L{}

    local caption_x = self.base_x + self.width / 2
    local caption_y = self.base_y + self.height / 2 - 40
    local caption_text = ''
    if (self.action_type == action_types.DELETE) then
        caption_text = 'Delete binding?'
    elseif (self.action_type == action_types.CHANGE_ICON) then
        caption_text = 'Change icon for this slot?'
    elseif (self.action_type == action_types.GLOBAL_ICON_SET) then
        caption_text = 'Change icon for matching actions across your sets?'
    else
        caption_text = 'Bind ' .. self.action_name .. '?'
    end
    self:confirm_buttons()
    self:show_control_hints('Confirm', 'Go Back')

    local caption = self:create_text(caption_text, caption_x, caption_y)
    caption:size(14)
    self:center_caption(caption, caption_y)
    self.hints:append(caption)
end

function action_binder:assign_action()
    self.save_binding(self.active_crossbar, self.hotkey, prefix_lookup[self.action_type], self.action_name, self.action_target, self.action_command, self.action_icon, self.action_linked_action, self.action_linked_type, self.action_alias, self.action_catalog)
    self:hide()
    self:reset_state()
end

function action_binder:delete_action()
    self.delete_binding(self.active_crossbar, self.hotkey, prefix_lookup[self.action_type], self.action_name, self.action_target)
    self:hide()
    self:reset_state()
end

function action_binder:show_icon(path, x, y)
    local icon = ui_resources.image({draggable = false})
    local icon_path = windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/' .. path
    icon:path(icon_path)
    icon:repeat_xy(1, 1)
    icon:draggable(false)
    icon:fit(true)
    icon:alpha(255)
    icon:show()
    icon:pos(x, y)
    self.images:append(icon)
    return icon
end

function action_binder:show_pressed_buttons()
    local icons = L{}
    ui_resources.clear(self.images); self.images = L{}

    if (self.theme_options.hotbar_number > 3) then
        if (self.active_crossbar == 1) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 2) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 3) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/arrow_right.png')
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 4) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/arrow_right.png')
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 5) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/x2.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 6) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/x2.png')
            icons:append('ui/binding_icons/plus.png')
        end
    else
        if (self.trigger_left_pressed) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/plus.png')
        end
        if (self.trigger_right_pressed) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/plus.png')
        end
    end

    if (self.dpad_left_pressed) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_left.png')
    end
    if (self.dpad_right_pressed) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_right.png')
    end
    if (self.dpad_down_pressed) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_down.png')
    end
    if (self.dpad_up_pressed) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_up.png')
    end
    if (self.button_a_pressed) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png')
    end
    if (self.button_b_pressed) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png')
    end
    if (self.button_x_pressed) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png')
    end
    if (self.button_y_pressed) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png')
    end

    local all_icon_width = #icons * 40
    local center = self.width / 2
    local start_x = self.base_x + center - (all_icon_width / 2)
    local start_y = self.base_y + self.height / 2

    for i=1,#icons,1 do
        self:show_icon(icons[i], start_x + (i - 1) * 40, start_y)
    end

    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:confirm_buttons()
    local icons = L{}
    ui_resources.clear(self.images); self.images = L{}

    if (self.theme_options.hotbar_number > 3) then
        if (self.active_crossbar == 1) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 2) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 3) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/arrow_right.png')
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 4) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/arrow_right.png')
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 5) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/x2.png')
            icons:append('ui/binding_icons/plus.png')
        elseif (self.active_crossbar == 6) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/x2.png')
            icons:append('ui/binding_icons/plus.png')
        end
    else
        if (self.trigger_left_pressed) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
            icons:append('ui/binding_icons/plus.png')
        end
        if (self.trigger_right_pressed) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_right.png')
            icons:append('ui/binding_icons/plus.png')
        end
    end

    if (self.hotkey == 1) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_left.png')
    end
    if (self.hotkey == 3) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_right.png')
    end
    if (self.hotkey == 2) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_down.png')
    end
    if (self.hotkey == 4) then
        icons:append('ui/binding_icons/dpad_' .. self.button_layout .. '_up.png')
    end
    if (self.hotkey == 6) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png')
    end
    if (self.hotkey == 5) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png')
    end
    if (self.hotkey == 7) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png')
    end
    if (self.hotkey == 8) then
        icons:append('ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png')
    end

    local all_icon_width = #icons * 40
    local center = self.width / 2
    local start_x = self.base_x + center - (all_icon_width / 2)
    local start_y = self.base_y + self.height / 2

    for i=1,#icons,1 do
        self:show_icon(icons[i], start_x + (i - 1) * 40, start_y)
    end
end

function action_binder:show_hint(hint_text, path, x, y)
    local icon = self:show_icon(path, x, y)
    self.control_hint_images = self.control_hint_images or L{}
    self.control_hint_images:append(icon)
    local caption = self:create_text(hint_text, x + 45, y + 10)
    caption:size(14)
    self.hints:append(caption)
    if self.state == states.SELECT_BUTTON_ASSIGNMENT then
        local disabled = hint_text == 'Confirm' or (hint_text == 'Go Back' and
            (self.trigger_left_pressed or self.trigger_right_pressed))
        if disabled then
            caption:alpha(80)
            self.images[#self.images]:alpha(80)
        end
    end
end

function action_binder:show_exit_hint()
    local x = self.base_x + 10
    local y = self.base_y + self.height - 50
    local icon=require('libs/controller/menu_buttons').hint('binder',self.button_layout)

    if (self.button_layout == 'gamecube') then
        if (self.confirm_button == 'a') then
            self:show_hint('Exit', icon, x, y)
        end
    elseif (self.button_layout == 'playstation') then
        if (self.confirm_button == 'cross') then
            self:show_hint('Exit', icon, x, y)
        end
    elseif (self.button_layout == 'xbox') then
        if (self.confirm_button == 'a') then
            self:show_hint('Exit', icon, x, y)
        end
    elseif (self.button_layout == 'nintendo') then
        if (self.confirm_button == 'b') then
            self:show_hint('Exit', icon, x, y)
        end
    end
end

function action_binder:show_control_hints(confirm, go_back)
    ui_resources.clear(self.control_hint_images); self.control_hint_images = L{}
    for i=#self.images,1,-1 do
        if ui_resources.is_disposed(self.images[i]) then self.images:remove(i) end
    end
    ui_resources.clear(self.hints); self.hints = L{}
    local y = self.base_y + self.height - 50
    local x1 = self.base_x + self.width - 130
    local x2 = self.base_x + self.width - 250

    self:show_exit_hint()

    if (self.button_layout == 'gamecube') then
        if (self.confirm_button == 'a') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x2, y)
        elseif (self.confirm_button == 'b') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x2, y)
        elseif (self.confirm_button == 'x') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x2, y)
        elseif (self.confirm_button == 'y') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x2, y)
        end
    elseif (self.button_layout == 'playstation') then
        if (self.confirm_button == 'cross') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x2, y)
        elseif (self.confirm_button == 'square') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x2, y)
        elseif (self.confirm_button == 'circle') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x2, y)
        elseif (self.confirm_button == 'triangle') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x2, y)
        end
    elseif (self.button_layout == 'xbox') then
        if (self.confirm_button == 'a') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x2, y)
        elseif (self.confirm_button == 'x') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x2, y)
        elseif (self.confirm_button == 'b') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x2, y)
        elseif (self.confirm_button == 'y') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x2, y)
        end
    elseif (self.button_layout == 'nintendo') then
        if (self.confirm_button == 'b') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x2, y)
        elseif (self.confirm_button == 'y') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x2, y)
        elseif (self.confirm_button == 'a') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x2, y)
        elseif (self.confirm_button == 'x') then
            self:show_hint(confirm, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x2, y)
        end
    end

    if (self.button_layout == 'gamecube') then
        if (self.cancel_button == 'a') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x1, y)
        elseif (self.cancel_button == 'b') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x1, y)
        elseif (self.cancel_button == 'x') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x1, y)
        elseif (self.cancel_button == 'y') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x1, y)
        end
    elseif (self.button_layout == 'playstation') then
        if (self.cancel_button == 'cross') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x1, y)
        elseif (self.cancel_button == 'square') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x1, y)
        elseif (self.cancel_button == 'circle') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x1, y)
        elseif (self.cancel_button == 'triangle') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x1, y)
        end
    elseif (self.button_layout == 'xbox') then
        if (self.cancel_button == 'a') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x1, y)
        elseif (self.cancel_button == 'x') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x1, y)
        elseif (self.cancel_button == 'b') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x1, y)
        elseif (self.cancel_button == 'y') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x1, y)
        end
    elseif (self.button_layout == 'nintendo') then
        if (self.cancel_button == 'b') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_a.png', x1, y)
        elseif (self.cancel_button == 'y') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_b.png', x1, y)
        elseif (self.cancel_button == 'a') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_x.png', x1, y)
        elseif (self.cancel_button == 'x') then
            self:show_hint(go_back, 'ui/binding_icons/facebuttons_' .. self.button_layout .. '_y.png', x1, y)
        end
    end
end

function action_binder:display_ability_selector()
    self.title:text('Select Job Ability')
    self.title:show()

    local LV_1_SP_ABILITY_RECAST_ID = 0
    local LV_96_SP_ABILITY_RECAST_ID = 254

    local player = windower.ffxi.get_player()
    local abilities = windower.ffxi.get_abilities().job_abilities
    local ability_list = L{}

    local skip_categories = {
        ['phantom-rolls'] = true,
        ['quick-draw'] = true,
        ['stratagems'] = true,
        ['dances'] = true,
        ['wards'] = true,
        ['effusions'] = true,
        ['ready'] = true,
        ['blood-pacts/rage'] = true,
        ['blood-pacts/ward'] = true,
    }

    for key, id in pairs(abilities) do
        local recast_id = res.job_abilities[id].recast_id
        local name = res.job_abilities[id].en
        local target_type = res.job_abilities[id].targets
        local ability = crossbar_abilities[kebab_casify(name)]
        if (not skip_categories[ability.category]) then
            local icon_path, icon_overridden = maybe_get_custom_icon(ability.default_icon, ability.custom_icon)
            local icon_offset = 4
            if (icon_overridden) then
                icon_offset = 0
            end

            ability_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
        end
    end

    ability_list:sort(sortByName)

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_weaponskill_selector()
    self.title:text('Select Weaponskill')
    self.title:show()

    local abilities = windower.ffxi.get_abilities().weapon_skills
    local ability_list = L{}

    for key, id in pairs(abilities) do
        local ws = res.weapon_skills[id]
        local weapon = res.skills[ws.skill].en:lower()
        local name = ws.en
        local ws_action = crossbar_abilities[kebab_casify(name)]
        local icon_path, icon_overridden = maybe_get_custom_icon(ws_action.default_icon, ws_action.custom_icon)
        local icon_offset = 4
        if (icon_overridden) then
            icon_offset = 0
        end

        ability_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = {['Enemy'] = true}}})
    end

    ability_list:sort(sortByName)

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

-- TODO: Add get_drg_pet_commands(mlvl, slvl)
-- TODO This ↑ comment is by Icydeath. Maybe this has already been implemented? → Test it.
function action_binder:display_pet_command_selector()
    self.title:text('Select Pet Command')
    self.title:show()

    local player = windower.ffxi.get_player()

    -- BST
    local commands = get_bst_pet_commands(player.main_job_id, player.main_job_level)
    for i, command in ipairs(get_bst_pet_commands(player.sub_job_id, player.sub_job_level)) do
        commands:append(command)
    end

    -- SMN
    for i, command in ipairs(get_smn_pet_commands(player.main_job_id, player.main_job_level)) do
        commands:append(command)
    end
    for i, command in ipairs(get_smn_pet_commands(player.sub_job_id, player.sub_job_level)) do
        commands:append(command)
    end

    -- PUP
    for i, command in ipairs(get_pup_pet_commands(player.main_job_id, player.main_job_level)) do
        commands:append(command)
    end
    for i, command in ipairs(get_pup_pet_commands(player.sub_job_id, player.sub_job_level)) do
        commands:append(command)
    end

    -- DRG
    for i, command in ipairs(get_drg_pet_commands(player.main_job_id, player.main_job_level)) do
        commands:append(command)
    end
    for i, command in ipairs(get_drg_pet_commands(player.sub_job_id, player.sub_job_level)) do
        commands:append(command)
    end

    self.selector:display_options(commands)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_magic_selector_internal(magic_type)
    local player = windower.ffxi.get_player()
    local main_job = player.main_job:lower()
    local jp_spent = player.job_points[main_job].jp_spent
    local level = player.main_job_level

    -- JP gift spells have a "level" requirement equivalent to their JP spend requirement
    if (level == 99 and jp_spent > 99) then
        level = jp_spent
    end

    local main_spells = get_spells_for_job(player.main_job_id, level, magic_type)
    local sub_spells = get_spells_for_job(player.sub_job_id, player.sub_job_level, magic_type)

    local all_spells = T{}
    for id in pairs(main_spells) do
        all_spells[id] = id
    end
    for id in pairs(sub_spells) do
        all_spells[id] = id
    end

    local spell_list = L{}
    for id in pairs(all_spells) do
        local name = res.spells[id].name
        local target_type = fix_target_types(id, magic_type, res.spells[id].targets)
        local spell = crossbar_spells[kebab_casify(name)]

        local magic_filter_type = SPELL_TYPE_LOOKUP[magic_type]
        if (magic_filter_type == nil) then
            magic_filter_type = kebab_casify(magic_type)
        end

        if (spell ~= nil and spell.category == magic_filter_type) then
            local icon_path, icon_overridden = maybe_get_custom_icon(spell.default_icon, spell.custom_icon)
            
            -- TODO: This is duplicated a lot, remove the redundancy
            -- Also, I noticed that this fails for regular icons if you logout and login again. Fix this as well.
            local icon_offset = 4
            if (icon_overridden) then
                icon_offset = 0
            end

            spell_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
        end
    end

    spell_list:sort(sortByName)

    self.selector:display_options(spell_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_white_magic_selector()
    self.title:text('Select White Magic Spell')
    self.title:show()

    self:display_magic_selector_internal('WhiteMagic')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_black_magic_selector()
    self.title:text('Select Black Magic Spell')
    self.title:show()

    self:display_magic_selector_internal('BlackMagic')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_song_selector()
    self.title:text('Select Song')
    self.title:show()

    self:display_magic_selector_internal('BardSong')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_ready_selector()
    self.title:text('Select Ready Ability')
    self.title:show()

    local ability_list = L{}

    for id, ability in pairs(res.job_abilities) do
        local name = ability.name
        local target_type = ability.targets
        local ready_ability = crossbar_abilities[kebab_casify(name)]
        if (ready_ability.category == 'ready') then
            local icon_path, icon_overridden = maybe_get_custom_icon(ready_ability.default_icon, ready_ability.custom_icon)
            local icon_offset = 4
            if (icon_overridden) then
                icon_offset = 0
            end

            ability_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
        end
    end

    ability_list:sort(sortByName)

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_ninjutsu_selector()
    self.title:text('Select Ninjutsu Spell')
    self.title:show()

    self:display_magic_selector_internal('Ninjutsu')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_summoning_selector()
    self.title:text('Select Summoning Spell')
    self.title:show()

    self:display_magic_selector_internal('SummonerPact')
    self:show_control_hints('Confirm', 'Go Back')
end

-- A: both pact selectors use native availability and identical icon fallback.
function action_binder:display_blood_pact_selector(kind)
    local ward=kind=='BloodPactWard'
    self.title:text(ward and 'Select Blood Pact: Ward' or 'Select Blood Pact: Rage')
    self.title:show()
    local pacts=require('libs/blood_pacts')
    local ability_list=L{}
    for _,ability in ipairs(pacts.available(res.job_abilities,windower.ffxi.get_abilities(),kind)) do
        local name=ability.name or ability.en
        local metadata=crossbar_abilities[kebab_casify(name)]
        local icon,custom=pacts.icon(ability,metadata,get_icon_pathbase(),require('ui/assets').exists)
        ability_list:append({id=ability.id,name=name,icon=icon,icon_offset=custom and 0 or 4,
            data={target_type=ability.targets}})
    end
    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm','Go Back')
end
function action_binder:display_bp_rage_selector() self:display_blood_pact_selector('BloodPactRage') end
function action_binder:display_bp_ward_selector() self:display_blood_pact_selector('BloodPactWard') end

function action_binder:display_blue_magic_selector()
    self.title:text('Select Blue Magic Spell')
    self.title:show()

    self:display_magic_selector_internal('BlueMagic')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_phantom_roll_selector()
    self.title:text('Select Phantom Roll')
    self.title:show()

    local abilities = windower.ffxi.get_abilities().job_abilities
    local ability_list = L{}

    for key, id in pairs(abilities) do
        local name = res.job_abilities[id].name
        local target_type = res.job_abilities[id].targets
        local roll = crossbar_abilities[kebab_casify(name)]
        if (roll.category == 'phantom-rolls') then
            local icon_path, icon_overridden = maybe_get_custom_icon(roll.default_icon, roll.custom_icon)
            local icon_offset = 4
            if (icon_overridden) then
                icon_offset = 0
            end

            ability_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
        end
    end

    ability_list:sort(sortByName)

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_quick_draw_selector()
    self.title:text('Select Quick Draw')
    self.title:show()

    local abilities = windower.ffxi.get_abilities().job_abilities
    local ability_list = L{}

    for key, id in pairs(abilities) do
        local name = res.job_abilities[id].name
        local target_type = res.job_abilities[id].targets
        local quick_draw = crossbar_abilities[kebab_casify(name)]
        if (quick_draw.category == 'quick-draw') then
            local icon_path, icon_overridden = maybe_get_custom_icon(quick_draw.default_icon, quick_draw.custom_icon)
            local icon_offset = 4
            if (icon_overridden) then
                icon_offset = 0
            end

            ability_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
        end
    end

    ability_list:sort(sortByName)

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_stratagem_selector()
    self.title:text('Select Stratagem')
    self.title:show()

    local player = windower.ffxi.get_player()
    local stratagems = get_stratagems(player.main_job_id, player.main_job_level)

    for i, stratagem in ipairs(get_stratagems(player.sub_job_id, player.sub_job_level)) do
        stratagems:append(stratagem)
    end

    self.selector:display_options(stratagems)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_dance_selector()
    self.title:text('Select Dance')
    self.title:show()

    local player = windower.ffxi.get_player()
    local dances = get_dances(player.main_job_id, player.main_job_level)

    for i, dance in ipairs(get_dances(player.sub_job_id, player.sub_job_level)) do
        dances:append(dance)
    end

    self.selector:display_options(dances)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_geomancy_selector()
    self.title:text('Select Geomancy Spell')
    self.title:show()

    self:display_magic_selector_internal('Geomancy')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_rune_enchantment_selector()
    self.title:text('Select Rune Enchantment')
    self.title:show()

    local player = windower.ffxi.get_player()
    local is_main_high_enough = (player.main_job_id == 22 and player.main_job_level >= 5)
    local is_sub_high_enough = (player.sub_job_id == 22 and player.sub_job_level >= 5)

    local rune_enchantment_list = L{}
    if (is_main_high_enough or is_sub_high_enough) then
        rune_enchantment_list = L{358, 359, 360, 361, 362, 363, 364, 365}
    end

    local ability_list = L{}
    for key, id in ipairs(rune_enchantment_list) do
        local name = res.job_abilities[id].name
        local target_type = res.job_abilities[id].targets
        local element = res.elements[res.job_abilities[id].element].en:lower()
        local rune_enchantment = crossbar_abilities[kebab_casify(name)]
        if (rune_enchantment.category == 'rune-enchantments') then
            local icon_path, icon_overridden = maybe_get_custom_icon(rune_enchantment.default_icon, rune_enchantment.custom_icon)
            local icon_offset = 4
            if (icon_overridden) then
                icon_offset = 0
            end

            ability_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
        end
    end

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_ward_selector()
    self.title:text('Select Ward')
    self.title:show()

    local player = windower.ffxi.get_player()
    local wards = get_wards(player.main_job_id, player.main_job_level)

    for i, ward in ipairs(get_wards(player.sub_job_id, player.sub_job_level)) do
        wards:append(ward)
    end

    self.selector:display_options(wards)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_effusion_selector()
    self.title:text('Select Effusion')
    self.title:show()

    local player = windower.ffxi.get_player()
    local effusions = get_effusions(player.main_job_id, player.main_job_level)

    for i, effusion in ipairs(get_effusions(player.sub_job_id, player.sub_job_level)) do
        effusions:append(effusion)
    end

    self.selector:display_options(effusions)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_crossbar_sets_selector()
    local is_quick_switch = (self.action_type == action_types.QUICK_SWITCH_CROSSBARS)
    if (is_quick_switch) then
        self.title:text('Select Crossbar Set (Quick Switch)')
    else
        self.title:text('Select Crossbar Set')
    end
    self.title:show()

    local crossbar_set_list = L{}
    local icon = '/ui/facebuttons_' .. self.button_layout
    local icon_path = 'images/' .. get_icon_pathbase() .. icon .. '.png'
    for _, destination in ipairs(self.get_crossbar_sets_binding()) do
        -- Accept older string callbacks too; production supplies stable keys.
        local name = type(destination)=='table' and destination.name or destination
        local key = type(destination)=='table' and destination.key or kebab_casify(destination)
        local data = {target_type={None=true},icon_path=icon,alias=name,action_name=key}
        if not is_quick_switch then data.command='xb bar '..key end
        crossbar_set_list:append({id=key,name=name,icon=icon_path,icon_offset=0,data=data})
    end

    self.selector:display_options(crossbar_set_list)
    self:show_control_hints('Confirm', 'Go Back')
end

-- Explicit artwork wins; valid linked metadata can supply a catalog icon.
-- Only unlinked/unresolved entries use the full-size gear catalog default.
function action_binder:custom_action_icon(record)
    local base = 'images/' .. get_icon_pathbase() .. '/'
    if record.icon and record.icon ~= '' then return base .. record.icon .. '.png',0 end
    local name,kind = record.linked_action,record.linked_type
    if name and name ~= '' and (kind=='ma' or kind=='ja' or kind=='ws' or kind=='pet') then
        local resources = kind=='ma' and crossbar_spells or crossbar_abilities
        local metadata = resources[kebab_casify(name)]
        if metadata then
            local path,overridden = maybe_get_custom_icon(metadata.default_icon,metadata.custom_icon)
            if path then return path,overridden and 0 or 4 end
        end
    end
    return base .. 'custom_actions.png',0
end

function action_binder:display_custom_actions_selector()
    if player_data.refresh_custom_catalogs then player_data:refresh_custom_catalogs() end
    self.title:text('Select Custom Action')
    self.title:show()

    local action_list = L{}
    if (player_data.custom_actions ~= nil) then
        for name, record in pairs(player_data.custom_actions) do
            local icon_path,icon_offset = self:custom_action_icon(record)

            local resolved_alias = record.name or name
            if (record.alias ~= nil and record.alias ~= '') then
                resolved_alias = record.alias
            end

            local resolved_linked_action = nil
            if (record.linked_action ~= nil and record.linked_action ~= '') then
                resolved_linked_action = record.linked_action
            end

            local resolved_linked_type = nil
            if (record.linked_type ~= nil and record.linked_type ~= '') then
                resolved_linked_type = record.linked_type
            end

            action_list:append({
                id = name,
                name = name,
                icon = icon_path,
                icon_offset = icon_offset,
                data = {
                    catalog_name = record.name,
                    catalog_scope = record._scope,
                    catalog_id = record.id,
                    command = record.command,
                    icon_path = record.icon,
                    alias = resolved_alias,
                    linked_action = resolved_linked_action,
                    linked_type = resolved_linked_type,
                    target_type = {['None'] = true},
                }
            })
        end
    end

    action_list:sort(sortByName)
    self.selector:display_options(action_list)
    self:show_control_hints('Confirm', 'Go Back')
end

local icon_picker_excluded_files = {
    ['goring_blade'] = true, -- duplicate top-level sample, not the weaponskill icon
    ['bar_bg'] = true,
    ['bar_bg_compact'] = true,
    ['bar_bg_compact_alt'] = true,
    ['black-square'] = true,
    ['blank'] = true,
    ['blue-square'] = true,
    ['feedback'] = true,
    ['frame'] = true,
    ['frame_step1'] = true,
    ['frame_step2'] = true,
    ['frame_step3'] = true,
    ['frame_step4'] = true,
    ['frame_step5'] = true,
    ['frame_step6'] = true,
    ['frame_step7'] = true,
    ['frame_step8'] = true,
    ['green'] = true,
    ['red'] = true,
    ['square'] = true,
    ['needs_job_ability'] = true,
    ['red-x'] = true,
    ['bg'] = true,
}
local icon_picker_excluded_dirs = {
    ['binding_icons'] = true,
}

local function list_iconpack_dir(rel_path)
    -- A: the folder browser and recursive picker must use the same roots as
    -- rendering. Normalize the entire Windows command path, including addon_path.
    local dirs,files=L{},L{}
    local seen_dirs,seen_files={},{}
    for _,root in ipairs(require('ui/assets').pack_roots(icon_pack)) do
        local path=(root..((rel_path or '')~='' and '/'..rel_path or '')):gsub('/', '\\')
        for _,kind in ipairs({'dirs','files'}) do
            local command=kind=='dirs' and ('dir /b /a:d "'..path..'" 2>nul')
                or ('dir /b /a:-d "'..path..'\\*.png" 2>nul')
            local handle=io.popen(command)
            if handle then
                for line in handle:lines() do
                    line=line:gsub('\r$', '')
                    if kind=='dirs' then
                        local key=line:lower()
                        if key~='' and not seen_dirs[key] and not icon_picker_excluded_dirs[key] then
                            seen_dirs[key]=true;dirs:append(line)
                        end
                    else
                        local stem=line:match('^(.*)%.[pP][nN][gG]$')
                        local key=stem and stem:lower()
                        if key and key~='' and not seen_files[key] and not icon_picker_excluded_files[key] then
                            seen_files[key]=true;files:append(stem)
                        end
                    end
                end
                handle:close()
            end
        end
    end
    return dirs,files
end

function action_binder:display_icon_selector(rel_path)
    rel_path = rel_path or self.icon_picker_path or ''
    self.icon_picker_path = rel_path
    local title_text
    if (self.action_type == action_types.GLOBAL_ICON_SET) then
        title_text = 'Pick Icon for "' .. (self.global_icon_source_name or '?') .. '"'
    elseif (self.action_type == action_types.CHANGE_ICON) then
        title_text = 'Pick Icon for Slot'
    else
        title_text = 'Pick an Icon'
    end
    if (rel_path ~= nil and rel_path ~= '') then
        title_text = title_text .. ' — ' .. rel_path
    end
    self.title:text(title_text)
    self.title:show()

    local pathbase = get_icon_pathbase()
    local dirs, files = list_iconpack_dir(rel_path)

    local list = L{}
    if self.icon_picker_return == 'custom_review' then
        list:append({id='CLEAR_ICON', name='Clear Icon', icon='images/' .. pathbase .. '/ui/red-x.png'})
    end

    table.sort(dirs, function(a, b) return a:lower() < b:lower() end)
    for _, dirname in ipairs(dirs) do
        local child_path = (rel_path == '' and dirname) or (rel_path .. '/' .. dirname)
        list:append({
            id = 'DIR_' .. child_path,
            name = dirname .. ' >',
            icon = 'images/' .. pathbase .. '/icon-set.png',
            data = {
                is_dir = true,
                path = child_path,
            }
        })
    end

    table.sort(files, function(a, b) return a:lower() < b:lower() end)
    for _, filename in ipairs(files) do
        local rel_icon = (rel_path == '' and filename) or (rel_path .. '/' .. filename)
        local display_name = filename:gsub('-', ' '):gsub('_', ' ')
        display_name = display_name:gsub('(%a)([%w]*)', function(first, rest)
            return first:upper() .. rest
        end)
        list:append({
            id = 'FILE_' .. rel_icon,
            name = display_name,
            icon = 'images/' .. pathbase .. '/' .. rel_icon .. '.png',
            data = {
                is_dir = false,
                icon_path = rel_icon,  -- matches existing <icon> tag format (no leading slash)
            }
        })
    end

    self.selector:display_options(list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:apply_icon_change()
    if (self.change_slot_icon == nil) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Change Icon: callback not wired (please reload addon).'))
        return
    end
    self.change_slot_icon(self.active_crossbar, self.hotkey, self.action_icon)
end

function action_binder:display_custom_action_field_review(field_label, field_letter, current_value, hint_text)
    self.title:text('Custom Action: ' .. field_label)
    self.title:show()

    self.selector:hide()
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}

    windower.prim.set_visibility('button_entry_bg', true)

    self:show_control_hints('Confirm', 'Go Back')

    local lines = {
        'Current value: ' .. ((current_value ~= nil and current_value ~= '') and current_value or '(not set)'),
        '',
        'Set via:  //xivcrossbar ca ' .. field_letter .. ' <value>',
        '          ' .. (hint_text or ''),
        '',
        'Press Confirm to proceed, or Go Back to revise.',
    }

    local x = self.base_x + self.width / 2 - 220
    local y = self.base_y + self.height / 2 - 70
    for i, line in ipairs(lines) do
        local t = self:create_text(line, x, y + (i - 1) * 22)
        t:size(13)
        self.hints:append(t)
    end
end

function action_binder:on_custom_action_field_set(field, value)
    if (self.custom_action_draft == nil) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] No Custom Action in progress. Open the binder and choose Create Custom Action first.'))
        return false
    end

    -- Reject empty values (whitespace-only counts as empty).
    if field == 'name' and not review.nonempty(value) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] You must provide a value for "' .. field .. '".'))
        return false
    end

    local on_alias_screen   = (self.state == states.ENTER_CUSTOM_ACTION_ALIAS)
    local on_name_screen    = (self.state == states.ENTER_CUSTOM_ACTION_NAME)
    local on_command_screen = (self.state == states.ENTER_CUSTOM_ACTION_COMMAND)
    local on_confirm_screen = (self.state == states.CONFIRM_CUSTOM_ACTION)
    local on_edit_screen    = (self.state == states.EDIT_CUSTOM_ACTION_REVIEW)
    local on_any_all_fields = on_confirm_screen or on_edit_screen

    local accepted = false
    if (field == 'alias' and (on_alias_screen or on_any_all_fields)) then accepted = true end
    if (field == 'name' and (on_name_screen or on_any_all_fields)) then accepted = true end
    if (field == 'command' and (on_command_screen or on_any_all_fields)) then accepted = true end

    if (not accepted) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Field "' .. field .. '" can only be set on its own review screen or the final review/confirm screen.'))
        return false
    end

    if (field == 'name') then
        local is_original = (self.editing_custom_action and value == self.custom_action_original_name)
        if (not is_original and not player_data:custom_name_available(value,self.custom_action_original_name)) then
            windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] A custom action named "' .. value .. '" already exists. Pick a different name.'))
            return false
        end
    end

    self.custom_action_draft[field] = value or ''
    if field == 'name' and self.custom_action_name_required then
        self.custom_action_name_required = false
        self.custom_action_review_field = nil
        self:set_capturing_text(false)
    end
    windower.add_to_chat(0,require('libs/chat_status').legacy(207,'[XIVCrossbar] ' .. field .. ' set to: ' .. value))

    if (on_alias_screen) then
        self:display_custom_action_field_review('Alias', 'a', self.custom_action_draft.alias, '(display label shown on the slot)')
    elseif (on_name_screen) then
        self:display_custom_action_field_review('Catalog Name', 'n', self.custom_action_draft.name, '(unique key in CustomActions.xml)')
    elseif (on_command_screen) then
        self:display_custom_action_field_review('Command', 'c', self.custom_action_draft.command, '(raw command this action will fire)')
    elseif (on_confirm_screen) then
        self:display_custom_action_confirm()
    elseif (on_edit_screen) then
        self:display_edit_custom_action_review()
    end
    return true
end

function action_binder:apply_global_icon()
    if (self.save_global_icon == nil) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Global Icon Set: callback not wired (please reload addon).'))
        return
    end
    if (self.global_icon_source_name == nil or self.global_icon_source_name == '') then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Global Icon Set: no action name captured.'))
        return
    end
    self.save_global_icon(self.global_icon_source_name, self.action_icon)
end

function action_binder:apply_custom_action_save()
    local d=self.custom_action_draft
    if not d or not player_data:custom_name_available(d.name,nil) or not self.save_custom_action then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Enter a unique catalog name before saving.')); return false
    end
    return self.save_custom_action(d) ~= false
end

function action_binder:new_custom_action(name, origin)
    if not self.title then windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Log in before editing.')); return false end
    if self.custom_action_draft then windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Save or cancel the current draft first.')); return false end
    name=name or ''
    if player_data.refresh_custom_catalogs then player_data:refresh_custom_catalogs() end
    local record,key=player_data:find_custom_action(name)
    self.custom_action_entry_origin=origin
    self.editing_custom_action=record ~= nil
    self.custom_action_original_name=record and key or nil
    self.action_type=record and action_types.EDIT_CUSTOM_ACTION or action_types.CREATE_CUSTOM_ACTION
    self.custom_action_draft={name=record and record.name or name,_scope=record and record._scope or player_data:catalog_save_scope(),
        _expected=require('libs/custom_catalog').copy(record),id=record and record.id or nil,alias=record and record.alias or nil,command=record and record.command or nil,
        icon=record and record.icon or nil,linked_action=record and record.linked_action or nil,linked_type=record and record.linked_type or nil}
    self.state=states.EDIT_CUSTOM_ACTION_REVIEW
    self.custom_action_name_required = not review.nonempty(name)
    self:show()
    if self.custom_action_name_required then
        self.custom_action_review_field = 'name'
        self.text_entry_buffer = ''
        self:set_capturing_text(true)
        self:display_inline_custom_action_entry()
    else self:display_edit_custom_action_review() end
    return true
end

function action_binder:display_custom_actions_picker(title_text,preferred)
    if player_data.refresh_custom_catalogs then player_data:refresh_custom_catalogs() end
    self.title:text(title_text)
    self.title:show()
    self.selector:hide()
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}
    windower.prim.set_visibility('button_entry_bg', false)

    local names = {}
    if (player_data.custom_actions ~= nil) then
        for name in pairs(player_data.custom_actions) do
            names[#names + 1] = name
        end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)

    local list = L{}
    local preferred_index
    for _, name in ipairs(names) do
        local record = player_data.custom_actions[name]
        if preferred and ((preferred.id and record.id==preferred.id and record._scope==preferred.scope)
            or (not preferred.id and name==preferred.key)) then preferred_index=#list+1 end
        local icon_path,icon_offset = self:custom_action_icon(record)
        list:append({id = 'CA_' .. name, name = name, icon = icon_path, icon_offset = icon_offset})
    end

    local columns=self.selector.normal_max_col
    local rows=self.selector.normal_max_row
    local capacity=rows*columns
    if preferred_index then self.selector:set_page(math.floor((preferred_index-1)/capacity)+1) end
    self.selector:display_options(list)
    if preferred_index then
        local offset=(preferred_index-1)%capacity
        self.selector.selected_row=math.floor(offset/columns)+1
        self.selector.selected_col=offset%columns+1
        self.selector:highlight_selection()
    end
    self:show_control_hints('Confirm', 'Go Back')
end

-- A: actions above, aligned values below; optional metadata is secondary.
function action_binder:display_edit_custom_action_review()
    local d=self.custom_action_draft or {}
    self:show_set_title(self.editing_custom_action and 'Custom Action: Review and Edit' or 'New Custom Action: Review and Save')
    self.title:show(); self.selector:hide()
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}
    -- The inline caption was owned by the previous hints, not the new review.
    self.inline_entry_text = nil
    require('ui/menu_background').set_color(windower.prim, 'dialog_bg',215,0,0,0)
    windower.prim.set_visibility('button_entry_bg',false)
    local path='images/'..get_icon_pathbase()..'/'
    local list=L{}
    for _,option in ipairs({
        {'SAVE_BIND','Save & Bind','custom_actions'},
        {'SAVE_EDIT',self.editing_custom_action and 'Save Changes' or 'Save Only','custom_actions'},
        {'CHANGE_NAME','Edit Name','custom_actions'},
        {'CHANGE_ALIAS','Edit Alias','custom_actions'},
        {'CHANGE_COMMAND','Edit Command','custom_actions'},
        {'CHANGE_ICON','Choose Icon','icon-set'},
        {'CHANGE_LINKED','Link Action','custom_actions'},
    }) do
        local saving = option[1]=='SAVE_BIND' or option[1]=='SAVE_EDIT'
        list:append({id=option[1],name=option[2],icon=path..option[3]..'.png',
            disabled=saving and not review.nonempty(d.name)})
    end
    self.selector.review_base_x=self.base_x+(self.width-560)/2
    if review.nonempty(d.name) then
        self.selector:set_page(1); self.selector:display_options(list,'review')
    else
        local prompt = self:create_text('Type Custom Action Name and confirm.', self.base_x+70, self.base_y+90)
        self.hints:append(prompt)
    end
    self:show_control_hints('Confirm','Go Back')
    self.custom_action_value_texts={}
    self.review_value_x=self.base_x+self.width*.40
    self.review_rows_y=self.base_y+(review.nonempty(d.name) and 250 or 150)
    local rows={
        {'Custom Action Name',d.name or '',false,'name'},
        {'Alias',review.alias(d),not review.nonempty(d.alias),'alias'},
        {'Command',review.command(d),not review.nonempty(d.command),'command'},
        {'Icon',review.nonempty(d.icon) and d.icon or 'none',not review.nonempty(d.icon)},
        {'Linked',review.nonempty(d.linked_action) and d.linked_action or 'none',not review.nonempty(d.linked_action)},
    }
    for i,row in ipairs(rows) do
        local y=self.review_rows_y+(i-1)*29
        local label=self:create_text(row[1]..':',self.base_x+self.width*.17,y)
        local value=row[3] and ('('..(row[2]~='' and row[2] or 'none')..')') or row[2]
        local text=self:create_text(value:len()>48 and value:sub(1,45)..'...' or value,self.review_value_x,y)
        label:size(i==1 and 14 or 12); text:size(i==1 and 14 or 12)
        if not review.nonempty(d.name) then
            if i==1 then label:color(255,255,255) else label:color(255,149,151) end
            text:color(255,149,151)
        elseif row[3] then label:color(194,253,195); text:color(194,253,195) end
        self.hints:append(label);self.hints:append(text)
        if row[4] then self.custom_action_value_texts[row[4]]=text end
    end
    for i,line in ipairs({
        self.capturing_text and 'Type your value; Enter applies it.' or 'Arrows select; Enter confirms; Esc goes back. Edit a field to type.',
        'Or use: //xb ca name <name of action> | //xb ca alias <label for action> | //xb ca command <console command to fire>',
    }) do
        local y=self.base_y+self.height-95+(i-1)*18
        local help=self:create_text(line,self.base_x+30,y)
        help:size(10);self:center_caption(help,y);self.hints:append(help)
    end
end

function action_binder:display_inline_custom_action_entry()
    self:display_edit_custom_action_review()
    self.selector:hide()
    local field=self.custom_action_review_field
    self.custom_action_value_texts[field]:hide()
    local row=({name=0,alias=1,command=2})[field]
    local x,y=self.review_value_x-5,self.review_rows_y+row*29-3
    windower.prim.set_position('button_entry_bg',x,y)
    windower.prim.set_size('button_entry_bg',self.width*.52,27)
    windower.prim.set_color('button_entry_bg',240,16,26,48)
    windower.prim.set_visibility('button_entry_bg',true)
    self.inline_entry_text=self:create_text('',x+5,y+3)
    self.inline_entry_text:size(12);self.hints:append(self.inline_entry_text)
    self:update_text_entry_display()
end

function action_binder:display_delete_custom_action_confirm()
    local target = self.custom_action_delete_target or '(unknown)'
    self.title:text('Delete Custom Action')
    self.title:show()
    self.selector:hide()
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}
    windower.prim.set_visibility('button_entry_bg', false)

    self:show_control_hints('Confirm', 'Go Back')

    local lines = {
        'Delete custom action "' .. target .. '"?',
        '',
        'This will remove the entry from CustomActions.xml.',
        'Existing slot bindings that reference "' .. target .. '" will',
        'NOT be auto-updated.',
        '',
        'Press Confirm to delete, Go Back to cancel.',
    }
    local x = self.base_x + self.width / 2 - 220
    local y = self.base_y + self.height / 2 - 80
    for i, line in ipairs(lines) do
        local t = self:create_text(line, x, y + (i - 1) * 22)
        t:size(13)
        self.hints:append(t)
    end
end

function action_binder:apply_custom_action_update()
    local d=self.custom_action_draft
    if not d or not player_data:custom_name_available(d.name,self.custom_action_original_name) or not self.update_custom_action then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Enter a unique catalog name before saving.')); return false
    end
    return self.update_custom_action(self.custom_action_original_name,d) ~= false
end

function action_binder:apply_custom_action_delete()
    if (self.delete_custom_action == nil) then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Delete Custom Action: callback not wired (please reload addon).'))
        return
    end
    local target = self.custom_action_delete_target
    if (target == nil or target == '') then
        windower.add_to_chat(0,require('libs/chat_status').legacy(123,'[XIVCrossbar] Delete Custom Action: no entry selected.'))
        return
    end
    self.delete_custom_action(target)
end

function action_binder:clear_button_entry_ui()
    windower.prim.set_visibility('button_entry_bg', false)
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}
end

function action_binder:return_to_action_type_menu()
    self:clear_button_entry_ui()
    self.state = states.SELECT_ACTION_TYPE
    self.action_type = nil
    self.active_crossbar = nil
    self.hotkey = nil
    self.icon_picker_path = ''
    self.icon_picker_stack = {}
    if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
        self.selector:set_page(self.selection_states[states.SELECT_ACTION_TYPE].page)
    end
    self:display_action_type_selector()
    if (self.selection_states[states.SELECT_ACTION_TYPE] ~= nil) then
        self.selector:import_selection_state(self.selection_states[states.SELECT_ACTION_TYPE])
        self.selection_states[states.SELECT_ACTION_TYPE] = nil
    end
end

function action_binder:capture_global_icon_source_name()
    local function lookup(env_name)
        local env_table = player_data.hotbar[env_name]
        if (env_table == nil) then return nil end
        local hb = env_table['hotbar_' .. self.active_crossbar]
        if (hb == nil) then return nil end
        local action = hb['slot_' .. self.hotkey]
        if (action == nil or action.action == nil) then return nil end
        return action
    end

    local env = player_data.hotbar_settings.active_environment
    local action = lookup(env)
    if (action == nil) then
        for _, d in ipairs({'default', 'job-default', 'all-jobs-default'}) do
            if (d ~= env) then
                action = lookup(d)
                if (action ~= nil) then break end
            end
        end
    end

    if (action == nil) then return nil end

    if (action.alias ~= nil and action.alias ~= '') then
        return action.alias
    end
    return action.action
end

function action_binder:check_slot_bound_in_active_env()
    local env = player_data.hotbar_settings.active_environment

    local function lookup(env_name)
        local env_table = player_data.hotbar[env_name]
        if (env_table == nil) then return nil end
        local hb = env_table['hotbar_' .. self.active_crossbar]
        if (hb == nil) then return nil end
        local action = hb['slot_' .. self.hotkey]
        if (action == nil or action.action == nil) then return nil end
        return action
    end

    if (lookup(env) ~= nil) then
        return true, nil
    end

    local defaults = {'default', 'job-default', 'all-jobs-default'}
    for _, d in ipairs(defaults) do
        if (d ~= env and lookup(d) ~= nil) then
            return false, 'Slot is not bound in current set "' .. env .. '" - it is being shown from the "' .. d .. '" fallback set. Switch to that set first to change the icon there, or bind the action directly in "' .. env .. '".'
        end
    end

    return false, 'No action bound at the selected slot.'
end

function action_binder:display_icon_choice_selector()
    self.title:text('Custom Action: Icon')
    self.title:show()
    self.selector:hide()
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}
    windower.prim.set_visibility('button_entry_bg', false)

    local pathbase = get_icon_pathbase()
    local list = L{}
    list:append({id = 'SET_ICON', name = 'Set Icon', icon = 'images/' .. pathbase .. '/icon-set.png'})
    list:append({id = 'SKIP_ICON', name = 'Skip Icon (use default)', icon = 'images/' .. pathbase .. '/ui/red-x.png'})

    self.selector:display_options(list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_linked_type_selector()
    self.title:text('Custom Action: Linked Action Category')
    self.title:show()
    self.selector:hide()
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}
    windower.prim.set_visibility('button_entry_bg', false)

    local p = windower.ffxi.get_player()
    local main_job, sub_job = p.main_job, p.sub_job
    local pathbase = get_icon_pathbase()
    local pet_jobs = {BST = true, SMN = true, DRG = true, PUP = true}
    local white_magic_jobs = {WHM = true, RDM = true, PLD = true, SCH = true, RUN = true}
    local black_magic_jobs = {BLM = true, RDM = true, DRK = true, SCH = true, GEO = true, RUN = true}

    local list = L{}
    list:append({id = 'SKIP_LINKED', name = 'Skip (no linked metadata)', icon = 'images/' .. pathbase .. '/ui/red-x.png'})
    list:append({id = action_types.JOB_ABILITY, name = 'Job Ability', icon = 'images/icons/abilities/00001.png', icon_offset = 4})
    list:append({id = action_types.WEAPONSKILL, name = 'Weaponskill', icon = 'images/icons/weapons/sword.png', icon_offset = 4})
    if (pet_jobs[main_job] or pet_jobs[sub_job]) then
        list:append({id = action_types.PET_COMMAND, name = 'Pet Command', icon = 'images/' .. pathbase .. '/mounts/crab.png'})
    end
    if (white_magic_jobs[main_job] or white_magic_jobs[sub_job]) then
        list:append({id = action_types.WHITE_MAGIC, name = 'White Magic', icon = 'images/' .. pathbase .. '/jobs/WHM.png'})
    end
    if (black_magic_jobs[main_job] or black_magic_jobs[sub_job]) then
        list:append({id = action_types.BLACK_MAGIC, name = 'Black Magic', icon = 'images/' .. pathbase .. '/jobs/BLM.png'})
    end
    if (main_job == 'BRD' or sub_job == 'BRD') then
        list:append({id = action_types.SONG, name = 'Song', icon = 'images/' .. pathbase .. '/jobs/BRD.png'})
    end
    if (main_job == 'BST' or sub_job == 'BST') then
        list:append({id = action_types.READY, name = 'Ready', icon = 'images/' .. pathbase .. '/jobs/BST.png'})
    end
    if (main_job == 'NIN' or sub_job == 'NIN') then
        list:append({id = action_types.NINJUTSU, name = 'Ninjutsu', icon = 'images/' .. pathbase .. '/jobs/NIN.png'})
    end
    if (main_job == 'SMN' or sub_job == 'SMN') then
        list:append({id = action_types.SUMMON, name = 'Summon', icon = 'images/' .. pathbase .. '/jobs/SMN.png'})
        list:append({id = action_types.BP_RAGE, name = 'Blood Pact: Rage', icon = 'images/' .. pathbase .. '/jobs/SMN.png'})
        list:append({id = action_types.BP_WARD, name = 'Blood Pact: Ward', icon = 'images/' .. pathbase .. '/jobs/SMN.png'})
    end
    if (main_job == 'BLU' or sub_job == 'BLU') then
        list:append({id = action_types.BLUE_MAGIC, name = 'Blue Magic', icon = 'images/' .. pathbase .. '/jobs/BLU.png'})
    end
    if (main_job == 'COR' or sub_job == 'COR') then
        list:append({id = action_types.PHANTOM_ROLL, name = 'Phantom Roll', icon = 'images/' .. pathbase .. '/jobs/COR.png'})
        list:append({id = action_types.QUICK_DRAW, name = 'Quick Draw', icon = 'images/' .. pathbase .. '/jobs/COR.png'})
    end
    if (main_job == 'SCH' or sub_job == 'SCH') then
        list:append({id = action_types.STRATAGEMS, name = 'Stratagem', icon = 'images/' .. pathbase .. '/jobs/SCH.png'})
    end
    if (main_job == 'DNC' or sub_job == 'DNC') then
        list:append({id = action_types.DANCES, name = 'Dance', icon = 'images/' .. pathbase .. '/jobs/DNC.png'})
    end
    if (main_job == 'RUN' or sub_job == 'RUN') then
        list:append({id = action_types.RUNE_ENCHANTMENT, name = 'Rune Enchantment', icon = 'images/' .. pathbase .. '/jobs/RUN.png'})
        list:append({id = action_types.WARD, name = 'Ward', icon = 'images/' .. pathbase .. '/jobs/RUN.png'})
        list:append({id = action_types.EFFUSION, name = 'Effusion', icon = 'images/' .. pathbase .. '/jobs/RUN.png'})
    end
    if (main_job == 'GEO' or sub_job == 'GEO') then
        list:append({id = action_types.GEOMANCY, name = 'Geomancy', icon = 'images/' .. pathbase .. '/jobs/GEO.png'})
    end

    self.selector:display_options(list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_custom_action_confirm()
    self.title:text('Custom Action: Review and Save')
    self.title:show()
    self.selector:hide()
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}
    windower.prim.set_visibility('button_entry_bg', true)

    self:show_control_hints('Confirm', 'Go Back')

    local d = self.custom_action_draft or {}
    local lines = {
        'Alias:        ' .. (d.alias or ''),
        'Name:         ' .. (d.name or ''),
        'Command:      ' .. (d.command or ''),
        'Icon:         ' .. (d.icon or '(none)'),
        'Linked:       ' .. (d.linked_action or '(none)') .. ((d.linked_type and d.linked_type ~= '') and ('  [' .. d.linked_type .. ']') or ''),
        '',
        'Revise any text field from here:',
        '  //xivcrossbar ca a <alias>   //xivcrossbar ca n <name>   //xivcrossbar ca c <command>',
        '',
        'Press Confirm to save, or Go Back to revise the linked action.',
    }

    local x = self.base_x + self.width / 2 - 220
    local y = self.base_y + self.height / 2 - 80
    for i, line in ipairs(lines) do
        local t = self:create_text(line, x, y + (i - 1) * 22)
        t:size(13)
        self.hints:append(t)
    end
end

function action_binder:display_trust_selector()
    self.title:text('Select Trust')
    self.title:show()

    self:display_magic_selector_internal('Trust')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_mount_selector()
    self.title:text('Select Mount')
    self.title:show()

    self.selector:display_options(get_mounts())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_usable_item_selector()
    self.title:text('Select Usable Item')
    self.title:show()

    self.selector:display_options(get_usable_items())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_tradable_item_selector()
    self.title:text('Select Tradable Item')
    self.title:show()

    self.selector:display_options(get_tradable_items())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_execute_command_selector()
    self.title:text('Select an icon for the command')
    self.title:show()

    self.selector:display_options(get_icons())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_superwarp_selector()
    self.title:text('Select Warp Location')
    self.title:show()

    self.selector:display_options(get_warp_zones())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_player_selector(include_self)
    self.title:text('Select Player to Assist')
    self.title:show()

    self.selector:display_options(get_party_names(include_self))
    self:show_control_hints('Confirm', 'Go Back')
end

-- TODO: Either rename this to better discern it from action_binder:display_icon_selector() or merge the two functions
function action_binder:display_icon_selector_sylvebits()
    self.title:text('Select Icon')
    self.title:show()

    local icon_list = L{}
    local pathbase = get_icon_pathbase()

    -- Excluded files that are UI framework images, not usable as button icons
    local excluded_files = {
        ['bar_bg'] = true,
        ['bar_bg_compact'] = true,
        ['black-square'] = true,
        ['blank'] = true,
        ['blue-square'] = true,
        ['feedback'] = true,
        ['frame'] = true,
        ['frame_step1'] = true,
        ['frame_step2'] = true,
        ['frame_step3'] = true,
        ['frame_step4'] = true,
        ['frame_step5'] = true,
        ['frame_step6'] = true,
        ['frame_step7'] = true,
        ['frame_step8'] = true,
        ['green'] = true,
        ['red'] = true,
        ['square'] = true,
        ['needs_job_ability'] = true,
        ['red-x'] = true,
        ['bg'] = true,
    }

    -- Excluded subdirectories that contain UI framework images, not button icons
    local excluded_dirs = {
        ['binding_icons'] = true,
    }

    local icon_id = 1

    -- Scan the icon pack directory recursively for all .png files
    local all_icons,seen=L{},{}
    for _,base_dir in ipairs(require('ui/assets').pack_roots(icon_pack)) do
        -- cmd.exe parses forward slashes as switches; asset paths use '/'.
        local scan_dir = base_dir:gsub('/', '\\')
        local command = 'dir /b /s "' .. scan_dir .. '\\*.png" 2>nul'
        local handle = io.popen(command)
        if (handle) then
            for full_path in handle:lines() do
                -- Convert backslashes to forward slashes
                full_path = full_path:gsub('\\', '/')

                -- Extract the relative path after the iconpack base directory
                local relative = full_path:sub(1,#base_dir):lower()==base_dir:lower() and full_path:sub(#base_dir+2)
                if (relative) then
                    -- Remove .png extension
                    local icon_key = relative:gsub('%.png$', '')

                    -- Get just the filename without extension
                    local filename = icon_key:match('.*/(.+)$') or icon_key

                    -- Get the subdirectory if any
                    local subdir = icon_key:match('(.*)/') or ''
                    local immediate_dir = subdir:match('.*/(.*)')  or subdir

                    -- Skip excluded files and directories
                    if (not seen[icon_key] and not excluded_files[filename] and not excluded_dirs[immediate_dir]) then
                        seen[icon_key]=true
                        -- Build display name: capitalize and clean up
                        local display_name = filename:gsub('-', ' '):gsub('_', ' ')
                        -- Capitalize first letter of each word
                        display_name = display_name:gsub('(%a)([%w]*)', function(first, rest)
                            return first:upper() .. rest
                        end)

                        -- Build category prefix for sorting
                        local sort_key = subdir .. '/' .. filename

                        all_icons:append({
                            sort_key = sort_key,
                            name = display_name,
                            icon = 'images/' .. pathbase .. '/' .. icon_key .. '.png',
                            icon_path = '/' .. icon_key,
                            subdir = subdir
                        })
                    end
                end
            end
            handle:close()
        end
    end

    -- Sort alphabetically by category then name
    all_icons:sort(function(a, b) return a.sort_key < b.sort_key end)

    -- Build the final icon list
    for i, entry in ipairs(all_icons) do
        local data = { icon_path = entry.icon_path }
        icon_list:append({id = icon_id, name = entry.name, icon = entry.icon, data = data})
        icon_id = icon_id + 1
    end
    self.selector:display_options(icon_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_text_entry(title_text, placeholder)
    self.title:text(title_text)
    self.title:show()

    self.selector:hide()

    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}

    windower.prim.set_position('button_entry_bg', self.base_x+30, self.base_y+self.height/2-60)
    windower.prim.set_size('button_entry_bg', self.width-60,120)
    windower.prim.set_color('button_entry_bg',150,0,0,0)
    windower.prim.set_visibility('button_entry_bg', true)

    local caption_x = self.base_x + self.width / 2
    local caption_y = self.base_y + self.height / 2 - 40

    local caption = self:create_text(placeholder, caption_x, caption_y)
    caption:size(14)
    self:center_caption(caption, caption_y)
    self.hints:append(caption)
    self:show_exit_hint()
end

function action_binder:update_text_entry_display()
    if self.custom_action_review_field and self.inline_entry_text then
        self.inline_entry_text:text(self.text_entry_buffer:sub(-48) .. '|'); self.inline_entry_text:show(); return
    end
    ui_resources.clear(self.images); self.images = L{}
    ui_resources.clear(self.hints); self.hints = L{}

    local caption_x = self.base_x + self.width / 2
    local caption_y = self.base_y + self.height / 2 - 40

    local display_text = self.text_entry_buffer
    if (display_text == '') then
        if (self.state == states.ENTER_SET_NAME) then
            display_text = '<Type set name, press Enter>'
        else
            display_text = '<Type alias, press Enter>'
        end
    end

    local caption = self:create_text(display_text, caption_x, caption_y)
    caption:size(14)
    self:center_caption(caption, caption_y)
    self.hints:append(caption)
    self:show_exit_hint()
end

function action_binder:is_keyboard_review()
    return not self.is_hidden and not self.chooser_active and not self.capturing_text
        and (self.state==states.EDIT_CUSTOM_ACTION_REVIEW or self.state==states.CONFIRM_CUSTOM_ACTION)
end

function action_binder:set_capturing_text(enabled)
    self.capturing_text = enabled
    require('libs/controller/text_input_guard'):update(enabled, windower.send_command)
end

function action_binder:send_key(char)
    if (self.capturing_text) then
        self.text_entry_buffer = self.text_entry_buffer .. char
        self:update_text_entry_display()
    end
end

function action_binder:send_backspace()
    if (self.capturing_text) then
        self.text_entry_buffer = self.text_entry_buffer:sub(1, -2)
        self:update_text_entry_display()
    end
end

function action_binder:send_enter()
    if self.custom_action_review_field then
        local field,value=self.custom_action_review_field,self.text_entry_buffer
        if self:on_custom_action_field_set(field,value) == false then return end
        self.custom_action_review_field=nil; self:set_capturing_text(false)
        self:display_edit_custom_action_review(); return
    end
    if (not self.capturing_text) then return end

    if self.state == states.ENTER_SET_NAME then
        local name = self.text_entry_buffer
        if not review.nonempty(name) then return end
        if self.create_new_set_binding(name) == false then return end
        self:set_capturing_text(false)
        self.text_entry_buffer = ''
        self:return_to_action_type_menu()
    end

end

function action_binder:send_escape_text()
    if (self.capturing_text) then
        self:set_capturing_text(false)
        self.text_entry_buffer = ''
        self:go_back()
    end
end

function action_binder:is_capturing_text()
    return self.capturing_text
end

function action_binder:display_credits()
    self.title:text('XIVCrossbar Development Credits')
    self.title:show()

    local NO_DATA = {target_type = {['None'] = true}}

    local credits = L{
        {id = 0, name = 'Programming\nAliekber', icon = 'images/credit_avatars/aliekber.png', data = NO_DATA},
        {id = 0, name = 'MS Paint Art\nAliekber', icon = 'images/credit_avatars/aliekber.png', data = NO_DATA},
        {id = 0, name = 'Based on XIVHotbar by\nSirEdeonX', icon = 'images/credit_avatars/edeon.png', data = NO_DATA},
        {id = 0, name = 'Skillchain library\nIvaar', icon = 'images/credit_avatars/ivaar.png', data = NO_DATA},
        {id = 0, name = 'MountRoulette library\nXurion', icon = 'images/credit_avatars/xurion.png', data = NO_DATA},
        {id = 0, name = 'IconExtractor library\nRubenator', icon = 'images/credit_avatars/rubenator.png', data = NO_DATA},
        {id = 0, name = 'Beta Testing\nJinxs', icon = 'images/credit_avatars/jinxs.png', data = NO_DATA},
        {id = 0, name = 'Beta Testing\nMartel', icon = 'images/credit_avatars/martel.png', data = NO_DATA},
    }

    -- The main menu's saved selection remains available for Go Back, but
    -- this shorter responsive list always starts on its own first page.
    self.selector:set_page(1)
    self.selector:display_options(credits)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:is_moving_crossbars()
    return not self.is_hidden and self.state == states.MOVE_CROSSBARS
end

function action_binder:display_crossbar_mover()
    self.title:text('Move Crossbars')
    self.title:show()
    local help = self:create_text('Move with the D-pad, or click and drag.', self.base_x + self.width/2 - 155, self.base_y + self.height/2)
    self.hints:append(help)
    self:show_control_hints('Confirm', 'Go Back')
end

function get_spells_for_job(job_id, job_level, magic_type)
    local known_spell_ids = T(windower.ffxi.get_spells()):filter(boolean._true):keyset()
    local all_spells = res.spells:type(magic_type)
    local job_spells = T{}

    for id, spell in pairs(all_spells) do
        local is_known = known_spell_ids[id] ~= nil
        local job_can_know = spell.levels[job_id] ~= nil
        if (job_can_know and is_known and spell.levels[job_id] <= job_level and spell.type == magic_type) then
            job_spells[id] = id
        end
    end

    return job_spells:keyset()
end

function get_bst_pet_commands(job_id, job_level)
    local commands = L{
        {name = 'Fight', id = 69, level = 1},
        {name = 'Heel', id = 70, level = 10},
        {name = 'Stay', id = 73, level = 15},
        {name = 'Sic', id = 72, level = 25},
        {name = 'Leave', id = 71, level = 35},
        {name = 'Snarl', id = 225, level = 45},
        {name = 'Spur', id = 281, level = 83},
        {name = 'Run Wild', id = 282, level = 93}
    }

    command_list = L{}

    if (job_id == 9) then
        for i, command in ipairs(commands) do
            if (job_level >= command.level) then
                local crossbar_command = crossbar_abilities[kebab_casify(command.name)]
                local target_type = res.job_abilities[command.id].targets
                local icon_path = 'ui/red-x.png'
                local icon_offset = 0
                local icon_overridden = true
                if (crossbar_command ~= nil) then
                    icon_path, icon_overridden = maybe_get_custom_icon(crossbar_command.default_icon, crossbar_command.custom_icon)
                    if (icon_overridden) then
                        icon_offset = 0
                    else
                        icon_offset = 4
                    end
                end
                command_list:append({id = command.id, name = command.name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
            end
        end
    end

    return command_list
end

function get_smn_pet_commands(job_id, job_level)
    local commands = L{
        {name = 'Assault', id=88, level = 1},
        {name = 'Retreat', id=89, level = 1},
        {name = 'Release', id=90, level = 1},
        {name = 'Avatar\'s Favor', id=250, level = 55}
    }

    command_list = L{}

    if (job_id == 15) then
        for i, command in ipairs(commands) do
            if (job_level >= command.level) then
                local crossbar_command = crossbar_abilities[kebab_casify(command.name)]
                local target_type = res.job_abilities[command.id].targets
                local icon_path = 'ui/red-x.png'
                local icon_offset = 0
                local icon_overridden = true
                if (crossbar_command ~= nil) then
                    icon_path, icon_overridden = maybe_get_custom_icon(crossbar_command.default_icon, crossbar_command.custom_icon)
                    if (icon_overridden) then
                        icon_offset = 0
                    else
                        icon_offset = 4
                    end
                end
                command_list:append({id = command.id, name = command.name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
            end
        end
    end

    return command_list
end

function get_pup_pet_commands(job_id, job_level)
    local commands = L{
        {name = 'Deploy', id = 138, level = 1},
        {name = 'Deactivate', id = 139, level = 1},
        {name = 'Retrieve', id = 140, level = 10},
        {name = 'Fire Maneuver', id = 141, level = 1},
        {name = 'Ice Maneuver', id = 142, level = 1},
        {name = 'Wind Maneuver', id = 143, level = 1},
        {name = 'Earth Maneuver', id = 144, level = 1},
        {name = 'Thunder Maneuver', id = 145, level = 1},
        {name = 'Water Maneuver', id = 146, level = 1},
        {name = 'Light Maneuver', id = 147, level = 1},
        {name = 'Dark Maneuver', id = 148, level = 1}
    }

    command_list = L{}

    if (job_id == 18) then
        for i, command in ipairs(commands) do
            if (job_level >= command.level) then
                local crossbar_command = crossbar_abilities[kebab_casify(command.name)]
                local target_type = res.job_abilities[command.id].targets
                local icon_path = 'ui/red-x.png'
                local icon_offset = 0
                local icon_overridden = true
                if (crossbar_command ~= nil) then
                    icon_path, icon_overridden = maybe_get_custom_icon(crossbar_command.default_icon, crossbar_command.custom_icon)
                    if (icon_overridden) then
                        icon_offset = 0
                    else
                        icon_offset = 4
                    end
                end
                command_list:append({id = command.id, name = command.name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
            end
        end
    end

    return command_list
end

function get_drg_pet_commands(job_id, job_level)
    local commands = L{
        {name = 'Dismiss', id = 87, level = 1},
        {name = 'Restoring Breath', id = 319, level = 90},
        {name = 'Smiting Breath', id = 318, level = 90},
        {name = 'Steady Wing', id = 295, level = 95}
    }

    command_list = L{}

    if (job_id == 14) then
        for i, command in ipairs(commands) do
            if (job_level >= command.level) then
                local crossbar_command = crossbar_abilities[kebab_casify(command.name)]
                local target_type = res.job_abilities[command.id].targets
                local icon_path = 'ui/red-x.png'
                local icon_offset = 0
                local icon_overridden = true
                if (crossbar_command ~= nil) then
                    icon_path, icon_overridden = maybe_get_custom_icon(crossbar_command.default_icon, crossbar_command.custom_icon)
                    if (icon_overridden) then
                        icon_offset = 0
                    else
                        icon_offset = 4
                    end
                end
                command_list:append({id = command.id, name = command.name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
            end
        end
    end

    return command_list
end

function get_stratagems(job_id, job_level)
    local grimoire_white = get_icon_pathbase() .. '/abilities/book_white.png'
    local grimoire_black = get_icon_pathbase() .. '/abilities/book_black.png'

    local stratagems = L{
        {name = 'Penury', id = 215, level = 10, icon = grimoire_white},
        {name = 'Celerity', id = 216, level = 25, icon = grimoire_white},
        {name = 'Addendum: White', id = 234, level = 10, icon = grimoire_white},
        {name = 'Accession', id = 218, level = 40, icon = grimoire_white},
        {name = 'Rapture', id = 217, level = 55, icon = grimoire_white},
        {name = 'Altruism', id = 240, level = 75, icon = grimoire_white},
        {name = 'Tranquility', id = 242, level = 75, icon = grimoire_white},
        {name = 'Perpetuance', id = 316, level = 87, icon = grimoire_white},
        {name = 'Parsimony', id = 219, level = 10, icon = grimoire_black},
        {name = 'Alacrity', id = 220, level = 25, icon = grimoire_black},
        {name = 'Addendum: Black', id = 235, level = 30, icon = grimoire_black},
        {name = 'Manifestation', id = 222, level = 40, icon = grimoire_black},
        {name = 'Ebullience', id = 221, level = 55, icon = grimoire_black},
        {name = 'Focalization', id = 241, level = 75, icon = grimoire_black},
        {name = 'Equanimity', id = 243, level = 75, icon = grimoire_black},
        {name = 'Immanence', id = 317, level = 87, icon = grimoire_black},
    }

    stratagem_list = L{}

    if (job_id == 20) then
        for i, stratagem in ipairs(stratagems) do
            if (job_level >= stratagem.level) then
                local target_type = res.job_abilities[stratagem.id].targets
                local crossbar_stratagem = crossbar_abilities[kebab_casify(stratagem.name)]
                local icon_path = maybe_get_custom_icon(crossbar_stratagem.default_icon, crossbar_stratagem.custom_icon)
                stratagem_list:append({id = stratagem.id, name = stratagem.name, icon = icon_path, data = {target_type = target_type}})
            end
        end
    end

    return stratagem_list
end

function get_dances(job_id, job_level)
    local dances = L{
        {name = 'Drain Samba', id = 184, level = 5},
        {name = 'Drain Samba II', id = 185, level = 35},
        {name = 'Drain Samba III', id = 186, level = 65},
        {name = 'Aspir Samba', id = 187, level = 25},
        {name = 'Aspir Samba II', id = 188, level = 60},
        {name = 'Haste Samba', id = 189, level = 45},
        {name = 'Healing Waltz', id = 194, level = 35},
        {name = 'Curing Waltz', id = 190, level = 15},
        {name = 'Curing Waltz II', id = 191, level = 30},
        {name = 'Curing Waltz III', id = 192, level = 45},
        {name = 'Curing Waltz IV', id = 193, level = 70},
        {name = 'Curing Waltz V', id = 311, level = 87},
        {name = 'Divine Waltz', id = 195, level = 25},
        {name = 'Divine Waltz II', id = 262, level = 78},
        {name = 'Spectral Jig', id = 196, level = 25},
        {name = 'Chocobo Jig', id = 197, level = 55},
        {name = 'Chocobo Jig II', id = 381, level = 70},
        {name = 'Quickstep', id = 201, level = 20},
        {name = 'Box Step', id = 202, level = 30},
        {name = 'Stutter Step', id = 203, level = 40},
        {name = 'Feather Step', id = 312, level = 83},
        {name = 'Animated Flourish', id = 204, level = 20},
        {name = 'Desperate Flourish', id = 205, level = 30},
        {name = 'Violent Flourish', id = 207, level = 45},
        {name = 'Reverse Flourish', id = 206, level = 40},
        {name = 'Building Flourish', id = 208, level = 50},
        {name = 'Wild Flourish', id = 209, level = 60},
        {name = 'Climactic Flourish', id = 264, level = 80},
        {name = 'Striking Flourish', id = 313, level = 89},
        {name = 'Ternary Flourish', id = 314, level = 93}
    }

    dance_list = L{}

    if (job_id == 19) then
        for i, dance in ipairs(dances) do
            if (job_level >= dance.level) then
                local crossbar_dance = crossbar_abilities[kebab_casify(dance.name)]
                local target_type = res.job_abilities[dance.id].targets
                local icon_path = 'ui/red-x.png'
                local icon_offset = 0
                local icon_overridden = true
                if (crossbar_dance ~= nil) then
                    icon_path, icon_overridden = maybe_get_custom_icon(crossbar_dance.default_icon, crossbar_dance.custom_icon)
                    if (icon_overridden) then
                        icon_offset = 0
                    else
                        icon_offset = 4
                    end
                end
                dance_list:append({id = dance.id, name = dance.name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
            end
        end
    end

    return dance_list
end

function get_wards(job_id, job_level)
    local wards = L{
        {name = 'Vallation', id = 366, level = 10},
        {name = 'Pflug', id = 369, level = 40},
        {name = 'Valiance', id = 371, level = 50},
        {name = 'Battuta', id = 376, level = 75},
        {name = 'Liement', id = 373, level = 85}
    }

    ward_list = L{}

    if (job_id == 22) then
        for i, ward in ipairs(wards) do
            if (job_level >= ward.level) then
                local crossbar_ward = crossbar_abilities[kebab_casify(ward.name)]
                local target_type = res.job_abilities[ward.id].targets
                local icon_path = 'ui/red-x.png'
                local icon_offset = 0
                local icon_overridden = true
                if (crossbar_ward ~= nil) then
                    icon_path, icon_overridden = maybe_get_custom_icon(crossbar_ward.default_icon, crossbar_ward.custom_icon)
                    if (icon_overridden) then
                        icon_offset = 0
                    else
                        icon_offset = 4
                    end
                end
                ward_list:append({id = ward.id, name = ward.name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
            end
        end
    end

    return ward_list
end

function get_effusions(job_id, job_level)
    local effusions = L{
        {name = 'Swipe', id = 344, level = 25},
        {name = 'Lunge', id = 368, level = 25},
        {name = 'Gambit', id = 372, level = 70},
        {name = 'Rayke', id = 375, level = 75}
    }

    effusion_list = L{}

    if (job_id == 22) then
        for i, effusion in ipairs(effusions) do
            if (job_level >= effusion.level) then
                local crossbar_effusion = crossbar_abilities[kebab_casify(effusion.name)]
                local target_type = res.job_abilities[effusion.id].targets
                local icon_path = 'ui/red-x.png'
                local icon_offset = 0
                local icon_overridden = true
                if (crossbar_effusion ~= nil) then
                    icon_path, icon_overridden = maybe_get_custom_icon(crossbar_effusion.default_icon, crossbar_effusion.custom_icon)
                    if (icon_overridden) then
                        icon_offset = 0
                    else
                        icon_offset = 4
                    end
                end
                effusion_list:append({id = effusion.id, name = effusion.name, icon = icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
            end
        end
    end

    return effusion_list
end

-- TODO: Do we really need FAKE_ID? The same is used for every mount, so that's not really useful
-- Find a better solution.
-- TODO: Check if this still works after the rewrite
function get_mounts()
    local allowed_mounts = mount_roulette:get_allowed_mounts()
    local FAKE_ID = 0
    mount_list = L{}

    -- Set up the mount list
    local target_type = {['None'] = true}
    for i, mount_name in ipairs(allowed_mounts) do
        local default_icon = 'images/' .. get_icon_pathbase() .. '/mount.png'
        local custom_icon = 'mounts/' .. kebab_casify(mount_name) .. '.png'
        local icon_path = maybe_get_custom_icon(default_icon, custom_icon)
        mount_list:append({id = FAKE_ID, name = string.capitalize(mount_name), icon = icon_path, data = {target_type = target_type}})
    end

    mount_list:sort(sortByName)

    -- Add the mount roulette option
    local default_icon = 'images/' .. get_icon_pathbase() .. '/mount.png'
    local custom_icon = 'mounts/mount-roulette.png'
    local icon_path = maybe_get_custom_icon(default_icon, custom_icon)
    mount_list:append({id = FAKE_ID, name = "Mount Roulette", icon = icon_path, data = {target_type = target_type}})

    return mount_list
end

function get_party_names(include_self)
    local player_name = windower.ffxi.get_player().name
    local party = windower.ffxi.get_party()

    icon_path = get_icon_pathbase() .. '/party-member.png'

    local party_names = L{}

    for key, person in pairs(party) do
        if (person ~= nil and type(person) ~= 'number') then
            if (include_self or person.name ~= player_name) then
                party_names:append({id = FAKE_ID, name = person.name, icon = icon_path, data = NO_DATA})
            end
        end
    end

    return party_names
end

local INVENTORY_BAG = 0
local TEMP_ITEMS_BAG = 3

function get_items(category)
    local inventory = windower.ffxi.get_items(INVENTORY_BAG)
    local temp_items = windower.ffxi.get_items(TEMP_ITEMS_BAG)

    if (inventory) then
        local all_items = L{}
        local already_included_ids = {}

        append_items(all_items, already_included_ids, category, temp_items)
        append_items(all_items, already_included_ids, category, inventory)

        all_items:sort(sortByName)

        return all_items
    else
        return L{}
    end
end

function append_items(items_list, already_included_ids, category, inventory)
    local ignore_indices = {max = true, count = true, enabled = true}
    local usable_icon_path = 'images/' .. get_icon_pathbase() .. '/usable-item.png'
    local tradable_icon_path = 'images/' .. get_icon_pathbase() .. '/item.png'

    for i, inv_item in pairs(inventory or {}) do
        if ((not ignore_indices[i]) and type(inv_item) == 'table' and inv_item.id ~= 0) then
            local item = res.items[inv_item.id]
            if (item and not already_included_ids[item.id]) then
                already_included_ids[item.id] = true
                local custom_icon = 'items/' .. kebab_casify(item.en) .. '.png'
                local icon_path = maybe_get_custom_icon(nil, custom_icon)
                local is_32_by_32 = false
                if (icon_path == nil) then
                    icon_path = item_icons.resolve(inv_item.id)
                    is_32_by_32 = icon_path ~= nil
                end
                local target_type = nil

                local is_usable = item.category == 'Usable' and category == 'Usable'
                local is_tradable = item.category == 'General' and category == 'General'
                if (is_usable) then
                    target_type = item.targets
                    if (icon_path == nil) then
                        icon_path = usable_icon_path
                    end
                elseif (is_tradable) then
                    target_type = {NPC = true}
                    if (icon_path == nil) then
                        icon_path = tradable_icon_path
                    end
                end
                local offset = 0
                if (is_32_by_32) then
                    offset = 4
                end

                if (is_usable or is_tradable) then
                    items_list:append({id = item.id, name = item.en, icon = icon_path, icon_offset = offset, data = {target_type = target_type}})
                end
            end
        end
    end
end

function get_usable_items()
    return get_items('Usable')
end

function get_tradable_items()
    return get_items('General')
end

function get_icons() -- Used for EXECUTE_COMMAND action type
	local lognotice = false
	local command_list = L{}
	
	local txt_file = file.new('images/' .. get_icon_pathbase() .. '/icon_list.txt')
	if txt_file:exists() then
		local FAKE_ID = 0
		local icon_offset = 0
		local target_type = {['None'] = true}
		
		local icon_list = txt_file:readlines()
		for key,line in pairs(icon_list) do
			if not tonumber(line) and line ~= nil and line ~= '' and not line:contains('home-point') and not line:contains('survival-guide') then
				local icon_name = tostring(line):gsub('\r$', ''):gsub('%.[pP][nN][gG]$',''):gsub('\\','/')
				local icon_path = get_icon_pathbase()..'/'..icon_name..'.png'
				local icon_file = require('ui/assets').exists('images/'..icon_path)
				if icon_file then
					command_list:append({id = FAKE_ID, name = icon_name, icon = 'images/' .. icon_path, icon_offset = icon_offset, data = {target_type = target_type}})
				else
					lognotice = true
				end
			end
		end
	else
		error('FILE NOT FOUND "icon_list.txt". Please run "images/'..get_icon_pathbase()..'/GENERATE_ICON_LIST.bat"')
	end
	
	if lognotice then
		warning('Some icons not found. Resolve by running "images/'..get_icon_pathbase()..'/GENERATE_ICON_LIST.bat"')
	end
	
	command_list:sort(sortByName)
	
	return command_list
end

function get_warp_zones()
    local commands = L{}
    local all = action_binder.theme_options.enable_superwarp_all and ' all' or ''
    for _, entry in pairs(res.zones) do
        if entry and entry.en ~= 'unknown' then
            for _, transport in ipairs({'hp', 'sg'}) do
                if sw_zones[transport][entry.en] then
                    local icon = transport == 'hp' and 'home-point' or 'survival-guide'
                    commands:append({id = 0, name = entry.en,
                        icon = 'images/' .. get_icon_pathbase() .. '/' .. icon .. '.png',
                        data = {target_type = {['None'] = true}, alias = entry.en,
                            command = 'sw ' .. transport .. all .. ' ' .. entry.en,
                            icon_path = icon}})
                end
            end
        end
    end
    commands:sort(sortByName)
    return commands
end

function fix_target_types(id, magic_type, targets)
    local needs_player_target_added = {
        [14] = true, -- POISONA
        [15] = true, -- PARALYNA
        [16] = true, -- BLINDNA
        [17] = true, -- SILENA
        [18] = true, -- STONA
        [19] = true, -- VIRUNA
        [20] = true, -- CURSNA
        [57] = true, -- HASTE
        [51] = true  -- HASTE_II
    }

    if (needs_player_target_added[id]) then
        targets['Player'] = true
    end

    local need_to_account_for_pianissimo = magic_type == 'BardSong' and targets['Self']
    if (need_to_account_for_pianissimo) then
        targets['Player'] = true
        targets['Party'] = true
    end

    return targets
end

local click_row = nil
local click_col = nil

windower.register_event('prerender', function() caption_layout:update() end)

windower.register_event('mouse', function(type, x, y, delta, blocked)
    if blocked then
        return
    end

    if (action_binder.selector and action_binder.selector.is_showing) then
        -- Mouse left click
        if type == 1 then
            local row, col = action_binder.selector:get_row_col_from_pos(x, y)
            if (action_binder.selector:is_valid_row_col(row, col)) then
                click_row = row
                click_col = col
                return true
            end
        -- Mouse left release
        elseif type == 2 then
            local row, col = action_binder.selector:get_row_col_from_pos(x, y)
            if (row == click_row and col == click_col) then
                action_binder:submit_selected_option()
                return true
            end
        end
    end
end)

function action_binder:reload()
    if (self.update_offsets ~= nil) then
		self.update_offsets(settings.Style.OffsetX, settings.Style.OffsetY)
	end
end

-- HELPER FUNCTIONS
function sortByName(a, b)
    return a.name < b.name
end

return action_binder
