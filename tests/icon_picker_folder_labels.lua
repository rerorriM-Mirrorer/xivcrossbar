-- Folder names are for display only. Directory paths and stored icon IDs
-- must keep their original spelling, separators and case.
local file = assert(io.open('action_binder.lua', 'rb'))
local source = assert(file:read('*a'))
file:close()
local first = assert(source:find('-- Presentation-only: folder labels', 1, true))
local last = assert(source:find('local function list_iconpack_dir(rel_path)', first, true))
local compile = loadstring or load
local factory, err = compile(source:sub(first, last-1) ..
    '\nreturn icon_picker_folder_label, icon_picker_breadcrumb')
assert(factory, err)
local label, breadcrumb = factory()
assert(label('blue-magic') == 'Blue Magic')
assert(label('rune-enchantments') == 'Rune Enchantments')
assert(label('phantom-rolls') == 'Phantom Rolls')
assert(label('white-magic') == 'White Magic')
assert(label('Songs') == 'Songs')
assert(label('ui') == 'UI')
assert(label('weaponskills') == 'Weapon Skills')
assert(label('petcommands') == 'Pet Commands')
assert(label('Great-axe') == 'Great Axe')
assert(label('misc') == 'Misc')
assert(breadcrumb('weaponskills/Great-axe') == 'Weapon Skills / Great Axe')
assert(breadcrumb('ui/binding_icons') == 'UI / Binding Icons')
assert(source:find("name = icon_picker_folder_label(dirname) .. ' >'", 1, true),
    'directory rows must render the pretty name')
assert(source:find("title_text = title_text .. ' — ' .. icon_picker_breadcrumb(rel_path)", 1, true),
    'breadcrumbs must render the pretty path')
assert(source:find("id = 'DIR_' .. child_path", 1, true),
    'folder IDs should remain raw paths')
assert(source:find("path = child_path,", 1, true),
    'navigation must keep the original path')
assert(source:find("icon_path = rel_icon,", 1, true),
    'saved custom icon must keep the original path')
print('Icon picker presentation: friendly folders, breadcrumbs, unmodified icon paths passed.')
