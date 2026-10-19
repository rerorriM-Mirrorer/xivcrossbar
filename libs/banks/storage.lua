-- Bank persistence is independent of Windower's main settings map. Read/merge
-- under the same cross-client lock used by catalogs; replace atomically on
-- Windows. A failed migration never removes its recovery input.
local Banks=require('libs/banks/banks')
local Legacy=require('libs/banks/legacy')
local M={}
local function copy(t) local r={};for k,v in pairs(t) do r[k]=type(v)=='table' and copy(v) or v end;return r end
local function shape() return {CompanionBanks=Banks.defaults(),L1=Legacy.defaults()} end
local function merge(a,b)
    for k,v in pairs(b or {}) do
        if type(v)=='table' and type(a[k])=='table' then merge(a[k],v) else a[k]=type(v)=='table' and copy(v) or v end
    end
    return a
end
local function diff(a,b)
    local r={}
    for k,v in pairs(b) do
        if type(v)=='table' then local d=diff(type(a[k])=='table' and a[k] or {},v);if next(d) then r[k]=d end
        elseif v~=a[k] then r[k]=v end
    end
    return r
end
local function escape(v)
    return tostring(v):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;'):gsub("'",'&apos;')
end
local function encode_table(t,indent,lines)
    local keys={};for k in pairs(t) do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys) do
        local v=t[k];local prefix=string.rep(' ',indent)..'<'..k..'>'
        if type(v)=='table' then
            lines[#lines+1]=prefix;encode_table(v,indent+4,lines)
            lines[#lines+1]=string.rep(' ',indent)..'</'..k..'>'
        else lines[#lines+1]=prefix..escape(v)..'</'..k..'>' end
    end
end
function M.encode(records)
    local lines={'<?xml version="1.1" ?>','<settings bank_storage_version="1" legacy_import_complete="true">'}
    encode_table(records,4,lines);lines[#lines+1]='</settings>'
    return table.concat(lines,'\n')..'\n'
end
-- Restore field spelling/types from the declared shape, as Windower config
-- does. Reject malformed values instead of silently replacing user commands.
local function decode_fields(node,defaults)
    local out,keys={},{}
    for k in pairs(defaults) do keys[k:lower()]=k end
    for _,tag in ipairs(node.children or {}) do
        local k=tag.name and keys[tag.name:lower()]
        if k then
            if out[k]~=nil then return nil,'Duplicate bank field: '..k end
            local expected=defaults[k]
            if type(expected)=='table' then
                local value,err=decode_fields(tag,expected);if not value then return nil,err end;out[k]=value
            else
                local value=''
                for _,child in ipairs(tag.children or {}) do
                    if child.type=='tag' then return nil,'Unexpected nested bank field: '..k end
                    if child.type=='text' then value=value..(child.value or '') end
                end
                if type(expected)=='number' then value=tonumber(value)
                    if not value or value~=value or math.abs(value)==math.huge then return nil,'Invalid bank number: '..k end
                elseif type(expected)=='boolean' then
                    if value~='true' and value~='false' then return nil,'Invalid bank boolean: '..k end
                    value=value=='true'
                end
                out[k]=value
            end
        end
    end
    return out
end
function M.decode(raw,parse)
    local ok,root,err=pcall(parse,raw)
    if not ok then return nil,root end
    if not root or root.name:lower()~='settings' then return nil,err or 'Expected settings XML.' end
    local version=root.attributes and root.attributes.bank_storage_version
    local imported=root.attributes and root.attributes.legacy_import_complete
    for _,node in ipairs(root.children or {}) do
        if node.type=='attribute' and node.name=='bank_storage_version' then version=node.value end
        if node.type=='attribute' and node.name=='legacy_import_complete' then imported=node.value end
    end
    if version and version~='1' then return nil,'Unsupported bank storage version: '..tostring(version) end
    local records={}
    for _,node in ipairs(root.children or {}) do
        if node.type=='tag' then
            local name=node.name:lower()
            if not name:match('^%a+$') or records[name] then return nil,'Invalid/duplicate bank character section.' end
            local value,why=decode_fields(node,shape());if not value then return nil,why end
            if value.CompanionBanks and (value.CompanionBanks.Version or 0)>2 then return nil,'Unsupported bank definition version.' end
            records[name]=value
        end
    end
    return records,nil,imported=='true'
end
local function effective(records,name)
    local t=merge(shape(),records.global)
    if name~='global' then merge(t,records[name]) end
    Banks.ensure(t);return t
end
local function strip_legacy(raw)
    -- Match live tags only: comments/CDATA may contain examples of old settings
    -- and must survive byte-for-byte too. Keep byte offsets while masking them.
    local function mask(s)return (s:gsub('[^\r\n]',' '))end
    local visible=raw:gsub('<!%-%-.-%-%->',mask):gsub('<!%[CDATA%[.-%]%]>',mask)
    local ranges={}
    for _,tag in ipairs({'[Cc][Oo][Mm][Pp][Aa][Nn][Ii][Oo][Nn][Bb][Aa][Nn][Kk][Ss]','[Ll]1'})do
        for _,pattern in ipairs({'<'..tag..'%s*>.-</'..tag..'%s*>','<'..tag..'%s*/>'})do
            local pos=1
            while true do
                local first,last=visible:find(pattern,pos);if not first then break end
                ranges[#ranges+1]={first,last};pos=last+1
            end
        end
    end
    table.sort(ranges,function(a,b)return a[1]<b[1] or a[1]==b[1] and a[2]>b[2]end)
    local pieces,pos={},1
    for _,range in ipairs(ranges)do
        if range[1]>=pos then pieces[#pieces+1]=raw:sub(pos,range[1]-1);pos=range[2]+1 end
    end
    pieces[#pieces+1]=raw:sub(pos);return table.concat(pieces)
end
function M.new(options)
    local self={state=shape(),source='legacy',ready=false,character='global'}
    local path,main=options.path,options.main
    local function read(path)
        local raw,err=options.read(path)
        if raw~=nil or err then return raw,err end
        -- A Windows swap interrupted between renames retains the prior file.
        -- Read that recovery copy until the next successful replace restores it.
        return options.read(path..'.pending')
    end
    local function warn(err) if options.say then options.say('Bank settings: '..tostring(err)) end end
    local function transaction(fn)
        local release,err=options.lock(path);if not release then return false,err end
        local ok,a,b=pcall(fn);release()
        if not ok then return false,a end
        return a,b
    end
    local function checked(raw)
        if not raw then return nil,'Bank settings file is missing.' end
        return M.decode(raw,options.parse)
    end
    function self:prepare()
        local ok,err=transaction(function()
            local raw,read_error=read(path)
            if read_error then return false,read_error end
            if raw then
                local existing,why,imported=checked(raw);if not existing then return false,why end
                -- A hand-created partial file is authoritative for its edits,
                -- but is not evidence that all legacy characters were imported.
                if not imported then return true end
            else
                local original,why=read(main);if why then return false,why end
                local legacy={global={}}
                if original then legacy,why=M.decode(original,options.parse);if not legacy then return false,why end end
                local records={global=effective(legacy,'global')}
                for name in pairs(legacy) do if name~='global' then records[name]=diff(records.global,effective(legacy,name)) end end
                local contents=M.encode(records)
                local verified,verify_error=checked(contents);if not verified then return false,verify_error end
                local written,write_error=options.replace(path,contents);if not written then return false,write_error end
                local reread=read(path);if reread~=contents then return false,'Bank migration readback failed; main settings retained.' end
            end
            -- Strip only the two complete bank sections, preserving unrelated
            -- bytes/comments and every character's main preferences verbatim.
            local release,lock_error=options.lock(main);if not release then return false,lock_error end
            local safe,result,detail=pcall(function()
                local original,why=read(main);if why then return false,why end
                if not original then return true end
                local cleaned=strip_legacy(original)
                if cleaned==original then return true end
                local backup=main..'.before-bank-cleanup.bak'
                local old,backup_error=read(backup);if backup_error then return false,backup_error end
                if not old then local saved,save_error=options.replace(backup,original);if not saved then return false,save_error end end
                local current=read(main)
                if current~=original then return false,'Main settings changed during migration; retry on reload.' end
                return options.replace(main,cleaned)
            end)
            release();if not safe then return false,result end;return result,detail
        end)
        if not ok then warn(err) end
        return ok,err
    end
    function self:refresh(legacy,name)
        self.character=type(name)=='string' and name:match('^%a+$') and name:lower() or 'global'
        local raw,err=read(path);local records
        if not err then records,err=checked(raw) end
        self.ready=records~=nil
        local value
        if records then value=effective(records,self.character);self.source=path
        else
            -- Invalid/newer files are never overwritten. Keep legacy/factory
            -- controls usable for this session and report why saving is blocked.
            local original=read(main)
            local recovery=original and M.decode(original,options.parse)
            value=recovery and effective(recovery,self.character) or merge(shape(),legacy or {})
            Banks.ensure(value);self.source='legacy (save blocked)';warn(err)
        end
        self.state.CompanionBanks=value.CompanionBanks;self.state.L1=value.L1
        self.expected=records and M.encode({current=effective(records,self.character)}) or nil
    end
    function self:save()
        if not self.ready then warn('Saving blocked; repair or restore companion_banks.xml, then reload.');return false end
        local ok,err=transaction(function()
            local raw,why=read(path);if why then return false,why end
            local records;records,why=checked(raw);if not records then return false,why end
            if M.encode({current=effective(records,self.character)})~=self.expected then
                return false,'This character changed in another client; draft retained. Reload before editing again.'
            end
            if self.character=='global' then return false,'Log in before saving bank settings.' end
            records[self.character]=diff(effective(records,'global'),self.state)
            local contents=M.encode(records)
            local verified,verify_error=checked(contents);if not verified then return false,verify_error end
            local backed,backup_error=options.replace(path..'.bak',raw);if not backed then return false,backup_error end
            local written,write_error=options.replace(path,contents);if not written then return false,write_error end
            if read(path)~=contents then return false,'Bank save readback failed; backup retained.' end
            self.expected=M.encode({current=effective(records,self.character)})
            return true
        end)
        if not ok then warn(err) end
        return ok,err
    end
    return self
end
return M
