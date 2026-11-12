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
for _,key in ipairs({'set_visibility','set_color','set_size','set_position','set_rounding'}) do
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
assert(load(section('function ui:combat_strip_left','function ui:display_gcd_indicator'),
    'actual skillchain bar','t',env))()
assert(load(section('local function lockout_tint', '-- Separate tracking from opacity'),
    'actual lockout renderer','t',env))()
ui.theme.spell_lockout_opacity=220
ui.theme.spell_lockout_primary_red=200
ui.theme.spell_lockout_primary_green=200
ui.theme.spell_lockout_primary_blue=255
ui.gcd_offset_x,ui.gcd_offset_y,ui.hotbar_spacing=0,0,0
env.gcd_active,env.gcd_start_time,env.gcd_duration,env.gcd_kind=true,clock,3,'spell'
ui:display_gcd_indicator(true)
assert(surface.gcd_indicator and surface.gcd_indicator_bg,'active spell lockout must show')
ui:display_gcd_indicator(false)
assert(not surface.gcd_indicator and not surface.gcd_indicator_bg and env.gcd_active)
ui.theme.spell_lockout_opacity=0
ui:display_gcd_indicator(true)
assert(not surface.gcd_indicator and not surface.gcd_indicator_bg,'zero lockout opacity must hide both')
ui.theme.spell_lockout_opacity=220
clock=clock+3
ui:display_gcd_indicator(true)
assert(not surface.gcd_indicator and not env.gcd_active,'lockout must expire after suppression')
clock=10

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
local function ribbon_color(name)
    for i=#calls,1,-1 do
        local c=calls[i]
        if c[1]=='set_color' and c[2]==name then return table.unpack(c,3,6) end
    end
end
local a,r,g,b=ribbon_color('skillchain_indicator')
assert(a==220 and r==237 and g==28 and b==36, 'Legacy waiting color')
ui.display_palette=require('theme').display_palette('xi')
ui:display_skillchain_indicator({},2,0)
a,r,g,b=ribbon_color('skillchain_indicator')
assert(a==125 and r==255 and g==255 and b==255, 'XI waiting white')
local _,br,bg,bb=ribbon_color('skillchain_indicator_bg')
assert(br==0 and bg==0 and bb==0, 'black waiting border')
ui:display_skillchain_indicator({},0,.275)
a,r,g,b=ribbon_color('skillchain_indicator')
assert(a==220 and r==151 and g==211 and b==255, 'XI open TP blue')
ui:display_skillchain_indicator({},0,.55)
a,r,g,b=ribbon_color('skillchain_indicator')
assert(a==220 and r==255 and g==255 and b==255, 'XI open white')
ui.display_palette=nil
local function last_call(method,name)
    for i=#calls,1,-1 do
        local c=calls[i]
        if c[1]==method and c[2]==name then return c end
    end
end
assert(last_call('set_size','skillchain_indicator')[4]==5)
assert(last_call('set_rounding','skillchain_indicator')[3]==true)
ui:display_skillchain_indicator({},0,1)
assert(last_call('set_size','skillchain_indicator')[4]==10)
assert(last_call('set_rounding','skillchain_indicator')[3]==false)
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
-- Run the actual root visibility branch with the crossbar slots hidden.
local draw_start=assert(code:find('    if ui.is_setup then\n        local lockout_visible',1,true))
local draw_end=assert(code:find('    if visible and ui.is_setup then',draw_start,true))
local allowed
local display_env={ui={is_setup=true,display_gcd_indicator=function(_,value) allowed=value end},
    visibility_mode='oninput',visible=false,xivcrossbar={hide_hotbars=false}}
local draw=assert(load(code:sub(draw_start,draw_end-1),'actual lockout visibility','t',display_env))
draw();assert(allowed,'autohide must allow the lockout strip with no trigger held')
display_env.xivcrossbar.hide_hotbars=true
draw();assert(allowed,'Auto strip remains available during status 4')
display_env.visible=true
draw();assert(allowed,'a visible trigger-held bar can show the strip')
display_env.visibility_mode='hidden'
draw();assert(not allowed,'explicit hide suppresses the strip')
local old_windower=windower
local colors={}
windower={prim={create=function()end,set_color=function(name,alpha) colors[name]=alpha end}}
local geometry=require('ui_geometry').new()
local draw_prim=geometry:prim()
draw_prim.create('normal')
draw_prim.create('lockout',true)
draw_prim.set_color('normal',220,1,2,3)
draw_prim.set_color('lockout',220,1,2,3)
geometry:set_opacity(0)
assert(colors.normal==0 and colors.lockout==220,'only the lockout strip bypasses crossbar opacity')
draw_prim.set_color('lockout',150,1,2,3)
assert(colors.lockout==150,'the strip must still accept explicit opacity')
local sizes, caps, deleted = {}, {}, {}
windower.prim.create=function() end
windower.prim.set_visibility=function(name,visible) caps[name]=visible end
windower.prim.set_size=function(name,w,h) sizes[name]={w,h} end
windower.prim.set_position=function() end
windower.prim.delete=function(name) deleted[name]=(deleted[name] or 0)+1 end
draw_prim.create_rounded('ribbon',true)
draw_prim.set_position('ribbon',0,0)
draw_prim.set_size('ribbon',40,4)
draw_prim.set_color('ribbon',255,255,255,255)
draw_prim.set_visibility('ribbon',true)
assert(caps.ribbon_left_cap and caps.ribbon_right_cap and sizes.ribbon[1]==38)
assert(colors.ribbon_left_cap==255 and colors.ribbon==255)
draw_prim.set_rounding('ribbon',true,false)
assert(not caps.ribbon_right_cap and sizes.ribbon[1]==39)
geometry:set_scale(1.5)
assert(sizes.ribbon[1]==58.5 and sizes.ribbon[2]==6)
geometry:shutdown()
assert(deleted.ribbon==1 and deleted.ribbon_left_cap==1 and deleted.ribbon_right_cap==1)
windower=old_windower

assert(code:find("if command == 'autoattack' then",1,true))

assert(code:find("if ui.aa_enabled and (act.category == CATEGORY_MELEE",1,true))
assert(code:find("if not ui.aa_enabled then return end",1,true))
local command_start=assert(code:find("    if command == 'skillchain' or command == 'lockout'",1,true))
local command_end=assert(code:find("    if command == 'textsettle'",command_start,true))
local command_settings=require('defaults')
local changes=0
local command_env=setmetatable({
    settings=command_settings, theme_options={}, default_skillchain_opacity=220,
    ui={theme={},set_autoattack_enabled=function(_,enabled) command_settings.tracking=enabled end},
    chat_format={say=function() end}, config={save=function() changes=changes+1 end},
},{__index=_G})
local command=assert(load(code:sub(command_start,command_end-1),'strip commands','t',command_env))
local function issue(name,mode)
    command_env.command,command_env.args=name,{mode}
    command()
end
issue('skillchain','255'); assert(command_env.ui.theme.skillchain_window_opacity==255)
issue('lockout','off'); assert(command_settings.LockoutOpacity==0)
issue('lockout','255'); assert(command_env.ui.theme.lockout_opacity==255)
issue('lockout','on'); assert(command_settings.LockoutOpacity==-1)
issue('autoattack','255'); assert(command_settings.tracking and command_env.ui.theme.aa_opacity==255)
issue('autoattack','off'); assert(not command_settings.tracking)
issue('autoattack','on'); assert(command_settings.tracking and command_settings.AutoAttackIndicator.Opacity==255)
issue('autoattack','0'); assert(not command_settings.tracking and command_settings.AutoAttackIndicator.Opacity==0)
issue('autoattack','status'); issue('autoattack','256')
assert(changes==8)
local d=require('defaults')
local theme=require('theme')
assert(d.AutoAttackIndicator.Enabled==false,'New installs must not track swings')
assert(theme.apply(d).aa_enabled==false)
d.AutoAttackIndicator.Enabled=true
assert(theme.apply(d).aa_enabled==true)
d.AutoAttackIndicator.Enabled=false
assert(theme.apply(d).aa_enabled==false,'Saved opt-out stays off')
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
