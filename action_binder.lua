local config = require('libs/settings_config')
local shoulders = require('shoulder_banks')
local chat_format = require('libs/chat_status')
local ui_resources = require('ui/resources')
require("lists")
require("strings")
require("tables")

local mount_roulette = require('libs/mountroulette/mountroulette')
local item_icons = require('ui/item_icons')
local kebab_casify = require('libs/kebab_casify')
local crossbar_abilities = require('resources/crossbar_abilities')
local crossbar_spells = require('resources/crossbar_spells')
local player_data = require('player')
texts = require('texts')
local defaults = require('defaults')
settings = config.load(defaults)
local action_binder = {}
local review = require('custom_action_review')
local caption_layout = require('ui/text_layout').new()
local theme = require('theme')
local theme_options = theme.apply(settings)
local icon_pack = nil
local sw_zones = require('sw_zones')

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
    return 'icons/iconpacks/' .. icon_pack
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
    local icon_file = file.new(icon_path)

    if (icon_file:exists()) then
        return icon_path, true
    else
        -- TODO: Remove the redundancy
        -- TODO: Check if the fallback actually works if only e.g. curing-waltz.png is available,
        -- but not curing-waltz-iii
        -- TODO: Also check if the fallback maybe is already implemented elsewhere to avoid doing a redundant fallback check
        if category == "spell" then
            local fallback_icon_path = get_base_spell_for_higher_level_spells(icon_path)
            local fallback_icon_file = file.new(fallback_icon_path)
            
            if (fallback_icon_file:exists()) then
                return fallback_icon_path, true
            else
                return default_icon, false
            end
        elseif category~= nil and string.contains(category, "blood_pact") and element ~= nil then
            local fallback_found, fallback_icon_path = get_spirit_by_element(icon_path, element)
            
            if not fallback_found then
                return default_icon, false
            end
            
            local fallback_icon_file = file.new(fallback_icon_path)
            
            if (fallback_icon_file:exists()) then
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
    ['DELETE_SET'] = 22,
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
    -- A: 2026-11-16 edit-mode main menu entries.
    ['DELETE_SET'] = 46,
    ['UNDO'] = 47,
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

-- Curation for the Trust binder only. Names use the same key normalization as
-- custom portrait filenames. Role groups are presentation, not gameplay logic.
-- 1 passive/non-interactive; 2 healer; 3 tank; 4 support;
-- 5 offensive caster; 6 ranged attacker; 7 melee/fallback attacker.
local TRUST_ROLE_PRIORITY = {
    -- Passive auras: cannot be attacked or targeted.
    ['brygid']=1, ['cornelia']=1, ['kupofried']=1,
    ['kuyin-hathdenna']=1, ['moogle']=1, ['sakura']=1, ['star-sibyl']=1,
    -- Healing is the defining role, including non-spell healers.
    ['apururu-uc']=2, ['cherukiki']=2, ['ferreous-coffin']=2,
    ['karaha-baruha']=2, ['kupipi']=2, ['mihli-aliapoh']=2,
    ['monberaux']=2, ['nashmeira-ii']=2, ['pieuje-uc']=2,
    ['ygnas']=2, ['yoran-oran-uc']=2,
    -- Tanks, including ninja/rune tanking and the Ark Angel tanks.
    ['aaev']=3, ['aahm']=3, ['amchuchu']=3, ['august']=3,
    ['curilla']=3, ['gessho']=3, ['halver']=3,
    ['invincible-shield-uc']=3, ['mnejing']=3, ['rahal']=3,
    ['rughadjeen']=3, ['trion']=3, ['valaineral']=3,
    -- Active enhancement, debuffs, songs, rolls, and party utility.
    ['abquhbah']=4, ['arciela']=4, ['arciela-ii']=4,
    ['joachim']=4, ['king-of-hearts']=4, ['koru-moru']=4,
    ['luzaf']=4, ['nashmeira']=4, ['qultada']=4,
    ['selhteus']=4, ['sylvie-uc']=4, ['uka-totlihn']=4,
    ['ulmia']=4,
    -- Primarily offensive spellcasters.
    ['adelheid']=5, ['ajido-marujido']=5, ['aatt']=5,
    ['d-shantotto']=5, ['gadalar']=5, ['ingrid']=5,
    ['ingrid-ii']=5, ['kayeel-payeel']=5, ['kukki-chebukki']=5,
    ['leonoyne']=5, ['mumor-ii']=5, ['ovjang']=5,
    ['robel-akbel']=5, ['rosulatia']=5, ['shantotto']=5,
    ['shantotto-ii']=5, ['teodor']=5, ['ullegore']=5,
    -- Ranged physical attackers (not magic casters).
    ['elivira']=6, ['makki-chebukki']=6, ['margret']=6,
    ['najelith']=6, ['semih-lafihna']=6, ['tenzen-ii']=6,
    -- Other Trusts fall into the final attacker/unclassified group.
}

local function sortTrusts(a, b)
    -- Custom portrait availability is checked against the active icon pack.
    -- This makes the user's remaining default-pack portraits appear first.
    if a.custom_portrait ~= b.custom_portrait then
        return a.custom_portrait == true
    end
    local a_role = TRUST_ROLE_PRIORITY[kebab_casify(a.name)] or 7
    local b_role = TRUST_ROLE_PRIORITY[kebab_casify(b.name)] or 7
    if a_role ~= b_role then return a_role < b_role end
    return a.id < b.id
end

function action_binder:setup(buttonmapping, save_binding_func, delete_binding_func, theme_options, get_crossbar_sets_func, base_x, base_y, max_width, max_height,
change_slot_icon_func, save_global_icon_func, save_custom_action_func, update_custom_action_func, delete_custom_action_func, create_new_set_func)
    ui_resources.clear(self.images); ui_resources.clear(self.hints)
    if self.title then self.title:destroy() end
    -- A single centered panel owns the background, title and selector. Style
    -- offsets move the crossbar only; applying them here displaced the backdrop.
    local screen = windower.get_windower_settings()
    base_x, base_y, max_width, max_height = require('menu_layout').fit(screen.ui_x_res, screen.ui_y_res)
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
    self.title = self:create_text('XIV Crossbar', base_x + 50, base_y + 30)
    self.title:size(18)
    self.title:pad(5)
    self.title:bg_color(15, 17, 24)
    self.title:bg_alpha(215)
    self.title:bg_visible(true)
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
    self.binding_preview_icon = nil
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
    self.binding_preview_icon = nil
    self.icon_picker_return = nil
    self.action_linked_action = nil
    self.action_linked_type = nil
    self.action_alias = nil
    self.superwarp_folder = nil
    self.superwarp_parent_selection = nil
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
    self.custom_action_delete_from_review = false
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
    self.shoulder_crossbar = nil
    self.trigger_left_pressed = false
    self.trigger_left_doublepressed = false
    self.trigger_right_pressed = false
    self.trigger_right_doublepressed = false
end

function action_binder:clear_controller_input()
    self.held_navigation = nil
    self:reset_gamepad()
    if self:is_binding_combo() then self.active_crossbar = nil end
    close_left_doublepress_window()
    close_right_doublepress_window()
    -- Cancel a pending turn without treating focus changes as button presses.
    self.page_gesture = nil
    if self.selector then self.selector:page_highlight(nil) end
end

-- A: The Options/set chooser shares the saved physical button mapping.
-- The root router already calls this helper; missing it crashed cancel input.
function action_binder:is_cancel_button(button)
    local layouts={
        gamecube={a='a',b='b',x='x',y='y'},
        playstation={a='cross',b='square',x='circle',y='triangle'},
        xbox={a='a',b='x',x='b',y='y'},
        nintendo={a='b',b='y',x='a',y='x'},
    }
    local buttons=layouts[self.button_layout]
    return buttons~=nil and buttons[button]~=nil and buttons[button]==self.cancel_button
end

function action_binder:create_text(caption, x, y)
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

function action_binder:set_ui_offset_callback(update_offsets)
    self.update_offsets = update_offsets
end

function action_binder:update_active_crossbar(left_trigger_just_pressed, right_trigger_just_pressed)
    if (self.trigger_left_pressed and self.trigger_right_pressed) then
        if (self.theme_options.hotbar_number == 4 or self.theme_options.hotbar_number == 6) then
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
        self.active_crossbar = self.shoulder_crossbar
    end
end

function action_binder:dpad_left(pressed)
    if self:menu_input('left',pressed) then return end
    if self.capturing_text then return end
    if self:edit_slot_press(1, pressed) then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_left_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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
    if self:menu_input('right',pressed) then return end
    if self.capturing_text then return end
    if self:edit_slot_press(3, pressed) then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_right_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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
    if self:menu_input('down',pressed) then return end
    if self.capturing_text then return end
    if self:edit_slot_press(2, pressed) then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_down_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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
    if self:menu_input('up',pressed) then return end
    if self.capturing_text then return end
    if self:edit_slot_press(4, pressed) then return end
    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.dpad_up_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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
    if self:menu_input('a',pressed) then return end
    if self:edit_slot_press(6, pressed) then return end
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.active_crossbar and (self.button_layout == 'gamecube' and self.cancel_button == 'a' or
            self.button_layout == 'playstation' and self.cancel_button == 'cross' or
            self.button_layout == 'xbox' and self.cancel_button == 'a' or
            self.button_layout == 'nintendo' and self.cancel_button == 'b') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_a_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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
    if self:menu_input('b',pressed) then return end
    if self:edit_slot_press(5, pressed) then return end
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.active_crossbar and (self.button_layout == 'gamecube' and self.cancel_button == 'b' or
            self.button_layout == 'playstation' and self.cancel_button == 'square' or
            self.button_layout == 'xbox' and self.cancel_button == 'x' or
            self.button_layout == 'nintendo' and self.cancel_button == 'y') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_b_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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
    if self:menu_input('x',pressed) then return end
    if self:edit_slot_press(7, pressed) then return end
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.active_crossbar and (self.button_layout == 'gamecube' and self.cancel_button == 'x' or
            self.button_layout == 'playstation' and self.cancel_button == 'circle' or
            self.button_layout == 'xbox' and self.cancel_button == 'b' or
            self.button_layout == 'nintendo' and self.cancel_button == 'a') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_x_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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
    if self:menu_input('y',pressed) then return end
    if self:edit_slot_press(8, pressed) then return end
    if self.state == states.SELECT_BUTTON_ASSIGNMENT and pressed and not self.active_crossbar and (self.button_layout == 'gamecube' and self.cancel_button == 'y' or
            self.button_layout == 'playstation' and self.cancel_button == 'triangle' or
            self.button_layout == 'xbox' and self.cancel_button == 'y' or
            self.button_layout == 'nintendo' and self.cancel_button == 'x') then self:go_back(); return end

    if (self.state == states.SELECT_BUTTON_ASSIGNMENT) then
        self:reset_gamepad_dpad()
        self:reset_gamepad_face_buttons()
        self.button_y_pressed = pressed
        if (pressed and (self.active_crossbar)) then
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

function action_binder:is_binding_combo()
    return not self.is_hidden and not self.chooser_active and self.state == states.SELECT_BUTTON_ASSIGNMENT
end

function action_binder:set_shoulder_combo(bar)
    if self:is_edit_mode() then
        -- Edit mode: L1 / R1 / L1+R1 held picks the shoulder bank (7/8/9).
        self.shoulder_crossbar = bar
        return
    end
    if self:is_binding_combo() then
        self.shoulder_crossbar = bar
        self:update_active_crossbar(false, false)
        self:show_pressed_buttons()
    end
end

function action_binder:get_binding_preview_bank()
    if not self.is_hidden and not self.chooser_active
        and (self.state == states.SELECT_BUTTON_ASSIGNMENT or self.state == states.CONFIRM_BUTTON_ASSIGNMENT) then
        return self.active_crossbar
    end
    -- Edit mode: holding a trigger in any other menu screen shows that bank,
    -- exactly as it would outside the menu.
    if self:is_edit_mode() then return self:edit_bank() end
end

-- ---------------------------------------------------------------------------
-- A: Edit mode, step 1 (2026-11-16). While the XIV Crossbar menu is open the
-- crossbar chooses WHERE and the menu chooses WHAT. Holding a crossbar
-- trigger and pressing a slot button selects that slot as the destination.
-- Nothing is bound differently yet: this step only selects, shows and clears
-- the destination. The legacy Bind-to-Slot screens are left untouched.
-- The destination is a position (bank + slot), not a binding, so it survives
-- set switches; it is cleared only when the menu closes (clear_destination).
-- ---------------------------------------------------------------------------
function action_binder:is_edit_mode()
    return not self.is_hidden and not self.chooser_active and not self.capturing_text
        and self.state ~= states.HIDDEN
        and self.state ~= states.SELECT_BUTTON_ASSIGNMENT
        and self.state ~= states.CONFIRM_BUTTON_ASSIGNMENT
        and (states.MOVE_CROSSBARS == nil or self.state ~= states.MOVE_CROSSBARS)
end

-- Set chooser carry-over: the destination is a position, so it simply stays
-- selected while sets change. Slot presses are off while the chooser has the
-- controller, but the amber slot and the footer stay up and follow the set.
function action_binder:is_choosing_set_in_edit_mode()
    return not self.is_hidden and self.chooser_active == true
        and self.state ~= states.HIDDEN
        and self.state ~= states.SELECT_BUTTON_ASSIGNMENT
        and self.state ~= states.CONFIRM_BUTTON_ASSIGNMENT
end

-- Bank under the held trigger(s). L2+R2 follows the normal rule: the trigger
-- pressed second decides bank 3 or 4 when four or six banks exist.
-- Not yet supported here: double-tap banks (5/6) and L1/R1 shoulder banks.
function action_binder:edit_bank()
    local bars = self.theme_options and self.theme_options.hotbar_number or 2
    if self.trigger_left_pressed and self.trigger_right_pressed then
        if bars == 4 or bars == 6 then return self.edit_combined_bank or 3 end
        return 3
    end
    -- Double-tap banks follow the play-mode detection in xivcrossbar.lua.
    local left_double, right_double = false, false
    if self.doublepress_provider then left_double, right_double = self.doublepress_provider() end
    if self.trigger_left_pressed then return (left_double and bars >= 5) and 5 or 1
    elseif self.trigger_right_pressed then return (right_double and bars >= 5) and 6 or 2 end
    return self.shoulder_crossbar -- L1 / R1 / L1+R1 shoulder banks, or nil
end

-- Double-tapping a trigger means its first tap already turned a page; the
-- second press, now selecting the double-tap bank, puts that page back.
function action_binder:undo_double_tap_page(side)
    local turn = self.last_page_turn
    self.last_page_turn = nil
    if not turn or turn.side ~= side or turn.state ~= self.state or not self:is_in_selector_state() then return end
    if turn.next_page then self.selector:decrement_page() else self.selector:increment_page() end
end

-- A trigger used in a chord (slot press, set cycling) never turns a page.
function action_binder:consume_trigger_gesture()
    if self.page_gesture then self.page_gesture.used = true end
    self.selector:page_highlight(nil)
end

-- Names the four immediate main-menu entries bind under (see Confirm).
action_binder.main_menu_action_names = {[action_types.CHECK] = 'Check', [action_types.MAP] = 'View Map',
    [action_types.LAST_SYNTH] = 'Last Synth', [action_types.SWITCH_TARGET] = 'Switch Target'}

-- True when the next Confirm press would bind to the selected slot, so the
-- amber selection can step back and let the slot itself read clearly.
local immediate_main_menu = nil
function action_binder:is_bind_ready()
    if not self:is_edit_mode() or not self.destination then return false end
    if self.state == states.SELECT_PLAYER_BINDING then return true end
    if self.state == states.SELECT_ACTION_TARGET then
        local option = self.selector.is_showing and self.selector:get_selected_option()
        local target = option and action_targets[option.id]
        return not self:same_as_bound(self.action_name, target)
    end
    local option = self.selector.is_showing and self.selector:get_selected_option()
    if not option or option.disabled or option.id == 'PREV' or option.id == 'NEXT' then return false end
    if self.state == states.SELECT_ACTION_TYPE then
        immediate_main_menu = immediate_main_menu or {[action_types.CHECK] = true,
            [action_types.SWITCH_TARGET] = true, [action_types.MAP] = true, [action_types.LAST_SYNTH] = true,
            [action_types.DELETE] = true}
        if option.id == action_types.DELETE then return not self:destination_slot_empty() end
        if not immediate_main_menu[option.id] then return false end
        return not self:same_as_bound(action_binder.main_menu_action_names[option.id])
    end
    if self.state == states.SELECT_ICON then
        return self.action_type == action_types.CHANGE_ICON and option.data ~= nil
            and option.data.icon_path ~= nil and not option.data.is_dir
    end
    if self.state ~= states.SELECT_ACTION or self.is_linking_for_custom_action then return false end
    if option.data and (option.data.is_dir or option.data.warp_folder or option.data.menu_entry) then return false end
    if self:target_step(option.data and option.data.target_type) == 'picker' then return false end
    return not self:same_as_bound(option.data and option.data.action_name or option.text)
end


-- The selected slot's own binding in the active set (nil when the slot is
-- empty there; an action only shown from a default set does not count).
function action_binder:destination_record()
    local d = self.destination
    if not d or not player_data.hotbar_settings then return nil end
    local env = shoulders.destination(player_data.hotbar_settings.active_environment, d.bank)
    local bank = player_data.hotbar and shoulders.bar(player_data.hotbar, env, d.bank)
    local record = bank and bank['slot_' .. d.slot]
    if record and record.action ~= nil then return record end
end

-- True while a slot is selected and nothing of this set is bound on it.
function action_binder:destination_slot_empty()
    return self.destination ~= nil and self:destination_record() == nil
end

-- Would Confirm bind what the slot already holds? Then no glow, no ghost and
-- full amber: nothing would change.
function action_binder:same_as_bound(name, target)
    local record = self:destination_record()
    if not record or name == nil then return false end
    if record.action ~= name then return false end
    if target ~= nil and record.target ~= nil and tostring(record.target) ~= tostring(target) then return false end
    return true
end

-- The target step for a chosen action: 'self' and 'none' bind at once,
-- 'picker' shows the target list. Shared by Confirm and is_bind_ready.
function action_binder:target_step(target_type)
    if not target_type then return 'picker' end
    if target_type['Self'] and self.action_type ~= action_types.WEAPONSKILL and
            not (self.theme_options.allow_stpc_for_self_targeted_actions or
            target_type['NPC'] or target_type['Enemy'] or target_type['Party'] or
            target_type['Player'] or target_type['Ally']) then
        return 'self'
    elseif target_type['None'] then
        return 'none'
    end
    return 'picker'
end

-- Returns true when the press (and its release) belongs to edit mode, so the
-- caller must not also navigate the menu.
function action_binder:edit_slot_press(hotkey, pressed)
    if not self:is_edit_mode() then return false end
    local bank = self:edit_bank()
    if not bank then
        -- A release whose press selected a slot stays consumed even if the
        -- trigger was let go first.
        if not pressed and self.edit_consumed and self.edit_consumed[hotkey] then
            self.edit_consumed[hotkey] = nil
            return true
        end
        return false
    end
    -- A trigger held for a slot press never repeats menu navigation.
    self.held_navigation = nil
    self.edit_consumed = self.edit_consumed or {}
    if pressed then
        self.edit_consumed[hotkey] = true
        local d = self.destination
        if d and d.bank == bank and d.slot == hotkey then
            self.destination = nil -- pressing the selected slot again deselects it
        else
            self.destination = {bank = bank, slot = hotkey}
        end
    else
        self.edit_consumed[hotkey] = nil
    end
    return true
end

-- Which flows act straight on the destination: every binding, Clear and
-- Change Icon. Change Action Icon, new sets and the custom action editor's
-- Save & Bind keep their legacy screens for now.
function action_binder:can_bind_to_destination()
    if not self.destination or self.is_hidden or self.chooser_active then return false end
    if self.binding_custom_action_review then return false end
    local t = self.action_type
    if t == action_types.DELETE then return true end
    if t == action_types.CHANGE_ICON then return self.action_icon ~= nil end
    if t == nil or t == action_types.GLOBAL_ICON_SET or t == action_types.CREATE_NEW_SET
        or t == action_types.UNDO or t == action_types.DELETE_SET then
        return false
    end
    return self.action_name ~= nil and self.action_name ~= ''
end

-- Run an edit of one slot through the undo history (xivcrossbar.lua keeps it).
function action_binder:with_undo(bank, slot, label, change)
    if self.undo_wrap then return self.undo_wrap(bank, slot, label, change) end
    return change()
end

-- Act on the destination, flash it together with the confirmed menu row,
-- hold the screen until the flash has played, then return to where the
-- Confirm came from. The destination stays selected. No confirmations.
function action_binder:bind_to_destination()
    if not self:can_bind_to_destination() then return false end
    local d = self.destination
    local t = self.action_type
    self.active_crossbar, self.hotkey = d.bank, d.slot
    local origin = self.submit_origin_state or self.state
    local ok
    if t == action_types.DELETE then
        ok = self:with_undo(d.bank, d.slot, 'Clear', function()
            return self.delete_binding(d.bank, d.slot, prefix_lookup[t], self.action_name, self.action_target)
        end)
    elseif t == action_types.CHANGE_ICON then
        local valid, warning = self:check_slot_bound_in_active_env()
        if not valid then
            chat_format.say(123, '[XIVCrossbar] ' .. (warning or 'Nothing is bound on the selected slot.'))
            ok = false
        else
            ok = self:with_undo(d.bank, d.slot, 'Change Icon', function()
                if self.change_slot_icon == nil then return false end
                return self.change_slot_icon(d.bank, d.slot, self.action_icon)
            end)
        end
    else
        ok = self:with_undo(d.bank, d.slot, self.action_name, function()
            return self.save_binding(d.bank, d.slot, prefix_lookup[t], self.action_name,
                self.action_target, self.action_command, self.action_icon, self.action_linked_action,
                self.action_linked_type, self.action_alias)
        end)
    end
    -- The screen that was confirmed stays up (and in edit mode) during the hold.
    self.state = origin
    self.active_crossbar, self.hotkey = nil, nil
    if ok == false then
        self:return_after_bind(origin)
        return true
    end
    if self.on_bound then self.on_bound(d.bank, d.slot) end
    if t ~= action_types.DELETE and t ~= action_types.CHANGE_ICON then
        self.ghost_suppressed = {asset = self.binding_preview_icon, bank = d.bank, slot = d.slot}
    end
    self:start_bind_hold(function() self:return_after_bind(origin) end)
    return true
end

-- The confirmed row flashes gold/white in step with the slot. Input waits
-- until it finishes (bind_hold_seconds); then the screen changes.
action_binder.bind_hold_seconds = .4
function action_binder:start_bind_hold(after)
    if (self.bind_hold_seconds or 0) <= 0 then return after() end
    self.bind_hold = {after = after, started = self.nav_clock}
    if self.selector.set_flash then self.selector:set_flash(1) end
end

function action_binder:tick_bind_hold(now)
    local hold = self.bind_hold
    if not hold or now == nil then return end
    hold.started = hold.started or now
    local t = (now - hold.started) / self.bind_hold_seconds
    if t >= 1 or self.is_hidden then self:finish_bind_hold()
    elseif self.selector.set_flash then self.selector:set_flash(1 - t) end
end

function action_binder:finish_bind_hold()
    local hold = self.bind_hold
    if not hold then return end
    self.bind_hold = nil
    if self.selector.set_flash then self.selector:set_flash(nil) end
    if not self.is_hidden then hold.after() end
end

function action_binder:return_after_bind(origin)
    self:clear_button_entry_ui()
    self.action_name, self.action_target = nil, nil
    self.selection_states[states.SELECT_ACTION_TARGET] = nil
    local t = self.action_type
    if origin == states.SELECT_ACTION or origin == states.SELECT_ICON then
        -- The same list is still on screen: stay on it, cursor untouched.
        self.state = origin
        self.selection_states[states.SELECT_ACTION] = origin == states.SELECT_ACTION and nil
            or self.selection_states[states.SELECT_ACTION]
        if self.selector.is_showing then self.selector:highlight_selection() end
        return
    end
    local direct = t == action_types.CHECK or t == action_types.SWITCH_TARGET or t == action_types.MAP
        or t == action_types.LAST_SYNTH or t == action_types.ATTACK or t == action_types.RANGED_ATTACK
        or t == action_types.ASSIST or t == action_types.DELETE
    local list = not direct and self.selection_states[states.SELECT_ACTION]
    if list then
        -- From the target picker: back to the action list, same page and cursor.
        self.state = states.SELECT_ACTION
        self.selector:set_page(list.page)
        self:display_action_selector()
        self.selector:import_selection_state(list)
        self.selection_states[states.SELECT_ACTION] = nil
    else
        -- Main-menu actions (Check, View Map, Clear...): back to the main menu,
        -- rebuilt so Undo's count is current.
        self:return_to_action_type_menu()
    end
end

-- Undo: restores the slot the last edit-mode change touched, selects that
-- slot, plays the confirmation and refreshes the main menu.
function action_binder:undo_last_edit()
    local record = self.undo_binding and self.undo_binding()
    self.state = states.SELECT_ACTION_TYPE
    if not record then
        chat_format.say(207, '[XIVCrossbar] Nothing to undo yet.')
        return
    end
    self.destination = {bank = record.bank, slot = record.slot}
    self.ghost_suppressed = nil
    if self.on_bound then self.on_bound(record.bank, record.slot) end
    self:start_bind_hold(function() self:return_to_action_type_menu() end)
end

-- Delete Set: the set list (like Switch). The first Confirm on a set arms it
-- (its name turns red-pink and the title asks again); a second Confirm on the
-- same set deletes it. Moving the cursor disarms. Built-in sets are not listed.
function action_binder:display_delete_set_selector()
    self:set_title(self.delete_set_armed and ('Delete "' .. self.delete_set_armed.name .. '"? Confirm again')
        or 'Delete Set')
    self.title:show()
    local list = L{}
    local icon_path = 'images/' .. get_icon_pathbase() .. '/ui/red-x.png'
    for _, destination in ipairs(self.get_crossbar_sets_binding()) do
        local name = type(destination)=='table' and destination.name or destination
        local key = type(destination)=='table' and destination.key or kebab_casify(destination)
        if not (self.protected_set_keys and self.protected_set_keys[key]) then
            list:append({id = key, name = name, icon = icon_path, icon_offset = 0, data = {set_key = key}})
        end
    end
    self.selector:display_options(list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:submit_delete_set()
    local option = self.selector:submit_selected_option()
    if option.id == 'PREV' then self.selector:decrement_page(); self.delete_set_armed = nil; return
    elseif option.id == 'NEXT' then self.selector:increment_page(); self.delete_set_armed = nil; return end
    local key = option.data and option.data.set_key
    if not key then return end
    local state = self.selector:export_selection_state()
    if self.delete_set_armed and self.delete_set_armed.key == key then
        self.delete_set_armed = nil
        if self.delete_set_binding then self.delete_set_binding(key) end
    else
        self.delete_set_armed = {key = key, name = option.text}
    end
    self:display_delete_set_selector()
    self.selector:import_selection_state(state)
end

-- Ghost preview: the icon of what would be bound if Confirm were pressed now.
-- Action lists: the highlighted entry (not page buttons, folders or disabled
-- entries). Target picker: the action already chosen. Returns an absolute
-- path plus the destination bank and slot, or nil.
function action_binder:get_ghost()
    if not self:is_edit_mode() or not self.destination then return nil end
    local asset, name
    if self.state == states.SELECT_ACTION or self.state == states.SELECT_ACTION_TYPE then
        local option = self.selector.is_showing and self.selector:get_selected_option()
        if not option or option.disabled or option.id == 'PREV' or option.id == 'NEXT'
            or (option.data and (option.data.is_dir or option.data.menu_entry)) then return nil end
        if self.state == states.SELECT_ACTION_TYPE then
            if option.id == action_types.DELETE then
                -- Clear Slot: a red X breathes over a bound slot, nothing over an empty one.
                if not self:is_bind_ready() then return nil end
                asset = 'images/' .. get_icon_pathbase() .. '/ui/red-x.png'
            elseif not self:is_bind_ready() then
                return nil -- only entries that bind at once (Check, View Map...)
            else
                asset = option.asset_path
            end
        else
            asset = option.asset_path
            name = option.data and option.data.action_name or option.text
        end
    elseif self.state == states.SELECT_ACTION_TARGET then
        asset, name = self.binding_preview_icon, self.action_name
    elseif self.state == states.SELECT_ICON and self:is_bind_ready() then
        -- Change Icon: try each icon on the selected slot before choosing.
        asset = self.selector:get_selected_option().asset_path
    end
    if asset == nil or asset == '' then return nil end
    -- Nothing to preview when the slot already holds this action.
    if name and self:same_as_bound(name) then return nil end
    -- Right after a bind the cursor still rests on the action just bound; the
    -- slot already shows it, so no ghost until the cursor or slot changes.
    local d = self.destination
    local bound = self.ghost_suppressed
    if bound and bound.asset == asset and bound.bank == d.bank and bound.slot == d.slot then return nil end
    self.ghost_suppressed = nil
    return windower.addon_path .. asset, d.bank, d.slot
end

function action_binder:get_destination()
    if self.is_hidden or not self.destination then return nil end
    local d = self.destination
    return {bank = d.bank, slot = d.slot, ready = self:is_bind_ready()}
end

function action_binder:clear_destination()
    self.destination = nil
    self.edit_consumed = nil
    self.edit_combined_bank = nil
    self.ghost_suppressed = nil
    self:dispose_destination_footer()
end

function action_binder:dispose_destination_footer()
    if self.destination_footer then ui_resources.clear(self.destination_footer) end
    self.destination_footer = L{}
    self.destination_footer_objects = nil
    self.destination_footer_key = nil
end

local slot_button_icons = {
    [1] = 'dpad_%s_left', [2] = 'dpad_%s_down', [3] = 'dpad_%s_right', [4] = 'dpad_%s_up',
    [5] = 'facebuttons_%s_b', [6] = 'facebuttons_%s_a', [7] = 'facebuttons_%s_x', [8] = 'facebuttons_%s_y',
}

-- Button pictures for a bank + slot, matching the old Bind-to-Slot screen.
function action_binder:destination_icons(bank, slot)
    local layout = self.button_layout
    local left = 'ui/binding_icons/trigger_' .. layout .. '_left.png'
    local right = 'ui/binding_icons/trigger_' .. layout .. '_right.png'
    local icons = L{}
    if bank == 1 then icons:append(left)
    elseif bank == 2 then icons:append(right)
    elseif bank == 3 then
        if self.theme_options.hotbar_number == 4 or self.theme_options.hotbar_number == 6 then
            icons:append(right); icons:append('ui/binding_icons/arrow_right.png'); icons:append(left)
        else icons:append(left); icons:append(right) end
    elseif bank == 4 then
        icons:append(left); icons:append('ui/binding_icons/arrow_right.png'); icons:append(right)
    elseif bank == 5 then icons:append(left); icons:append('ui/binding_icons/x2.png')
    elseif bank == 6 then icons:append(right); icons:append('ui/binding_icons/x2.png')
    -- L1 / R1 shoulder banks: Xbox trigger pictures as placeholders for now.
    elseif bank == 7 then icons:append('ui/binding_icons/trigger_xbox_left.png')
    elseif bank == 8 then icons:append('ui/binding_icons/trigger_xbox_right.png')
    elseif bank == 9 then
        icons:append('ui/binding_icons/trigger_xbox_left.png'); icons:append('ui/binding_icons/trigger_xbox_right.png')
    end
    icons:append('ui/binding_icons/plus.png')
    icons:append('ui/binding_icons/' .. string.format(slot_button_icons[slot], layout) .. '.png')
    return icons
end

-- The name the crossbar's own set label shows (display name, as styled
-- there). xivcrossbar.lua supplies it; the internal key is only a fallback.
function action_binder:footer_set_name()
    local name = self.set_name_provider and self.set_name_provider()
    if name and name ~= '' then return name end
    local key = player_data.hotbar_settings and player_data.hotbar_settings.active_environment
    local bar = key and player_data.hotbar and player_data.hotbar[key]
    return tostring(bar and (bar.name or key) or key or ''):upper()
end

-- Footer objects are created once per menu opening and updated in place, so
-- choosing another slot or set never destroys and recreates them (no flash).
local footer_icon_count = 6
function action_binder:ensure_destination_footer()
    local f = self.destination_footer_objects
    if f and not ui_resources.is_disposed(f.label) then return f end
    f = {icons = {}, paths = {}}
    -- Same look as the crossbar's set name label, fully opaque.
    f.label = ui_resources.text({flags = {draggable = false}})
    f.label:bg_alpha(0); f.label:bg_visible(false)
    f.label:font(self.theme_options.font)
    -- Set-label font, amber text with a black outline, two points larger.
    f.label:size(11 * .94 + 2)
    f.label:bold(true)
    f.label:color(255, 216, 112)
    f.label:stroke_color(0, 0, 0)
    f.label:stroke_width(2)
    f.label:alpha(255); f.label:stroke_alpha(255)
    f.label:text('')
    f.label:hide()
    f.prompt = self:create_text('Choose a crossbar slot to bind to:', 0, 0)
    f.prompt:size(14)
    f.prompt:alpha(170)
    f.prompt:hide()
    for i = 1, footer_icon_count do
        local icon = ui_resources.image({draggable = false})
        icon:fit(false)
        icon:size(32, 32)
        icon:hide()
        f.icons[i] = icon
    end
    self.destination_footer = L{f.label, f.prompt}
    for i = 1, footer_icon_count do self.destination_footer:append(f.icons[i]) end
    self.destination_footer_objects = f
    return f
end

-- Called every rendered frame. Cheap when nothing changed: only the text
-- measurement is polled until it settles.
function action_binder:update_destination_footer()
    -- A: the menu side of edit mode, kept in step every frame (cheap):
    -- Clear Slot is dummied out while the selected slot is empty, and the
    -- highlighted entry glows while Confirm would bind it.
    if self.selector and not self.is_hidden then
        if self.state == states.SELECT_ACTION_TYPE and self.selector.is_showing and self.selector.set_option_disabled then
            local empty = self:destination_slot_empty()
            if empty ~= self.clear_slot_disabled then
                self.clear_slot_disabled = empty
                self.selector:set_option_disabled(action_types.DELETE, empty)
            end
        end
        if self.selector.set_option_glow then
            self.selector:set_option_glow(not self.bind_hold and self:is_bind_ready())
        end
    end
    -- Also visible while the set chooser is open over the menu, at full
    -- strength, so the set name visibly changes as sets are browsed.
    local visible = self:is_edit_mode() or self:is_choosing_set_in_edit_mode()
    local f = self.destination_footer_objects
    if not visible then
        if f and not ui_resources.is_disposed(f.label) and self.destination_footer_key ~= nil then
            f.label:hide(); f.prompt:hide()
            for i = 1, footer_icon_count do f.icons[i]:hide() end
        end
        self.destination_footer_key = nil
        return
    end
    f = self:ensure_destination_footer()
    local d = self.destination
    local name = d and self:footer_set_name() or ''
    local key = d and (name .. '|' .. d.bank .. '|' .. d.slot) or 'none'
    local y = self.base_y + self.height - 50
    local left_edge = self.base_x + 120              -- right of the Exit hint
    local right_edge = self.base_x + self.width - 260 -- left of Confirm
    local center = self.base_x + self.width / 2      -- centred on the menu
    if key ~= self.destination_footer_key then
        self.destination_footer_key = key
        f.width = nil
        if not d then
            f.label:hide()
            for i = 1, footer_icon_count do f.icons[i]:hide() end
            f.prompt:show()
            caption_layout:center(f.prompt, center, y + 10, 2 * math.min(center - left_edge, right_edge - center) + 140)
            return
        end
        f.prompt:hide()
        if f.label:text() ~= name .. ':' then f.label:text(name .. ':') end
        f.label:show()
        local paths = self:destination_icons(d.bank, d.slot)
        f.count = #paths
        for i = 1, footer_icon_count do
            local path = paths[i] and (windower.addon_path .. 'images/' .. get_icon_pathbase() .. '/' .. paths[i])
            if path then
                if f.paths[i] ~= path then f.icons[i]:path(path); f.paths[i] = path end
                f.icons[i]:show()
            else
                f.icons[i]:hide()
            end
        end
    end
    if not d then return end
    -- Position the group once the label's width is known; until then the
    -- label is held transparent by the text resource, then released.
    local width = f.label:measure_width()
    if width == nil then return end
    if width ~= f.width then
        f.width = width
        local gap, icon_size = 6, 32
        local total = width + gap + f.count * icon_size
        local x = center - total / 2
        f.label:pos(x, y + 11)
        x = x + width + gap
        for i = 1, f.count do
            f.icons[i]:pos(x, y + 4)
            x = x + icon_size
        end
    end
    f.label:commit_measurement()
end

function action_binder:get_tentative_binding_slot()
    if self.state == states.CONFIRM_BUTTON_ASSIGNMENT and self.action_name
        and self.action_type ~= action_types.DELETE and self.action_type ~= action_types.CHANGE_ICON
        and self.action_type ~= action_types.GLOBAL_ICON_SET then
        return self.hotkey
    end
end

function action_binder:is_in_selector_state()
    return not self.capturing_text and self.selector and self.selector.is_showing and (self.state == states.SELECT_ACTION_TYPE
        or self.state == states.SELECT_ACTION
        or self.state == states.SELECT_ACTION_TARGET
        or self.state == states.SELECT_PLAYER_BINDING
        or self.state == states.SELECT_ICON
        or self.state == states.DELETE_SET
        or self.state == states.SELECT_LINKED_TYPE
        or self.state == states.EDIT_CUSTOM_ACTION_PICK
        or self.state == states.DELETE_CUSTOM_ACTION_PICK
        or self.state == states.EDIT_CUSTOM_ACTION_REVIEW)
end

local repeat_navigation = {
    left='decrement_col', right='increment_col', down='increment_row', up='decrement_row',
}

function action_binder:tick_navigation(now, focused)
    self.nav_clock = now
    self:tick_bind_hold(now)
    local held = self.held_navigation
    if not held then return end
    if not focused or self.is_hidden or self.chooser_active or not self:is_in_selector_state()
        or held.state ~= self.state or held.options ~= self.selector.current_options then
        self.held_navigation = nil
        return
    end
    if not held.next then held.next = now + .35 end
    if now >= held.next then
        self[repeat_navigation[held.key]](self)
        held.next = now + .09
    end
end

-- A held trigger previews a page turn; another menu press consumes it.
function action_binder:menu_input(key,pressed)
    if self.bind_hold then return true end -- input waits for the bind confirmation
    if pressed and self.delete_set_armed and repeat_navigation[key] then
        -- Moving away from an armed set disarms it.
        self.delete_set_armed = nil
        if self.state == states.DELETE_SET then self:set_title('Delete Set') end
    end
    if pressed then
        self.held_navigation = nil
        if repeat_navigation[key] and self:is_in_selector_state() then
            self.held_navigation = {key=key, state=self.state, options=self.selector.current_options}
        end
    elseif self.held_navigation and self.held_navigation.key == key then
        self.held_navigation = nil
    end
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
    if just_pressed and self[other] then self.edit_combined_bank = side=='left' and 3 or 4 end
    if just_pressed and not self[other] and self.doublepress_provider and self:is_edit_mode() then
        local left_double, right_double = self.doublepress_provider()
        if (side == 'left' and left_double) or (side == 'right' and right_double) then
            self:undo_double_tap_page(side)
        end
    end
    if just_pressed then
        if self[other] and self.page_gesture then
            self.page_gesture.next_page=side=='right'
        else self.page_gesture={state=self.state,next_page=side=='right',used=self[other]} end
    elseif just_released and self.page_gesture then
        local gesture=self.page_gesture
        if not gesture.used and gesture.state==self.state and self:is_in_selector_state() then
            gesture.used=true
            local turned=false
            if gesture.next_page and self.selector.is_next_button_showing then self.selector:increment_page(); turned=true
            elseif not gesture.next_page and self.selector.is_prev_button_showing then self.selector:decrement_page(); turned=true end
            self.last_page_turn = turned and {side=side,next_page=gesture.next_page,state=self.state} or nil
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
        if pressed and not self.trigger_left_pressed and self.trigger_right_pressed then
            self.edit_combined_bank = 3
        end
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
        if pressed and not self.trigger_right_pressed and self.trigger_left_pressed then
            self.edit_combined_bank = 4
        end
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
    if self.bind_hold then return end -- the bind confirmation is still playing
    if self.custom_action_review_field then self:send_enter(); return end
    if self.selector.is_showing and self.selector.get_selected_option then
        local selected = self.selector:get_selected_option()
        if not selected then return end
        if selected.disabled then
            if selected.id == action_types.UNDO then
                chat_format.say(207, '[XIVCrossbar] Nothing to undo yet.')
            elseif selected.id == action_types.DELETE then
                chat_format.say(207, '[XIVCrossbar] That slot is already empty.')
            elseif selected.disabled_focusable then
                chat_format.say(207, '[XIVCrossbar] No custom actions saved. Choose Create Custom Action to add one.')
            end
            return
        end
    end
    -- A: where this Confirm came from; edit-mode binds return to it.
    self.submit_origin_state = self.state
    if (self.state == states.SELECT_ACTION_TYPE) then
        self.selection_states[states.SELECT_ACTION_TYPE] = self.selector:export_selection_state()
        local option = self.selector:submit_selected_option()
        self.action_type = option.id
        self.action_name, self.action_alias = nil, nil
        self.binding_preview_icon = option.asset_path

        if self.action_type == action_types.UNDO then
            self:undo_last_edit()
        elseif self.action_type == action_types.DELETE_SET then
            self.state = states.DELETE_SET
            self.delete_set_armed = nil
            self.selector:set_page(1)
            self:display_delete_set_selector()
        elseif (self.action_type == action_types.SHOW_CREDITS) then
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
    elseif (self.state == states.DELETE_SET) then
        self:submit_delete_set()
    elseif (self.state == states.SELECT_ACTION) then
        self.selection_states[states.SELECT_ACTION] = self.selector:export_selection_state()
        local option = self.selector:submit_selected_option()
        if (option.id == 'PREV') then
            self.selector:decrement_page()
        elseif (option.id == 'NEXT') then
            self.selector:increment_page()
        elseif option.id == 'CREATE_CUSTOM_ACTION' and option.data and option.data.menu_entry then
            self.action_type = action_types.CREATE_CUSTOM_ACTION
            self:new_custom_action('', 'menu')
        elseif option.id == 'EDIT_CUSTOM_ACTION' and option.data and option.data.menu_entry then
            self.action_type = action_types.EDIT_CUSTOM_ACTION
            self.state = states.EDIT_CUSTOM_ACTION_PICK
            self:display_custom_actions_picker('Edit Custom Action: Pick Entry')
        elseif self.action_type == action_types.SUPERWARP and option.data and option.data.warp_folder then
            -- Save the selected city in the root so Back returns to it.
            self.superwarp_parent_selection = self.selection_states[states.SELECT_ACTION]
            self.selection_states[states.SELECT_ACTION] = nil
            self.superwarp_folder = option.data.warp_folder
            self.selector:set_page(1)
            self:display_superwarp_selector()
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
            self.action_name = option.data.action_name or option.text
            self.binding_preview_icon = option.asset_path
            self.target_type = option.data.target_type

            -- Choosing a new action replaces nullable metadata too: Back from
            -- a switch/custom action must not carry its command into a spell.
            self.action_command = option.data.command
            self.action_icon = option.data.icon_path
            self.action_linked_action = option.data.linked_action
            self.action_linked_type = option.data.linked_type
            self.action_alias = option.data.alias

            -- A: self-only weaponskills still open the picker so <st> can be chosen.
            local step = self:target_step(self.target_type)
            if step == 'self' then
                self.action_target = action_targets.SELF
                self.state = states.SELECT_BUTTON_ASSIGNMENT
                self:display_button_assigner()
            elseif step == 'none' then
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
                chat_format.say(123, '[XIVCrossbar] ' .. warning)
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
                chat_format.say(123, '[XIVCrossbar] No action bound at the selected slot.')
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
                -- A: with a selected slot, change its icon in place and stay here.
                if self:bind_to_destination() then return end
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
            chat_format.say(123, '[XIVCrossbar] Set the alias first: //xivcrossbar ca a <value>')
            return
        end
        self.state = states.ENTER_CUSTOM_ACTION_NAME
        self:display_custom_action_field_review('Catalog Name', 'n', self.custom_action_draft.name, '(unique key in CustomActions.xml)')
    elseif (self.state == states.ENTER_CUSTOM_ACTION_NAME) then
        if (self.custom_action_draft.name == nil or self.custom_action_draft.name == '') then
            chat_format.say(123, '[XIVCrossbar] Set the catalog name first: //xivcrossbar ca n <value>')
            return
        end
        self.state = states.ENTER_CUSTOM_ACTION_COMMAND
        self:display_custom_action_field_review('Command', 'c', self.custom_action_draft.command, '(raw command this action will fire)')
    elseif (self.state == states.ENTER_CUSTOM_ACTION_COMMAND) then
        if (self.custom_action_draft.command == nil or self.custom_action_draft.command == '') then
            chat_format.say(123, '[XIVCrossbar] Set the command first: //xivcrossbar ca c <value>')
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
                chat_format.say(123, '[XIVCrossbar] Edit Custom Action: entry "' .. tostring(name) .. '" not found.')
                return
            end
            self.custom_action_draft = {
                alias         = record.alias,
                name          = name,
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
            -- Review may have left a trigger down or a page gesture pending.
            -- The icon picker starts with a fresh trigger press.
            self:reset_gamepad_triggers()
            self.page_gesture = nil
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
        elseif option.id == 'DELETE_CUSTOM_ACTION' and self.editing_custom_action and self.custom_action_original_name then
            self.custom_action_delete_target = self.custom_action_original_name
            self.custom_action_delete_from_review = true
            self.state = states.DELETE_CUSTOM_ACTION_CONFIRM
            self:display_delete_custom_action_confirm()
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
                self.custom_action_original_name = d.name
                self.binding_custom_action_review = true
                self.action_type = action_types.CUSTOM_ACTION
                self.action_name,self.action_alias = d.name,review.alias(d)
                self.action_command,self.action_icon = d.command,d.icon
                self.binding_preview_icon = self:custom_action_icon(d)
                self.action_linked_action,self.action_linked_type = d.linked_action,d.linked_type
                self.action_target = nil
                self.state = states.SELECT_BUTTON_ASSIGNMENT
                self:display_button_assigner()
            else
                self:return_to_custom_actions_list(self.custom_action_draft.name)
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
                chat_format.say(123, '[XIVCrossbar] Delete Custom Action: entry "' .. tostring(name) .. '" not found.')
                return
            end
            self.custom_action_delete_target = name
            self.state = states.DELETE_CUSTOM_ACTION_CONFIRM
            self:display_delete_custom_action_confirm()
        end
    elseif (self.state == states.DELETE_CUSTOM_ACTION_CONFIRM) then
        if not self:apply_custom_action_delete() then return end
        self:hide()
        self:reset_state()
    end
end

function action_binder:go_back()
    if self.bind_hold then return end -- the bind confirmation is still playing
    if self.custom_action_review_field then
        self.custom_action_review_field=nil; self:set_capturing_text(false)
        if self.custom_action_name_required then
            self.custom_action_name_required=false
            self:go_back()
        else self:display_edit_custom_action_review() end
        return
    end
    if self.state == states.SELECT_BUTTON_ASSIGNMENT then self:clear_button_entry_ui() end
    if self.binding_custom_action_review and self.state == states.SELECT_BUTTON_ASSIGNMENT then
        self.binding_custom_action_review=false
        self.state=states.EDIT_CUSTOM_ACTION_REVIEW
        self:display_edit_custom_action_review(); return
    end
    if self.custom_action_draft and (self.state == states.SELECT_LINKED_TYPE or
        (self.state == states.SELECT_ICON and (not self.icon_picker_stack or #self.icon_picker_stack == 0))) then
        self.is_linking_for_custom_action=false
        self.icon_picker_return=nil
        self.state=states.EDIT_CUSTOM_ACTION_REVIEW
        self:display_edit_custom_action_review(); return
    end
    if self.state == states.DELETE_SET then
        self.delete_set_armed = nil
        self:return_to_action_type_menu()
        return
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
        if self.action_type == action_types.SUPERWARP and self.superwarp_folder then
            local previous = self.superwarp_parent_selection
            self.superwarp_folder = nil
            self.superwarp_parent_selection = nil
            self.selection_states[states.SELECT_ACTION] = nil
            if previous then self.selector:set_page(previous.page) end
            self:display_superwarp_selector()
            if previous then self.selector:import_selection_state(previous) end
            return
        end
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
        if self.custom_action_delete_from_review then
            self.custom_action_delete_from_review = false
            self.state = states.EDIT_CUSTOM_ACTION_REVIEW
            self:display_edit_custom_action_review()
        else
            self.state = states.DELETE_CUSTOM_ACTION_PICK
            self:display_custom_actions_picker('Delete Custom Action: Pick Entry')
        end
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
    self.held_navigation = nil
    self.is_hidden = true
    -- Closing the menu (any path) clears the edit destination and footer.
    self.destination = nil
    self.edit_consumed = nil
    self.ghost_suppressed = nil
    self:dispose_destination_footer()
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
    self:set_title('XIV Crossbar')
    self.title:show()

    local player = windower.ffxi.get_player()
    local main_job = player.main_job
    local sub_job = player.sub_job

    local pet_jobs = {BST = true, SMN = true, DRG = true, PUP = true}
    local white_magic_jobs = {WHM = true, RDM = true, PLD = true, SCH = true, RUN = true}
    local black_magic_jobs = {BLM = true, RDM = true, DRK = true, SCH = true, GEO = true, RUN = true}

    local action_type_list = L{}
    local custom_icon = 'images/' .. get_icon_pathbase() .. '/custom_actions.png'
    local switch_icon = 'images/' ..get_icon_pathbase() .. '/ui/facebuttons_ps.png'
    local has = function(job) return main_job == job or sub_job == job end
    -- A: Sunshine's main menu order (2026-11-16). Entries flow in this order.
    -- Create/Edit Custom Action live inside Custom Action; Create Set lives
    -- in the set chooser; Delete Custom Action on the custom action edit screen.
    action_type_list:append({id = action_types.CUSTOM_ACTION, name = 'Custom Action', icon = custom_icon})
    action_type_list:append({id = action_types.JOB_ABILITY, name = 'Job Ability', icon = 'images/icons/abilities/00001.png', icon_offset = 4})
    action_type_list:append({id = action_types.WEAPONSKILL, name = 'Weaponskills', icon = 'images/icons/weapons/sword.png', icon_offset = 4})
    if (white_magic_jobs[main_job] or white_magic_jobs[sub_job]) then
        action_type_list:append({id = action_types.WHITE_MAGIC, name = 'White Magic', icon = 'images/' ..get_icon_pathbase() .. '/jobs/WHM.png'})
    end
    if (black_magic_jobs[main_job] or black_magic_jobs[sub_job]) then
        action_type_list:append({id = action_types.BLACK_MAGIC, name = 'Black Magic', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BLM.png'})
    end
    if has('BRD') then action_type_list:append({id = action_types.SONG, name = 'Songs', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BRD.png'}) end
    if has('DNC') then action_type_list:append({id = action_types.DANCES, name = 'Dances', icon = 'images/' ..get_icon_pathbase() .. '/jobs/DNC.png'}) end
    if has('SMN') then
        action_type_list:append({id = action_types.SUMMON, name = 'Summon', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SMN.png'})
        action_type_list:append({id = action_types.BP_RAGE, name = 'Rages', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SMN.png'})
        action_type_list:append({id = action_types.BP_WARD, name = 'Wards', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SMN.png'})
    end
    if (pet_jobs[main_job] or pet_jobs[sub_job]) then
        action_type_list:append({id = action_types.PET_COMMAND, name = 'Pet Commands', icon = 'images/' ..get_icon_pathbase() .. '/mounts/crab.png'})
    end
    if has('BST') then action_type_list:append({id = action_types.READY, name = 'Ready', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BST.png'}) end
    if has('NIN') then action_type_list:append({id = action_types.NINJUTSU, name = 'Ninjutsu', icon = 'images/' ..get_icon_pathbase() .. '/jobs/NIN.png'}) end
    if has('BLU') then action_type_list:append({id = action_types.BLUE_MAGIC, name = 'Blue Magic', icon = 'images/' ..get_icon_pathbase() .. '/jobs/BLU.png'}) end
    if has('COR') then
        action_type_list:append({id = action_types.PHANTOM_ROLL, name = 'Phantom Roll', icon = 'images/' ..get_icon_pathbase() .. '/jobs/COR.png'})
        action_type_list:append({id = action_types.QUICK_DRAW, name = 'Quick Draw', icon = 'images/' ..get_icon_pathbase() .. '/jobs/COR.png'})
    end
    if has('SCH') then action_type_list:append({id = action_types.STRATAGEMS, name = 'Stratagem', icon = 'images/' ..get_icon_pathbase() .. '/jobs/SCH.png'}) end
    if has('RUN') then
        action_type_list:append({id = action_types.RUNE_ENCHANTMENT, name = 'Rune Enchantment', icon = 'images/' ..get_icon_pathbase() .. '/jobs/RUN.png'})
        action_type_list:append({id = action_types.WARD, name = 'Ward', icon = 'images/' ..get_icon_pathbase() .. '/jobs/RUN.png'})
        action_type_list:append({id = action_types.EFFUSION, name = 'Effusion', icon = 'images/' ..get_icon_pathbase() .. '/jobs/RUN.png'})
    end
    if has('GEO') then action_type_list:append({id = action_types.GEOMANCY, name = 'Geomancy', icon = 'images/' ..get_icon_pathbase() .. '/jobs/GEO.png'}) end
    action_type_list:append({id = action_types.TRUST, name = 'Trusts', icon = 'images/' ..get_icon_pathbase() .. '/trust/yoran-oran.png'})
    action_type_list:append({id = action_types.SUPERWARP, name = 'Warps', icon = 'images/' .. get_icon_pathbase() .. '/home-point.png'})
    action_type_list:append({id = action_types.MOUNT, name = 'Mounts', icon = 'images/' ..get_icon_pathbase() .. '/mount.png'})
    action_type_list:append({id = action_types.SWITCH_CROSSBARS, name = 'Switch', icon = switch_icon})
    action_type_list:append({id = action_types.QUICK_SWITCH_CROSSBARS, name = 'Quick Switch', icon = switch_icon})
    action_type_list:append({id = action_types.USABLE_ITEM, name = 'Use Item', icon = 'images/' ..get_icon_pathbase() .. '/usable-item.png'})
    action_type_list:append({id = action_types.TRADABLE_ITEM, name = 'Trade Item', icon = 'images/' ..get_icon_pathbase() .. '/item.png'})
    action_type_list:append({id = action_types.ATTACK, name = 'Attack', icon = 'images/' ..get_icon_pathbase() .. '/attack.png'})
    action_type_list:append({id = action_types.RANGED_ATTACK, name = 'Ranged Attack', icon = 'images/' ..get_icon_pathbase() .. '/ranged.png'})
    action_type_list:append({id = action_types.ASSIST, name = 'Assist', icon = 'images/' ..get_icon_pathbase() .. '/assist.png'})
    action_type_list:append({id = action_types.SWITCH_TARGET, name = 'Switch Target', icon = 'images/' ..get_icon_pathbase() .. '/targetnpc.png'})
    action_type_list:append({id = action_types.MAP, name = 'View Map', icon = 'images/' ..get_icon_pathbase() .. '/map.png'})
    action_type_list:append({id = action_types.CHECK, name = 'Check', icon = 'images/' ..get_icon_pathbase() .. '/check.png'})
    action_type_list:append({id = action_types.LAST_SYNTH, name = 'Last Synth', icon = 'images/' ..get_icon_pathbase() .. '/synth.png'})
    action_type_list:append({id = action_types.CHANGE_ICON, name = 'Change Icon', icon = 'images/' ..get_icon_pathbase() .. '/icon-set.png'})
    -- Clear Slot is dummied out while the selected slot is empty (kept in step
    -- with the selection by refresh_clear_slot_entry).
    local clear_empty = self:destination_slot_empty()
    action_type_list:append({id = action_types.DELETE, name = 'Clear Slot', icon = 'images/' ..get_icon_pathbase() .. '/none.png',
        disabled = clear_empty, disabled_focusable = true})
    self.clear_slot_disabled = clear_empty
    local undo_count = self.undo_count and self.undo_count() or 0
    action_type_list:append({id = action_types.UNDO, name = undo_count > 0 and ('Undo (' .. undo_count .. ')') or 'Undo',
        icon = 'images/' ..get_icon_pathbase() .. '/Swap.png', disabled = undo_count == 0, disabled_focusable = true})
    action_type_list:append({id = action_types.MOVE_CROSSBARS, name = 'Move Crossbar', icon = 'images/' ..get_icon_pathbase() .. '/ui/dpad_ps.png'})
    action_type_list:append({id = action_types.DELETE_SET, name = 'Delete Set', icon = 'images/' ..get_icon_pathbase() .. '/ui/red-x.png'})
    action_type_list:append({id = action_types.SHOW_CREDITS, name = 'Credits', icon = 'images/credit_avatars/xiv.png'})
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
    self:set_title('Select Action Target')
    self.title:show()
    self.selector:display_options(action_binder.target_options_for(self.target_type, self.action_type,
        self.theme_options.allow_stpc_for_self_targeted_actions))
end

-- A: target picker order. Self-only actions lead with <me>; everything else
-- that can use <t> leads with it. Self-only weaponskills offer <me> and <st>.
function action_binder.target_options_for(target_type, action_type, allow_stpc_for_self)
    local icon = 'images/' .. get_icon_pathbase() .. '/mappoint.png'
    local names = {
        SELF = 'Self (<me>)', CURRENT_TARGET = 'Current Target (<t>)',
        SELECT_PARTY = 'Select Party (<stpt>)', SELECT_ALLIANCE = 'Select Ally (<stal>)',
        SELECT_PLAYER = 'Select Player (<stpc>)', SELECT_NPC = 'Select NPC (<stnpc>)',
        SELECT_TARGET = 'Select Target (<st>)', BATTLE_TARGET = 'Battle Target (<bt>)',
    }
    local ids = L{}
    local function add(id) if not ids:contains(id) then ids:append(id) end end

    local self_only = target_type['Self'] and not (target_type['Party'] or target_type['Ally'] or
        target_type['Player'] or target_type['NPC'] or target_type['Enemy'] or target_type['Corpse'])

    if self_only then
        add('SELF')
        if action_type == action_types.WEAPONSKILL then
            add('SELECT_TARGET')
        elseif allow_stpc_for_self then
            add('SELECT_PLAYER')
        end
    else
        if target_type['NPC'] or target_type['Enemy'] then add('CURRENT_TARGET') end
        if target_type['Self'] then add('SELF') end
        if target_type['Party'] or target_type['Corpse'] then add('SELECT_PARTY') end
        if target_type['Ally'] or target_type['Corpse'] then add('SELECT_ALLIANCE') end
        if target_type['Player'] or target_type['Corpse'] then add('SELECT_PLAYER') end
        if target_type['NPC'] or target_type['Enemy'] then add('SELECT_NPC') end
        if target_type['Enemy'] then add('SELECT_TARGET'); add('BATTLE_TARGET') end
    end

    local options = L{}
    for _, id in ipairs(ids) do options:append({id = id, name = names[id], icon = icon}) end
    return options
end

-- A: one title rule for every menu screen: centred on the menu. (Before
-- this, a title stayed centred only after a screen that centred it.)
function action_binder:set_title(text)
    self.title:text(text)
    caption_layout:center(self.title, self.base_x + self.width / 2, self.base_y + 30, self.width - 80)
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
    local name = bar and (bar.name or key) or key or ''
    local defaults = {default=true, ['job-default']=true, ['all-jobs-default']=true, shared=true}
    -- Set names in amber (the set label's colour), defaults and own sets alike.
    local color = '\\cs(255,216,112)'
    self:set_title(label .. ' — ' .. color .. name .. ' Crossbar\\cr')
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

function action_binder:binding_caption_y()
    local y = self.base_y + self.height / 2 - 40
    return self.action_name and math.max(y, self.base_y + 130) or y
end

function action_binder:show_binding_action_preview(caption_y)
    if not self.action_name then return end
    local center = self.base_x + self.width / 2
    local icon_path = self.binding_preview_icon or ('images/' .. get_icon_pathbase() .. '/custom_actions.png')
    local icon = ui_resources.image({draggable = false})
    icon:path(windower.addon_path .. icon_path)
    icon:fit(true)
    icon:size(38, 38)
    icon:pos(center - 19, caption_y - 68)
    icon:show()
    self.images:append(icon)

    local label = self:create_text(review.nonempty(self.action_alias) and self.action_alias or self.action_name,
        center, caption_y - 25)
    label:size(13)
    self:center_caption(label, caption_y - 25)
    self.hints:append(label)
end

function action_binder:show_button_entry_captions(confirming)
    self:show_control_hints('Confirm', 'Go Back')

    local caption_x = self.base_x + self.width / 2
    local caption_y = self:binding_caption_y()
    self:show_binding_action_preview(caption_y)
    local caption_text, secondary_text
    if self.action_type == action_types.DELETE then
        caption_text = confirming and 'Delete binding?' or 'Press a button combo to remove its bound action'
    elseif self.action_type == action_types.CHANGE_ICON then
        caption_text = confirming and 'Change icon for this slot?' or 'Press the button combo for the slot to change icon.'
    elseif self.action_type == action_types.GLOBAL_ICON_SET then
        caption_text = confirming and 'Change icon for matching actions across your sets?'
            or 'Press the button combo for the action to change icon.'
        if not confirming then
            secondary_text = 'Matches action names or aliases across your sets; slot icons take precedence.'
        end
    else
        caption_text = confirming and ('Bind ' .. self.action_name .. '?')
            or 'Press a button combo to bind it to this action'
    end

    local shoulder = shoulders.labels[self.active_crossbar]
    if shoulder then caption_text = shoulder..'  —  '..caption_text end
    local caption = self:create_text(caption_text, caption_x, caption_y)
    caption:size(14)
    self:center_caption(caption, caption_y)
    self.hints:append(caption)
    if secondary_text then
        local secondary = self:create_text(secondary_text, caption_x, caption_y + 25)
        secondary:size(11)
        self:center_caption(secondary, caption_y + 25)
        self.hints:append(secondary)
    end
end

function action_binder:display_button_assigner()
    -- A: edit mode step 2. With a destination selected, skip Enter Button
    -- Combo / Confirm and bind straight to it. Otherwise the legacy flow runs.
    if self:bind_to_destination() then return end
    self.active_crossbar = nil
    self:show_set_title('Enter Button Combo')
    self:reset_gamepad()
    self.selector:hide()

    windower.prim.set_position('button_entry_bg', self.base_x + 30, self:binding_caption_y() - 20)
    windower.prim.set_size('button_entry_bg', self.width - 60, 120)
    windower.prim.set_color('button_entry_bg', 150, 0, 0, 0)
    windower.prim.set_visibility('button_entry_bg', true)

    ui_resources.clear(self.images); self.images = L{}
    self:show_button_entry_captions(false)
end

function action_binder:display_button_confirmer()
    self:show_set_title('Enter Button Combo')
    self.selector:hide()
    self:confirm_buttons()
    self:show_button_entry_captions(true)
end

function action_binder:assign_action()
    self.save_binding(self.active_crossbar, self.hotkey, prefix_lookup[self.action_type], self.action_name, self.action_target, self.action_command, self.action_icon, self.action_linked_action, self.action_linked_type, self.action_alias)
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
        elseif (self.active_crossbar == 3 and self.theme_options.hotbar_number == 5) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
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
    local caption_y = self:binding_caption_y()
    local start_y = caption_y + 40

    for i=1,#icons,1 do
        self:show_icon(icons[i], start_x + (i - 1) * 40, start_y)
    end

    self:show_button_entry_captions(false)
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
        elseif (self.active_crossbar == 3 and self.theme_options.hotbar_number == 5) then
            icons:append('ui/binding_icons/trigger_' .. self.button_layout .. '_left.png')
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
    local start_y = self:binding_caption_y() + 40

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

    if (self.button_layout == 'gamecube') then
        if (self.confirm_button == 'a') then
            self:show_hint('Exit', 'ui/binding_icons/minus_' .. self.button_layout .. '.png', x, y)
        end
    elseif (self.button_layout == 'playstation') then
        if (self.confirm_button == 'cross') then
            self:show_hint('Exit', 'ui/binding_icons/minus_' .. self.button_layout .. '.png', x, y)
        end
    elseif (self.button_layout == 'xbox') then
        if (self.confirm_button == 'a') then
            self:show_hint('Exit', 'ui/binding_icons/minus_' .. self.button_layout .. '.png', x, y)
        end
    elseif (self.button_layout == 'nintendo') then
        if (self.confirm_button == 'b') then
            self:show_hint('Exit', 'ui/binding_icons/minus_' .. self.button_layout .. '.png', x, y)
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
    self:set_title('Select Job Ability')
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

    -- Experimental: resource-ID order for the current job's abilities.
    ability_list:sort(function(a, b) return a.id < b.id end)

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_weaponskill_selector()
    self:set_title('Select Weaponskill')
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

        -- A: use the resource's real targets. Self-only weaponskills (Myrkr,
        -- Dagan, Moonlight, Starlight...) must not offer <t>/<stnpc>/<bt>.
        local targets = ws.targets
        if targets == nil or next(targets) == nil then targets = {['Enemy'] = true} end
        ability_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset, data = {target_type = targets}})
    end

    -- Experimental: show the highest resource-ID weaponskills first.
    ability_list:sort(function(a, b) return a.id > b.id end)

    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm', 'Go Back')
end

-- TODO: Add get_drg_pet_commands(mlvl, slvl)
-- TODO This ↑ comment is by Icydeath. Maybe this has already been implemented? → Test it.
function action_binder:display_pet_command_selector()
    self:set_title('Select Pet Command')
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
    local jp_spent = player.job_points and player.job_points[main_job] and player.job_points[main_job].jp_spent or 0
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

            spell_list:append({id = id, name = name, icon = icon_path, icon_offset = icon_offset,
                custom_portrait = magic_type == 'Trust' and icon_overridden == true,
                data = {target_type = target_type}})
        end
    end

    -- Magic IDs preserve spell-family/tier order; summons put avatars before spirits.
    if magic_type == 'WhiteMagic' or magic_type == 'BardSong' or magic_type == 'BlackMagic' then
        spell_list:sort(function(a, b) return a.id < b.id end)
    elseif magic_type == 'SummonerPact' then
        spell_list:sort(require('libs/binder_sort').summons)
    elseif magic_type == 'Trust' then
        spell_list:sort(sortTrusts)
    else
        spell_list:sort(sortByName)
    end

    self.selector:display_options(spell_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_white_magic_selector()
    self:set_title('Select White Magic Spell')
    self.title:show()

    self:display_magic_selector_internal('WhiteMagic')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_black_magic_selector()
    self:set_title('Select Black Magic Spell')
    self.title:show()

    self:display_magic_selector_internal('BlackMagic')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_song_selector()
    self:set_title('Select Song')
    self.title:show()

    self:display_magic_selector_internal('BardSong')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_ready_selector()
    self:set_title('Select Ready Ability')
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
    self:set_title('Select Ninjutsu Spell')
    self.title:show()

    self:display_magic_selector_internal('Ninjutsu')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_summoning_selector()
    self:set_title('Select Summoning Spell')
    self.title:show()

    self:display_magic_selector_internal('SummonerPact')
    self:show_control_hints('Confirm', 'Go Back')
end

-- Binding eligibility is persistent level/avatar knowledge, not the current
-- pet-command list. Inactive Astral Flow must not hide a bindable pact.
function action_binder:display_blood_pact_selector(kind)
    local ward=kind=='BloodPactWard'
    self:set_title(ward and 'Select Blood Pact: Ward' or 'Select Blood Pact: Rage')
    self.title:show()
    local pacts=require('libs/blood_pacts')
    local ability_list=L{}
    local function exists(path)
        return file.new(path:gsub('^/','')):exists()
    end
    for _,ability in ipairs(pacts.available(res.job_abilities,windower.ffxi.get_player(),res.spells,windower.ffxi.get_spells(),kind)) do
        local name=ability.name or ability.en
        local metadata=crossbar_abilities[kebab_casify(name)]
        local icon,custom=pacts.icon(ability,metadata,get_icon_pathbase(),exists)
        ability_list:append({id=ability.id,name=name,icon=icon,icon_offset=custom and 0 or 4,
            data={target_type=ability.targets}})
    end
    self.selector:display_options(ability_list)
    self:show_control_hints('Confirm','Go Back')
end
function action_binder:display_bp_rage_selector() self:display_blood_pact_selector('BloodPactRage') end
function action_binder:display_bp_ward_selector() self:display_blood_pact_selector('BloodPactWard') end

function action_binder:display_blue_magic_selector()
    self:set_title('Select Blue Magic Spell')
    self.title:show()

    self:display_magic_selector_internal('BlueMagic')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_phantom_roll_selector()
    self:set_title('Select Phantom Roll')
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
    self:set_title('Select Quick Draw')
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
    self:set_title('Select Stratagem')
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
    self:set_title('Select Dance')
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
    self:set_title('Select Geomancy Spell')
    self.title:show()

    self:display_magic_selector_internal('Geomancy')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_rune_enchantment_selector()
    self:set_title('Select Rune Enchantment')
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
    self:set_title('Select Ward')
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
    self:set_title('Select Effusion')
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
        self:set_title('Select Crossbar Set (Quick Switch)')
    else
        self:set_title('Select Crossbar Set')
    end
    self.title:show()

    local crossbar_set_list = L{}
    local icon = '/ui/facebuttons_' .. self.button_layout
    local icon_path = 'images/' .. get_icon_pathbase() .. icon .. '.png'
    for _, destination in ipairs(self.get_crossbar_sets_binding()) do
        -- Labels are presentation. Both switch types save actual XML keys,
        -- including fallback sets whose labels need not match their keys.
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
    self:set_title('Select Custom Action')
    self.title:show()

    local action_list = L{}
    if (player_data.custom_actions ~= nil) then
        for name, record in pairs(player_data.custom_actions) do
            local icon_path,icon_offset = self:custom_action_icon(record)

            local resolved_alias = name
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
    -- A: Create and Edit lead the Custom Action list (moved from the main menu).
    local custom_icon = 'images/' .. get_icon_pathbase() .. '/custom_actions.png'
    local empty_catalog = action_list:length() == 0
    action_list:insert(1, {id = 'EDIT_CUSTOM_ACTION', name = 'Edit Custom Action', icon = custom_icon,
        disabled = empty_catalog, disabled_focusable = true, data = {menu_entry = true}})
    action_list:insert(1, {id = 'CREATE_CUSTOM_ACTION', name = 'Create Custom Action', icon = custom_icon,
        data = {menu_entry = true}})
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

-- Presentation-only: folder labels may be pretty, but all icon paths,
-- selection IDs and saved icon names must use the original directory spelling.
local icon_picker_folder_titles = {
    ['ui'] = 'UI',
    ['weaponskills'] = 'Weapon Skills',
    ['petcommands'] = 'Pet Commands',
}

local function icon_picker_folder_label(name)
    local alias = icon_picker_folder_titles[name:lower()]
    if alias then return alias end
    local spaced = name:gsub('[-_]', ' ')
    return (spaced:gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function icon_picker_breadcrumb(rel_path)
    local titled = rel_path:gsub('[^/]+', icon_picker_folder_label)
    return (titled:gsub('/', ' / '))
end

local function list_iconpack_dir(rel_path)
    local full_path = windower.addon_path .. 'images/' .. get_icon_pathbase()
        .. (rel_path and rel_path ~= '' and '/' .. rel_path or '')
    local dirs, files = L{}, L{}
    for _, name in ipairs(windower.get_dir(full_path) or {}) do
        if name ~= '.' and name ~= '..' then
            if windower.dir_exists(full_path .. '/' .. name) then
                if not icon_picker_excluded_dirs[name:lower()] then dirs:append(name) end
            else
                local stem = name:match('^(.*)%.[pP][nN][gG]$')
                if stem and not icon_picker_excluded_files[stem:lower()] then files:append(stem) end
            end
        end
    end
    dirs:sort()
    files:sort()
    return dirs, files
end

function action_binder:display_icon_selector(rel_path)
    rel_path = rel_path or self.icon_picker_path or ''
    self.icon_picker_path = rel_path
    local title_text
    if self.icon_picker_return == 'custom_review' and self.custom_action_draft then
        title_text = 'Pick Icon for "' .. self.custom_action_draft.name .. '"'
    elseif (self.action_type == action_types.GLOBAL_ICON_SET) then
        title_text = 'Pick Icon for "' .. (self.global_icon_source_name or '?') .. '"'
    elseif (self.action_type == action_types.CHANGE_ICON) then
        title_text = 'Pick Icon for Slot'
    else
        title_text = 'Pick an Icon'
    end
    if (rel_path ~= nil and rel_path ~= '') then
        title_text = title_text .. ' — ' .. icon_picker_breadcrumb(rel_path)
    end
    self:set_title(title_text)
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
            name = icon_picker_folder_label(dirname) .. ' >',
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
        if rel_path=='credits' then display_name=require('libs/contributor_credits').icon_names[filename] or display_name end
        list:append({
            id = 'FILE_' .. rel_icon,
            name = display_name,
            icon = 'images/' .. pathbase .. '/' .. rel_icon .. '.png',
            icon_size = rel_path=='credits' and 32 or nil,
            icon_offset = rel_path=='credits' and -1 or nil,
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
        chat_format.say(123, '[XIVCrossbar] Change Icon: callback not wired (please reload addon).')
        return
    end
    self.change_slot_icon(self.active_crossbar, self.hotkey, self.action_icon)
end

function action_binder:display_custom_action_field_review(field_label, field_letter, current_value, hint_text)
    self:set_title('Custom Action: ' .. field_label)
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
        chat_format.say(123, '[XIVCrossbar] No Custom Action in progress. Open the binder and choose Create Custom Action first.')
        return false
    end

    -- Reject empty values (whitespace-only counts as empty).
    if field == 'name' and not review.nonempty(value) then
        chat_format.say(123, '[XIVCrossbar] You must provide a value for "' .. field .. '".')
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
        chat_format.say(123, '[XIVCrossbar] Field "' .. field .. '" can only be set on its own review screen or the final review/confirm screen.')
        return false
    end

    if (field == 'name') then
        local is_original = (self.editing_custom_action and value == self.custom_action_original_name)
        if (not is_original and player_data.custom_actions ~= nil and player_data.custom_actions[value] ~= nil) then
            chat_format.say(123, '[XIVCrossbar] A custom action named "' .. value .. '" already exists. Pick a different name.')
            return false
        end
    end

    self.custom_action_draft[field] = value or ''
    if field == 'name' and self.custom_action_name_required then
        self.custom_action_name_required = false
        self.custom_action_review_field = nil
        self:set_capturing_text(false)
    end
    chat_format.say(207, '[XIVCrossbar] ' .. field .. ' set to: ' .. value)

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
        chat_format.say(123, '[XIVCrossbar] Global Icon Set: callback not wired (please reload addon).')
        return
    end
    if (self.global_icon_source_name == nil or self.global_icon_source_name == '') then
        chat_format.say(123, '[XIVCrossbar] Global Icon Set: no action name captured.')
        return
    end
    self.save_global_icon(self.global_icon_source_name, self.action_icon)
end

function action_binder:apply_custom_action_save()
    local d=self.custom_action_draft
    if not d or not review.valid_name(d.name,player_data.custom_actions,nil) or not self.save_custom_action then
        chat_format.say(123, '[XIVCrossbar] Enter a unique catalog name before saving.'); return false
    end
    return self.save_custom_action(d) ~= false
end

function action_binder:new_custom_action(name, origin)
    if not self.title then chat_format.say(123,'[XIVCrossbar] Log in before editing.'); return false end
    if self.custom_action_draft then chat_format.say(123,'[XIVCrossbar] Save or cancel the current draft first.'); return false end
    name=name or ''
    local record=player_data.custom_actions and player_data.custom_actions[name]
    self.custom_action_entry_origin=origin
    self.editing_custom_action=record ~= nil
    self.custom_action_original_name=record and name or nil
    self.action_type=record and action_types.EDIT_CUSTOM_ACTION or action_types.CREATE_CUSTOM_ACTION
    self.custom_action_draft={name=name,alias=record and record.alias or nil,command=record and record.command or nil,
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

-- Saving without binding stays in the catalog, ready to edit another entry.
-- Preserve the main-menu Back selection, but discard all completed draft state.
function action_binder:return_to_custom_actions_list(saved_name)
    self.custom_action_draft, self.custom_action_original_name = nil, nil
    self.custom_action_review_field, self.custom_action_entry_origin = nil, nil
    self.editing_custom_action, self.binding_custom_action_review = false, false
    self.custom_action_name_required, self.is_linking_for_custom_action = false, false
    self.inline_entry_text, self.custom_action_value_texts = nil, nil
    self.text_entry_buffer = ''
    self:set_capturing_text(false)
    self.action_name, self.action_alias, self.action_command, self.action_icon = nil, nil, nil, nil
    self.action_linked_action, self.action_linked_type = nil, nil
    self.action_target, self.target_type = nil, nil
    self.active_crossbar, self.hotkey = nil, nil
    self.state, self.action_type = states.EDIT_CUSTOM_ACTION_PICK, action_types.EDIT_CUSTOM_ACTION
    self:display_custom_actions_picker('Edit Custom Action: Pick Entry', saved_name)
end

function action_binder:display_custom_actions_picker(title_text, selected_name)
    self:set_title(title_text)
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
    for _, name in ipairs(names) do
        local record = player_data.custom_actions[name]
        local icon_path,icon_offset = self:custom_action_icon(record)
        list:append({id = 'CA_' .. name, name = name, icon = icon_path, icon_offset = icon_offset})
    end

    -- Review uses a different grid from the normal catalog. Locate the saved
    -- entry in normal-grid coordinates before displaying its (possibly new) page.
    local selection
    if selected_name then
        local rows, cols = self.selector.normal_max_row, self.selector.normal_max_col
        local capacity = rows * cols
        for index, name in ipairs(names) do
            if name == selected_name then
                local offset = (index - 1) % capacity
                selection = {page=math.floor((index - 1) / capacity) + 1,
                    row=math.floor(offset / cols) + 1, col=offset % cols + 1}
                break
            end
        end
        self.selector:set_page(selection and selection.page or 1)
    end
    self.selector:display_options(list)
    if selection then self.selector:import_selection_state(selection) end
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
    if self.editing_custom_action and self.custom_action_original_name then
        list:append({id='DELETE_CUSTOM_ACTION', name='Delete', icon=path..'ui/red-x.png'})
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
        'Select Edit Name, Edit Alias or Edit Command to type.',
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
    self:set_title('Delete Custom Action')
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
    if not d or not review.valid_name(d.name,player_data.custom_actions,self.custom_action_original_name) or not self.update_custom_action then
        chat_format.say(123,'[XIVCrossbar] Enter a unique catalog name before saving.'); return false
    end
    return self.update_custom_action(self.custom_action_original_name,d) ~= false
end

function action_binder:apply_custom_action_delete()
    if (self.delete_custom_action == nil) then
        chat_format.say(123, '[XIVCrossbar] Delete Custom Action: callback not wired (please reload addon).')
        return
    end
    local target = self.custom_action_delete_target
    if (target == nil or target == '') then
        chat_format.say(123, '[XIVCrossbar] Delete Custom Action: no entry selected.')
        return
    end
    return self.delete_custom_action(target)
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
        local hb = shoulders.bar(player_data.hotbar, env_name, self.active_crossbar)
        if (hb == nil) then return nil end
        local action = hb['slot_' .. self.hotkey]
        if (action == nil or action.action == nil) then return nil end
        return action
    end

    local env = shoulders.destination(player_data.hotbar_settings.active_environment, self.active_crossbar)
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
    local env = shoulders.destination(player_data.hotbar_settings.active_environment, self.active_crossbar)

    local function lookup(env_name)
        local env_table = player_data.hotbar[env_name]
        if (env_table == nil) then return nil end
        local hb = shoulders.bar(player_data.hotbar, env_name, self.active_crossbar)
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
    self:set_title('Custom Action: Icon')
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
    self:set_title('Custom Action: Linked Action Category')
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
    self:set_title('Custom Action: Review and Save')
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
    self:set_title('Select Trust')
    self.title:show()

    self:display_magic_selector_internal('Trust')
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_mount_selector()
    self:set_title('Select Mount')
    self.title:show()

    self.selector:display_options(get_mounts())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_usable_item_selector()
    self:set_title('Select Usable Item')
    self.title:show()

    self.selector:display_options(get_usable_items())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_tradable_item_selector()
    self:set_title('Select Tradable Item')
    self.title:show()

    self.selector:display_options(get_tradable_items())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_execute_command_selector()
    self:set_title('Select an icon for the command')
    self.title:show()

    self.selector:display_options(get_icons())
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_superwarp_selector()
    self:set_title(self.superwarp_folder or 'Select Warp Location')
    self.title:show()

    self.selector:display_options(get_warp_zones(self.superwarp_folder))
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_player_selector(include_self)
    self:set_title('Select Player to Assist')
    self.title:show()

    self.selector:display_options(get_party_names(include_self))
    self:show_control_hints('Confirm', 'Go Back')
end

-- TODO: Either rename this to better discern it from action_binder:display_icon_selector() or merge the two functions
function action_binder:display_icon_selector_sylvebits()
    self:set_title('Select Icon')
    self.title:show()

    local icon_list = L{}
    local pathbase = get_icon_pathbase()
    local base_dir = windower.addon_path .. 'images/' .. pathbase

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

    local all_icons = L{}
    local function scan(directory, prefix, depth)
        if depth > 16 then return end
        for _, name in ipairs(windower.get_dir(directory) or {}) do
            if name ~= '.' and name ~= '..' then
                local path = directory .. '/' .. name
                if windower.dir_exists(path) then
                    if not excluded_dirs[name:lower()] then scan(path, prefix .. name .. '/', depth + 1) end
                else
                    local stem = name:match('^(.*)%.[pP][nN][gG]$')
                    if stem and not excluded_files[stem:lower()] then
                        local key = prefix .. stem
                        all_icons:append({
                            sort_key = prefix .. '/' .. stem,
                            name = stem:gsub('[-_]', ' '):gsub('(%a)([%w]*)', function(first, rest)
                                return first:upper() .. rest
                            end),
                            icon = 'images/' .. pathbase .. '/' .. prefix .. name,
                            icon_path = '/' .. key,
                        })
                    end
                end
            end
        end
    end
    scan(base_dir, '', 0)
    all_icons:sort(function(a, b) return a.sort_key < b.sort_key end)
    for _, entry in ipairs(all_icons) do
        icon_list:append({id=icon_id, name=entry.name, icon=entry.icon, data={icon_path=entry.icon_path}})
        icon_id = icon_id + 1
    end

    self.selector:display_options(icon_list)
    self:show_control_hints('Confirm', 'Go Back')
end

function action_binder:display_text_entry(title_text, placeholder)
    self:set_title(title_text)
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

-- Own physical navigation across the custom-action workflow. Inline
-- fields have their own Enter and Escape behavior in the root router.
function action_binder:is_keyboard_review()
    if self.is_hidden or self.chooser_active or self.capturing_text then return false end
    local state = self.state
    return state==states.EDIT_CUSTOM_ACTION_REVIEW or state==states.CONFIRM_CUSTOM_ACTION
        or state==states.EDIT_CUSTOM_ACTION_PICK or state==states.DELETE_CUSTOM_ACTION_PICK
        or state==states.DELETE_CUSTOM_ACTION_CONFIRM
        or state==states.ENTER_CUSTOM_ACTION_ALIAS or state==states.ENTER_CUSTOM_ACTION_NAME
        or state==states.ENTER_CUSTOM_ACTION_COMMAND or state==states.SELECT_CUSTOM_ACTION_ICON_CHOICE
        or (self.custom_action_draft ~= nil and (state==states.SELECT_ICON
            or state==states.SELECT_LINKED_TYPE or state==states.SELECT_ACTION))
end

function action_binder:set_capturing_text(enabled)
    self.capturing_text = enabled
    require('text_input_guard'):update(enabled, windower.send_command)
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
    self:set_title('XIVCrossbar Development Credits')
    self.title:show()

    local NO_DATA = {target_type = {['None'] = true}}

    local credits = L{}
    for index,entry in ipairs(require('libs/contributor_credits').entries) do
        credits:append({id=index,name=entry.name,
            icon='images/credit_avatars/'..entry.icon..'.png',icon_size=32,icon_offset=-1,data=NO_DATA})
    end

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
    self:set_title('Move Crossbars')
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
				local icon_file = file.new('images/'..icon_path)
				if icon_file:exists() then
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

function get_warp_zones(folder_name)
    local commands = L{}
    local all = action_binder.theme_options.enable_superwarp_all and ' all' or ''
    local icon_base = 'images/' .. get_icon_pathbase() .. '/'

    -- City choices are directly bindable: no extra zone subfolders.
    if folder_name then
        for _, folder in ipairs(sw_zones.city_folders) do
            if folder.name == folder_name then
                for _, zone in ipairs(folder.zones) do
                    for point, landmark in ipairs(zone.points) do
                        local name = zone.short .. ' - ' .. landmark
                        commands:append({id = 0, name = name,
                            icon = icon_base .. 'home-point.png',
                            data = {target_type = {['None'] = true},
                                action_name = zone.zone .. ' - ' .. landmark,
                                alias = name,
                                command = 'sw hp' .. all .. ' ' .. zone.zone .. ' ' .. point,
                                icon_path = 'home-point'}})
                    end
                    if zone.guide then
                        commands:append({id = 0, name = zone.short .. ' - Survival Guide',
                            icon = icon_base .. 'survival-guide.png',
                            data = {target_type = {['None'] = true},
                                action_name = zone.zone .. ' - Survival Guide',
                                alias = zone.short .. ' SG',
                                command = 'sw sg' .. all .. ' ' .. zone.zone,
                                icon_path = 'survival-guide'}})
                    end
                end
                return commands
            end
        end
        return commands
    end

    -- The original alphabetical catalog stays below the three new folders.
    -- Remove only the city entries now reachable through those folders.
    local in_folders = {hp = {}, sg = {}}
    for _, folder in ipairs(sw_zones.city_folders) do
        commands:append({id = 0, name = folder.name,
            icon = icon_base .. 'map.png',
            data = {warp_folder = folder.name}})
        for _, zone in ipairs(folder.zones) do
            in_folders.hp[zone.zone:lower()] = true
            if zone.guide then in_folders.sg[zone.zone:lower()] = true end
        end
    end

    local remaining = L{}
    for _, entry in pairs(res.zones) do
        if entry and entry.en ~= 'unknown' then
            for _, transport in ipairs({'hp', 'sg'}) do
                if sw_zones[transport][entry.en] and not in_folders[transport][entry.en:lower()] then
                    local icon = transport == 'hp' and 'home-point' or 'survival-guide'
                    remaining:append({id = 0, name = entry.en,
                        icon = icon_base .. icon .. '.png',
                        data = {target_type = {['None'] = true}, alias = entry.en,
                            command = 'sw ' .. transport .. all .. ' ' .. entry.en,
                            icon_path = icon}})
                end
            end
        end
    end
    remaining:sort(sortByName)
    for _, option in ipairs(remaining) do commands:append(option) end
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
