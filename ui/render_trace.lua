-- A: optional observation of calls we already make. No extra native getters,
-- per-frame disk writes, renderer changes, or retained references to UI objects.
local M = {enabled=false, capacity=6000}
local ids = setmetatable({}, {__mode='k'})
local next_id = 0
local clock = function() return require('socket').gettime() end
local events, head, count, dropped, frame = {}, 1, 0, 0, 0
local started, previous_frame, context, epoch = 0, nil, nil, 0
local counters = {}
local max_gap = 0

local function clean(value)
    local s = tostring(value == nil and '<nil>' or value)
    s = s:gsub('[\r\n\t]', ' ')
    return s:sub(1,240)
end

function M.track(object, kind, owner, role)
    local info = ids[object]
    if not info then
        next_id=next_id+1
        info={id=next_id,kind=kind or 'unknown',owner=owner or 'unassigned',role=role or 'surface',revision=0}
        ids[object]=info
    end
    if owner then info.owner=owner end
    if role then info.role=role end
    return info
end

function M.alias(proxy, object, owner, role)
    local info=M.track(object,nil,owner,role)
    ids[proxy]=info
    return info
end

function M.caption(object, value)
    local info=M.track(object)
    if info.caption~=value then info.revision=info.revision+1;info.caption=value end
end

local function append(kind, info, values)
    local t=clock()
    local descriptor=info and table.concat({info.id,info.kind,info.owner,info.role,
        'rev='..info.revision,clean(info.caption or '')},'|') or '-'
    local line=string.format('%.6f\t%d\t%s\t%s\t%s',t,frame,kind,descriptor,values)
    local index=(head+count-1)%M.capacity+1
    if count==M.capacity then index=head;head=head%M.capacity+1;dropped=dropped+1
    else count=count+1 end
    events[index]=line
    counters[kind]=(counters[kind] or 0)+1
end

function M.event(kind, object, ...)
    if not M.enabled then return end
    local values={}
    for i=1,select('#',...) do values[i]=clean(select(i,...)) end
    append(kind,object and M.track(object) or nil,table.concat(values,'|'))
end

-- Native methods may be called with unchanged values every frame. Keep totals,
-- but store only changed values. This leaves useful history in the bounded ring.
function M.call(object, kind, ...)
    if not M.enabled then return end
    local info=M.track(object)
    if info.epoch~=epoch then info.epoch=epoch;info.last={} end
    local values={}
    for i=1,select('#',...) do values[i]=clean(select(i,...)) end
    local value=table.concat(values,'|')
    counters['calls.'..kind]=(counters['calls.'..kind] or 0)+1
    if info.last[kind]==value and kind~='native.text' then return end
    info.last[kind]=value
    append(kind,info,value)
end

function M.begin_frame(now)
    if not M.enabled then return end
    frame=frame+1
    if previous_frame then
        local gap=now-previous_frame
        max_gap=math.max(max_gap,gap)
        if gap>.05 then M.event('frame-gap',nil,gap) end
    end
    previous_frame=now
end

function M.context(...)
    if not M.enabled then return end
    local values={}
    for i=1,select('#',...) do values[i]=clean(select(i,...)) end
    local value=table.concat(values,'|')
    if context~=value then context=value;append('context',nil,value) end
end

function M.start()
    if M.enabled then return false end
    events,head,count,dropped,frame={},1,0,0,0
    counters={}
    context,previous_frame=nil,nil
    max_gap=0;epoch=epoch+1;started=clock();M.enabled=true
    M.event('start',nil,os.date('!%Y-%m-%dT%H:%M:%SZ'),_addon and _addon.version or 'test')
    return true
end

function M.stop() M.event('stop');M.enabled=false end

function M.status()
    return {enabled=M.enabled,count=count,dropped=dropped,frames=frame,max_gap=max_gap,started=started}
end

function M.dump()
    local lines={ '# XIVCrossbar render trace v1',
        '# Lua requests/returned extents only; not observed GPU pixels.',
        string.format('# started=%.6f frames=%d max_gap=%.6f retained=%d overwritten=%d capacity=%d',
            started,frame,max_gap,count,dropped,M.capacity),
        '# context fields: bar,set,input,binder_state,binder_page,chooser,menu,chat,viewport_w,viewport_h,scale,dirty,l1_mode,button_ack',
        '# time(socket.gettime)\tframe\tevent\tid|kind|owner|role|revision|caption\tvalues'}
    local names={};for name in pairs(counters) do names[#names+1]=name end;table.sort(names)
    for _,name in ipairs(names) do lines[#lines+1]='# '..name..'='..counters[name] end
    for i=1,count do lines[#lines+1]=events[(head+i-2)%M.capacity+1] end
    return table.concat(lines,'\n')..'\n'
end

-- Return chronological trace lines for the unified Beta 1 recorder.
-- Keeping this read-only leaves the rendering implementation unchanged.
function M.lines()
    local result={}
    for i=1,count do result[i]=events[(head+i-2)%M.capacity+1] end
    return result,dropped,M.status()
end

function M.save(path,replace)
    -- Assemble before touching the destination. The shared replacement helper
    -- stages a complete file and rolls back failed Windows swaps, preserving
    -- an earlier capture instead of truncating it at the start of a save.
    local assembled,body=pcall(M.dump)
    if not assembled then return false,body end
    local ok,saved,err=pcall(function()
        return (replace or require('libs/windows_file').new().replace)(path,body)
    end)
    if not ok then return false,saved end
    return saved,err
end

function M.command(mode,path,report)
    mode=type(mode)=='string' and mode:lower() or 'status'
    if mode=='on' then M.start();report('Render trace ON; use rendertrace mark after a hop, then rendertrace save.')
    elseif mode=='mark' then
        if not M.enabled then report('Render trace is OFF; use //xb rendertrace on first.');return end
        M.event('MARK');report('Render trace marked.')
    elseif mode=='save' or mode=='off' then
        if mode=='off' then M.stop() end
        if count==0 then report('No render trace captured.');return end
        local ok,err=M.save(path)
        report(ok and ('Render trace saved: '..path..(mode=='off' and ' (OFF)' or ''))
            or ('Render trace save failed: '..tostring(err)))
    elseif mode=='status' then
        report('Render trace '..(M.enabled and 'ON' or 'OFF')..'; retained='..count..', overwritten='..dropped..', frames='..frame)
    else report('//xb rendertrace [on|mark|save|off|status]') end
end

return M
