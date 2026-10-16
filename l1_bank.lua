-- A: one per-character companion bank. Lua owns the saved mode and actions;
-- the wrapper owns native keyboard keys. No user command is compiled as Lua.
local M = {}
M.buttons = {'Left','Down','Right','Up','Square','Cross','Circle','Triangle'}
M.references = {'Ctrl+J','Ctrl+E','Ctrl+M','Ctrl+I','Ctrl+Q','Ctrl+Space','Reserved','Ctrl+S'}
function M.defaults()
    local d={Mode='keyboard',Scale=0.8,X=24,Y=70,Locked=true}
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
        if d.Mode~='bank' then d.Mode='keyboard' end
        d.Scale=finite(d.Scale) and math.max(.4,math.min(2,d.Scale)) or .8
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
    function self:mode() return self:settings().Mode end
    function self:event(kind,slot)
        local now=self.options.clock()
        if kind=='show' then self.held=true;self.activity=now
        elseif kind=='release' or kind=='cancel' then self.held=false;self.activity=now
        elseif kind=='tap' then
            self.held=false;self.activity=now
            local d=self:settings();d.Mode=d.Mode=='bank' and 'keyboard' or 'bank'
            self.options.save();self.options.say('L1: '..d.Mode..' mode.')
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
        if self:mode()=='bank' or self.held or now<self.preview_until then return 1 end
        if self.activity==0 then return 0 end
        return math.max(0,math.min(1,(self.activity+1.8-now)/.6))
    end
    function self:help()
        local rows={
            {'l1 status','Mode, bank entries and event counters.'},
            {'l1 mode keyboard|bank|toggle','Choose a mode (unused L1 tap toggles).'},
            {'l1 <1-8> <alias> <command...>','Assign a slot; quote a multiword alias.'},
            {'l1 append <1-8> <command...>','Append one console command with a semicolon.'},
            {'l1 clear <1-8>','Clear one slot.'},
            {'l1 scale <0.4-2>','Set companion scale.'},
            {'l1 pos <x> <y>','Set companion position.'},
            {'l1 lock|unlock','Allow dragging only while unlocked and visible.'},
            {'l1 resetpos','Recover the upper-left default position.'},
            {'l1 preview','Show the current companion for six seconds.'},
        }
        for _,r in ipairs(rows) do self.options.help(r[1],r[2]) end
    end
    function self:status()
        local d=self:settings();local used=0
        for i=1,8 do if d['Slot'..i].Command:match('%S') then used=used+1 end end
        self.options.say('L1 '..d.Mode..' | '..used..'/8 assigned | scale='..d.Scale..
            ' | pos='..d.X..','..d.Y..' | '..(d.Locked and 'locked' or 'unlocked')..
            ' | executed='..self.executed..' | empty='..self.empty)
    end
    function self:command(args)
        local op=(args[1] or 'help'):lower();local d=self:settings()
        local changed=false
        if op=='help' then self:help();return
        elseif op=='status' then self:status();return
        elseif op=='mode' and (args[2]=='keyboard' or args[2]=='bank' or args[2]=='toggle') then
            d.Mode=args[2]=='toggle' and (d.Mode=='bank' and 'keyboard' or 'bank') or args[2]
            self:cancel();self.activity=self.options.clock();changed=true
        elseif (op=='lock' or op=='unlock') and not args[2] then d.Locked=op=='lock';changed=true
        elseif op=='resetpos' then d.X,d.Y=24,70;changed=true
        elseif op=='preview' then self.preview_until=self.options.clock()+6;return
        elseif op=='scale' and finite(tonumber(args[2])) and tonumber(args[2])>=.4 and tonumber(args[2])<=2 then
            d.Scale=tonumber(args[2]);changed=true
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
        self.options.save();self:status();return true
    end
    self:settings()
    return self
end
return M
