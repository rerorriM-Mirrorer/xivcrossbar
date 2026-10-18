-- Fixture: Windower/Lua live config.lua merge function (blank-line whitespace trimmed).
-- Source blob 7829c7f199b447130c75228a2acfe3e2d259e6f2, inspected 2026-10-18.
local merge
function merge(t, t_merge, path)
    path = type(path) == 'string' and T{path} or path

    local keys = {}
    for key in pairs(t) do
        keys[tostring(key):lower()] = key
    end

    if not t_merge then
        return t
    end

    for lkey, val in pairs(t_merge) do
        local key = keys[lkey:lower()]
        if not key then
            if type(val) == 'table' then
                t[lkey] = setmetatable(table.copy(val), getmetatable(val) or _meta.T)
            else
                t[lkey] = val
            end

        else
            local err = false
            local oldval = rawget(t, key)
            local oldtype = type(oldval)

            if oldtype == 'table' and type(val) == 'table' then
                t[key] = merge(oldval, val, path and path:copy() + key or nil)

            elseif oldtype ~= type(val) then
                if oldtype == 'table' then
                    if type(val) == 'string' then
                        -- Single-line CSV parser, can possible refactor this to tables.lua
                        local res = {}
                        local current = ''
                        local quote = false
                        local last
                        for c in val:gmatch('.') do
                            if c == ',' and not quote then
                                res[#res + 1] = current
                                current = ''
                                last = nil
                            elseif c == '"' then
                                if last == '"' then
                                    current = current .. c
                                    last = nil
                                else
                                    last = '"'
                                end

                                quote = not quote
                            else
                                current = current .. c
                                last = c
                            end
                        end
                        res[#res + 1] = current

                        -- TODO: Remove this after a while, not standard compliant
                        -- Currently needed to not mess up existing settings
                        res = table.map(res, string.trim)

                        if class then
                            if class(oldval) == 'Set' then
                                res = S(res)
                            elseif class(oldval) == 'List' then
                                res = L(res)
                            elseif class(oldval) == 'Table' then
                                res = T(res)
                            end
                        end
                        t[key] = res

                    else
                        err = true

                    end

                elseif oldtype == 'number' then
                    local testdec = tonumber(val)
                    local testhex = tonumber(val, 16)
                    if testdec then
                        t[key] = testdec
                    elseif testhex then
                        t[key] = testhex
                    else
                        err = true
                    end

                elseif oldtype == 'boolean' then
                    if val == 'true' then
                        t[key] = true
                    elseif val == 'false' then
                        t[key] = false
                    else
                        err = true
                    end

                elseif oldtype == 'string' then
                    if type(val) == 'table' and not next(val) then
                        t[key] = ''
                    else
                        t[key] = val
                        err = true
                    end

                else
                    err = true
                end

            else
                t[key] = val
            end

            if err then
                if path then
                    warning('Could not safely merge values for \'%s/%s\', %s expected (default: %s), got %s (%s).':format(path:concat('/'), key, class(oldval), tostring(oldval), class(val), tostring(val)))
                end
                t[key] = val
            end
        end
    end

    return t
end

return merge

--[[
Copyright © 2013-2015, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
