-- Fresh-install defaults and saved override behavior for public Beta 1.
local d=require('defaults')
local theme=require('theme')
local visibility=require('visibility')
local controller=require('controller_transport')
assert(d.GameplayDPad=='ijkl','Fresh-install bare D-pad must be IJKL')
assert(d.VisibilityMode=='oninput','Fresh-install bars must be trigger visible')
assert(d.Animation.TextFade==true,'Text must fade with artwork by default')
assert(d.Animation.Enabled==true,'Main fade must remain on')
assert(d.Animation.FadeIn==.1 and d.Animation.FadeOut==.5
    and d.Animation.LoadFadeIn==2,'Fade timings must not change')
assert(d.TextSettling==true,'Measurement stabilization must stay enabled')
assert(d.AutoAttackIndicator.Enabled==false,'Tracking disabled by default')
assert(d.AutoAttackIndicator.Opacity==0,'Swing bar hidden by default')
assert(theme.apply(d).aa_enabled==false and theme.apply(d).text_fade==true)
assert(controller:gameplay_key({arrow='up'}, {},d.GameplayDPad)=='i')
assert(controller:gameplay_key({arrow='left'}, {},d.GameplayDPad)=='j')
assert(controller:gameplay_key({arrow='down'}, {},d.GameplayDPad)=='k')
assert(controller:gameplay_key({arrow='right'}, {},d.GameplayDPad)=='l')
assert(not visibility.should_show(d.VisibilityMode,false,false,false),
    'No visible bar with released trigger and no startup reveal')
assert(visibility.should_show(d.VisibilityMode,true,false,false))
assert(visibility.should_show(d.VisibilityMode,false,false,true),
    'Startup reveal still visible')
assert(not visibility.should_show(d.VisibilityMode,true,true,false),
    'Cutscenes suppress bar')
-- Simulate saved values taking precedence after config has merged settings.
local previous_fade,previous_tracking=d.Animation.TextFade,d.AutoAttackIndicator.Enabled
d.Animation.TextFade,d.AutoAttackIndicator.Enabled=false,true
assert(theme.apply(d).text_fade==false and theme.apply(d).aa_enabled==true,
    'User-chosen opposite values must remain effective')
d.Animation.TextFade,d.AutoAttackIndicator.Enabled=previous_fade,previous_tracking
assert(visibility.should_show('always',false,false,false),
    'User-selected always-visible mode must remain supported')
assert(controller:gameplay_key({arrow='up'}, {},'arrows')=='up',
    'User-selected legacy D-pad mode must remain supported')
-- No timer has yet been added: this regression deliberately documents the
-- current immediate hide after trigger release (plus existing fade-out).
assert(not visibility.should_show('oninput',false,false,false))
print('Beta defaults: IJKL, oninput, text fade ON, swing tracking OFF, override modes and old fade durations passed.')

-- Public MP-cost color parity and repeated main-bar feedback regression.
local source_file=assert(io.open('ui.lua','rb'))
local ui_source=source_file:read('*a');source_file:close()
local function extract(start_token,end_token)
    local a=assert(ui_source:find(start_token,1,true),'missing function '..start_token)
    local b=assert(ui_source:find(end_token,a+#start_token,1,true),'missing end marker '..end_token)
    return ui_source:sub(a,b-1)
end
assert(d.Color.MpCost.Red==194 and d.Color.MpCost.Green==253 and d.Color.MpCost.Blue==195)
assert(d.Color.MpCostInsufficient.Red==255 and d.Color.MpCostInsufficient.Green==149 and d.Color.MpCostInsufficient.Blue==151)
local opts=theme.apply(d)
assert(opts.mp_cost_insufficient_red==255 and opts.mp_cost_color_green==253)
local slot_cost={color=function(self,r,g,b)self.last={r,g,b}end}
local tester={theme=opts,hotbars={[1]={slot_cost={[1]=slot_cost}}}}
local env=setmetatable({ui=tester},{__index=_G})
assert(load(extract('function ui:set_mp_cost_color','-- check player vitals'),'MP cost helper','t',env))()
tester:set_mp_cost_color(1,1,false)
assert(table.concat(slot_cost.last,',')=='194,253,195','affordable MP green')
tester:set_mp_cost_color(1,1,true)
assert(table.concat(slot_cost.last,',')=='255,149,151','insufficient MP pink')
assert(ui_source:find('self:set_mp_cost_color(h, i, can_afford_mp)',1,true),
    'MP must recover from pink to green without rebuilding the slot')
assert(ui_source:find('self:set_mp_cost_color(hotbar, slot, player_vitals.mp < crossbar_action.mp_cost)',1,true),
    'initial slot color must reflect affordability')
local feedback_code=extract('function ui:trigger_feedback','return ui')
local feedback={max_opacity=150,current_opacity=0,is_active=false,speed=90}
local feedback_icon={pos=function()end,alpha=function(self,a)self.last=a end,show=function(self)self.visible=true end,
    hide=function(self)self.visible=false end}
tester.feedback=feedback;tester.feedback_icon=feedback_icon
function tester:get_slot_x()return 0 end
function tester:get_slot_y()return 0 end
assert(load(feedback_code,'actual slot feedback functions','t',env))()
tester:trigger_feedback(1,1)
assert(feedback.current_opacity==150)
tester:show_feedback();assert(feedback_icon.last==60)
tester:trigger_feedback(1,1);assert(feedback.current_opacity==150,'repeat press must restart')
tester:show_feedback();tester:show_feedback()
assert(feedback_icon.last==0 and not feedback.is_active,'fade must clamp and finish')
print('Public MP cost color parity and feedback retrigger/opacity clamp passed.')
