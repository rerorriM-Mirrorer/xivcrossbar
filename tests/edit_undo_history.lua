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

-- Swap is one Undo step restoring both slots.
local hs=undo.new({read=function() return nil end, write=function() end})
hs:push_group({{environment='basic',bank=2,slot=7,before={action='Cure'}},{environment='second',bank=1,slot=3,before=nil}},'Swap')
assert(hs:count()==1)
local rec=hs:pop()
assert(rec.label=='Swap' and #rec.group==2 and rec.group[1].before.action=='Cure' and rec.group[2].before==false)
assert(rec.environment=='basic' and rec.bank==2 and rec.slot==7, 'first slot selected after Undo')
local saved_group
local hp=undo.new({read=function() return saved_group end, write=function(t) saved_group=t end})
hp:push_group({{environment='a',bank=1,slot=1,before={action='X'}},{environment='a',bank=1,slot=2,before={action='Y'}}},'Swap')
assert(undo.new({read=function() return saved_group end}):pop().group[2].before.action=='Y', 'group survives a reload')

-- swap_slots and undo_last_edit from xivcrossbar.lua, run against a fake hotbar.
local f2=assert(io.open('xivcrossbar.lua')); local main=f2:read('*a'); f2:close()
local s1=main:find('function swap_slots(a, b)',1,true)
local s2=main:find('-- command to set a crossbar action in action_binder',s1,true)
local u1=main:find('function undo_last_edit()',1,true)
local u2=main:find('\n%-%- A: exchange two slots',u1)
local hotbar={basic={hotbar_2={slot_7={action='Cure'}}},second={hotbar_1={slot_3={action='Haste'}}},shared={}}
local p2={hotbar=hotbar,hotbar_settings={active_environment='basic'},hotbar_load_ok=true}
p2.get_slot_record=player.get_slot_record; p2.restore_slot_record=player.restore_slot_record
local history2=undo.new({read=function() return nil end, write=function() end})
local said={}
local env2=setmetatable({player=p2,shoulder_banks=require('shoulder_banks'),edit_undo=undo,
    ensure_edit_undo_history=function() return history2 end,
    chat_format={say=function(_,t) said[#said+1]=t end},
    reload_hotbar=function() end,set_active_environment=function() end},{__index=_G})
function p2:save_hotbar() self.saves=(self.saves or 0)+1 end
assert((load or loadstring)(main:sub(s1,s2-1),'swap_slots','t',env2))()
assert((load or loadstring)(main:sub(u1,u2),'undo_last_edit','t',env2))()
assert(env2.swap_slots({environment='basic',bank=2,slot=7},{environment='second',bank=1,slot=3}))
assert(hotbar.basic.hotbar_2.slot_7.action=='Haste' and hotbar.second.hotbar_1.slot_3.action=='Cure', 'swapped across sets')
assert(env2.swap_slots({environment='basic',bank=2,slot=7},{environment='basic',bank=1,slot=4}))
assert(hotbar.basic.hotbar_2.slot_7==nil and hotbar.basic.hotbar_1.slot_4.action=='Haste', 'swap onto an empty slot moves it')
assert(env2.undo_last_edit() and hotbar.basic.hotbar_2.slot_7.action=='Haste' and hotbar.basic.hotbar_1.slot_4==nil)
assert(env2.undo_last_edit() and hotbar.basic.hotbar_2.slot_7.action=='Cure' and hotbar.second.hotbar_1.slot_3.action=='Haste',
    'one Undo restores both slots of a swap')
p2.hotbar_load_ok=false
assert(env2.swap_slots({environment='basic',bank=2,slot=7},{environment='second',bank=1,slot=3})==false)
assert(hotbar.basic.hotbar_2.slot_7.action=='Cure', 'nothing changes after a failed load')
print('swap undo groups and swap_slots: passed')
