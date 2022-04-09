-- The Tsukidanshi's memory is its defining feature. With only 64KiB total of
-- memory, the Tsukidanshi is as limited in memory as the GameBoy (and in fact,
-- some of the memory layout decisions were inspired by the GameBoy). But what
-- Tsukidanshi lacks in memory, it makes up for in power. Unlike the GameBoy,
-- which has to be programmed in assembly code, the Tsukidanshi can run Lua
-- code, thanks to the brilliant power of LuaJIT and the fact that this is a
-- LOVE project instead of a handheld from 1989.

local ffi = require"ffi" -- gonna need this

ffi.cdef[[

void *malloc(size_t size);
void free(void *ptr);

]]

local callabletable = require"utils.callabletable"
local function proxytable(t,name)
    return callabletable(
        function(_,k)
            local v = t[k]
            if type(v)=="table" then return proxytable(v,name.."."..k) end
            return v
        end,
        function(_,k)
            error("Attempt to write to global variable "..name.."."..k,2)
        end
    )
end

local function wrap_ptr(mem,offset,ptr)
    return callabletable(
        function(t,k)
            for i=1,#mem.handlers do
                mem.handlers[i](offset+k)
            end
            return ptr[k]
        end,
        function(t,k,v)
            for i=1,#mem.handlers do
                if mem.handlers[i](offset+k,v) then return end
            end
            ptr[k]=v
        end
    )
end

local function new()
    -- The memory object, at its core, is a buffer of 65536 bytes that gets
    -- indexed and messed with as required for the game's memory.
    local obj = {}
    obj.__memory = ffi.gc(ffi.C.malloc(65536),ffi.C.free)
    ffi.fill(obj.__memory,65536,0)
    -- Gives a void pointer to an offset within the 65536 bytes of memory.
    obj.ptr_to_offset = function(offset)
        return ffi.cast("void*",ffi.cast("intptr_t",obj.__memory)+offset)
    end
    -- defines handlers for offsets
    -- basically, every function in obj.handlers gets called with the offset
    -- that is being read or written (and the value that's being written), which
    -- allows for peripherals to handle state.
    obj.handlers = {}
    -- reads n of ctype from offset offset (ctype defaults to uint8_t)
    obj.read = function(offset,n,ctype,raw)
        ctype = ctype or "uint8_t"
        local len = n*ffi.sizeof(ctype)
        if not raw then
            for i=offset,(offset+len-1) do
                for k=1,#obj.handlers do
                    obj.handlers[k](i)
                end
            end
        end
        local buf = ffi.cast(ctype.."*",obj.ptr_to_offset(offset))
        local ret = {}
        for i=1,n do
            ret[i]=buf[i-1]
        end
        return ret
    end
    -- writes #values of ctype to offset offset (ctype defaults to uint8_t)
    obj.write = function(offset,values,ctype,raw)
        ctype = ctype or "uint8_t"
        local len = #values * ffi.sizeof(ctype)
        local writerestore = {}
        if not raw then
            local c = ffi.new(ctype.."[?]",#values,values)
            local b = ffi.cast("uint8_t*",c)
            for i=1,len do
                i=i-1
                local debounce = false
                for k=1,#obj.handlers do
                    debounce = debounce or obj.handlers[k](offset+i,b[i])
                end
                if debounce then writerestore[#writerestore+1]=i end
            end
        end
        local ptr = obj.ptr_to_offset(offset)
        local bt = ffi.cast("uint8_t*",ptr)
        local restore = {}
        for i=1,#writerestore do
            restore[i]=bt[writerestore[i]]
        end
        local p = ffi.cast(ctype.."*",ptr)
        for i=1,#values do
            p[i-1]=values[i]
        end
        for i=1,#writerestore do
            bt[writerestore[i]]=restore[i]
        end
    end
    -- The global environment proxy is how we enforce the memory restrictions
    -- of Tsukidanshi.
    -- Holds definitions of memory values (defs[varname]={offset,ctype}).
    obj.defs = {}
    -- Holds the variables we don't want to expose
    -- when we proxy access to _G[k], if obj.blacklist[k], then error
    obj.blacklist = {}
    -- Holds extra variables we want to make available (as well as functions
    -- defined by proxied chunks)
    obj.sandbox_exclusive_vars = {}
    -- The global environment proxy itself. By using an empty table, we force
    -- any gets or sets to call our metamethods, which interface the memory
    -- and construct the variable from it.
    obj.environment = callabletable(
        function(t,k)
            if obj.defs[k] then
                if obj.defs[k][2]=="uint8_t*" then
                    return wrap_ptr(obj,obj.defs[k][1],ffi.cast("uint8_t*",obj.ptr_to_offset(obj.defs[k][1])))
                else
                    return obj.read(obj.defs[k][1],1,obj.defs[k][2])[1]
                end
            elseif obj.sandbox_exclusive_vars[k] then
                return obj.sandbox_exclusive_vars[k]
            elseif _G[k] then
                if obj.blacklist[k] then error("Attempt to access blacklisted global variable "..k) end
                local v = _G[k]
                if type(v)=="table" then return proxytable(v,k) end
                return v
            end
            error("Invalid variable "..k)
        end,
        function(t,k,v)
            if type(v)=="function" then obj.sandbox_exclusive_vars[k]=v return end
            if obj.defs[k] then
                obj.write(obj.defs[k][1],{v},obj.defs[k][2])
                return
            elseif _G[k] then
                error("Attempt to write to global variable "..k)
            end
            error("Invalid variable "..k)
        end
    )
    return obj
end

return {new=new}
