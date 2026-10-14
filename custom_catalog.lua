-- A: catalogs merge for display, but edits retain ownership. Saves merge one
-- intended entry under a lock rather than writing an old whole-catalog snapshot.
local M={}
local fields={'name','id','alias','command','icon','linked_action','linked_type','deleted'}
local function escape(s)
    return s:gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;'):gsub("'",'&apos;')
end
function M.copy(record)
    if not record then return nil end
    local out={};for _,k in ipairs(fields) do if record[k]~=nil and record[k]~='' then out[k]=record[k] end end
    return out
end
function M.same(a,b)
    if not a or not b then return a==b end
    for _,k in ipairs(fields) do if (a[k] or '')~=(b[k] or '') then return false end end
    return true
end
function M.encode(records)
    local names={};for name in pairs(records) do names[#names+1]=name end;table.sort(names)
    local lines={'<custom_actions>'}
    for _,name in ipairs(names) do
        local rec=records[name];lines[#lines+1]='    <action>'
        for _,k in ipairs(fields) do
            local value=rec[k]
            if value~=nil and value~='' then lines[#lines+1]='        <'..k..'>'..escape(tostring(value))..'</'..k..'>' end
        end
        lines[#lines+1]='    </action>'
    end
    lines[#lines+1]='</custom_actions>';return table.concat(lines,'\n')..'\n'
end
function M.decode(raw,parse)
    if raw==nil then return {} end
    local dom,err=parse(raw)
    if not dom or dom.name~='custom_actions' then return nil,err or 'Expected a custom_actions XML document.' end
    local records,ids={},{}
    for _,node in ipairs(dom.children or {}) do
        if node.name=='action' then
            local rec={}
            for _,tag in ipairs(node.children or {}) do
                if tag.children and tag.children[1] then rec[tag.name]=tag.children[1].value end
            end
            if rec.name and rec.name:match('%S') then
                rec.id=rec.id or ('legacy:'..rec.name)
                if ids[rec.id] then return nil,'Duplicate catalog identity: '..rec.id end
                ids[rec.id]=true
                local key=rec.deleted=='true' and ('@retired:'..rec.id) or rec.name
                if records[key] then return nil,'Duplicate catalog entry: '..rec.name end
                records[key]=rec
            end
        end
    end
    return records
end
function M.view(global,character,save_scope)
    local out={}
    for _,scope in ipairs({'global','character'}) do
        for name,record in pairs(scope=='global' and global or character) do
            if record.deleted~='true' then
            local copy=M.copy(record);copy._scope=scope
            local key=name
            if global[name] and character[name] then key=name..' ['..(scope=='global' and 'Global' or 'Character')..']' end
            while out[key] do key=key..' ['..scope..']' end
            copy._key=key;out[key]=copy
            end
        end
    end
    return out
end
function M.find(view,name,scope)
    if view[name] then return view[name],name end
    local fallback,key
    for k,rec in pairs(view) do
        if rec.name==name then
            if rec._scope==scope then return rec,k end
            fallback,key=rec,k
        end
    end
    return fallback,key
end
function M.save(options,path,expected,record)
    local release,lock_error=options.lock(path)
    if not release then return false,lock_error end
    local ok,result,detail=pcall(function()
        local raw,read_error=options.read(path)
        if read_error then return false,read_error end
        local latest,err=M.decode(raw,options.parse);if not latest then return false,err end
        if expected then
            if not M.same(latest[expected.name],expected) then return false,'This action changed in another client; draft retained. Reopen it before saving.' end
            if record and record.name~=expected.name and latest[record.name] then return false,'That name already exists in this catalog.' end
            if not record then
                local retired=M.copy(expected);retired.deleted='true'
                latest['@retired:'..retired.id]=retired
            end
            latest[expected.name]=nil
        elseif record and latest[record.name] then return false,'That name already exists in this catalog.' end
        if record then latest[record.name]=M.copy(record) end
        local contents=M.encode(latest)
        local checked,parse_error=M.decode(contents,options.parse)
        if not checked then return false,parse_error end
        if raw then
            local backed,backup_error=options.replace(path..'.bak',raw)
            if not backed then return false,backup_error end
        end
        local written,write_error=options.replace(path,contents)
        if not written then return false,write_error end
        return true,latest
    end)
    release()
    if not ok then return false,tostring(result) end
    return result,detail
end
return M
