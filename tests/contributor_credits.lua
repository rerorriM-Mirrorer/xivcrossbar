local registry=require('libs/contributor_credits')
assert(#registry.entries==20 and registry.entries[1].name=='Programming/Art\nAliekber')
local seen={}
for _,entry in ipairs(registry.entries)do
    assert(entry.person and entry.icon and registry.icon_names[entry.icon]==entry.person)
    seen[entry.icon]=true
    for _,prefix in ipairs({'images/credit_avatars/','images/icons/iconpacks/default/credits/'})do
        local f=assert(io.open(prefix..entry.icon..'.png','rb'))
        assert(f:read(8)=='\137PNG\r\n\26\n');f:close()
    end
end
assert(seen.a and seen.edeon and seen.aeliya and seen.akirane and seen.qeaglestrikerp)
local f=assert(io.open('action_binder.lua'));local source=f:read('*a');f:close()
local body=assert(source:match('function action_binder:display_credits%(%)\n(.-)\nend'))
local env=setmetatable({L=function(seed)seed=seed or {};seed.append=function(t,v)table.insert(t,v)end;return seed end},{__index=_G})
local draw=assert(load('return function(self)\n'..body..'\nend','actual credits screen','t',env))()
local rows,page
local screen={title={text=function()end,show=function()end},selector={set_page=function(_,p)page=p end,display_options=function(_,r)rows=r end},show_control_hints=function()end}
draw(screen)
assert(page==1 and #rows==20 and rows[20].name=='Development\nA')
for i,row in ipairs(rows)do assert(row.id==i and row.icon_size==32 and row.icon_offset==-1 and row.data.target_type.None and row.icon:find('images/credit_avatars/',1,true)==1)end
print('Contributor credits: original roles, 20 valid portrait/icon assets, exact names and production 20-row menu passed.')
