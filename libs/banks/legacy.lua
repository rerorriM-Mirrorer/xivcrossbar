-- A: one per-character companion bank. Lua owns actions and the revealed layer;
-- the wrapper owns native keyboard keys. No user command is compiled as Lua.
local M = {}
M.buttons = {'Left','Down','Right','Up','Square','Cross','Circle','Triangle'}
M.references = {'Ctrl+J','Ctrl+E','Ctrl+M','Ctrl+I','Ctrl+Q','Ctrl+Space','Reserved','Ctrl+S'}
function M.defaults()
    local d={Mode='keyboard',Scale=1,FollowCrossbar=true,X=24,Y=70,Locked=true}
    for i=1,8 do d['Slot'..i]={Alias='',Command=''} end
    return d
end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function M.command_text(args,start)
    -- Windower may tokenize a quoted spell/item into one multiword argument.
    -- Restore those quotes, but accept one whole quoted console command too.
    if #args==start then return args[start] end
    local parts={}
    for i=start,#args do
        local value=args[i]
        if value:match('%s') and not value:match('^["\']') then value='"'..value:gsub('"','\\"')..'"' end
        parts[#parts+1]=value
    end
    return table.concat(parts,' ')
end
function M.new(options)
    local self={options=options,held=false,activity=0,preview_until=0,executed=0,empty=0}
    function self:settings()
        local parent=self.options.settings
        if type(parent.L1)~='table' then parent.L1=M.defaults() end
        local d=parent.L1
        -- Mode remains readable for old configs; physical order now owns it.
        if d.FollowCrossbar==nil then d.FollowCrossbar=true end
        d.Scale=finite(d.Scale) and math.max(.4,math.min(2,d.Scale)) or 1
        d.X=finite(d.X) and d.X or 24;d.Y=finite(d.Y) and d.Y or 70
        if type(d.Locked)~='boolean' then d.Locked=true end
        for i=1,8 do
            local key='Slot'..i
            if type(d[key])~='table' then d[key]={} end
            for _,field in ipairs({'Alias','Command'}) do
                if type(d[key][field])~='string' then d[key][field]='' end
            end
        end
        return d
    end
    function self:cancel() self.held=false;self.activity=0;self.preview_until=0 end
    function self:mode() return self.layer or 'keyboard' end
    function self:event(kind,slot)
        local now=self.options.clock()
        if kind=='show' or kind=='bank' then
            self.layer=kind=='bank' and 'bank' or 'keyboard';self.held=true;self.activity=now
        elseif kind=='release' or kind=='cancel' then self.held=false;self.activity=now
        elseif kind=='slot' and self:mode()=='bank' and self.held then
            self.activity=now
            local d=self:settings()['Slot'..slot]
            if d and d.Command:match('%S') then
                self.executed=self.executed+1;self.options.execute(d.Command)
            else self.empty=self.empty+1 end
        end
    end
    function self:opacity(eligible)
        if not eligible then return 0 end
        local now=self.options.clock()
        return (self.held or now<self.preview_until) and 1 or 0
    end
    function self:help()
        local rows={
            {'l1 status','Mode, bank entries and event counters.'},
            {'l1 preview [keyboard|bank]','Preview a layer for six seconds; L1 then L2 reveals the bank.'},
            {'l1 <1-8> <alias> <command...>','Assign a slot; quote a multiword alias.'},
            {'l1 append <1-8> <command...>','Append one console command with a semicolon.'},
            {'l1 clear <1-8>','Clear one slot.'},
            {'l1 scale crossbar|<0.4-2>','Follow main crossbar size (default), or set an independent scale.'},
            {'l1 pos <x> <y>','Set companion position.'},
            {'l1 lock|unlock','Allow dragging only while unlocked and visible.'},
            {'l1 resetpos','Recover the upper-left default position.'},
        }
        for _,r in ipairs(rows) do self.options.help(r[1],r[2]) end
    end
    function self:status()
        local d=self:settings();local used=0
        for i=1,8 do if d['Slot'..i].Command:match('%S') then used=used+1 end end
        self.options.say('L1 '..self:mode()..' (momentary) | '..used..'/8 bank slots | scale='..(d.FollowCrossbar and 'crossbar' or d.Scale)..
            ' | pos='..d.X..','..d.Y..' | '..(d.Locked and 'locked' or 'unlocked')..
            ' | executed='..self.executed..' | empty='..self.empty)
    end
    function self:command(args)
        local op=(args[1] or 'help'):lower();local d=self:settings()
        local changed=false
        if op=='help' then self:help();return
        elseif op=='status' then self:status();return
        elseif (op=='lock' or op=='unlock') and not args[2] then d.Locked=op=='lock';changed=true
        elseif op=='resetpos' then d.X,d.Y=24,70;changed=true
        elseif op=='preview' and (not args[2] or args[2]=='keyboard' or args[2]=='bank') then
            if not self.held then self.layer=args[2] or 'keyboard' end
            self.preview_until=self.options.clock()+6;return
        elseif op=='scale' and args[2]=='crossbar' then d.FollowCrossbar=true;changed=true
        elseif op=='scale' and finite(tonumber(args[2])) and tonumber(args[2])>=.4 and tonumber(args[2])<=2 then
            d.Scale=tonumber(args[2]);d.FollowCrossbar=false;changed=true
        elseif op=='pos' and finite(tonumber(args[2])) and finite(tonumber(args[3])) then
            d.X,d.Y=tonumber(args[2]),tonumber(args[3]);changed=true
        else
            local assignment=tonumber(op)
            local slot=assignment or tonumber(args[2])
            if slot and slot>=1 and slot<=8 and slot==math.floor(slot) then
                local entry=d['Slot'..slot]
                if op=='clear' and not args[3] then entry.Alias,entry.Command='','';changed=true
                elseif op=='append' and args[3] and table.concat(args,' ',3):match('%S') then
                    local command=M.command_text(args,3)
                    entry.Command=entry.Command:match('%S') and (entry.Command..'; '..command) or command;changed=true
                elseif assignment and args[2] and args[3] and table.concat(args,' ',3):match('%S') then
                    entry.Alias,entry.Command=args[2],M.command_text(args,3);changed=true
                end
            end
        end
        if not changed then self.options.say('Invalid L1 command.');self:help();return false end
        self.options.save();self.options.say('L1: '..op..' updated.');return true
    end
    self:settings()
    return self
end
return M
