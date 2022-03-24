-- The basic outline for all peripherals.

function Peripheral(type,mem)
    local obj = {}
    obj.mem = mem
    obj.type = type

    -- called every frame, before the game has ran its code for the frame
    function obj.tick()
        return -- NOP
    end

    -- called every time memory is written to (value~=nil) or read from
    -- (value==nil)
    function obj.memhook(address, value)
        return -- NOP
    end
    table.insert(obj.mem.handlers,function(addr,val) return obj.memhook(addr,val) end)

    return obj
end

return Peripheral
