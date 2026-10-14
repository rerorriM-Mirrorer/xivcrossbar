local lines={}
function string.color(s,c) return '['..c..']'..s end
windower={add_to_chat=function(c,s)assert(c==0);lines[#lines+1]=s end}
local help=require('chat_help')
help.heading('Catalogs');help.command('catalog [global|character|status]','Choose new-action save location.')
assert(lines[1]:find('[140]--- [167]Catalogs[140] ---',1,true))
assert(lines[2]:find('[200]//xb[207] catalog [global|character|status][200] -> [0]',1,true))
print('Chat-only help fragment colors and complete command prefix passed.')
