-- Execute the actual selector navigation against full and ragged grids.
local f=assert(io.open('ui/selectablelist.lua'));local source=f:read('*a');f:close()
local first=assert(source:find('function selectable_list:move_selection(dr, dc)',1,true))
local last=assert(source:find('\nfunction selectable_list:increment_row()',first,true))
local grid={max_row=3,max_col=4,selected_row=1,selected_col=1,highlights=0,cells={}}
function grid:is_valid_row_col(r,c)return self.cells[r..':'..c]==true end
function grid:highlight_selection()self.highlights=self.highlights+1 end
assert(load(source:sub(first,last-1),'actual menu wrap','t',{selectable_list=grid}))()
for r=1,3 do for c=1,4 do grid.cells[r..':'..c]=true end end
local function expect(r,c,dr,dc,er,ec)
 grid.selected_row,grid.selected_col=r,c;local n=grid.highlights
 grid:move_selection(dr,dc)
 assert(grid.selected_row==er and grid.selected_col==ec,'wrong row/column wrap')
 assert(grid.highlights==n+((r~=er or c~=ec) and 1 or 0),'extra highlight')
end
expect(1,1,0,-1,1,4);expect(2,4,0,1,2,1)
expect(1,2,-1,0,3,2);expect(3,2,1,0,1,2)
grid.cells['3:3']=nil;grid.cells['3:4']=nil
expect(3,2,0,1,3,1);expect(3,1,0,-1,3,2)
expect(2,4,1,0,1,4);expect(1,4,-1,0,2,4)
grid.cells['2:2']=false;expect(1,2,1,0,3,2)
grid.cells['4:4']=true;expect(2,4,1,0,4,4);expect(4,4,0,1,4,4)
grid.cells={['1:1']=true};expect(1,1,1,0,1,1);expect(1,1,0,1,1,1)
grid.cells={};expect(1,1,0,1,1,1)
expect(1,1,0,0,1,1)
print('Actual menu wrap: same row/column, ragged rows, skipped disabled/empty cells, footer and singleton bounds passed.')
