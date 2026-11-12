-- Visibility and controller ownership must not be tied to FFXI event gates.
-- These are Lua policy/mock checks, NOT in-game FFXI acceptance.
local visibility = require('visibility')
local shoulder = require('shoulder_banks')
local function yes(x,label) assert(x,label) end
local function no(x,label) assert(not x,label) end

-- The only optional cinematic hide applies to Show when the character is
-- alive in a non-menu Event state. Status 4 alone is not a cutscene signal.
yes(visibility.cutscene_hidden('always',true,true,100,{chat_open=false,menu_open=false}), 'Show can hide a cutscene')
no(visibility.cutscene_hidden('always',false,true,100,{}), 'Cutscene off leaves Show visible')
no(visibility.cutscene_hidden('oninput',true,true,100,{}), 'Auto ignores Cutscene')
no(visibility.cutscene_hidden('always',true,true,0,{}), 'Death and Raise remain visible')
no(visibility.cutscene_hidden('always',true,true,100,{chat_open=true}), 'Chat is not a cutscene')
no(visibility.cutscene_hidden('always',true,true,100,{menu_open=true}), 'FFXI menu is not a cutscene')
no(visibility.cutscene_hidden('always',true,false,100,{}), 'Ordinary gameplay is not a cutscene')
no(visibility.cutscene_hidden('always',true,true,nil,{}), 'Unknown HP does not hide')
no(visibility.cutscene_hidden('hidden',true,true,100,{}), 'Cutscene cannot override Hide')
yes(visibility.should_show('oninput',true,true,false), 'Held Auto visible in event')
yes(visibility.should_show('oninput',false,true,true), 'Auto startup reveal in event')
no(visibility.should_show('oninput',false,true,false), 'Auto idle hidden')
yes(visibility.should_show('always',false,false,false), 'Show remains visible')
no(visibility.should_show('always',false,true,false), 'Show respects optional Cutscene')
no(visibility.should_show('hidden',true,false,false), 'Hide stays hidden')
assert(visibility.event_mode('always',true,true)=='always', 'Event never demotes Show to Auto')

-- AutoHold is not cancelled by a chat/death/event transition.
local hold={}
no(visibility.update_hold(hold,true,3,0,true), 'Held state is represented by the physical trigger')
yes(visibility.update_hold(hold,false,3,.2,true), 'AutoHold continues after release')
yes(visibility.update_hold(hold,false,3,2,true), 'AutoHold remains until deadline')
no(visibility.update_hold(hold,false,3,3.3,true), 'AutoHold expires normally')

-- Shoulder banks use the same in-world eligibility as trigger banks.
local actor={status=4}
yes(shoulder.slot_context({chat_open=true,menu_open=false},actor), 'L1/R1 in chat')
yes(shoulder.slot_context({chat_open=false,menu_open=true},actor), 'L1/R1 in FFXI menu')
yes(shoulder.slot_context({chat_open=false,menu_open=false},actor), 'L1/R1 in Event status')
yes(shoulder.slot_context({chat_open=true,menu_open=true},{status=2}), 'L1/R1 on death/Raise prompt')
no(shoulder.slot_context(nil,actor), 'No game info is not an in-world bank')
no(shoulder.slot_context({},nil), 'No player cannot select character binding')

print('Cutscene/Auto visibility, hold and unrestricted in-world shoulder context passed.')
