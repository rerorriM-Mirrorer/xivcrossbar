-- Shared chat-only formatting; syntax and prose remain independently readable.
local M={}
function M.heading(label)
    windower.add_to_chat(0,require('libs/chat_status').heading(label))
end
function M.command(syntax,description)
    windower.add_to_chat(0,('//xb'):color(200)..(' '..syntax):color(207)..(' -> '):color(200)..description:color(0))
end
return M
