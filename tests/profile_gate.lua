-- Recovered gate plus the real root observer; no character storage is touched
-- while the lobby advertises a valid-looking server before an in-world entity.
local now=0
local gate=require('libs/controller/profile_gate').new(function()return now end)
local info={logged_in=false,server=1,zone=0}
local player={name='Cioara',id=123,main_job='WHM'}
local entity
local servers={[1]={en='Asura'},[2]={en='Fenrir'}}
local source=assert(io.open('xivcrossbar.lua')):read('*a')
local first=assert(source:find('local function check_profile_ready()',1,true))
local last=assert(source:find('-- trigger hotbar action',first,true))
local initialized,reloads=0,0
local state={ready=false}
local storage={identity_valid=false}
local env=setmetatable({profile_gate=gate,xivcrossbar=state,storage=storage,player={},resources={servers=servers},
    crossbar_drag={finish=function()end},ui={is_setup=true,hide=function()end},
    windower={ffxi={get_info=function()return info end,get_player=function()return player end,
        get_mob_by_id=function()return entity end},add_to_chat=function()end,
        send_command=function(command)assert(command=='lua r xivcrossbar');reloads=reloads+1 end},
    initialize=function(id,name,pid)
        assert(id==info.server and name==player.name and pid==player.id)
        initialized=initialized+1;state.ready=true;storage.identity_valid=true;return true
    end}, {__index=_G})
local observe=assert(load(source:sub(first,last-1)..'\nreturn check_profile_ready','actual observer','t',env))()
observe();now=2;observe();assert(initialized==0 and not storage.identity_valid)
info.logged_in=true;observe();now=3;observe();assert(initialized==0)
info.zone=100;entity={name='Other',id=999};observe();now=4;observe();assert(initialized==0)
entity={name='Cioara',id=123};info.server=2;observe()
now=4.5;observe();assert(initialized==0)
info.server=1;observe();now=4.6;info.server=2;observe()
now=5.34;observe();assert(initialized==0)
now=5.36;observe();assert(initialized==1 and state.ready and storage.identity_valid)
now=10;observe();assert(initialized==1 and reloads==0,'stable identity rebuilt repeatedly')
-- A later valid correction is still observed after ready, and requests one
-- normal Lua reload rather than stacking another UI on top of the first.
info.server=1;observe();now=10.8;observe()
assert(reloads==1 and initialized==1 and not storage.identity_valid and env.restart_pending)
observe();assert(reloads==1)
-- Asura itself is valid; the gate never hardcodes a preferred server.
gate:reset();env.restart_pending=false;state.ready=false;observe();now=11.6;observe()
assert(initialized==2 and gate.loaded:find('1/Cioara/123',1,true))
-- Character ID changes reset the window even when the name/server match.
gate:reset();player.id=124;entity.id=124;observe();now=12;player.id=125;entity.id=125;observe()
now=12.7;observe();assert(initialized==2);state.ready=false;now=12.8;observe();assert(initialized==3)
-- A frame invalidated between observation and initialization is retried.
gate:reset();state.ready=false;env.initialize=function()return false,'identity'end
observe();now=13.6;observe();assert(gate.loaded==nil)
assert(source:find('if not restart_pending and catalog_clock()>=next_identity_retry then',1,true))
assert(source:find('check_profile_ready()',source:find('-- ON PRERENDER',1,true),true))
print('Actual profile observer: lobby/entity guards, 0.75s stable tuple, changed IDs, real Asura, late correction reload and transient retry passed.')
