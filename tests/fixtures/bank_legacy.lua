-- Explicit saved pre-batch mappings for backward-compatibility routing tests.
-- Only inherited entries are materialized; imported/custom/cleared slots survive.
local function action(label,kind,value,hold) return {Alias=label,Kind=kind,Command=kind=='command' and value or '',Key=kind=='key' and value or '',Hold=hold==true} end
local factory={}
factory.l1={Closed={action('Wardrobe','command','input /wardrobe'),action('Wardrobe 2','command','input /wardrobe2'),
    action('Equipment','key','ctrl+e'),action('Items','key','ctrl+i'),action('Sack','command','input /sack'),
    action('Jump','command','input /jump'),action('Satchel','command','input /satchel'),action('Case','command','input /case')},
    Menu={action('Previous','key','alt+left'),action('List next','key','ctrl+right'),
    action('Next','key','alt+right'),action('List previous','key','ctrl+left'),action('Bow','command','input /bow'),
    action('Jump','command','input /jump'),action('Nod','command','input /yes'),action('Wave','command','input /wave')}}
factory.r1={Closed={action('Left','key','left',true),action('Down','key','down',true),action('Right','key','right',true),
    action('Up','key','up',true),action('Close Trust','command','trust menu close'),action('Confirm','key','enter'),
    action('Back','key','escape'),action('Open Trust','command','trust menu open')}}
factory.r1.Menu=factory.r1.Closed
-- Guarded NPC steps stay on Confirm/Back. Raw all-client taps are deliberately
-- separate D-pad actions; they bypass SlowEnter's dialogue/choice guards.
factory.r1r2={Closed={action('Call party','command','npcmirror call'),action('Raw Esc all','command','slowenter all once esc'),
    action('NPC status','command','npcmirror status'),action('Raw Enter all','command','slowenter all once'),
    action('Stop NPC','command','npcmirror stop'),action('NPC Enter','command','npcmirror enter'),
    action('NPC Escape','command','npcmirror esc'),action('Interact','command','npcmirror interact')}}
factory.r1r2.Menu=factory.r1r2.Closed

return function(bank)
 for layer,name in pairs({l1='L1',l1l2='L1L2',r1='R1',r1r2='R1R2'}) do
  local b=bank:settings()[name];b.Enabled=true;b.MenuActions=true;b.ShowOnMenu=false
  for _,ctx in ipairs({'Closed','Menu'})do for i=1,8 do
   if b[ctx]['Slot'..i].Kind=='default' then
    local e=factory[layer] and factory[layer][ctx] and factory[layer][ctx][i]
    local v={Alias='',Kind='command',Command='',Key='',Hold=false};for k,x in pairs(e or {})do v[k]=x end
    b[ctx]['Slot'..i]=v
   end
  end end
 end
end

