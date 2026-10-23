local t=require('libs/controller/transport')
assert(t:login_key(t.signals[59],{})=='up')
assert(t:login_key(t.signals[63],{})=='enter')
assert(t:login_key(t.signals[65],{})=='escape')
assert(t:login_key(t.signals[87],{})==nil)
assert(t:login_key(t.signals[88],{})==nil)
assert(t:login_key(t.signals[68],{})==nil)
t:reset()
local _,edge=t:edge(63,true,'login');assert(edge=='down')
local _,repeat_edge=t:edge(63,true,'login');assert(repeat_edge=='repeat')
local _,release,owner=t:edge(63,false,'gameplay');assert(release=='up' and owner=='login')
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
assert(source:find("if context == 'login' then",1,true))
assert(source:find("if not xivcrossbar.ready then return 'login' end",1,true))
print('Pre-login arrow/confirm/cancel transport, ignored trigger/set signals and edge ownership passed.')
-- The wizard saves controller-specific names; the transport uses positions.
local layouts={
    xbox={confirm_button='a',cancel_button='b',mainmenu_button='y',activewindow_button='x'},
    playstation={confirm_button='cross',cancel_button='circle',mainmenu_button='triangle',activewindow_button='square'},
    nintendo={confirm_button='b',cancel_button='a',mainmenu_button='x',activewindow_button='y'},
    gamecube={confirm_button='a',cancel_button='x',mainmenu_button='y',activewindow_button='b'},
}
for layout,mapping in pairs(layouts) do
    mapping.button_layout=layout
    for dik,key in pairs({[63]='enter',[65]='escape',[66]='numpad-',[64]='numpad+'}) do
        assert(t:gameplay_key(t.signals[dik],mapping,'ijkl')==key,layout..' '..dik)
        assert(t:login_key(t.signals[dik],mapping)==key)
    end
    mapping.confirm_button,mapping.mainmenu_button=mapping.mainmenu_button,mapping.confirm_button
    assert(t:gameplay_key(t.signals[66],mapping)=='enter','remapped confirm ignored')
    assert(t:gameplay_key(t.signals[63],mapping)=='numpad-','remapped menu ignored')
end
assert(t:login_key(t.signals[63],{button_layout='xbox'})=='enter')
assert(t:login_key(t.signals[65],{button_layout='xbox'})=='escape')
print('Actual saved face roles: Xbox, PS5, Nintendo and GameCube gameplay/login and arbitrary remaps passed.')
