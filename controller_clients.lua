-- A: registration belongs to the Lua session, not a character. A held owner
-- file distinguishes live sessions from stale metadata without a Lua FFI module.
local M={}
function M.new(options)
    local backend=options.backend or require('windows_file').new()
    local clock=options.clock or backend.clock or require('socket').gettime
    local id=backend.session_id
    local self={path=options.directory..id..'.ini',loaded=false}
    local create_dir=options.create_dir or windower.create_dir
    create_dir(options.directory)
    local function write(state,kill,closed)
        local data='[Client]\nprotocol=owner-file-v1\nid='..id..'\ntoken='..backend.token..'\nstate='..state..
            '\nkill='..tostring(kill==true)..'\nclosed='..string.format('%.6f',closed or 0)..'\n'
        return backend.replace(self.path,data)
    end
    function self:register(kill)
        if self.loaded and self.kill==kill then return true end
        if not self.owner then
            local owner,err=backend.hold_owner(self.path..'.owner')
            if not owner then return false,err end
            self.owner=owner
        end
        local ok,err=write('loaded',kill,0)
        if ok then self.loaded,self.kill=true,kill end
        if not ok and not self.loaded then self.owner:close();self.owner=nil end
        return ok,err
    end
    function self:close(kill)
        if not self.loaded then return true end
        local ok,err=write('closing',kill,clock())
        if ok then self.loaded=false;self.owner:close();self.owner=nil end
        return ok,err
    end
    return self
end
return M
