local status_format=require('libs/chat_status')
-- A: saved companion definitions and the single physical-input owner. Rendering
-- reads these same entries. The old L1 section remains untouched for recovery.
local M={buttons={'Left','Down','Right','Up','Square','Cross','Circle','Triangle'}}
local slot_for={[4]=1,[3]=2,[2]=3,[1]=4,[6]=5,[5]=6,[7]=7,[8]=8}
local layers={l1='L1',l1l2='L1L2',r1='R1',r1r2='R1R2'}
local prefixes={l1='L1',l1l2='L1 + L2',r1='R1',r1r2='R1 + R2'}
local layer_aliases={l='l1',r='r1',l2='l1l2',r2='r1r2'}
local titles={l1='L1  Party',l1l2='L1 + L2  Available',r1='R1  NPC',r1r2='R1 + R2  Available'}
M.aliases={l1l2=true,r1=true,r1r2=true} -- l1 retains its older L1L2 editor meaning
local function clone(t) local r={};for k,v in pairs(t) do r[k]=type(v)=='table' and clone(v) or v end;return r end
local function action(label,kind,value,hold)
    return {Alias=label,Kind=kind,Command=kind=='command' and value or '',Key=kind=='key' and value or '',Hold=hold==true}
end
local function empty() return action('','command','') end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function inherited() return {Alias='',Kind='default',Command='',Key='',Hold=false} end
local factory={}
-- A: Cioara's supplied October 23 L1 layout, with no fixed character names.
factory.l1={Closed={action('Back','command','switch p'),action('Call','command','npc call'),
    action('Next','command','switch next'),action('Leader','command','switch p1'),
    action('Trust','command','trust menu'),
    action('Ready','command','send @others trust start; input /echo Asked party to stand ready!'),
    action('Stand Down','command','send @all trust stop; input /echo Asked party to stand down!'),
    action('Toggle','command','trust toggle')}}
factory.l1.Menu=factory.l1.Closed
factory.r1={Closed={action('Left','command','npc raw left'),action('Down','command','npc raw down'),
    action('Right','command','npc raw right'),action('Up','command','npc raw up'),
    action('Raw Enter','command','npc raw enter'),action('Enter','command','npc enter'),
    action('Cancel','command','npc cancel'),action('Interact','command','npc interact')}}
factory.r1.Menu=factory.r1.Closed
-- Empty second levels are disabled independently of drawing; a shoulder-first
-- extra trigger keeps its first-level bank, while trigger-first stays ordinary.
function M.factory(layer,slot,menu)
    local bank=factory[layer];local entries=bank and bank[menu and 'Menu' or 'Closed']
    return clone(entries and entries[slot] or empty())
end
local function same(a,b)
    for _,field in ipairs({'Alias','Kind','Command','Key','Hold'}) do if a[field]~=b[field] then return false end end
    return true
end
function M.defaults()
    -- Windower config lowercases XML tags and restores their spelling from
    -- defaults. Declare the whole shape, including empty strings/booleans, so
    -- a fresh process can reload saved banks without losing names or types.
    local d={Version=0,Preset=''}
    for _,name in pairs(layers) do
        d[name]={Closed={},Menu={},Display='held',Enabled=name=='L1' or name=='R1',Visible=true,ShowOnMenu=true,MenuActions=false,AllowCutscenes=false,Title=''}
        for _,context in ipairs({'Closed','Menu'}) do for i=1,8 do
            d[name][context]['Slot'..i]={Alias='',Kind='',Command='',Key='',Hold=false}
        end end
    end
    for _,side in ipairs({'Left','Right'}) do
        d[side..'Panel']={X=side=='Left' and 24 or 1000000,Y=70,Scale=1,FollowCrossbar=true,Locked=true,Initialized=false}
    end
    return d
end
function M.ensure(settings)
    local d=settings.CompanionBanks
    if type(d)~='table' then d={Version=0};settings.CompanionBanks=d end
    d.Preset=type(d.Preset)=='string' and d.Preset or ''
    local version=tonumber(d.Version) or 0
    local migrate=version<2
    for layer,name in pairs(layers) do
        if type(d[name])~='table' then d[name]={} end
        local b=d[name]
        if b.Enabled==nil then b.Enabled=name=='L1' or name=='R1' end
        b.Enabled=b.Enabled==true
        b.Display=b.Display=='always' and 'always' or 'held'
        b.Visible=b.Visible~=false;b.ShowOnMenu=b.ShowOnMenu~=false
        b.MenuActions=b.MenuActions==true;b.Title=type(b.Title)=='string' and b.Title or ''
        b.AllowCutscenes=b.AllowCutscenes==true
        for _,context in ipairs({'Closed','Menu'}) do
            if type(d[name][context])~='table' then d[name][context]={} end
            for i=1,8 do
                local key='Slot'..i
                local current=d[name][context][key]
                if type(current)~='table' or current.Kind=='' and current.Alias=='' and current.Command=='' and current.Key=='' then
                    local entry=inherited()
                    if version==0 then
                        if name=='L1L2' and context=='Closed' then
                            local old=type(settings.L1)=='table' and settings.L1[key]
                            if type(old)=='table' and ((old.Alias or '')~='' or (old.Command or '')~='') then
                                entry=action(old.Alias or '', 'command',old.Command or '')
                            end
                        end
                    end
                    d[name][context][key]=entry
                end
                local e=d[name][context][key]
                for _,field in ipairs({'Alias','Command','Key'}) do if type(e[field])~='string' then e[field]='' end end
                if e.Kind~='key' and e.Kind~='command' and e.Kind~='default' then e.Kind='command' end
                e.Hold=e.Hold==true
                if version==1 and ((name=='L1' or name=='R1') and same(e,M.factory(layer,i,context=='Menu'))
                    or name=='R1R2' and e.Kind=='command' and e.Alias=='' and e.Command=='' and e.Key=='') then
                    d[name][context][key]=inherited()
                end
            end
        end
    end
    for _,side in ipairs({'Left','Right'}) do
        local panel=side..'Panel'
        if type(d[panel])~='table' or migrate and d[panel].Initialized==false then
            local old=side=='Left' and type(settings.L1)=='table' and settings.L1 or {}
            d[panel]={X=old.X or (side=='Left' and 24 or 1000000),Y=old.Y or 70,
                Scale=old.Scale or 1,FollowCrossbar=old.FollowCrossbar~=false,Locked=old.Locked~=false}
        end
        local p=d[panel]
        p.X=finite(p.X) and p.X or 24;p.Y=finite(p.Y) and p.Y or 70
        p.Scale=finite(p.Scale) and math.max(.4,math.min(2,p.Scale)) or 1
        p.FollowCrossbar=p.FollowCrossbar~=false;p.Locked=p.Locked~=false
        p.Initialized=true
    end
    d.Version=2
    return d,migrate
end
function M.new(options)
    local self={down={},owners={},blocked={},layer='',menu=false,eligible=false,executed=0,empty=0,
        previews={},output=require('libs/banks/output').new({clock=options.clock})}
    self.feedback=require('libs/banks/feedback').new(options.clock)
    self.migrated=select(2,M.ensure(options.settings))
    local normalized=options.settings.CompanionBanks
    function self:settings()
        if normalized~=options.settings.CompanionBanks then normalized=M.ensure(options.settings) end
        return normalized
    end
    function self:cutscene_enabled()
        for _,name in pairs(layers) do
            local b=self:settings()[name]
            if b.Enabled and b.AllowCutscenes then return true end
        end
        return false
    end
    function self:stored_entry(layer,slot,menu) return self:settings()[layers[layer]][menu and 'Menu' or 'Closed']['Slot'..slot] end
    function self:uses_menu(layer,menu)
        return menu==true and self:settings()[layers[layer]].MenuActions~=false
    end
    function self:entry(layer,slot,menu)
        local e=self:stored_entry(layer,slot,menu)
        return e.Kind=='default' and M.factory(layer,slot,menu) or e
    end
    function self:release_slots()
        self.feedback:cancel()
        local retained={}
        for button,owner in pairs(self.owners) do
            if button>8 then retained[button]=owner
            elseif owner=='ordinary' then options.ordinary(button,false) end
        end
        self.owners=retained;self.output:release()
        for i=1,8 do if self.down[i] then self.blocked[i]=true end end
    end
    function self:cancel()
        self:release_slots();self.output:cancel()
        self.down={};self.owners={};self.blocked={};self.layer='';self.left=false;self.right=false
        self.tailL=false;self.tailR=false;self.r1used=true
    end
    function self:choose_layer()
        local d=self.down
        if not self.eligible or d[9] or d[10] then return '' end
        if self.tailL or self.tailR then return 'tail' end
        if d[11] and not (d[13] and self.left) or d[12] and not (d[14] and self.right) then return '' end
        if d[13] and d[14] then return 'pair' end
        if d[13] then
            if d[11] and self:settings().L1L2.Enabled then return 'l1l2' end
            return self:settings().L1.Enabled and 'l1' or 'blocked'
        end
        if d[14] then
            if d[12] and self:settings().R1R2.Enabled then return 'r1r2' end
            return self:settings().R1.Enabled and 'r1' or 'blocked'
        end
        return ''
    end
    function self:choose()
        local layer=self:choose_layer()
        -- Dialogue permits bare navigation, never trigger actions or shortcuts.
        -- Chat retains its separate typing owner. Explicit banks work in both.
        if (self.cutscene or self.chat) and not layers[layer] then
            if self.cutscene and not self.chat and layer=='' then
                local modified=false
                for button=9,14 do if self.down[button] then modified=true end end
                if not modified then return 'dialogue' end
            end
            return 'blocked'
        end
        return layer
    end
    function self:refresh()
        local eligible,menu,cutscene,chat=options.context()
        chat=chat==true
        cutscene=cutscene==true
        if self.eligible and not eligible then
            self:release_slots();self.output:cancel();self.r1used=true
        elseif self.menu~=menu or self.cutscene~=cutscene or self.chat~=chat then
            self:release_slots();self.output:cancel();self.r1used=true
        end
        self.eligible,self.menu,self.cutscene,self.chat=eligible,menu,cutscene,chat
        local layer=self:choose()
        if layer~=self.layer then self:release_slots();self.layer=layer end
    end
    function self:edge(button,pressed)
        self:refresh()
        local before=self.layer
        local used=self.r1used
        if pressed==not not self.down[button] then return end
        self.down[button]=pressed or nil
        if not pressed then self.feedback:release(button) end
        if button==13 then
            if pressed then self.left=not self.down[11]
            else self.tailL=self.left and self.down[11] or false;self.left=false end
        elseif button==14 then
            if pressed then
                self.right=not self.down[12];self.r1used=false
                for i=1,13 do if self.down[i] then self.r1used=true end end
            else self.tailR=self.right and self.down[12] or false;self.right=false end
        elseif button==11 and not pressed then self.tailL=false;if self.down[13] then self.left=true end
        elseif button==12 and not pressed then self.tailR=false;if self.down[14] then self.right=true end end
        if pressed and button~=14 and self.down[14] then self.r1used=true end
        -- Finish the original ordinary owner even after a context/layer change.
        if not pressed and self.owners[button]=='ordinary' then
            options.ordinary(button,false);self.owners[button]=nil
        elseif not pressed and type(self.owners[button])=='table' then
            local key=self.owners[button].Key;self.owners[button]=nil
            local other=false
            for _,owner in pairs(self.owners) do if type(owner)=='table' and owner.Key==key then other=true end end
            if not other then self.output:edge(key,false) end
        end
        self:refresh()
        if pressed and self.layer=='pair' and before~='pair' and not self.resuming then
            self.r1used=true
            local slots=false;for i=1,12 do if self.down[i] then slots=true end end
            if self.eligible and not slots then self.output:pulse('tab') end
        elseif button==14 and not pressed and not used and before=='r1' and self.eligible and not self.cutscene and not self.chat then
            self.output:pulse('r')
        end
        if button>=13 then return end
        if button>=9 then
            if pressed and not self.cutscene and not self.chat and (button<=10 or self.layer=='') then
                options.ordinary(button,true);self.owners[button]='ordinary'
            end
            return
        end
        if not pressed then self.blocked[button]=nil;return end
        if self.blocked[button] then return end
        -- Bare Cancel dismisses native chat; modified bank actions are unchanged.
        if self.chat and self.eligible and self.layer=='blocked' and options.chat_cancel and options.chat_cancel(button) then
            local modified=false
            for i=9,14 do if self.down[i] then modified=true end end
            if not modified then options.ordinary(button,true);self.owners[button]='ordinary';return end
        end
        if self.layer=='' or self.layer=='dialogue' then options.ordinary(button,true);self.owners[button]='ordinary';return end
        if not layers[self.layer] or not self.eligible then return end
        self.feedback:press(button,self.layer,slot_for[button])
        local e=self:entry(self.layer,slot_for[button],self:uses_menu(self.layer,self.menu))
        if e.Kind=='key' and require('libs/banks/keys').parse(e.Key) then
            -- Native navigation can hold. Pulses retain both edges even if the
            -- physical release happened before AHK read the next Lua frame.
            local _,_,key=require('libs/banks/keys').parse(e.Key)
            local held=self.output.held[key]
            self.output:edge(key,true)
            if e.Hold then self.owners[button]=clone(e);self.owners[button].Key=key
            elseif not held then self.output:edge(key,false) end
            self.executed=self.executed+1
        elseif e.Kind=='command' and e.Command:match('%S') then
            self.executed=self.executed+1;options.execute(e.Command)
        else self.empty=self.empty+1 end
    end
    function self:resume(button)
        -- Restore only held controls, in their original order. No slot, Tab or
        -- unused-R release may be synthesized by recovering a lost session.
        if button<11 or button>14 then return end
        self.resuming=true;self:edge(button,true);self.resuming=false;self.r1used=true
    end
    function self:panel(side)
        local parent=self
        local names=side=='Left' and {l1=true,l1l2=true} or {r1=true,r1r2=true}
        local function selected()
            local preview=parent.previews[side]
            return names[parent.layer] and parent.layer or preview and options.clock()<preview.until_time and preview.layer or (side=='Left' and 'l1' or 'r1')
        end
        local proxy=setmetatable({}, {__index=function(_,key)return parent:settings()[side..'Panel'][key] end,
            __newindex=function(_,key,value) parent:settings()[side..'Panel'][key]=value end})
        return {
            feedback=function(_,slot) return parent.feedback:alpha(selected(),slot) end,
            settings=function() local layer=selected()
                for i=1,8 do rawset(proxy,'Slot'..i,parent:entry(layer,i,parent:uses_menu(layer,parent.menu))) end;return proxy end,
            mode=function() return selected() end,
            title=function(_,mode) local title=parent:settings()[layers[mode]].Title
                return title~='' and title or titles[mode] end,
            opacity=function(_,eligible)
                local preview=parent.previews[side];local b=parent:settings()[layers[selected()]]
                local showing=preview and options.clock()<preview.until_time and selected()==preview.layer
                local editing=showing and preview.editing
                local held=names[parent.layer] and parent.layer==selected()
                -- A controller menu may own actions without hiding a held
                -- primary bank. Drawing never grants permission to execute.
                if not parent.eligible and selected()==(side=='Left' and 'l1' or 'r1') then
                    held=side=='Left' and parent.down[13] and parent.left and not parent.down[14]
                        or side=='Right' and parent.down[14] and parent.right and not parent.down[13]
                end
                return eligible and (editing or b.Enabled and b.Visible) and (editing or not parent.menu or b.ShowOnMenu)
                    and (showing or b.Display=='always' or held) and 1 or 0
            end,
        }
    end
    function self:swap(a,b)
        if not layers[a] or not layers[b] or a==b then return false end
        local function materialize(layer)
            local result=clone(self:settings()[layers[layer]])
            if result.Title=='' then result.Title=titles[layer] end
            for _,context in ipairs({'Closed','Menu'}) do for i=1,8 do
                result[context]['Slot'..i]=clone(self:entry(layer,i,context=='Menu'))
            end end
            return result
        end
        local first,second=materialize(a),materialize(b)
        -- Inherited entries must retain their original meaning at a new layer.
        self:settings()[layers[a]],self:settings()[layers[b]]=second,first
        for _,pair in ipairs({{a,b},{b,a}}) do
            local layer,source=pair[1],prefixes[pair[2]]
            local bank=self:settings()[layers[layer]]
            if bank.Title:sub(1,#source)==source then bank.Title=prefixes[layer]..bank.Title:sub(#source+1) end
        end
        return true
    end
    function self:previewing(side)
        return self.previews[side] and options.clock()<self.previews[side].until_time or false
    end
    function self:help()
        for _,row in ipairs({
            {'bank <layer> status [details]','Show panel state; details lists normal/menu bindings.'},
            {'bank l2|r2 <command>','Aliases for bank l1l2 and bank r1r2; bindings are shared.'},
            {'bank l|r <command>','Aliases for bank l1 and bank r1.'},
            {'bank <layer> enable|disable','Enable input/drawing, or disable this layer without deleting its bindings.'},
            {'bank <layer> display held|always','Draw while held (default), or keep this bank visible at rest.'},
            {'bank <layer> show|hide','Draw or hide this bank; its controls stay active.'},
            {'bank <layer> edit on|off','Pin/unlock this bank for mouse-only dragging; off hides preview and locks.'},
            {'bank swap <layer> <layer>','Exchange current bindings and visibility policies; positions stay put.'},
            {'bank <layer> menus on|off','Allow this bank to draw over native game menus.'},
            {'bank <layer> menuactions on|off','Use menu bindings automatically, or always use Closed bindings.'},
            {'bank <layer> cutscenes on|off','Legacy setting retained for compatibility; held banks now work during dialogue.'},
            {'bank preset cioara apply','Apply Party/NPC defaults; clear/disable second levels; keep positions.'},
            {'bank <layer> [menu] <button> <label> <command...>','Assign a console command; layer: l1, l1l2, r1, r1r2.'},
            {'bank <layer> [menu] key <button> <label> <key> [hold]','Native key, e.g. ctrl+i or alt+left; pulse by default.'},
            {'bank <layer> [menu] clear <button>','Reserve a slot without executing anything.'},
            {'bank <layer> [menu] default <button>','Remove one override; use its shipped action and label.'},
            {'bank <layer> [menu] defaults','Restore all eight actions in that context; keep panel layout.'},
            {'bank <layer> preview|lock|unlock|resetpos','Preview for six seconds or change the shared side panel.'},
            {'bank <layer> scale crossbar|<0.4-2>','Follow main crossbar scale, or set a panel scale.'},
            {'bank <layer> pos <x> <y>','Move the shared left/right panel.'},
        }) do options.help(row[1],row[2]) end
    end
    function self:summary(layer)
        local b=self:settings()[layers[layer]]
        options.say(status_format.row(layer:upper(),'Enabled: '..status_format.toggle(b.Enabled)..' | Draw: '..status_format.toggle(b.Visible)..
            ' | Draw in Menus: '..status_format.toggle(b.ShowOnMenu)..
            ' | Menu Input: '..status_format.toggle(b.Enabled)..' | Bindings in Menus: '..(b.MenuActions and 'Menu' or 'Normal')..
            ' | Display: '..(b.Display=='always' and 'Always' or 'Held')))
    end
    function self:status(layer,details)
        local b=self:settings()[layers[layer]]
        options.say(status_format.heading('XIVCrossbar | '..layer:upper()..' bank'))
        self:summary(layer)
        local p=self:settings()[(layer:sub(1,1)=='l' and 'Left' or 'Right')..'Panel']
        options.say(status_format.row('Position','//xb bank '..layer..' pos '..tostring(p.X)..' '..tostring(p.Y)))
        options.say(status_format.row('Panel','Scale: '..tostring(p.Scale)..' | Follow Crossbar: '..status_format.toggle(p.FollowCrossbar)..' | Locked: '..status_format.toggle(p.Locked)))
        if not details then options.say(status_format.notice('Bindings: //xb bank '..layer..' status details'));return end
        options.say(status_format.row('Input','Active Layer: '..(self.layer~='' and self.layer:upper() or 'Ordinary')..
            ' | Native Menu: '..status_format.toggle(self.menu)))
        for _,context in ipairs({'Closed','Menu'}) do
            options.say(status_format.heading(context=='Menu' and 'Menu Bindings' or 'Normal Bindings'))
            for i,name in ipairs(M.buttons) do
                local e=self:entry(layer,i,context=='Menu')
                local source=self:stored_entry(layer,i,context=='Menu').Kind=='default' and 'default' or 'override'
                options.say(status_format.row(name,e.Alias..' | '..(e.Kind=='key' and e.Key..(e.Hold and ' hold' or '') or e.Command)..' | '..source))
            end
        end
    end
    function self:command(args)
        local normalized={};for i,value in ipairs(args) do normalized[i]=value end
        args=normalized
        for _,i in ipairs(args[1]=='swap' and {2,3} or {1}) do
            local name=type(args[i])=='string' and args[i]:lower()
            if layer_aliases[name] then args[i]=layer_aliases[name] end
        end
        local layer=(args[1] or ''):lower()
        if layer=='swap' then
            if args[4] or not layers[args[2]] or not layers[args[3]] or args[2]==args[3] then self:help();return false end
            self:release_slots();self.output:cancel();self.r1used=true
            self:swap(args[2],args[3]);options.save();options.say(status_format.notice('Swapped '..args[2]:upper()..' and '..args[3]:upper()..' bindings and visibility.'));return true
        end
        if layer=='preset' then
            if args[2]~='cioara' or args[3]~='apply' or args[4] then self:help();return false end
            self:release_slots();self.output:cancel();self.r1used=true
            require('libs/banks/presets').cioara(self)
            options.save();options.say(status_format.notice('Party/NPC preset applied; second levels cleared and disabled; positions preserved.'));return true
        end
        if not layers[layer] then self:help();return false end
        local offset=args[2]=='menu' and 1 or 0;local menu=offset==1
        local op=(args[2+offset] or 'status'):lower()
        local side=layer:sub(1,1)=='l' and 'Left' or 'Right';local p=self:settings()[side..'Panel']
        local changed=false
        if op=='help' then self:help();return
        elseif op=='status' then
            if args[3] and args[3]~='details' then self:help();return false end
            self:status(layer,args[3]=='details');return
        elseif op=='edit' and offset==0 and not args[4] and (args[3]=='on' or args[3]=='off') then
            local enabled=args[3]=='on';p.Locked=not enabled
            self.previews[side]=enabled and {layer=layer,until_time=math.huge,editing=true} or nil
            changed=true
        elseif op=='display' and offset==0 and not args[4] and (args[3]=='held' or args[3]=='always') then
            self:settings()[layers[layer]].Display=args[3];changed=true
        elseif (op=='enable' or op=='disable') and offset==0 and not args[3] then
            self:settings()[layers[layer]].Enabled=op=='enable';changed=true
        elseif (op=='show' or op=='hide') and offset==0 and not args[3] then
            self:settings()[layers[layer]].Visible=op=='show';changed=true
            if op=='hide' and self.previews[side] and self.previews[side].layer==layer then self.previews[side]=nil end
        elseif (op=='menus' or op=='menuactions' or op=='cutscenes') and offset==0 and not args[4] and (args[3]=='on' or args[3]=='off') then
            local field=op=='menus' and 'ShowOnMenu' or op=='menuactions' and 'MenuActions' or 'AllowCutscenes'
            self:settings()[layers[layer]][field]=args[3]=='on';changed=true
        elseif op=='defaults' and not args[3+offset] then
            for i=1,8 do self:settings()[layers[layer]][menu and 'Menu' or 'Closed']['Slot'..i]=inherited() end
            changed=true
        elseif op=='preview' then self.previews[side]={layer=layer,until_time=options.clock()+6};return
        elseif op=='lock' or op=='unlock' then p.Locked=op=='lock';changed=true
        elseif op=='resetpos' then p.X,p.Y=side=='Left' and 24 or 1000000,70;changed=true
        elseif op=='scale' then
            local v=args[3+offset];local n=tonumber(v)
            if v=='crossbar' then p.FollowCrossbar=true;changed=true
            elseif finite(n) and n>=.4 and n<=2 then p.Scale=n;p.FollowCrossbar=false;changed=true end
        elseif op=='pos' then
            local x,y=tonumber(args[3+offset]),tonumber(args[4+offset])
            if finite(x) and finite(y) then p.X,p.Y=x,y;changed=true end
        else
            local special=op=='key' or op=='clear' or op=='append' or op=='default'
            local index=2+offset+(special and 1 or 0)
            local button=(args[index] or ''):lower();local slot=tonumber(button)
            for i,name in ipairs(M.buttons) do if button==name:lower() then slot=i end end
            if slot and slot==math.floor(slot) and slot>=1 and slot<=8 then
                local e=self:stored_entry(layer,slot,menu)
                if op=='default' and not args[index+1] then
                    self:settings()[layers[layer]][menu and 'Menu' or 'Closed']['Slot'..slot]=inherited();changed=true
                elseif op=='clear' and not args[index+1] then
                    self:settings()[layers[layer]][menu and 'Menu' or 'Closed']['Slot'..slot]=empty();changed=true
                elseif op=='key' and args[index+1] and args[index+2] and (not args[index+3] or args[index+3]=='hold') and not args[index+4] then
                    local _,_,key=require('libs/banks/keys').parse(args[index+2])
                    if key then e.Alias=args[index+1];e.Kind='key';e.Key=key;e.Command='';e.Hold=args[index+3]=='hold';changed=true end
                elseif op=='append' and self:entry(layer,slot,menu).Kind=='command' and args[index+1] then
                    e=clone(self:entry(layer,slot,menu))
                    self:settings()[layers[layer]][menu and 'Menu' or 'Closed']['Slot'..slot]=e
                    local text=require('libs/banks/legacy').command_text(args,index+1)
                    e.Command=(e.Command~='' and e.Command..'; ' or '')..text;changed=true
                elseif not special and args[index+1] and args[index+2] then
                    e.Alias=args[index+1];e.Kind='command';e.Command=require('libs/banks/legacy').command_text(args,index+2);e.Key='';e.Hold=false;changed=true
                end
            end
        end
        if not changed then options.say('Invalid bank command.');self:help();return false end
        self:release_slots();self.output:cancel();self.r1used=true
        options.save()
        local message
        local label=layer:upper()
        if op=='menus' then message=label..': Draw in Menus: '..status_format.toggle(self:settings()[layers[layer]].ShowOnMenu)
        elseif op=='menuactions' then message=label..': Bindings in Menus: '..(self:settings()[layers[layer]].MenuActions and 'Menu' or 'Normal')
        elseif op=='cutscenes' then message=label..': Held banks work during dialogue; legacy preference retained.'
        elseif op=='display' then message=label..': Display: '..(self:settings()[layers[layer]].Display=='always' and 'Always' or 'Held')
        elseif op=='enable' or op=='disable' then message=label..': Enabled: '..status_format.toggle(self:settings()[layers[layer]].Enabled)
        elseif op=='show' or op=='hide' then message=label..': Draw: '..status_format.toggle(self:settings()[layers[layer]].Visible)
        elseif op=='edit' then message=label..': Edit: '..status_format.toggle(args[3]=='on')
        elseif op=='pos' or op=='resetpos' then message=label..': Position: '..tostring(p.X)..', '..tostring(p.Y)
        elseif op=='scale' then message=label..': Scale: '..(p.FollowCrossbar and 'Follows Crossbar' or tostring(p.Scale))
        elseif op=='lock' or op=='unlock' then message=label..': panel '..(p.Locked and 'locked' or 'unlocked')
        elseif op=='defaults' then message=label..': '..(menu and 'Menu' or 'Normal')..' bindings restored. '..
            'Other bindings: //xb bank '..layer..(menu and ' defaults' or ' menu defaults')
        else message=label..': '..(menu and 'menu' or 'normal')..' '..tostring(args[2+offset+((op=='key' or op=='clear' or op=='append' or op=='default') and 1 or 0)])..' binding updated' end
        options.say(status_format.notice(message));return true
    end
    function self:legacy(args)
        local copy={'l1l2'}
        if args[1]=='preview' and args[2]=='keyboard' then return self:command({'l1','preview'}) end
        for i,v in ipairs(args) do if not (i==2 and args[1]=='preview') then copy[#copy+1]=v end end
        if #args==0 or args[1]=='help' then self:help();return end
        return self:command(copy)
    end
    return self
end
return M
