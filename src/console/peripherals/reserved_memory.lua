-- This peripheral's only purpose is to prevent you from writing to the reserved
-- blocks of RAM in the Fxxx page. Those might eventually be used, so I can't
-- have people using them all willy-nilly.
-- This peripheral also ensures you can't write to the ROM.

local Peripheral = require"console.peripherals.base"

function ReservedMemory(mem)
    local obj = Peripheral("ReservedMemory",mem)

    function obj.memhook(addr,val)
        return (addr>=0x0000 and addr<=0x7fff)
            or (addr>=0xf180 and addr<=0xf1ff)
            or (addr>=0xf500 and addr<=0xfeff)
    end

    return obj
end

return ReservedMemory
