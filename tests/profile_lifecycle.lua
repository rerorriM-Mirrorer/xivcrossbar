-- Actual initializer and logout handlers with storage/UI spies. No Windows API
-- is present: this verifies sequencing and mutation guards, not native loading.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local info={logged_in=true,server=2,zone=100}
local wp={name='Cioara',id=123,main_job='WHM',sub_job=nil,status=0}
local entity={name='Cioara',id=123}
local state={ready=false}
local storage={identity_valid=false}
local player={hotbar={},vitals={},hotbar_settings={}}
local setups,loads,hidden,started,released=0,0,0,0,0
function player:initialize(p,server)
    assert(self.identity_confirmed and server=='Fenrir' and p==wp)
    self.server,self.name=server,p.name;storage.identity_valid=true;setups=setups+1
end
function player:load_hotbar()loads=loads+1;return true end
local ui={setup=function()end,load_player_hotbar=function()end,
    get_set_chooser_anchor=function()end,hide=function()hidden=hidden+1 end}
local env=setmetatable({xivcrossbar=state,storage=storage,player=player,ui=ui,
    chat_format={say=function()end},
    character_identity=require('character_identity'),profile_gate=require('profile_gate').new(function()return 0 end),
    resources={servers={[1]={en='Asura'},[2]={en='Fenrir'}}},
    windower={ffxi={get_player=function()return wp end,get_info=function()return info end,
        get_mob_by_id=function()return entity end},get_windower_settings=function()return {ui_x_res=1280,ui_y_res=720}end,
        send_command=function()end},buttonmapping={validate=function()return true end},
    theme_options={},y_adjust=450,action_binder={setup=function()end,set_ui_offset_callback=function()end},
    env_chooser={get_default_active_environment=function()return 'default'end,setup=function()end,set_anchor=function()end},
    consumables={setup=function()end},gamepad_converter={setup=function()end},aa_set_engaged=function()end,
    set_active_environment=function()end,gamepad_state={},controller_bind_prefix='#',
    skillchains={load=function()end,login=function()end,logout=function()end},
    start_controller_wrappers=function()started=started+1 end,
    release_gameplay_keys=function()released=released+1 end,transport={reset=function()end},
    message_lease={close=function()end},message_bridge=nil}, {__index=_G})
local first=assert(source:find('function initialize(',1,true))
local last=assert(source:find('-- Continue observing after initialization:',first,true))
assert(load(source:sub(first,last-1),'real initialize','t',env))()
assert(env.initialize()==false and setups==0 and not storage.identity_valid)
assert(env.initialize(1,'Cioara',123)==false and setups==0)
info.server=99;assert(env.initialize(99,'Cioara',123)==false and setups==0)
info.server=2;entity=nil;assert(env.initialize(2,'Cioara',123)==false and setups==0)
entity={name='Other',id=123};assert(env.initialize(2,'Cioara',123)==false and setups==0)
entity.name='Cioara';assert(env.initialize(2,'Cioara',123)==true)
assert(setups==1 and loads==1 and state.ready and storage.identity_valid)
local handlers={}
env.windower.register_event=function(name,fn)handlers[name]=fn end
first=assert(source:find('-- ON LOAD',1,true));last=assert(source:find('-- ON UNLOAD',first,true))
assert(load(source:sub(first,last-1),'real load/login/logout','t',env))()
info.logged_in=false;handlers.load();assert(started==1,'wrapper startup depended on world identity')
handlers.logout();assert(not state.ready and not state.initialized and not storage.identity_valid)
assert(not player.identity_confirmed and released==1 and hidden==1)
info.logged_in=true;handlers.login();assert(not state.ready and setups==1,'login opened storage before observation')
print('Real initialize/load/login/logout: guarded storage, no-sub identity, independent wrapper startup and logout invalidation passed.')
