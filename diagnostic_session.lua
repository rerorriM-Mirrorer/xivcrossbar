-- Beta 1 diagnostic sessions: one immutable per-character result per request.
-- Only Lua writes the final log. AHK exports a bounded, temporary observation feed.
local M={}
local function clean(s)
    return tostring(s==nil and '<nil' or s):gsub('[\r\n\t]',' '):sub(1,350)
end
local function snapshot(prefix,value,lines,seen,depth)
    if type(value)~='table' then
        lines[#lines+1]=prefix..'='..clean(value)
        return
    end
    if seen[value] or depth>7 then
        lines[#lines+1]=prefix..'=[reference]'
        return
    end
    seen[value]=true
    local keys={}
    for key in pairs(value) do keys[#keys+1]=key end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
    for _,key in ipairs(keys) do
        snapshot(prefix..'.'..tostring(key),value[key],lines,seen,depth+1)
    end
end
function M.new(opts)
    local self={active=false,limit=opts.limit or 12000,events={},dropped=0,serial=0}
    local clock=opts.clock or require('socket').gettime
    local wall=opts.date or os.date
    local read=opts.read or function(path)
        local f=io.open(path,'rb')
        if not f then return nil end
        local text=f:read(1048577);f:close()
        return text
    end
    local function append(time,kind,message)
        if #self.events>=self.limit then
            self.dropped=self.dropped+1
            return
        end
        self.events[#self.events+1]={time,kind,clean(message)}
    end
    local function record(kind,message)
        if self.active then append(clock(),kind,message) end
    end
    function self:record(kind,message) record(kind,message) end
    function self:state(name,object)
        if not self.active then return end
        local lines={}
        snapshot(name,object or {},lines,{},0)
        for _,line in ipairs(lines) do record('STATE',line) end
    end
    function self:start(name,state,skip_ahk)
        if self.active or self.pending then return nil,'A diagnostic is already active or saving.' end
        name=tostring(name or 'prelogin'):gsub('[^%w_-]','_')
        self.serial=self.serial+1
        local stamp=wall('!%Y%m%d-%H%M%S')
        local usec=math.floor(clock()*1000000)%1000000
        -- Per-request names never overwrite a previous capture, even if
        -- another client started in the same second.
        local id=stamp..'-'..string.format('%06d',usec)..'-'..self.serial..'-'..name
        self.id=id
        self.skip_ahk=skip_ahk==true
        self.name=name
        self.path=opts.directory..'/'..name..'-'..id..'.log'
        self.feed=opts.staging..'/'..id..'.ahk'
        self.events={};self.dropped=0
        self.deadline=clock()+30
        self.active=true
        if opts.mkdir then opts.mkdir(opts.directory);opts.mkdir(opts.staging) end
        append(clock(),'SESSION','start id='..id..' character='..name..' duration=30s')
        self:state('start',state)
        if opts.request and not self.skip_ahk then
            local ok,err=opts.request('on '..id..' '..name)
            if not ok then record('WARNING','AHK capture request failed: '..tostring(err)) end
        end
        return self.path
    end
    function self:mark(note) record('MARK',note or 'user observation') end
    function self:status()
        return {active=self.active,pending=self.pending==true,path=self.path,
            count=#self.events,dropped=self.dropped,
            remaining=self.active and math.max(0,self.deadline-clock()) or 0}
    end
    local finalize
    function self:tick()
        if self.active and clock()>=self.deadline then self:stop('deadline') end
        if self.pending and clock()>=self.finish_at then finalize() end
    end
    -- Keep the 30-second streams bounded in memory and merge them while
    -- writing, rather than copying/sorting ~18k events then concatenating
    -- another multi-megabyte string inside Windower's 32-bit Lua process.
    -- Each source is already recorded chronologically; merge three cursors.
    local function assemble_stream(reason,emit)
        local render,render_dropped,render_state=opts.render_lines()
        render=render or {}
        local feed=not self.skip_ahk and read(self.feed) or nil
        if feed and (#feed>1048576 or feed:match('^# diagnostic%-feed ([^%s]+)')~=self.id) then
            feed=nil
        end
        local ahk_count,ahk_dropped=0,0
        if feed then
            ahk_dropped=tonumber(feed:match('\ndropped=(%d+)')) or 0
            for line in feed:gmatch('[^\r\n]+') do
                local millis,message=line:match('^(%d+)%s+(.+)$')
                if millis and #message<=400 then ahk_count=ahk_count+1 end
            end
        end
        for _,line in ipairs({
            '# XIVCrossbar unified diagnostic v1',
            '# Character: '..self.name,
            '# Session: '..self.id,
            '# Started UTC: '..wall('!%Y-%m-%dT%H:%M:%SZ',math.floor(self.deadline-30)),
            '# Termination: '..reason,
            '# Rendering: observed Lua drawing API calls, not GPU pixels',
            '# AHK: OS wall-clock timestamps from Windows FILETIME; controller polling is sampled',
            '# AHK events: '..ahk_count..' dropped: '..ahk_dropped,
            '# Lua dropped: '..self.dropped..' render overwritten: '..(render_dropped or 0)..
                ' render frames: '..(render_state and render_state.frames or 0),
            '# Unix epoch seconds | source | observation',
        }) do emit(line) end

        local li,ri=1,1
        local lua_event=self.events[li]
        local function next_render()
            while ri<=#render do
                local line=render[ri]
                ri=ri+1
                local t,frame,kind,details=line:match('^(%d+%.%d+)\t([^\t]+)\t([^\t]+)\t(.*)$')
                if t then return {tonumber(t),'RENDER',kind..' frame='..frame..' '..details} end
            end
        end
        local render_event=next_render()
        local feed_iterator=feed and feed:gmatch('[^\r\n]+')
        local function next_ahk()
            if not feed_iterator then return nil end
            while true do
                local line=feed_iterator()
                if not line then return nil end
                local millis,message=line:match('^(%d+)%s+(.+)$')
                if millis and #message<=400 then return {tonumber(millis)/1000,'AHK',message} end
            end
        end
        local ahk_event=next_ahk()
        while lua_event or render_event or ahk_event do
            local chosen,source
            for _,candidate in ipairs({
                {'lua',lua_event},{'render',render_event},{'ahk',ahk_event}
            }) do
                local event=candidate[2]
                if event and (not chosen or event[1]<chosen[1] or
                    (event[1]==chosen[1] and event[2]<chosen[2])) then
                    chosen,source=event,candidate[1]
                end
            end
            emit(string.format('%.6f [%s] %s',chosen[1],chosen[2],chosen[3]))
            if source=='lua' then li=li+1;lua_event=self.events[li]
            elseif source=='render' then render_event=next_render()
            else ahk_event=next_ahk() end
        end
        if ahk_count==0 then
            emit(string.format('%.6f [%s] %s',clock(),self.skip_ahk and 'INFO' or 'WARNING',
                self.skip_ahk and 'Instantaneous snapshot: AHK capture intentionally omitted'
                or 'AHK feed absent or unreadable at finalization; temporary feed may have arrived late'))
        end
        emit('# End diagnostic')
    end
    finalize=function()
        if not self.pending then return end
        local success,saved,err=pcall(function()
            if opts.write_stream then
                return opts.write_stream(self.path,function(emit)
                    assemble_stream(self.pending_reason,emit)
                end)
            end
            -- Compatibility only for the isolated fake-filesystem test fixture.
            -- Production always provides write_stream and never builds this copy.
            local lines={}
            assemble_stream(self.pending_reason,function(line) lines[#lines+1]=line end)
            return opts.write(self.path,table.concat(lines,'\n')..'\n')
        end)
        if not success then err=saved;saved=false end
        if saved and opts.remove then opts.remove(self.feed) end
        self.pending=false
        self.last_path=self.path
        self.last_error=not saved and err or nil
        if opts.say then opts.say(saved and 'Diagnostic saved: '..self.path
            or 'Diagnostic save failed: '..tostring(err)) end
        return saved,err,self.path
    end
    function self:force(reason,ending_state)
        if self.active then self:stop(reason or 'unload',ending_state) end
        if self.pending then return finalize() end
        return false,'No pending diagnostic'
    end
    function self:stop(reason,ending_state)
        if not self.active then return false,'No diagnostic is active' end
        self:state('end',ending_state)
        record('SESSION','stop reason='..(reason or 'manual'))
        self.active=false
        self.pending=true
        self.pending_reason=reason or 'manual'
        self.finish_at=clock()+.75
        if opts.request and not self.skip_ahk then opts.request('off '..self.id..' '..self.name) end
        if opts.render_stop then opts.render_stop() end
        return true,nil,self.path
    end
    return self
end
return M
