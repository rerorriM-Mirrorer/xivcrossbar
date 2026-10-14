-- A: short exclusive file handles coordinate clients; same-directory replacement
-- publishes a complete catalog. Closing a handle releases the lock, even on crash.
local M = {}
function M.new()
    local ffi = require('ffi')
    ffi.cdef[[
        void* __stdcall CreateFileW(const unsigned short*, unsigned long, unsigned long, void*, unsigned long, unsigned long, void*);
        int __stdcall CloseHandle(void*);
        int __stdcall MoveFileExW(const unsigned short*, const unsigned short*, unsigned long);
        int __stdcall MultiByteToWideChar(unsigned int, unsigned long, const char*, int, unsigned short*, int);
        unsigned long __stdcall GetCurrentProcessId(void);
        unsigned long __stdcall GetLastError(void);
    ]]
    local api = ffi.load('kernel32')
    local function wide(path)
        local n=api.MultiByteToWideChar(65001,0,path,-1,nil,0)
        if n==0 then return nil end
        local out=ffi.new('unsigned short[?]',n)
        if api.MultiByteToWideChar(65001,0,path,-1,out,n)==0 then return nil end
        return out
    end
    local counter=0
    return {
        pid=tonumber(api.GetCurrentProcessId()),
        lock=function(path)
            local p=wide(path..'.lock');if not p then return nil,'Invalid catalog path.' end
            local h=api.CreateFileW(p,0x80000000+0x40000000,0,nil,4,128,nil)
            if h==ffi.cast('void*',-1) then return nil,'Catalog is busy or inaccessible; draft retained. Retry saving. (Windows '..tonumber(api.GetLastError())..')' end
            return function() api.CloseHandle(h) end
        end,
        replace=function(path,contents)
            counter=counter+1
            local temp=path..'.tmp.'..tonumber(api.GetCurrentProcessId())..'.'..counter
            local f,err=io.open(temp,'wb');if not f then return false,err end
            local ok,write_err=f:write(contents);local closed,close_err=f:close()
            if not ok or not closed then os.remove(temp);return false,write_err or close_err end
            if api.MoveFileExW(wide(temp),wide(path),1+8)==0 then
                local code=tonumber(api.GetLastError());os.remove(temp)
                return false,'Catalog replacement failed (Windows '..code..').'
            end
            return true
        end,
    }
end
return M
