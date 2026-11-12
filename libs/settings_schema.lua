-- Public XML vocabulary at the storage boundary. Runtime consumers retain the
-- established names; translate each raw scope BEFORE global/character merging.
local M={}
local function copy(t)
    if type(t)~='table' then return t end
    local out={};for k,v in pairs(t)do out[k]=copy(v)end;return out
end
local function key(t,name)
    for k in pairs(t or {})do if tostring(k):lower()==name:lower() then return k end end
end
local function get(t,name) local k=key(t,name);if k then return t[k] end end
local function take(t,name) local k=key(t,name);if k then local v=t[k];t[k]=nil;return v end end
local function put(t,name,value) if value~=nil then take(t,name);t[name]=value end end
local function lower(v) return type(v)=='string' and v:lower() or v end
local function title(v) return type(v)=='string' and v:sub(1,1):upper()..v:sub(2):lower() or v end
local profiles={ps='ps5-directinput',xbox='xinput',xboxrb='xinput-r1-chooser',f710='f710-directinput',fightpad='fightpadpro-directinput'}
local short={['ps5-directinput']='PS',xinput='Xbox',['xinput-r1-chooser']='XboxRB',['f710-directinput']='F710',['fightpadpro-directinput']='FightPad'}
local visibility={show='always',hide='hidden',auto='oninput'}
local public_visibility={always='Show',hidden='Hide',oninput='Auto'}
local top={Controller='ControllerProfile',Device='ControllerDevice',Preset='SettingsPreset',Layout='iscompact',Scale='CrossbarScale',Visibility='VisibilityMode',StartupSet='StartupEnvironment',SharedSet='UseSharedSet'}
local texts={CrossbarLabels='BankLabels',CrossbarLabelOffsetX='BankLabelOffsetX',CrossbarLabelOffsetY='BankLabelOffsetY',LabelOpacity='BankLabelOpacity'}
local slots={Labels='HideActionName',Costs='HideActionCost',RecastText='HideRecastText',RecastAnimation='HideRecastAnimation',Elements='HideActionElement'}
local animations={Fading='Enabled',SlotGlow='SlotGlow',RecastFlash='RecastFlash',TriggerScale='TriggerScale'}
function M.decode(section)
    local t=copy(section or {})
    for new,old in pairs(top)do
        local v=take(t,new)
        if v~=nil then
            if new=='Controller' then v=profiles[lower(v)] or v
            elseif new=='Preset' then v=lower(v)
            elseif new=='Layout' then local s=lower(v);if s=='compact' then v=true elseif s=='full' then v=false else v=nil end
            elseif new=='Visibility' then v=visibility[lower(v)] or v end
            put(t,old,v)
        end
    end
    local a=get(t,'Animation') or {}
    for new,old in pairs(animations)do local v=take(t,new);if v~=nil then put(a,old,v) end end
    if next(a) then put(t,'Animation',a) end
    local x=get(t,'Texts')
    if type(x)=='table' then for new,old in pairs(texts)do local v=take(x,new);if v~=nil then put(x,old,v) end end end
    local bars=take(t,'Crossbar')
    if type(bars)=='table' then
        local h=get(t,'Hotbar') or {}
        for k,v in pairs(bars)do
            local old
            for new,name in pairs(slots)do if lower(k)==lower(new) then old=name;break end end
            if old then put(h,old,not v) else put(h,k,v) end
        end
        put(t,'Hotbar',h)
    end
    local event=get(t,'EventBars')
    if get(t,'Cutscene')==nil and event~=nil then put(t,'Cutscene',not event) end
    take(t,'EventBars')
    -- A newly named Preset owns presentation; old DisplayPreset is accepted on
    -- migration without reapplying any other preset values or personal controls.
    local preset=get(t,'SettingsPreset')
    if preset and get(t,'DisplayPreset')==nil then put(t,'DisplayPreset',lower(preset)=='legacy' and 'legacy' or 'xi') end
    return t
end
function M.finalize(t)
    t.buttonbackgroundalpha=210
    t.AllowSTPCForSelfTargetedActions=true
    t.TextSettling=true
    if t.Hotbar then t.Hotbar.HideBattleNotice=false end
    if t.Animation then
        t.Animation.TextFade=true
        t.Animation.FadeIn=.1;t.Animation.FadeOut=.5;t.Animation.LoadFadeIn=2
    end
    return t
end
local function prune_defaults(t,base)
    for k,v in pairs(t)do
        local expected=get(base,k)
        if type(v)=='table' and type(expected)=='table' then
            prune_defaults(v,expected)
            if not next(v) then t[k]=nil end
        elseif v==expected then t[k]=nil end
    end
end
function M.encode(section,scope)
    local t=copy(section or {})
    -- Derive the public preset from old appearance-only overrides, rather than
    -- silently losing an existing user's selected legacy/modern presentation.
    local preset=get(t,'SettingsPreset')
    local display=take(t,'DisplayPreset')
    if not preset and display then
        preset=display=='legacy' and 'legacy' or 'default'
    elseif display and ((display=='legacy')~=(lower(preset)=='legacy')) then
        -- An existing appearance-only override must not change Me's identity
        -- or personal-control permissions. Retain this exceptional legacy key
        -- until the user explicitly applies a complete preset.
        put(t,'DisplayPreset',display)
    end
    if preset then put(t,'SettingsPreset',preset) end
    for new,old in pairs(top)do
        local v=take(t,old)
        if v~=nil then
            if new=='Controller' then v=short[v] or v
            elseif new=='Preset' then v=title(v)
            elseif new=='Layout' then v=v and 'Compact' or 'Full'
            elseif new=='Visibility' then v=public_visibility[v] or v end
            put(t,new,v)
        end
    end
    local a=get(t,'Animation')
    if type(a)=='table' then
        for new,old in pairs(animations)do put(t,new,take(a,old)) end
        for _,name in ipairs({'TextFade','FadeIn','FadeOut','LoadFadeIn'})do take(a,name)end
        if not next(a) then take(t,'Animation') end
    end
    local x=get(t,'Texts')
    if type(x)=='table' then for new,old in pairs(texts)do put(x,new,take(x,old))end end
    local h=take(t,'Hotbar')
    if type(h)=='table' then
        take(h,'HideBattleNotice')
        for new,old in pairs(slots)do local v=take(h,old);if v~=nil then put(h,new,not v) end end
        put(t,'Crossbar',h)
    end
    -- Hide stock implementation/theme details from the GLOBAL XML only.
    -- Preserve non-default advanced values and every character override: a
    -- character explicitly restoring a stock value must beat a custom global.
    if scope==nil or scope=='global' then
        local base=require('libs/preset_base')
        for _,name in ipairs({'Color','Theme','NativeControllerGuard','NativeDetachOnUnload',
            'InputTest','InputTrace','FrameSkip','AutoCreateXML','TextSettling'})do
            local k=key(t,name)
            if k then
                local value,expected=t[k],get(base,name)
                if type(value)=='table' and type(expected)=='table' then
                    prune_defaults(value,expected);if not next(value) then t[k]=nil end
                elseif value==expected then t[k]=nil end
            end
        end
    end
    for _,name in ipairs({'buttonbackgroundalpha','AllowSTPCForSelfTargetedActions','TextSettling','EventBars','on_unload_killahk'})do take(t,name)end
    return t
end
return M
