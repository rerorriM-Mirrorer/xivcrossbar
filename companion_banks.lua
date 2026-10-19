-- A: saved companion definitions and the single physical-input owner. Rendering
-- reads these same entries. The old L1 section remains untouched for recovery.
local M={buttons={'Left','Down','Right','Up','Square','Cross','Circle','Triangle'}}
local slot_for={[4]=1,[3]=2,[2]=3,[1]=4,[6]=5,[5]=6,[7]=7,[8]=8}
local layers={l1='L1',l1l2='L1L2',r1='R1',r1r2='R1R2'}
M.aliases={l1l2=true,r1=true,r1r2=true} -- l1 retains its older L1L2 editor meaning
local function clone(t) local r={};for k,v in pairs(t) do r[k]=type(v)=='table' and clone(v) or v end;return r end
local function action(label,kind,value,hold)
    return {Alias=label,Kind=kind,Command=kind=='command' and value or '',Key=kind=='key' and value or '',Hold=hold==true}
end
local function empty() return action('','command','') end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function inherited() return {Alias='',Kind='default',Command='',Key='',Hold=false} end
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
        d[name]={Closed={},Menu={},Visible=true,ShowOnMenu=false,MenuActions=true,Title=''}
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
        b.Visible=b.Visible~=false;b.ShowOnMenu=b.ShowOnMenu==true
        b.MenuActions=b.MenuActions~=false;b.Title=type(b.Title)=='string' and b.Title or ''
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
        previews={},output=require('companion_output').new({clock=options.clock})}
    self.migrated=select(2,M.ensure(options.settings))
    local normalized=options.settings.CompanionBanks
    function self:settings()
        if normalized~=options.settings.CompanionBanks then normalized=M.ensure(options.settings) end
        return normalized
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
    function self:choose()
        local d=self.down
        if not self.eligible or d[9] or d[10] then return '' end
        if self.tailL or self.tailR then return 'tail' end
        if d[11] and not (d[13] and self.left) or d[12] and not (d[14] and self.right) then return '' end
        if d[13] and d[14] then return 'pair' end
        if d[13] then return d[11] and 'l1l2' or 'l1' end
        if d[14] then return d[12] and 'r1r2' or 'r1' end
        return ''
    end
    function self:refresh()
        local eligible,menu=options.context()
        if self.eligible and not eligible then
            self:release_slots();self.output:cancel();self.r1used=true
        elseif self.menu~=menu then
            self:release_slots();self.output:cancel();self.r1used=true
        end
        self.eligible,self.menu=eligible,menu
        local layer=self:choose()
        if layer~=self.layer then self:release_slots();self.layer=layer end
    end
    function self:edge(button,pressed)
        self:refresh()
        local before=self.layer
        local used=self.r1used
        if pressed==not not self.down[button] then return end
        self.down[button]=pressed or nil
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
        elseif button==14 and not pressed and not used and before=='r1' and self.eligible then
            self.output:pulse('r')
        end
        if button>=13 then return end
        if button>=9 then
            if pressed and (button<=10 or self.layer=='') then
                options.ordinary(button,true);self.owners[button]='ordinary'
            end
            return
        end
        if not pressed then self.blocked[button]=nil;return end
        if self.blocked[button] then return end
        if self.layer=='' then options.ordinary(button,true);self.owners[button]='ordinary';return end
        if not layers[self.layer] or not self.eligible then return end
        local e=self:entry(self.layer,slot_for[button],self:uses_menu(self.layer,self.menu))
        if e.Kind=='key' and require('companion_keys').parse(e.Key) then
            -- Native navigation can hold. Pulses retain both edges even if the
            -- physical release happened before AHK read the next Lua frame.
            local _,_,key=require('companion_keys').parse(e.Key)
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
            return names[parent.layer] and parent.layer or parent.previews[side] and parent.previews[side].layer or (side=='Left' and 'l1' or 'r1')
        end
        local proxy=setmetatable({}, {__index=function(_,key)return parent:settings()[side..'Panel'][key] end,
            __newindex=function(_,key,value) parent:settings()[side..'Panel'][key]=value end})
        return {
            settings=function() local layer=selected()
                for i=1,8 do rawset(proxy,'Slot'..i,parent:entry(layer,i,parent:uses_menu(layer,parent.menu))) end;return proxy end,
            mode=function() return selected() end,
            title=function(_,mode) local title=parent:settings()[layers[mode]].Title
                return title~='' and title or ({l1='L1  Inventory',l1l2='L1 + L2  Actions',r1='R1  Trust',r1r2='R1 + R2  NPC'})[mode] end,
            opacity=function(_,eligible)
                local preview=parent.previews[side];local b=parent:settings()[layers[selected()]]
                return eligible and b.Visible and (not parent.menu or b.ShowOnMenu)
                    and (names[parent.layer] or preview and options.clock()<preview.until_time) and 1 or 0
            end,
        }
    end
    function self:previewing(side)
        return self.previews[side] and options.clock()<self.previews[side].until_time or false
    end
    function self:help()
        for _,row in ipairs({
            {'bank <layer> status','Show saved closed/menu entries and input/output state.'},
            {'bank <layer> show|hide','Draw or hide this bank; its controls stay active.'},
            {'bank <layer> menus on|off','Allow this bank to draw over native game menus.'},
            {'bank <layer> menuactions on|off','Use menu bindings automatically, or always use Closed bindings.'},
            {'bank preset cioara apply','Replace four bank layouts with the Cioara template; back up settings first.'},
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
    function self:status(layer)
        options.say('Banks v2 | layer='..(self.layer~='' and self.layer or 'ordinary')..' | native menu='..tostring(self.menu)..
            ' | executed='..self.executed..' | empty='..self.empty..' | native ack='..self.output.ack..'/'..self.output.seq)
        local b=self:settings()[layers[layer]]
        options.say(layer..' visible='..tostring(b.Visible)..' | draw on native menus='..tostring(b.ShowOnMenu)..' | menu actions='..tostring(b.MenuActions))
        for _,context in ipairs({'Closed','Menu'}) do
            local entries={}
            for i,name in ipairs(M.buttons) do local e=self:entry(layer,i,context=='Menu');local source=self:stored_entry(layer,i,context=='Menu').Kind=='default' and 'default' or 'override'
                entries[#entries+1]=name..'='..e.Alias..' ['..(e.Kind=='key' and e.Key..(e.Hold and ' hold' or '') or e.Command)..'; '..source..']' end
            options.say(layer..' '..context..': '..table.concat(entries,'; '))
        end
    end
    function self:command(args)
        local layer=(args[1] or ''):lower()
        if layer=='preset' then
            if args[2]~='cioara' or args[3]~='apply' or args[4] then self:help();return false end
            self:release_slots();self.output:cancel();self.r1used=true
            require('companion_presets').cioara(self)
            options.save();options.say('Cioara banks applied. Inventory is on L1+L2; menu actions OFF retains its inventory-opening bindings.');return true
        end
        if not layers[layer] then self:help();return false end
        local offset=args[2]=='menu' and 1 or 0;local menu=offset==1
        local op=(args[2+offset] or 'status'):lower()
        local side=layer:sub(1,1)=='l' and 'Left' or 'Right';local p=self:settings()[side..'Panel']
        local changed=false
        if op=='help' then self:help();return
        elseif op=='status' then self:status(layer);return
        elseif (op=='show' or op=='hide') and offset==0 and not args[3] then
            self:settings()[layers[layer]].Visible=op=='show';changed=true
        elseif (op=='menus' or op=='menuactions') and offset==0 and not args[4] and (args[3]=='on' or args[3]=='off') then
            self:settings()[layers[layer]][op=='menus' and 'ShowOnMenu' or 'MenuActions']=args[3]=='on';changed=true
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
                    local _,_,key=require('companion_keys').parse(args[index+2])
                    if key then e.Alias=args[index+1];e.Kind='key';e.Key=key;e.Command='';e.Hold=args[index+3]=='hold';changed=true end
                elseif op=='append' and self:entry(layer,slot,menu).Kind=='command' and args[index+1] then
                    e=clone(self:entry(layer,slot,menu))
                    self:settings()[layers[layer]][menu and 'Menu' or 'Closed']['Slot'..slot]=e
                    local text=require('l1_bank').command_text(args,index+1)
                    e.Command=(e.Command~='' and e.Command..'; ' or '')..text;changed=true
                elseif not special and args[index+1] and args[index+2] then
                    e.Alias=args[index+1];e.Kind='command';e.Command=require('l1_bank').command_text(args,index+2);e.Key='';e.Hold=false;changed=true
                end
            end
        end
        if not changed then options.say('Invalid bank command.');self:help();return false end
        self:release_slots();self.output:cancel();self.r1used=true
        options.save();self:status(layer);return true
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
