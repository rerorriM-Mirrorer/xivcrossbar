-- A: keep discovery off the ordinary controller-start path. The discovery
-- bootstrap verifies the executable; an actual v2 wrapper's status can seed the
-- same cache when upgrading an existing installation. #Requires remains the
-- final interpreter guard, even if a cached executable is replaced in place.
local M={}
local function version_ok(value)
    if type(value)~='string' then return false end
    local minor,patch,tail=value:match('^2%.(%d+)%.(%d+)(.*)$')
    return minor~=nil and (tail=='' or tail:match('^%.%d+$'))~=nil
        and (tonumber(minor)>0 or tonumber(patch)>=19)
end
local function safe_path(path,executable)
    if type(path)~='string' or path:find('[%c";|<>]') then return false end
    if not (path:match('^%a:[/\\]') or path:match('^\\\\[^\\]+\\[^\\]+\\')) then return false end
    return not executable or path:lower():match('%.exe$')~=nil
end
local function same_path(a,b)
    return a:lower():gsub('\\','/')==b:lower():gsub('\\','/')
end
local function parse(contents)
    local result,section={},nil
    for line in contents:gmatch('[^\r\n]+') do
        local heading=line:match('^%s*%[([^%]]+)%]%s*$')
        if heading then section=heading:lower()
        elseif section=='runtime' then
            local key,value=line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
            if key then result[key:lower()]=value end
        end
    end
    return result
end
function M.new(options)
    options=options or {}
    local open=options.open or io.open
    local function read(path)
        local f,err,code=open(path,'rb');if not f then return nil,err,code end
        local contents=f:read(4097);f:close()
        if not contents then return '' end
        contents=contents:gsub('^\239\187\191','')
        if #contents>4096 then return nil,'Runtime file exceeds 4096 bytes.',0 end
        return contents
    end
    local function size(path)
        local f=open(path,'rb');if not f then return nil end
        local value=f:seek('end');f:close();return value
    end
    local function record_ok(record,override)
        return safe_path(record.executable,true) and version_ok(record.version)
            and (not override or same_path(record.executable,override))
            and tonumber(record.size)~=nil and tonumber(record.size)==size(record.executable)
    end
    local function save(path,record)
        local contents='[Runtime]\nprotocol=ahk-v2-cache1\nexecutable='..record.executable..
            '\nversion='..record.version..'\nsize='..record.size..'\nEND\n'
        if options.replace then return options.replace(path,contents) end
        local f=open(path,'wb');if not f then return false end
        local ok=f:write(contents);local closed=f:close();return ok and closed
    end
    local self={}
    function self:plan(directory,profile,device,modifier,status)
        if not safe_path(directory,false) then return nil,'Invalid addon path for wrapper startup.' end
        local name,number=require('libs/controller/profiles').validate(profile,device)
        if not name or (modifier~='apps' and modifier~='ctrl') then return nil,'Invalid wrapper startup selection.' end
        local override_contents,err,code=read(directory..'data/controller-runtime.ini')
        if not override_contents and code and code~=2 then return nil,err end
        local override
        if override_contents then
            override=parse(override_contents).executable
            if override then override=override:match('^"(.*)"$') or override end
            if not safe_path(override,true) then return nil,'controller-runtime.ini needs an absolute v2 executable path.' end
        end
        local cache_path=directory..'data/controller-runtime-cache.ini'
        local contents=read(cache_path)
        local record=contents and contents:sub(-4)=='END\n' and parse(contents) or nil
        local source='cache'
        if not (record and record.protocol=='ahk-v2-cache1' and record_ok(record,override)) then
            record=nil
            if not contents and status and tostring(status.ahk_major)=='2' and safe_path(status.ahk_path,true)
                and version_ok(status.ahk_version) and (not override or same_path(override,status.ahk_path)) then
                local bytes=size(status.ahk_path)
                if bytes then record={executable=status.ahk_path,version=status.ahk_version,size=bytes};source='status' end
            end
            if record then save(cache_path,record) end
        end
        if record then
            local script=directory..'ffxi_directinput.ahk'
            local arguments='/ErrorStdOut "'..script..'" '..modifier..' '..name..' '..number
            return {mode='direct',source=source,executable=record.executable,arguments=arguments,
                command='run "'..record.executable..'" '..arguments}
        end
        -- Discovery is exceptional: fresh installation, changed override or a
        -- missing/replaced interpreter. It publishes a verified cache before
        -- launching; subsequent starts bypass CMD and PowerShell entirely.
        return {mode='bootstrap',source='discovery',command='run addons/xivcrossbar/launch-controller.cmd '..modifier..' '..name..' '..number}
    end
    return self
end
return M
