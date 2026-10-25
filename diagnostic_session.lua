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
    function self:start(name,state)
        if self.active then self:stop('replaced') end
        name=tostring(name or 'prelogin'):gsub('[^%w_-]','_')
        self.serial=self.serial+1
        local stamp=wall('!%Y%m%d-%H%M%S')
        local usec=math.floor(clock()*1000000)%1000000
        -- Per-request names never overwrite a previous capture, even if
        -- another client started in the same second.
        local id=stamp..'-'..string.format('%06d',usec)..'-'..self.serial..'-'..name
        self.id=id
        self.name=name
        self.path=opts.directory..'/'..name..'-'..id..'.log'
        self.feed=opts.staging..'/'..id..'.ahk'
        self.events={};self.dropped=0
        self.deadline=clock()+30
        self.active=true
        if opts.mkdir then opts.mkdir(opts.directory);opts.mkdir(opts.staging) end
        append(clock(),'SESSION','start id='..id..' character='..name..' duration=30s')
        self:state('start',state)
        if opts.request then
            local ok,err=opts.request('on '..id..' '..name)
            if not ok then record('WARNING','AHK capture request failed: '..tostring(err)) end
        end
        return self.path
    end
    function self:mark(note) record('MARK',note or 'user observation') end
    function self:status()
        return {active=self.active,path=self.path,count=#self.events,dropped=self.dropped,
            remaining=self.active and math.max(0,self.deadline-clock()) or 0}
    end
    function self:tick()
        if self.active and clock()>=self.deadline then self:stop('deadline') end
    end
    local function assemble(reason)
        local entries={}
        for _,event in ipairs(self.events) do entries[#entries+1]=event end
        local render,render_dropped,render_state=opts.render_lines()
        for _,line in ipairs(render or {}) do
            local t,frame,kind,details=line:match('^(%d+%.%d+)\t([^\t]+)\t([^\t]+)\t(.*)$')
            if t then entries[#entries+1]={tonumber(t),'RENDER',kind..' frame='..frame..' '..details} end
        end
        local feed=read(self.feed)
        local ahk_count=0
        local ahk_dropped=0
        if type(feed)=='string' and #feed<=1048576 then
            local header=feed:match('^# diagnostic%-feed ([^%s]+)')
            if header==self.id then
                ahk_dropped=tonumber(feed:match('\ndropped=(%d+)')) or 0
                for line in feed:gmatch('[^\r\n]+') do
                    local millis,message=line:match('^(%d+)%s+(.+)$')
                    if millis and #message<=400 then
                        entries[#entries+1]={tonumber(millis)/1000,'AHK',message}
                        ahk_count=ahk_count+1
                    end
                end
            end
        end
        if ahk_count==0 then
            entries[#entries+1]={clock(),'WARNING','AHK feed absent or unreadable at finalization; temporary feed may have arrived late'}
        end
        table.sort(entries,function(a,b)
            if a[1]==b[1] then return a[2]<b[2] end
            return a[1]<b[1]
        end)
        local body={'# XIVCrossbar unified diagnostic v1',
            '# Character: '..self.name,
            '# Session: '..self.id,
            '# Started UTC: '..wall('!%Y-%m-%dT%H:%M:%SZ',math.floor(self.deadline-30)),
            '# Termination: '..reason,
            '# Rendering: observed Lua drawing API calls, not GPU pixels',
            '# AHK: OS wall-clock timestamps from Windows FILETIME; controller polling is sampled',
            '# AHK events: '..ahk_count..' dropped: '..ahk_dropped,
            '# Lua dropped: '..self.dropped..' render overwritten: '..(render_dropped or 0)..
                ' render frames: '..(render_state and render_state.frames or 0),
            '# Unix epoch seconds | source | observation'}
        for _,event in ipairs(entries) do
            body[#body+1]=string.format('%.6f [%s] %s',event[1],event[2],event[3])
        end
        body[#body+1]='# End diagnostic'
        return table.concat(body,'\n')..'\n'
    end
    function self:stop(reason,ending_state)
        if not self.active then return false,'No diagnostic is active' end
        self:state('end',ending_state)
        record('SESSION','stop reason='..(reason or 'manual'))
        self.active=false
        if opts.request then opts.request('off '..self.id..' '..self.name) end
        if opts.render_stop then opts.render_stop() end
        local ok,body=pcall(assemble,reason or 'manual')
        if not ok then return false,body end
        local saved,err=opts.write(self.path,body)
        if saved and opts.remove then opts.remove(self.feed) end
        self.last_path=self.path
        self.last_error=not saved and err or nil
        return saved,err,self.path
    end
    return self
end
return M
