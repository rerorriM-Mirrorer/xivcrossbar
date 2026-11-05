-- t33: the bank router is the only decoder of bare versus banked Cross.
local M=dofile('libs/controller/npc_actions.lua')
local actions={}
local bridge=M.new({emit=function(op,seq,token)
    actions[#actions+1]={op=op,seq=seq,token=token}
end})
local token='owner-buttons-14'
assert(bridge:edge(5,true,'ordinary',true,token,12))
assert(#actions==1 and actions[1].op=='enter' and actions[1].seq==12)
assert(bridge:edge(7,true,'ordinary',true,token,13))
assert(#actions==2 and actions[2].op=='esc')
-- A bank's own command is never misread as dialogue Enter by NPCMirror.
assert(not bridge:edge(5,true,nil,true,token,14))
assert(not bridge:edge(5,true,'bank',true,token,15))
assert(not bridge:edge(5,true,'ordinary',false,token,16))
assert(not bridge:edge(5,false,'ordinary',true,token,17))
assert(not bridge:edge(5,true,'ordinary',true,nil,18))
assert(not bridge:edge(5,true,'ordinary',true,token,-1))
assert(#actions==2,'no modified/gameplay/release/malformed action forwarded')
-- Ensure the actual root feeds the ownership result *after* companion routing.
local root=assert(io.open('xivcrossbar.lua')):read('*a')
local dispatch=root:find('companion_banks:edge(button,pressed)',1,true)
local forward=root:find('npc_owned_input:edge(button,true,companion_banks.owners[button]',1,true)
assert(dispatch and forward and forward>dispatch,'bare intent must be classified after bank dispatch')
assert(root:find('npc_owner=controller_message_bridge.token~=nil',1,true))
local lease=assert(io.open('libs/controller/personal_controls.lua')):read('*a')
assert(lease:find('npc_owner=',1,true) and lease:find('xivcrossbar',1,true))
-- Source bank owner is ordinary ONLY in a genuinely bare path.
local banks=assert(io.open('libs/banks/banks.lua')):read('*a')
assert(banks:find("if self.layer=='' or self.layer=='dialogue' then options.ordinary",1,true))
assert(banks:find("if not layers[self.layer] or not self.eligible then return end",1,true))
print('PASS: owned NPC input: bare Cross/Circle, R1 bank isolation, release, lease and actual bank dispatch order')
