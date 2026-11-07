-- Execute actual public selector navigation; no UI runtime required.
local f=assert(io.open('ui/selectablelist.lua','rb'));local src=f:read('*a');f:close()
local a=assert(src:find('function selectable_list:move_selection',1,true))
local b=assert(src:find('function selectable_list:increment_row()',a,true))
local M={max_row=2,max_col=3,selected_row=1,selected_col=1,highlighted=0,current_page=2}
local valid={['1,1']=true,['1,3']=true,['2,1']=true,['3,3']=true}
function M:is_valid_row_col(r,c)return valid[r..','..c]==true end
function M:highlight_selection()self.highlighted=self.highlighted+1 end
assert(load(src:sub(a,b-1),'real beta selector movement','t',setmetatable({selectable_list=M},{__index=_G})))()
M:move_selection(0,-1);assert(M.selected_col==3 and M.selected_row==1,'left wrap should skip missing middle')
M:move_selection(0,1);assert(M.selected_col==1,'right wrap')
M.selected_row=2;M.selected_col=3;M:move_selection(1,0);assert(M.selected_row==3,'includes page button cell')
M:move_selection(1,0);assert(M.selected_row==1,'vertical wrap to top')
M:move_selection(0,-1);assert(M.selected_col==1,'same cell if no other valid in row?')
assert(M.current_page==2,'wrap must not change page')
local seen=M.highlighted;M:move_selection(2,0);assert(M.highlighted==seen,'invalid movement ignored')
print('Public editor row and column wrap, skipped holes, page boundary and invalid direction passed.')
