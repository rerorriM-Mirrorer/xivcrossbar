-- Real binder plus real catalog callbacks; persistent writes are a failure-
-- injectable spy. Exercise list paging, rename, retry and the existing bind flow.
dofile('tests/menu_resources.lua')
local binder=require('action_binder')
local player=package.loaded.player
local resources=require('ui/resources')
local screen={ui_x_res=1280,ui_y_res=720}
windower.get_windower_settings=function()return screen end
windower.ffxi={get_player=function()return {main_job='WAR',sub_job=nil}end}
windower.add_to_chat=function()end
local failing,writes,saved_binding=false,0,nil
function player:save_custom_actions_file()
    writes=writes+1
    if failing=='throw' then error('simulated write failure') end
    return not failing
end
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local first=assert(source:find('function save_custom_action(',1,true))
local last=assert(source:find('-- Delete Custom Action callback',first,true))
local env=setmetatable({player=player,windower=windower,chat_format={say=function()end}}, {__index=_G})
assert(load(source:sub(first,last-1),'actual catalog save/update','t',env))()
local options=require('theme').apply(require('defaults'));options.button_layout='playstation'
local function select_id(id)
    for col,rows in pairs(binder.selector.field_coords) do
        for row,entry in pairs(rows) do
            if entry.id==id then
                binder.selector.selected_row,binder.selector.selected_col=row,col
                binder:submit_selected_option();return
            end
        end
    end
    error('visible choice missing: '..id)
end
local function returned(name)
    assert(binder.state==16 and not binder.is_hidden and binder.selector.is_showing)
    assert(binder.selector:get_selected_option().text==name,'saved entry/page not selected')
    assert(not binder.custom_action_draft and not binder.capturing_text)
    assert(not binder.binding_custom_action_review and not binder.custom_action_entry_origin)
    assert(not binder.action_alias and not binder.action_command and not binder.action_icon)
end
for _,resolution in ipairs({{960,540},{1280,720},{1600,900},{1920,1080},{2560,1440},{3840,2160}}) do
    screen.ui_x_res,screen.ui_y_res=resolution[1],resolution[2]
    binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},
        function(...)saved_binding={...}end,function()end,options,function()return {'Basic'}end,
        nil,nil,nil,nil,nil,nil,env.save_custom_action,env.update_custom_action)
    binder:reset_state();player.custom_actions={}
    local capacity=binder.selector.normal_max_row*binder.selector.normal_max_col
    for i=1,capacity*2+1 do player.custom_actions[string.format('Entry%03d',i)]={command='input /echo old'} end
    -- A command-origin new entry sorts onto page three.
    assert(binder:new_custom_action('Zebra','command'))
    binder.custom_action_draft.command='input /echo new';select_id('SAVE_EDIT');returned('Zebra')
    assert(binder.selector.current_page==3 and player.custom_actions.Zebra.command=='input /echo new')
    -- Edit the selected entry, rename it to the first page, save, edit again.
    binder:submit_selected_option();assert(binder.editing_custom_action)
    binder.custom_action_draft.name='Aardvark';select_id('SAVE_EDIT');returned('Aardvark')
    assert(binder.selector.current_page==1 and not player.custom_actions.Zebra)
    binder:submit_selected_option();binder.custom_action_draft.alias='Pretty label'
    select_id('SAVE_EDIT');returned('Aardvark');assert(player.custom_actions.Aardvark.alias=='Pretty label')
    -- Back returns to the selected main-menu action rather than a stale review.
    binder.selection_states[1]={page=1,row=1,col=3}
    binder:go_back();assert(binder.state==1 and binder.selector:get_selected_option().text=='Edit Custom Action')
    -- A menu-origin create also remains in the editable list after saving.
    binder:hide();binder:reset_state();assert(binder:new_custom_action('MenuEntry','menu'))
    select_id('SAVE_EDIT');returned('MenuEntry')
    -- Failed create, failed rename and invalid/duplicate name retain the draft.
    binder:hide();binder:reset_state();assert(binder:new_custom_action('Failed','command'))
    failing=true;select_id('SAVE_EDIT')
    assert(binder.state==17 and binder.custom_action_draft.name=='Failed' and not player.custom_actions.Failed)
    failing=false;select_id('SAVE_EDIT');returned('Failed')
    binder:submit_selected_option();binder.custom_action_draft.name='FailedRename'
    failing='throw';select_id('SAVE_EDIT')
    assert(binder.state==17 and player.custom_actions.Failed and not player.custom_actions.FailedRename)
    failing=false;select_id('SAVE_EDIT');returned('FailedRename')
    binder:submit_selected_option();binder.custom_action_draft.name='Aardvark'
    binder:display_edit_custom_action_review();local before=writes;select_id('SAVE_EDIT')
    assert(binder.state==17 and writes==before,'duplicate name saved or lost draft')
    binder.custom_action_draft.name='';binder:display_edit_custom_action_review();select_id('SAVE_EDIT')
    assert(binder.state==17 and writes==before,'blank name saved or lost draft')
    binder:hide();binder:reset_state()
    -- Save & Bind remains unchanged, including Back to the intact draft.
    assert(binder:new_custom_action('BindMe','command'))
    binder.custom_action_draft.command='input /echo bound';select_id('SAVE_BIND')
    assert(binder.state==5 and binder.binding_custom_action_review and not binder.selector.is_showing)
    binder:go_back();assert(binder.state==17 and binder.custom_action_draft.name=='BindMe')
    select_id('SAVE_BIND');binder.active_crossbar,binder.hotkey=2,4;binder:assign_action()
    assert(saved_binding[4]=='BindMe' and saved_binding[6]=='input /echo bound' and binder.is_hidden)
    -- Cancel without saving still follows the original command-origin exit.
    assert(binder:new_custom_action('Unsaved','command'));binder:go_back()
    assert(binder.is_hidden and not player.custom_actions.Unsaved)
    -- Repeated save-return transitions must not retain previous review objects.
    local baseline=resources.snapshot()
    for i=1,30 do
        assert(binder:new_custom_action('Aardvark','command'));select_id('SAVE_EDIT');returned('Aardvark')
        binder:hide();binder:reset_state()
        local after=resources.snapshot()
        assert(after.text==baseline.text and after.image==baseline.image,'save-return retained drawings')
    end
end
resources.destroy_all()
print('Save-return: six resolutions, new/edit/rename/paged selection, menu/command origins, failures/invalid names, Back/cancel, Save & Bind and 180 bounded repeat cycles passed.')
