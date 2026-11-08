local M = {}
local names = {'movement', 'menu', 'ps'}
local directions = {[59]='up',[60]='right',[61]='down',[62]='left'}
local faces = {
    playstation={'cross','square','circle','triangle'},
    xbox={'a','x','b','y'}, nintendo={'b','y','a','x'}, gamecube={'a','b','x','y'},
}

function M.mode(settings, name)
    local mode = settings.ControllerBridge[name]
    if mode ~= 'on' and mode ~= 'test' then return 'off' end
    if settings.InputTest and mode == 'on' then return 'test' end
    return mode
end

function M.command(settings, feature, mode, save, say)
    if feature == nil or feature == 'status' then
        for _, name in ipairs(names) do
            local saved, effective = settings.ControllerBridge[name], M.mode(settings,name)
            say(name..' '..saved..(saved ~= effective and ' (InputTest dry run)' or ''))
        end
        return
    end
    if (feature ~= 'all' and settings.ControllerBridge[feature] == nil)
        or (mode ~= 'on' and mode ~= 'off' and mode ~= 'test') then
        say('//xb bridge <movement|menu|ps|all> <off|test|on> | //xb bridge status')
        return
    end
    for _, name in ipairs(names) do
        if feature == 'all' or feature == name then settings.ControllerBridge[name] = mode end
    end
    save()
    say(feature..' '..mode)
end

function M.new(clock, execute, report)
    local self = {held={}, mode='off', next_read=0}
    local function action_for(dik, mapping)
        if directions[dik] then return directions[dik] end
        local layout = faces[mapping.button_layout]
        local face = layout and layout[dik-62]
        if not face then return end
        if face == mapping.confirm_button then return 'confirm' end
        if face == mapping.cancel_button then return 'back' end
    end
    function self:update(mode, path, id)
        local now = clock()
        if path ~= self.path or mode ~= self.mode then
            self.path,self.mode,self.next_read,self.token = path,mode,0,nil
            for _, hold in pairs(self.held) do hold.repeat_action = nil end
        end
        if not path or mode == 'off' then
            self.lease_reason = mode=='off' and 'off' or 'context-ineligible'
            return
        end
        if now >= self.next_read then
            self.next_read = now + .05
            local file = io.open(path,'rb')
            if file then
                local contents = (file:read(513) or ''):gsub('\r\n','\n')
                file:close()
                local owner, token, state, stamp = contents:match(
                    '^trust%-menu1\n(%d+)\n([%w%-]+)\n(%a+)\n([%d%.]+)\nEND\n$')
                if tonumber(owner) == id and (state == 'navigation' or state == 'text' or state == 'paused')
                    and tonumber(stamp) then
                    if token ~= self.token or state ~= self.state then
                        for _, hold in pairs(self.held) do hold.repeat_action = nil end
                    end
                    if token ~= self.last_token then self.last_token,self.sequence = token,0 end
                    self.token,self.state,self.stamp = token,state,tonumber(stamp)
                    self.lease_reason = 'fresh'
                end
            end
        end
        if self.token and (now-self.stamp > .35 or self.stamp-now > .1) then
            self.token,self.lease_reason = nil,'stale'
        elseif not self.token and self.lease_reason ~= 'stale' then
            self.lease_reason = 'unavailable'
        end
    end
    function self:mask(mapping)
        if not self.token or self.mode ~= 'on' then return 0 end
        local mask = 0
        for dik=59,66 do
            if action_for(dik,mapping) then mask = mask + 2^(dik-59) end
        end
        return mask
    end
    function self:send(action)
        self.last = action
        if self.mode == 'test' then
            report('Would route '..action..' to Trust')
        else
            self.sequence = self.sequence + 1
            execute(('lua c trust __controller %s %d %.6f %s'):format(self.token,self.sequence,clock(),action))
        end
    end
    function self:edge(dik, pressed, mapping, live)
        local hold = self.held[dik]
        if not pressed then
            self.held[dik] = nil
            return hold and hold.live
        end
        if hold then return hold.live end
        local action = action_for(dik,mapping)
        if not self.token or not action or (self.mode == 'on' and not live) then return false end
        hold = {live=self.mode=='on',token=self.token,mode=self.mode,next=clock()+.4}
        self.held[dik] = hold
        if self.state == 'navigation' or self.state == 'text' and not directions[dik] then
            self:send(action)
            hold.decision = 'trust-'..action
            if directions[dik] and hold.live then hold.repeat_action = action end
        elseif self.mode == 'test' then report('Trust menu '..self.state..' would hold '..action) end
        return hold.live,hold.decision or 'trust-'..self.state..'-held'
    end
    function self:tick(live)
        if not live or self.mode ~= 'on' or self.state ~= 'navigation' then return end
        local now = clock()
        for _, hold in pairs(self.held) do
            if hold.repeat_action and hold.mode == self.mode and self.token and hold.token == self.token and now >= hold.next then
                hold.next = now+.1
                self:send(hold.repeat_action)
            end
        end
    end
    return self
end
return M
