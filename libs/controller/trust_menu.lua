-- A: the existing AHK button stream has one owner. Trust receives logical
-- actions through its addon command entry point, without native keyboard output.
local M={}
local directions={[1]='up',[2]='right',[3]='down',[4]='left'}
local faces={[5]='cross',[6]='square',[7]='circle',[8]='triangle'}
function M.new(options)
    local self={held={},blocked={},sequence=0,sent=0,mode='closed'}
    function self:cancel()
        for button in pairs(self.held) do self.blocked[button]=true end
        self.held={}
    end
    function self:reset()
        self.held={};self.blocked={};self.r1=false
    end
    function self:update(contents,id)
        if type(contents)=='string' then contents=contents:gsub('\r\n','\n') end
        -- Atomic replacement can leave a brief Windows rename gap. A cached
        -- complete lease is usable only until its original timestamp expires.
        if type(contents)=='string' and #contents<=512
                and contents:match('^trust%-menu1\n%d+\n[%w%-]+\n%a+\n[%d%.]+\nEND\n$') then
            self.contents,self.id=contents,id
        else contents=nil end
        if self.id==id then contents=contents or self.contents end
        local found,token,mode,stamp
        if type(contents)=='string' and #contents<=512 then
            found,token,mode,stamp=contents:match('^trust%-menu1\n(%d+)\n([%w%-]+)\n(%a+)\n([%d%.]+)\nEND\n$')
        end
        local age=stamp and options.clock()-tonumber(stamp)
        if tonumber(found)~=id or not age or age<-.1 or age>.35
                or not ({navigation=true,text=true,paused=true})[mode] then token,mode=nil,'closed' end
        if token~=self.token then
            self:cancel();self.token=token;self.sequence=0
            if options.changed then options.changed() end
        end
        self.mode=mode
    end
    function self:send(action)
        if not self.token then return end
        self.sequence=self.sequence+1;self.sent=self.sent+1
        options.execute(string.format('lua c trust __controller %s %d %.6f %s',
            self.token,self.sequence,options.clock(),action))
    end
    function self:edge(button,pressed,mapping,r1)
        if button==14 then self.r1=pressed;return false end
        if button<1 or button>8 then return false end
        if not pressed then
            if self.blocked[button] or self.held[button] then
                self.blocked[button]=nil;self.held[button]=nil;return true
            end
            return false
        end
        if self.blocked[button] or self.held[button] then return true end
        if not self.token then return false end
        self.held[button]={token=self.token,next=options.clock()+.4}
        local action=directions[button]
        if button==6 and (r1 or self.r1) then action='close'
        elseif faces[button]==mapping.confirm_button then action='confirm'
        elseif faces[button]==mapping.cancel_button then action='back'
        end
        if self.mode=='paused' then return true end
        if self.mode=='text' and action~='confirm' and action~='back' and action~='close' then return true end
        if action then
            self.held[button].action=action
            self:send(action)
        end
        return true
    end
    function self:tick()
        local now=options.clock()
        for button,hold in pairs(self.held) do
            if directions[button] and hold.action and hold.token==self.token and self.mode=='navigation' and now>=hold.next then
                -- One repeat per frame at most. Never replay an overdue burst.
                hold.next=now+.10;self:send(hold.action)
            end
        end
    end
    return self
end
return M
