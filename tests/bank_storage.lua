-- Simulated XML DOM/file backend exercises actual migration/persistence policy.
-- Production uses libs/xml2; XML byte validity is also checked during packaging.
local Store=require('libs/banks/storage')
local function simulated_parse(raw)
    if raw=='broken' then return nil,'bad XML' end
    local tokens={};local root={children={}};local stack={root}
    raw=raw:gsub('<%?.-%?>',''):gsub('<!%-%-.-%-%->','')
    local function unescape(v)return v:gsub('&lt;','<'):gsub('&gt;','>'):gsub('&quot;','"'):gsub('&apos;',"'"):gsub('&amp;','&')end
    local pos=1
    for first,tag,last in raw:gmatch('()<([^>]+)>()') do
        local text=raw:sub(pos,first-1)
        if text:match('%S') then table.insert(stack[#stack].children,{type='text',value=unescape(text)}) end
        if tag:sub(1,1)=='/' then
            if stack[#stack].name~=tag:sub(2) then return nil,'unbalanced' end
            table.remove(stack)
        else
            local node={type='tag',name=tag:match('^([%w_]+)'),children={},attributes={}}
            for k,v in tag:gmatch('([%w_]+)="([^"]*)"') do node.attributes[k]=v end
            table.insert(stack[#stack].children,node)
            if tag:sub(-1)~='/' then table.insert(stack,node) end
        end
        pos=last
    end
    if #stack~=1 then return nil,'unbalanced' end
    return root.children[1]
end
local parse=bank_test_parse or simulated_parse
local files={main='<settings><global><Other>keep &amp; me</Other><L1><X>39</X><Slot1><Alias>Old</Alias><Command>input /echo &quot;a &amp; b&quot;</Command></Slot1></L1></global><cioara><Style><OffsetX>35</OffsetX></Style><CompanionBanks><Version>2</Version><L1><Closed><Slot1><Kind>command</Kind><Alias>Custom</Alias><Command>trust stop</Command></Slot1></Closed></L1><LeftPanel><X>1657</X><Y>1669</Y><Initialized>true</Initialized></LeftPanel></CompanionBanks></cioara><myrr><L1><X>71</X></L1></myrr></settings>'}
files.main=files.main:gsub('<settings>', '<settings><!-- keep <L1>example</L1> verbatim --><empty><L1 /></empty>',1)
local original=files.main;local locks={};local fail
local opts={path='banks',main='main',parse=parse,say=function()end,
    read=function(p)return files[p]end,
    lock=function(p)if locks[p]then return nil,'busy'end;locks[p]=true;return function()locks[p]=nil end end,
    replace=function(p,s)if p==fail then return false,'disk failure'end;files[p]=s;return true end}
local store=Store.new(opts)
fail='banks';assert(not store:prepare() and files.main==original)
fail=nil;assert(store:prepare())
assert(files['main.before-bank-cleanup.bak']==original)
assert(files.main:find('<Other>keep &amp; me</Other>',1,true))
assert(files.main:find('<Style><OffsetX>35</OffsetX></Style>',1,true))
assert(not files.main:find('CompanionBanks',1,true) and not files.main:find('<L1 />',1,true))
assert(files.main:find('<!-- keep <L1>example</L1> verbatim -->',1,true),'comment bytes changed')
store:refresh(nil,'Cioara');local d=store.state.CompanionBanks
assert(d.LeftPanel.X==1657 and d.LeftPanel.Y==1669)
assert(d.L1.Closed.Slot1.Command=='trust stop')
local state=store.state
store:refresh(nil,'Myrr');assert(store.state==state and state.CompanionBanks.LeftPanel.X==71)
assert(state.CompanionBanks.L1L2.Closed.Slot1.Command=='input /echo "a & b"')
state.CompanionBanks.L1L2.Closed.Slot1.Command='';assert(store:save())
store:refresh(nil,'Myrr');assert(state.CompanionBanks.L1L2.Closed.Slot1.Command=='','cleared slot reimported')
-- A second migration never resurrects old input or overwrites later edits.
files.main=original;assert(store:prepare());store:refresh(nil,'Myrr')
assert(state.CompanionBanks.L1L2.Closed.Slot1.Command=='')
local other=Store.new(opts);other:refresh(nil,'Cioara')
state.CompanionBanks.LeftPanel.X=90;assert(store:save())
other.state.CompanionBanks.RightPanel.X=200;assert(other:save(),'another character was overwritten/conflicted')
store:refresh(nil,'Cioara');assert(state.CompanionBanks.RightPanel.X==200)
local stale=Store.new(opts);stale:refresh(nil,'Cioara')
state.CompanionBanks.RightPanel.X=300;assert(store:save())
stale.state.CompanionBanks.RightPanel.X=400;local before=files.banks
assert(not stale:save() and files.banks==before,'same-character stale writer accepted')
store:refresh(nil,'Cioara');state.CompanionBanks.RightPanel.X=500
fail='banks';assert(not store:save() and files.banks==before)
fail=nil;assert(store:save())
files.banks='broken';store:refresh(nil,'Cioara');assert(not store.ready and not store:save())
assert(files.banks=='broken','invalid file overwritten')
files.banks='<settings bank_storage_version="999"><global /></settings>'
assert(not store:prepare());assert(not Store.decode(files.banks,parse))
files.banks='<settings bank_storage_version="1"><global><CompanionBanks><Version>99</Version></CompanionBanks></global></settings>'
assert(not store:prepare(),'newer bank definition was downgraded')
files.banks='<settings bank_storage_version="1"><global /><cioara><CompanionBanks><Version>2</Version><L1><Visible>false</Visible></L1></CompanionBanks></cioara></settings>'
files.main=original;assert(store:prepare() and files.main==original,'partial file erased unimported legacy records')
store:refresh(nil,'Cioara');assert(store.ready and not state.CompanionBanks.L1.Visible)
assert(state.CompanionBanks.R1.Visible,'partial file did not inherit defaults')
files['banks.pending']=files.banks;files.banks=nil
store:refresh(nil,'Cioara');assert(store.ready and not state.CompanionBanks.L1.Visible,'interrupted swap discarded')
assert(store:prepare() and files.banks==nil,'recovery input was replaced by a fresh import')
store:refresh(nil,nil);assert(not store:save(),'prelogin bank write accepted')
assert(not next(locks),'lock leaked')
print('Bank storage: all-character import, byte-preserved main cleanup/backup, legacy migration, inheritance, empty commands, idempotence, atomic failure, partial/invalid/newer files and multiclient conflicts passed.')
