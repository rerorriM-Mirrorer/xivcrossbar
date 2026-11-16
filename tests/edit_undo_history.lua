-- edit_undo.lua: history limit, order, persistence and isolation.
package.path='./?.lua;'..package.path
local undo=require('edit_undo')
local saved
local store={read=function() return saved end, write=function(text) saved=text end}
local h=undo.new(store)
local slot={action='Cure',type='ma',target='t',nested={a=1}}
h:push('basic',2,7,slot,'Cure')
slot.action='changed'; slot.nested.a=2
for i=1,10 do h:push('basic',1,i%8+1,nil,'Spell '..i) end
assert(h:count()==9, 'keeps the last nine')
local reopened=undo.new(store)
assert(reopened:count()==9, 'history survives a reload')
local last=reopened:pop()
assert(last.label=='Spell 10' and last.before==false, 'newest first; empty slot recorded as false')
assert(undo.new(store):count()==8, 'pop is saved')
local h2=undo.new({read=function() return nil end, write=function() end})
h2:push('basic',2,7,slot,'x'); slot.action='after'
assert(h2:pop().before.action=='changed', 'records are copies')
assert(undo.new({read=function() return 'os.exit()' end}):count()==0, 'unreadable file ignored')
assert(undo.new({read=function() return 'return {records={{environment="a",bank=1,slot=2,before=false}}}' end}):count()==1)
print('edit undo history: limit, persistence, copies and safe loading passed')

-- player.lua slot record helpers, extracted and run against a fake hotbar.
local f=assert(io.open('player.lua')); local src=f:read('*a'); f:close()
local a=src:find('function player:get_slot_record',1,true)
local b=src:find("-- update a slot's icon",1,true)
local player={hotbar={basic={hotbar_2={slot_7={action='Cure',icon='a'}}},shared={}}}
local env=setmetatable({player=player,shoulders=require('shoulder_banks')},{__index=_G})
assert((load or loadstring)(src:sub(a,b-1),'player slot records','t',env))()
local before=player:get_slot_record('basic',2,7)
assert(before and before.action=='Cure')
assert(player:get_slot_record('basic',2,3)==nil)
local saved_copy=undo.copy(before)
player.hotbar.basic.hotbar_2.slot_7.action='Thunder'
assert(player:restore_slot_record('basic',2,7,saved_copy) and player.hotbar.basic.hotbar_2.slot_7.action=='Cure')
assert(player:restore_slot_record('basic',2,7,false) and player.hotbar.basic.hotbar_2.slot_7==nil, 'undo of a bind on an empty slot clears it')
assert(player:restore_slot_record('basic',8,1,{action='Haste'}) and player.hotbar.shared['hotbar_shoulder-r1'].slot_1.action=='Haste', 'R1 bank lives in shared')
assert(not player:restore_slot_record('gone',2,1,{action='x'}), 'deleted set refuses')
print('player slot records: snapshot and restore passed')
