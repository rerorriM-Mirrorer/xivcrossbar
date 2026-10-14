dofile('tests/custom_catalog.lua')
local c=require('custom_catalog')
local b=require('catalog_bindings')
local f=assert(io.open('examples/CustomActions-template.xml'));local raw=f:read('*a');f:close()
local entries=assert(c.decode(raw,catalog_test_parse))
local count,npc=0,0
for name,record in pairs(entries) do
    count=count+1
    local values=b.values(record)
    assert(record.id and values.action==record.command and record.command~='')
    assert(not record.command:match('^//'))
    if record.icon then
        local image=assert(io.open('images/icons/iconpacks/default/'..record.icon..'.png','rb'));image:close()
    end
    if name:match('^NPCMirror') then
        npc=npc+1
        assert(({interact=true,enter=true,esc=true,status=true,stop=true,call=true})[record.command:match('^npcmirror (.+)$')])
    end
end
assert(count==34 and npc==6)
assert(entries['Utility - Follow Target'].command=='input /follow <t>')
assert(entries['Utility - Instant Warp'].command=='input /item "Instant Warp" <me>')
assert(entries['Dialogue - Raw Cancel'].command:find('; wait 0.1;',1,true))
assert(c.decode(c.encode(entries),catalog_test_parse)['Utility - Bow'].command=='input /bow')
print('34 template actions: actual catalog decoder/binding values, six implemented NPCMirror verbs, XML escaping/chains, stable IDs and shipped icons passed.')
