-- Execute the real status branch and identity/logout guards using the root's
-- actual storage import. Earlier fixtures hid the missing import with a local.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local imported=assert(source:match("local storage = require%('storage'%)"),'root storage import missing')
local storage=require('storage')
local defaults=require('defaults')
local start=assert(source:find("    if command == 'status' then",1,true))
local stop=assert(source:find("\n        return\n    end",start,true))
local body=source:sub(start,stop+#'\n        return\n    end'-1)
local lines={}
local env=setmetatable({_addon={version='test'},settings=defaults,
    player={catalog_save_scope=function()return 'global' end,hotbar_settings={active_environment='Basic'}},
    client_registry={loaded=true},report_controller_status=function()end,xivcrossbar={ready=false},
    gamepad_mapper={},gamepad_state={},text_input_guard={},
    l1_bank={status=function()end},l1_bridge={received=0,rejected=0,ack=0,reset=function()end},
    l1_drag={finish=function()end},l1_view={destroy=function()end},personal_controls={close=function()end},
    controller_message_bridge={reset=function()end},
    windower={add_to_chat=function(_,line)lines[#lines+1]=line end},
}, {__index=_G})
local status=assert(load(imported..'\nreturn function(command)\n'..body..'\nend','real status branch','t',env))()
_G.storage=nil
storage.identity_valid=false;storage.directory=''
status('status')
assert(lines[1]:find('awaiting character login',1,true))
storage.identity_valid=true;storage.directory='Fenrir/Cioara';lines={}
status('status')
assert(lines[1]:find('Fenrir/Cioara',1,true) and lines[2]:find('registration: true',1,true))
local first=assert(source:find('function initialize(',1,true))
local last=assert(source:find('\n    xivcrossbar.pending_initialize = false',first,true))
local invalid=source:sub(first,last-1)..'\nend\nreturn initialize'
env.windower.ffxi={get_player=function()return nil end,get_info=function()return{logged_in=false}end}
env.resources={servers={}}
env.character_identity=require('character_identity')
env.profile_gate=require('profile_gate').new(function()return 0 end)
local initialize=assert(load(imported..'\n'..invalid,'pre-login identity guard','t',env))()
assert(initialize()==false and storage.identity_valid==false)
local begin=assert(source:find("windower.register_event('logout'",1,true))
local finish=assert(source:find("\n-- ON UNLOAD",begin,true))
local logout
local releases,closes=0,0
env.windower.register_event=function(name,callback)assert(name=='logout');logout=callback end
env.player.identity_confirmed=true
env.action_binder={selector={},hide=function()end,reset_state=function()end}
env.env_chooser={is_setup=true,close=function()closes=closes+1 end}
env.gamepad_mapper={is_showing=true,hide=function()end}
env.transport={reset=function()end}
env.release_gameplay_keys=function()releases=releases+1 end
env.ui={autoattack={reset=function()end},hide=function()end}
env.skillchains={logout=function()end}
env.theme_options={on_logout_unload_addon=false}
assert(load(imported..'\n'..source:sub(begin,finish-1),'actual logout callback','t',env))()
logout()
assert(not storage.identity_valid and not env.player.identity_confirmed)
assert(releases==1 and closes==1 and not env.gamepad_state.left_trigger)
assert(_G.storage==nil,'test accidentally supplied global storage')
print('Actual root storage import, logged-in/pre-login status, invalid identity and logout cleanup passed without a global storage fixture.')
