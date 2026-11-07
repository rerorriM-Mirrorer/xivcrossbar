-- A: the reader owns delivery. The in-process hook only filters FFXI's copy.
local M = {}
function M.new(options)
    local self = {receiving=false, filtering=false}
    function self:stop()
        self.receiving, self.filtering = false, false
        self.selection, self.generation, self.last_poll = nil, nil, nil
        if self.dll then
            self.dll.stop()
            if not self.dll.detach() then options.notice('Native hooks could not detach. Filtering is off.') end
        end
    end
    function self:poll(settings, eligible, context, heartbeat)
        self.reset_input=false
        local now = options.clock()
        if now >= (self.next_status or 0) then
            self.status=options.status()
            self.next_status=now+.25
        end
        local status=self.status
        local profile = settings.ControllerProfile
        local profiles = require('libs/controller/profiles')
        local selected = status and status.state=='ready'
            and profiles.matches(status,profile,settings.ControllerDevice,options.modifier)
            and settings.ControllerMessages ~= false
        local key = selected and table.concat({profile,settings.ControllerDevice,status.pid}, ':') or nil
        if self.selection and self.selection ~= key then self:stop() end
        if not key then self.attempted=nil end
        if eligible and key and not self.selection and self.attempted ~= key then
            self.attempted = key
            if not self.dll then
                local ok, dll = pcall(options.open)
                if not ok then options.notice(tostring(dll)); return end
                self.dll = dll
            end
            local xbox = profiles.profiles[profile].backend=='xinput'
            local layout = ({['fightpadpro-directinput']=1,['xinput-r1-chooser']=2,
                ['ps5-extended']=3,['xinput-extended']=4})[profile] or 0
            local result = self.dll.begin(xbox and 1 or 2, settings.ControllerDevice-1, 3, layout,
                xbox and 'auto' or 'dinput8.dll')
            if result~=1 then
                options.notice('Native guard unavailable. FFXI input remains native; restart the client after changing hook backend/device.')
                return
            end
            self.selection=key
            self.polls=self.dll.poll_count()
        end
        if not self.selection then return end
        local route = eligible and (heartbeat and context or 4) or 0
        self.generation=self.dll.poll(route, function() self.last_poll=nil; self.reset_input=true end, function() end,self.generation)
        local polls=self.dll.poll_count()
        if route~=0 and polls~=self.polls then self.last_poll=now end
        self.polls=polls
        self.receiving=route~=0 and self.dll.armed() and self.last_poll~=nil and now-self.last_poll<.5
        self.filtering=self.receiving and route~=4
    end
    return self
end
return M
