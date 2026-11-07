-- Exercise the real command and the palette functions with stub drawing fields.
local function read(path)
    local f=assert(io.open(path)); local data=f:read('*a'); f:close(); return data
end
local function extract(source,first,last,result,env)
    local a=assert(source:find(first,1,true)); local b=assert(source:find(last,a,true))
    return assert(load(source:sub(a,b-1)..'\nreturn '..result,result,'t',env))()
end
local theme=require('theme')
local settings=require('defaults')
local saves, refreshes=0,0
local options=theme.apply(settings)
local ui={is_setup=true,geometry={interrupt_startup_reveal=function() end,
    configure_fade=function(self,value) self.enabled=value end,
    set_text_fade=function(self,value) self.text=value end},
    set_slot_pulse_enabled=function(self,value) self.pulses=value end,
    set_display_layout=function(self,palette,value) self.display_palette=palette;self.compact=value end,
    get_set_chooser_anchor=function() return 0,0 end,
    check_vitals=function() refreshes=refreshes+1 end}
local env=setmetatable({settings=settings,theme=theme,theme_options=options,ui=ui,
    crossbar_drag={finish=function() end},env_chooser={set_anchor=function() end},
    chat_format={say=function() end},config={save=function() saves=saves+1 end},
    xivcrossbar={ready=true},player={hotbar_settings={active_environment='basic'}}},{__index=_G})
local handler=extract(read('xivcrossbar.lua'),'local function set_display_preset(', "windower.register_event('mouse'",'set_display_preset',env)
assert(not options.display_palette and not options.slot_pulse_enabled)
handler()
assert(settings.DisplayPreset=='xi' and settings.VisibilityMode=='oninput' and settings.iscompact)
assert(ui.compact and ui.pulses and ui.geometry.enabled and ui.geometry.text and ui.display_palette)
assert(theme.apply(settings).display_palette==ui.display_palette)
handler()
assert(settings.DisplayPreset=='legacy' and settings.VisibilityMode=='always' and settings.iscompact)
assert(not ui.pulses and not ui.geometry.enabled and not ui.geometry.text and not ui.display_palette)
assert(theme.apply(settings).load_fade_in==0)
settings.iscompact=false
handler('legacy'); assert(not settings.iscompact)
handler('xi'); assert(settings.iscompact)
handler('status');handler('invalid')
assert(saves==4 and refreshes==4)

local captured
ui.hotbars={{slot_cost={{color=function(_,...) captured={...} end}}}}
ui.theme={mp_cost_color_red=230,mp_cost_color_green=91,mp_cost_color_blue=151}
local code=read('ui.lua')
extract(code,'function ui:set_action_cost_color','-- check player vitals','ui',env)
ui:set_action_cost_color(1,1,'mp',false);assert(captured[1]==194 and captured[2]==253)
ui:set_action_cost_color(1,1,'mp',true);assert(captured[1]==255 and captured[2]==149)
ui:set_action_cost_color(1,1,'tp',false);assert(captured[3]==255 and captured[2]==211)
ui.theme.hotbar_number=1
ui.disabled_slots={no_vitals={},actions={},on_cooldown={},on_warmup={}}
ui.toggle_slot=function() end
env.maybe_get_default_action=function() end
env.crossbar_abilities={['test-ws']={tp_cost=1000}}
env.kebab_casify=function(name) return name end
extract(code,'function ui:check_vitals','gcd_start_time = 0','ui',env)
local bars={basic={hotbar_1={slot_1={type='ws',action='test-ws'}}}}
ui:check_vitals(bars,{mp=0,tp=999},'basic');assert(captured[1]==255 and captured[2]==149)
ui:check_vitals(bars,{mp=0,tp=1000},'basic');assert(captured[1]==151 and captured[2]==211)
ui.display_palette=nil
ui:set_action_cost_color(1,1,'mp',false);assert(captured[1]==230 and captured[2]==91)
local round=math.round
math.round=function(value) return math.floor(value+.5) end
local tint=extract(code,'local function lockout_tint','function ui:display_gcd_indicator','lockout_tint',env)
local palette=theme.display_palette('xi')
local function same(kind, remaining, color)
    local r,g,b=tint(palette,kind,remaining);assert(r==color[1] and g==color[2] and b==color[3])
end
same('ma',1,palette.lockout_start);same('ma',0,palette.mp)
same('ws',0,palette.ws);same('ja',0,palette.tp)
math.round=round
print('Display toggle, saved preset, compact asymmetry, live refresh, cost colors and lockout tint passed.')
