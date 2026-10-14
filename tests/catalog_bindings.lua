dofile('tests/custom_catalog.lua')
local c=require('custom_catalog')
local b=require('catalog_bindings')
local old={name='Bow',id='one',command='input /bow'}
local slot={type='ex',action='input /bow',alias='Bow'}
b.attach(slot,old,'global')
local edited={name='Greeting',id='one',alias='Hi',command='input /wave',icon='check',linked_type='ma',linked_action='Cure'}
assert(b.apply(slot,edited))
assert(slot.action=='input /wave' and slot.alias=='Hi' and slot.icon=='check' and slot.catalog_id=='one')
slot.alias='Personal label';slot.icon='assist'
edited.alias='Changed';edited.icon='custom_actions';edited.command='input /echo retained'
assert(b.apply(slot,edited))
assert(slot.alias=='Personal label' and slot.icon=='assist' and slot.action=='input /echo retained')
local sources={global={Greeting=edited},character={}}
local exact={type='ex',action=edited.command,alias=edited.alias,icon=edited.icon,linked_type='ma',linked_action='Cure'}
assert(b.legacy_match(exact,sources)==edited)
sources.character.Copy=edited
assert(b.legacy_match(exact,sources)==nil)
sources.character.Copy=nil
edited.deleted='true'
local view=c.view({['@retired:one']=edited},{},'global')
assert(next(view)==nil)
assert(b.find({['@retired:one']=edited},'one')==edited)
assert(b.apply(slot,edited)==false and slot.action=='input /echo retained')
local named={name='OnlyName',id='n'}
assert(b.values(named).action=='OnlyName' and named.command==nil)
named.alias='Alias';assert(b.values(named).action=='Alias' and named.command==nil)
print('Catalog identity updates, renames, slot overrides, conservative legacy adoption and deletion snapshots passed.')
