-- Beta 1 parity with the already tested personal combat overlay controls.
-- Exercise actual extracted public UI functions with a tiny Windower prim mock.
local f=assert(io.open('ui.lua','rb'));local src=f:read('*a');f:close()
local function section(start,after)
    local a=assert(src:find(start,1,true),'Missing: '..start)
    local b=assert(src:find(after,a+#start,1,true),'Missing end: '..after)
    return src:sub(a,b-1)
end
local clock=10
local pending={}
local surface, calls={},{}
local prim={}
for _,key in ipairs({'set_visibility','set_color','set_size','set_position'}) do
    prim[key]=function(name,...)
        if key=='set_visibility' then surface[name]=select(1,...) end
        calls[#calls+1]={key,name,...}
    end
end
local ui={theme={skillchain_window_opacity=0,
    skillchain_waiting_color_red=237,skillchain_waiting_color_green=28,skillchain_waiting_color_blue=36,
    skillchain_open_color_red=15,skillchain_open_color_green=205,skillchain_open_color_blue=5}}
function ui:get_slot_x()return 20 end
function ui:get_slot_y()return 30 end
function ui:hide_aa_indicator()
    prim.set_visibility('aa_indicator_red',false)
    prim.set_visibility('aa_indicator_green',false)
    prim.set_visibility('aa_indicator_bg',false)
end
local target={hpp=100}
local env=setmetatable({ui=ui,prim=prim,math=setmetatable({round=function(x)return math.floor(x+.5)end},{__index=math}),
    os={clock=function()return clock end},
    coroutine={schedule=function(callback,delay)pending[#pending+1]={callback,delay}end},
    windower={ffxi={get_mob_by_target=function() return target end}}},
    {__index=_G})
-- This block includes the state machine and its explicit on/off guards.
local aa=section('-- Auto-attack swing timer state.','function ui:display_skillchain_indicator')
assert(load(aa,'actual autoattack state','t',env))()
assert(load(section('function ui:set_autoattack_enabled(enabled)','-- Hide all three auto-attack bar primitives.'),
    'actual estimator toggle','t',env))()
assert(load(section('function ui:display_skillchain_indicator','function ui:display_gcd_indicator'),
    'actual skillchain bar','t',env))()
ui.is_setup=false
ui:set_autoattack_enabled(false)
assert(surface.aa_indicator_red==nil,'Fresh disabled install must not touch uncreated prims')
ui.is_setup=true
ui:display_skillchain_indicator({},2,0)
assert(surface.skillchain_indicator==false and surface.skillchain_indicator_bg==false,
    'Zero opacity must hide both skillchain surfaces')
ui.theme.skillchain_window_opacity=220
ui:display_skillchain_indicator({},2,0)
assert(surface.skillchain_indicator==true and surface.skillchain_indicator_bg==true,
    'Enabled indicator must retain normal window display')
ui.theme.skillchain_window_opacity=0
ui:display_skillchain_indicator({},2,0)
assert(surface.skillchain_indicator==false and surface.skillchain_indicator_bg==false,
    'Toggling opacity to zero must hide previously visible primitives')
ui:set_autoattack_enabled(true)
assert(ui.aa_enabled==true and env.aa_estimate==nil)
env.aa_set_engaged(true)
env.aa_record_swing()
clock=13;env.aa_record_swing()
assert(env.aa_estimate and env.aa_estimate>0,'Estimator must learn when enabled')
env.aa_add_pause_source('ws');env.aa_clear_pause_after('ws',2)
local delayed=pending[#pending][1]
ui:set_autoattack_enabled(false)
assert(not ui.aa_enabled and env.aa_last_swing_time==0 and env.aa_estimate==nil)
local before=env.aa_last_swing_time
clock=20;env.aa_record_swing();env.aa_set_engaged(true);env.aa_add_pause_source('ws')
assert(env.aa_last_swing_time==before and env.aa_estimate==nil,
    'Disabled estimator must not record, engage or maintain pauses')
assert(surface.aa_indicator_red==false and surface.aa_indicator_bg==false)
ui:set_autoattack_enabled(true)
env.aa_set_engaged(true)
env.aa_add_pause_source('ws')
delayed()
assert(env.aa_is_paused(),'Old pending callback must not affect restarted estimator')
-- Actual source should gate all three event sources without changing GCD.
local root=assert(io.open('xivcrossbar.lua','rb'))
local code=root:read('*a');root:close()
assert(code:find("if command == 'autoattack' then",1,true))
assert(code:find("settings.AutoAttackIndicator.Enabled=enabled",1,true))
assert(code:find("if ui.aa_enabled and (act.category == CATEGORY_MELEE",1,true))
assert(code:find("if not ui.aa_enabled then return end",1,true))
local d=require('defaults')
local theme=require('theme')
assert(d.AutoAttackIndicator.Enabled==true,'Existing users must retain enabled estimates')
assert(theme.apply(d).aa_enabled==true)
d.AutoAttackIndicator.Enabled=false
assert(theme.apply(d).aa_enabled==false)
-- Check the frame restoration at the exact live conditional in check_recasts.
local restore=section('                    -- Restore base frame even with a warmup','                    -- Show skillchain indicator if WS has a compatible skillchain property')
local frame={alpha_count=0,path_count=0}
function frame:path(path) self.last_path=path;self.path_count=self.path_count+1 end
function frame:alpha(v) self.last_alpha=v;self.alpha_count=self.alpha_count+1 end
local hint={frame_image_path='icons/base.png',hotbars={[1]={slot_frame={[1]=frame}}}}
local reset_env=setmetatable({self=hint,h=1,i=1,skillchain_prop=nil},{__index=_G})
assert(load(restore,'actual skillchain frame restoration','t',reset_env))()
assert(frame.last_path=='icons/base.png' and frame.last_alpha==255)
reset_env.skillchain_prop='Fusion'
assert(load(restore,'actual active skillchain frame','t',reset_env))()
assert(frame.path_count==1,'Valid skillchain hint must retain animation frame')
print('Combat overlay: zero opacity hides both SC bars, disabled swing estimator stops events, stale callbacks isolated, icon frame restored.')


-- The public Options chooser was already calling a personal-only binder method.
-- Run that method against the four saved face-button artwork layouts.
local binder_file=assert(io.open('action_binder.lua','rb'))
local binder_src=binder_file:read('*a');binder_file:close()
local a=assert(binder_src:find('function action_binder:is_cancel_button(button)',1,true))
local b=assert(binder_src:find('function action_binder:create_text(',a,true))
local binder={}
assert(load(binder_src:sub(a,b-1),'actual Options cancel mapping','t',
    setmetatable({action_binder=binder},{__index=_G})))()
for _,pair in ipairs({
    {'playstation','circle','x'},
    {'xbox','b','x'},
    {'nintendo','b','a'},
    {'gamecube','b','b'},
}) do
    binder.button_layout,binder.cancel_button=pair[1],pair[2]
    assert(binder:is_cancel_button(pair[3]),'Options cancel not mapped for '..pair[1])
end
binder.button_layout,binder.cancel_button='playstation','circle'
assert(not binder:is_cancel_button('a'),'Confirm must not cancel chooser')
print('Options chooser physical cancel mapping now resolves all supported layouts.')
