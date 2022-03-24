-- The controller. The Tsukidanshi's controller has all of the same buttons
-- as a GameBoy (up, down, left, right, a, b, select, start).

local Peripheral = require"console.peripherals.base"

function Controller(mem)
    local obj = Peripheral("Controller",mem)
    obj.joystick = nil
    obj.keyboard_mapping = {
        ["up"]="up",
        ["down"]="down",
        ["left"]="left",
        ["right"]="right",
        ["a"]="z",
        ["b"]="x",
        ["select"]="lshift",
        ["start"]="return",
    }
    local bit_mapping = {
        ["up"]=0,
        ["down"]=1,
        ["left"]=2,
        ["right"]=3,
        ["a"]=4,
        ["b"]=5,
        ["select"]=6,
        ["start"]=7
    }

    function obj.tick()
        local up, down, left, right, a, b, select, start
        if obj.joystick then
            -- NYI: set gamepad state from joystick/gamepad
        else
            up=love.keyboard.isDown(obj.keyboard_mapping.up)
            down=love.keyboard.isDown(obj.keyboard_mapping.down)
            left=love.keyboard.isDown(obj.keyboard_mapping.left)
            right=love.keyboard.isDown(obj.keyboard_mapping.right)
            a=love.keyboard.isDown(obj.keyboard_mapping.a)
            b=love.keyboard.isDown(obj.keyboard_mapping.b)
            select=love.keyboard.isDown(obj.keyboard_mapping.select)
            start=love.keyboard.isDown(obj.keyboard_mapping.start)
        end
        v = 0
        if up then v=bit.bor(v,math.pow(2,bit_mapping.up)) end
        if down then v=bit.bor(v,math.pow(2,bit_mapping.down)) end
        if left then v=bit.bor(v,math.pow(2,bit_mapping.left)) end
        if right then v=bit.bor(v,math.pow(2,bit_mapping.right)) end
        if a then v=bit.bor(v,math.pow(2,bit_mapping.a)) end
        if b then v=bit.bor(v,math.pow(2,bit_mapping.b)) end
        if select then v=bit.bor(v,math.pow(2,bit_mapping.select)) end
        if start then v=bit.bor(v,math.pow(2,bit_mapping.start)) end
        obj.mem.write(0xff00,{v},nil,true) -- write
    end

    function obj.memhook(addr,value)
        return addr==0xff00 -- if read, it does nothing, if write, it ignores
    end

    return obj
end

return Controller
