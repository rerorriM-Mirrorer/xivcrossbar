-- Beta 1: a single opt-in diagnostic command, recording from all public subsystems.
-- Legacy controller-status/trace toggles remain unchanged.
local M={}
function M.new(opts)
    local session=require('diagnostic_session')
    local render=require('ui/render_trace')
    local clock=opts.clock or require('socket').gettime
    local directory=opts.path..'data/diagnostics'
    local staging=opts.path..'data/diagnostics-staging'
    local last_context
    local last_frame
    local function tell(message) if opts.say then opts.say(message) end end
    local function replace(path,body)
        local temporary=path..'.tmp'
        local f,err=io.open(temporary,'wb')
        if not f then return false,err end
        local written,werr=f:write(body)
        local closed,cerr=f:close()
        if not written or not closed then os.remove(temporary);return false,werr or cerr end
        -- The shared AHK request is a replaceable handoff, not a user log.
        if path:sub(-12)=='/request.txt' then os.remove(path) end
        local moved,merr=os.rename(temporary,path)
        if not moved then os.remove(temporary);return false,merr end
        return true
    end
    local recorder=session.new({
        clock=clock,date=opts.date, directory=directory,staging=staging,
        write=replace,remove=os.remove,
        -- Write to an adjacent temporary file as each chronological observation
        -- is emitted. No giant Lua table.concat or second full log string.
        write_stream=function(path,produce)
            local temporary=path..'.tmp'
            local f,open_error=io.open(temporary,'wb')
            if not f then return false,open_error end
            local ok,write_error=pcall(function()
                produce(function(line)
                    local written,err=f:write(line,'\n')
                    if not written then error(err or 'diagnostic write failed') end
                end)
            end)
            local closed,close_error=f:close()
            if not ok or not closed then
                os.remove(temporary)
                return false,ok and close_error or write_error
            end
            local moved,move_error=os.rename(temporary,path)
            if not moved then os.remove(temporary);return false,move_error end
            return true
        end,
        mkdir=function(path) opts.mkdir(path) end,
        request=function(command)
            return replace(staging..'/request.txt',command..'\n')
        end,
        render_lines=function() return render.lines() end,
        render_stop=function() render.stop() end,
        say=tell,
    })
    local self={recorder=recorder}
    function self:record(kind,message)
        recorder:record(kind,message)
    end
    function self:input_active()
        return recorder.active and recorder.profile ~= 'render' and recorder.profile ~= 'snapshot'
    end
    function self:command(mode,note)
        mode=type(mode)=='string' and mode:lower() or 'start'
        if mode=='on' then mode='start' end
        if mode=='start' then
            local state=opts.snapshot()
            local profile=type(note)=='string' and note:lower() or 'input'
            if profile~='input' and profile~='render' and profile~='full' then
                tell('Use //xb diagnose start [input|render|full]');return false
            end
            local pid=opts.pid and opts.pid()
            local path,err=recorder:start('client',state,profile=='render' or (opts.pid and not pid),profile,pid)
            if path and profile~='render' and opts.pid and not pid then
                recorder:record('INFO','No matching client PID available for scoped AHK capture')
            end
            if not path then tell('Diagnostic not started: '..tostring(err));return false end
            if profile~="input" then render.start(true) end
            last_context=nil;last_frame=nil;self.last_native=nil
            tell('Recording ' .. profile .. ' diagnostics for 30 seconds. Use //xb diagnose mark, stop, or status.')
            tell('Destination: '..path)
            return true
        elseif mode=='mark' then
            if not recorder.active then tell('No diagnostic is active.');return false end
            recorder:mark(note or 'user marked event')
            render.event('MARK',nil,note or 'user marked event')
            tell('Diagnostic marked.')
            return true
        elseif mode=='stop' or mode=='off' then
            local ok,err=recorder:stop('manual',opts.snapshot())
            tell(ok and 'Diagnostic capture ended. Saving the log.' or tostring(err))
            return ok
        elseif mode=='status' then
            local status=recorder:status()
            tell(status.active and string.format('Diagnostic ON; %.1fs left; %d Lua events; render=%d events.',
                status.remaining,status.count,render.enabled and render.status().count or 0)
                or status.pending and 'Saving diagnostic: '..status.path
                or 'Diagnostic idle. Last log: '..tostring(status.path or 'none'))
            return true
        elseif mode=='snapshot' then
            local state=opts.snapshot()
            local path,err=recorder:start('client',state,true,'snapshot')
            if not path then tell('Snapshot not started: '..tostring(err));return false end
            recorder:stop('snapshot',opts.snapshot())
            tell('Snapshot finalizing: '..path)
            return true
        end
        tell('Use //xb diagnose start [input|render|full] or stop|mark|status|snapshot')
        return false
    end
    function self:tick(context)
        if recorder.active then
            local now=clock()
            render.begin_frame(now)
            if last_frame and now-last_frame>.05 then
                recorder:record('FRAME',string.format('frame_gap_ms=%.1f',(now-last_frame)*1000))
            end
            last_frame=now
            if context~=last_context then
                last_context=context
                recorder:record('CONTEXT',context)
            end
            if now>=recorder.deadline then
                recorder:stop('deadline',opts.snapshot())
            elseif render.enabled then
                local st=opts.frame_state()
                render.context(st.bar,st.set,context,st.editor,st.width,
                    st.height,st.scale,st.route)
            end
        end
        recorder:tick()
    end
    function self:close()
        if recorder.active or recorder.pending then recorder:force('addon-unload',opts.snapshot()) end
    end
    return self
end
return M
