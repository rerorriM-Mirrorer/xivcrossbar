-- Exercises the real comparator extracted from action_binder.lua without loading Windower UI.
local stream = assert(io.open('action_binder.lua', 'rb'))
local source = assert(stream:read('*a'))
stream:close()
local from = assert(source:find('-- Curation for the Trust binder only.', 1, true))
local until_pos = assert(source:find('function action_binder:setup(', from, true))
local role_source = source:sub(from, until_pos - 1)
local compile = loadstring or load
local factory, err = compile("local kebab_casify = require('libs/kebab_casify')\n" ..
    role_source .. '\nreturn sortTrusts, TRUST_ROLE_PRIORITY')
assert(factory, err)
local sort_trusts, roles = factory()
local entries = {
    {name='Shantotto', id=120, custom_portrait=true},
    {name='Kupipi', id=45, custom_portrait=true},
    {name='Sakura', id=500, custom_portrait=true},
    {name='Moogle', id=700, custom_portrait=false},
    {name='Yoran-Oran (UC)', id=1120, custom_portrait=false},
    {name='Trion', id=30, custom_portrait=false},
    {name='Joachim', id=90, custom_portrait=false},
    {name='Najelith', id=75, custom_portrait=false},
    {name='Lion', id=35, custom_portrait=false},
    {name='Naji', id=10, custom_portrait=false},
    {name='Curilla', id=70, custom_portrait=false},
}
table.sort(entries, sort_trusts)
local expected = {'Sakura','Kupipi','Shantotto','Moogle','Yoran-Oran (UC)',
    'Trion','Curilla','Joachim','Najelith','Naji','Lion'}
for i, entry in ipairs(entries) do
    assert(entry.name == expected[i], 'Trust sort position '..i..': '..entry.name..' ~= '..expected[i])
end
assert(roles['kupofried'] == 1)
assert(roles['monberaux'] == 2)
assert(roles['august'] == 3)
assert(roles['selhteus'] == 4)
assert(roles['shantotto-ii'] == 5)
assert(roles['semih-lafihna'] == 6)
assert(roles['unclassified'] == nil)
assert(source:find("magic_type == 'WhiteMagic' or magic_type == 'BardSong'", 1, true))
assert(source:find("spell_list:sort(sortTrusts)", 1, true))
assert(source:find("ability_list:sort(function(a, b) return a.id < b.id end)", 1, true))
assert(source:find("ability_list:sort(function(a, b) return a.id > b.id end)", 1, true))
assert(source:find("custom_portrait = magic_type == 'Trust' and icon_overridden == true", 1, true))
print('Binder sorting: portrait priority, role priority, ID ties and prior sort policies passed.')
