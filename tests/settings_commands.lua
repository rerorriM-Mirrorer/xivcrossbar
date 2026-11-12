-- Actual command callback with only its external effects replaced.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local first=assert(source:find("windower.register_event('addon command', function(command, ...)",1,true))
local last=assert(source:find('local shifted_keys',first,true))
local settings=require('libs/settings_presets').values('me')
local handler,saves,reloads,selected,layout
local lines={};saves=0;reloads=0
local function noop()end
local env=setmetatable({settings=settings,theme_options={},controller_profiles=require('controller_profiles'),
    windower={register_event=function(_,fn)handler=fn end},
    chat_format={say=function(_,s)lines[#lines+1]=s end},
    config={save=function()saves=saves+1 end},graceful_restart=function()reloads=reloads+1 end,
    select_controller_profile=function(name,device)selected={name,device} end,
    set_compact_mode=function(v)layout=v end,
    ui={set_bank_labels_visible=noop,set_bank_label_offset=noop,set_bank_label_opacity=noop,
        geometry={configure_fade=noop},},diagnostic={record=noop},
},{__index=_G})
assert(load(source:sub(first,last-1),'real friendly settings commands','t',env))()
handler('layout','full');assert(layout=='off')
handler('layout','compact');assert(layout=='on')
handler('layout','tight');assert(layout=='on','deferred layout cannot change geometry')
handler('controller','ps',2);assert(selected[1]=='ps' and selected[2]==2)
assert(settings.ShoulderBanks.PersonalControls.CameraZoom and settings.ShoulderBanks.PersonalControls.TouchpadMap)
handler('crossbars',6);assert(settings.Hotbar.Number==6 and reloads==1)
handler('crossbars',8);assert(settings.Hotbar.Number==6 and reloads==1)
handler('crossbarlabels','off');assert(settings.Texts.BankLabels==false)
handler('banklabels','on');assert(settings.Texts.BankLabels==true)
handler('labelopacity',85);assert(settings.Texts.BankLabelOpacity==85)
handler('banklabelopacity',60);assert(settings.Texts.BankLabelOpacity==60)
local before=saves;handler('fading','status');assert(saves==before)
handler('fading','off');assert(settings.Animation.Enabled==false)
handler('fade','on');assert(settings.Animation.Enabled==true)
handler('preset','legacy');assert(settings.SettingsPreset=='legacy' and not settings.Texts.BankLabels)
handler('preset','me');assert(settings.SettingsPreset=='me' and settings.ShoulderBanks.PersonalControls.CameraZoom and settings.ShoulderBanks.PersonalControls.TouchpadMap)
handler('preset','unknown');assert(settings.SettingsPreset=='me')
for _,line in ipairs(lines)do assert(not line:find('[\128-\255]'),'new feedback must be ASCII')end
print('Friendly settings commands: actual callback, old aliases, legal crossbar counts, preset/layout/fading validation and personal-control isolation passed.')
