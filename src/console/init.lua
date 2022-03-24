local modules = {}

modules.memory = require"console.memory"
modules.peripherals = require"console.peripherals"

local ffi=require"ffi"
function Console()
    local obj = {}
    obj.memory = modules.memory.new()
    obj.peripherals = {}
    for k, v in pairs(modules.peripherals) do
        local r = v(obj.memory)
        obj.peripherals[r.type]=r
    end

    -- sandboxing
    -- first, blacklisting
    -- the debug library is just too much to give
    obj.memory.blacklist.debug = true
    -- you don't need loadfile/loadstring/load
    obj.memory.blacklist.loadfile = true
    obj.memory.blacklist.loadstring = true
    obj.memory.blacklist.load = true
    -- I could rewrite getfenv to not break the sandbox but that requires more
    -- effort to get right, easier to block (and maybe ease later)
    obj.memory.blacklist.getfenv = true
    -- rewrite rawset so it can't be used to break the sandbox
    obj.memory.sandbox_exclusive_vars.rawset = function(t,k,v)
    	if t==obj.environment then error("escape detected",2) end
    	rawset(t,k,v)
    end

    -- set up definitions here
    -- eventually they'll be parsed by the loader but until then
    obj.memory.defs = {
        ["charmap"]={0x8000,"uint8_t*"},
        ["tileset"]={0x9000,"uint8_t*"}
    }

    obj.halt=false

    obj.frame_hook_counter = 0
    obj.frame_hook = 0
    obj.memory_bank = 0
    obj.code_bank = 0

    function obj.load(filename)
        local code=love.filesystem.read(filename):gsub("%-%-([^\n]+)","")
        if code:find("([^A-Za-z0-9_])local([^A-Za-z0-9_])") then error("no local variables allowed") end
        if code:find("([^A-Za-z0-9_])for([^A-Za-z0-9_])") then error("no for loops allowed") end
        obj.bank0 = assert(loadstring(code,"bank0"))
        setfenv(obj.bank0,obj.memory.environment)
        local v=obj.bank0()
        v=v or v
        local bc = string.dump(obj.bank0,true)
        if string.len(bc)>0x8000 then
            error("code too large")
        end
        local rom=ffi.cast("uint8_t*",obj.memory.ptr_to_offset(0x0000))
        for i=1,#bc do
            rom[i-1]=string.byte(bc:sub(i,i))
        end
    end

    function obj.memhook(address,value)
        if address==0xfffc then
            if value then
                obj.memory_bank=tonumber(value)
            else
                obj.memory.write(address,{obj.memory_bank},nil,true)
            end
        end
        if address==0xfffd then
            if value then
                obj.code_bank=tonumber(value)
            else
                obj.memory.write(address,{obj.code_bank},nil,true)
            end
        end
        if address==0xfffe then
            if value then
                obj.frame_hook=tonumber(value)
                obj.frame_hook_counter=0
            else
                obj.memory.write(address,{obj.frame_hook},nil,true)
            end
        end
        if address==0xffff and bit32.band(value,0x80)==0x80 then
            obj.halt=true
        end
    end
    table.insert(obj.memory.handlers,obj.memhook)

    function obj.tick()
        obj.memory.sandbox_exclusive_vars.vblank()
        if obj.frame_hook>0 and (obj.frame_hook_counter%obj.frame_hook)==0 then
            obj.memory.sandbox_exclusive_vars.framecount()
        end
        for i,v in pairs(obj.peripherals) do
            v.tick()
        end
    end

    return obj
end

modules.Console = Console

return modules
