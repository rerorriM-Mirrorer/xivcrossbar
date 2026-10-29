-- Chat-only help. All commands use the same readable two-color syntax.
local M={}
pcall(require,'chat')
local fmt=require('libs/chat_status')
function M.heading(label)
    windower.add_to_chat(0,fmt.heading(label))
end
function M.command(syntax,description)
    local prefix=fmt.ink('//xb',200)
    windower.add_to_chat(0,prefix..fmt.ink(' '..syntax,207)..
        fmt.ink(' -> ',200)..fmt.ink(description,0))
end
function M.row(label,value)
    windower.add_to_chat(0,fmt.row(label,value))
end
return M
