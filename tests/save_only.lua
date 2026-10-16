dofile('tests/menu_resources.lua')
local binder=require('action_binder');local player=require('player')
local opts=require('theme').apply(require('defaults'));opts.button_layout='playstation'
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},function()end,function()end,
    opts,function()return {'Basic'}end,0,0,1000,600)
windower.add_to_chat=function()end
player.custom_actions={}
player.refresh_custom_catalogs=function()return true end
player.custom_name_available=function()return true end
player.find_custom_action=function()end
for i=1,150 do
    local name=string.format('Action %03d',i)
    player.custom_actions[name]={name=name,id='id'..i,_scope='global',command='input /echo '..i}
end
player.custom_actions['Action 100 [Character]']={name='Action 100',id='id100',_scope='character',command='input /echo private'}
local function choose(id)
    for col,rows in pairs(binder.selector.field_coords)do
        for row,entry in pairs(rows)do
            if entry.id==id then binder.selector.selected_col,binder.selector.selected_row=col,row;return end
        end
    end
    error('choice not found '..id)
end
local function review(scope,key)
    binder:new_custom_action('', 'command')
    binder:set_capturing_text(false)
    binder.custom_action_review_field=nil
    binder.editing_custom_action=true
    binder.custom_action_original_name=key
    binder.custom_action_draft={name='Renamed action',id='id100',_scope=scope,command='input /echo saved'}
    binder:display_edit_custom_action_review()
end
binder.update_custom_action=function(_,d)
    player.custom_actions[d._scope=='global' and 'Action 100' or 'Action 100 [Character]']=nil
    local key=d.name..(d._scope=='character' and ' [Character]' or '')
    d._key=key
    player.custom_actions[key]={name=d.name,id=d.id,_scope=d._scope,command=d.command}
    return true
end
for _,scope in ipairs({'global','character'})do
    review(scope,scope=='global' and 'Action 100' or 'Action 100 [Character]')
    choose('SAVE_EDIT');binder:submit_selected_option()
    assert(binder.state==16 and binder.custom_action_draft==nil and not binder.is_hidden,
        'state='..tostring(binder.state)..' draft='..tostring(binder.custom_action_draft)..' hidden='..tostring(binder.is_hidden))
    local selected=binder.selector:get_selected_option()
    assert(selected.id=='CA_Renamed action'..(scope=='character' and ' [Character]' or ''))
    assert(binder.selector.current_page>1)
    binder:hide();binder:reset_state()
end
review('global','Renamed action')
binder.update_custom_action=function()return false end
choose('SAVE_EDIT');binder:submit_selected_option()
assert(binder.state==17 and binder.custom_action_draft~=nil,'failed save lost the draft')
binder.update_custom_action=function()return true end
choose('SAVE_BIND');binder:submit_selected_option()
assert(binder.state~=16 and binder.binding_custom_action_review,'Save & Bind changed to catalog return')
binder:hide();binder:reset_state();require('ui/resources').destroy_all()
print('Actual binder Save Only: renamed/scope-owned entries selected on later pages, failed draft retained and Save & Bind preserved.')
