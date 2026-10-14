local c=require('custom_catalog')
-- Simulated parser/backend isolate coordination from unavailable Windows APIs.
local function parse(raw)
    if not raw:match('^<custom_actions>') then return nil,'Invalid XML' end
    local function decode(s)
        return s:gsub('&quot;','"'):gsub('&apos;',"'"):gsub('&lt;','<'):gsub('&gt;','>'):gsub('&amp;','&')
    end
    local dom={name='custom_actions',children={}}
    for body in raw:gmatch('<action>(.-)</action>') do
        local node={name='action',children={}}
        for key,value in body:gmatch('<([%w_]+)>(.-)</[%w_]+>') do
            node.children[#node.children+1]={name=key,children={{value=decode(value)}}}
        end
        dom.children[#dom.children+1]=node
    end
    return dom
end
local files,locked,releases={},false,0
local options={parse=parse,read=function(p)return files[p]end,
    lock=function()if locked then return nil,'busy' end;locked=true;return function()locked=false;releases=releases+1 end end,
    replace=function(p,raw)files[p]=raw;return true end}
assert(c.save(options,'global',nil,{name='Bow',id='one',command='' }))
assert(not files.global:find('<command>'))
local original=c.decode(files.global,parse).Bow
assert(c.save(options,'global',nil,{name='Dance',id='two',command='input /echo "a & b"; input /dance'}))
assert(c.decode(files.global,parse).Bow and c.decode(files.global,parse).Dance)
assert(c.save(options,'global',original,{name='Bow',id='one',command='input /bow'}))
local before=files.global
assert(not c.save(options,'global',original,{name='Bow',id='one',command='stale'}))
assert(files.global==before and not locked)
local current=c.decode(files.global,parse).Bow
assert(c.save(options,'global',current,{name='Bow2',id='one',command='input /bow'}))
assert(c.decode(files.global,parse).Bow2 and not c.decode(files.global,parse).Bow)
local global={Bow={name='Bow',id='g'}},character
character={Bow={name='Bow',id='p'},Private={name='Private',id='x'}}
local view=c.view(global,character,'global')
assert(view['Bow [Global]'] and view['Bow [Character]'] and view.Private)
assert(c.find(view,'Bow','global').id=='g' and c.find(view,'Bow','character').id=='p')
locked=true;before=files.global
assert(not c.save(options,'global',nil,{name='Blocked',id='b'}));assert(files.global==before)
locked=false
local replace=options.replace;options.replace=function()return false,'disk failure'end
assert(not c.save(options,'global',nil,{name='Failure',id='f'}));assert(files.global==before and not locked)
options.replace=replace
print('Merged catalog visibility, source choice, stale-save merging/conflicts, rename, blank commands, locks and failed-write preservation passed.')
