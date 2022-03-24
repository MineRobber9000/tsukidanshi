-- The Tsukidanshi features a random number generator. While a Tausworthe PRNG
-- like the one provided with LuaJIT is great and all, XoShiRo256** has a
-- period that is several orders of magnitude longer. (Furthermore, the PRNG
-- provided by love.math.random is worse than either LuaJIT or Tsukidanshi's
-- PRNGs.)

local ffi=require"ffi"

-- translated from the C code by Blackman and Vigna
-- original: https://prng.di.unimi.it/xoshiro256starstar.c
-- that was public domain, so to help pay it forward, rotl and next (the next 2
-- functions in this script) are also open source (implementing jump is an
-- exercise left to the reader, as I have no use for it)

-- static inline uint64_t rotl(const uint64_t x, int k)
local function rotl(u64,k)
    -- return (x << k) | (x >> (64 - k));
    return bit.bor(bit.lshift(u64,k),bit.rshift(u64,64-k))
end

-- uint64_t next(void)
-- the argument taken here is a uint64_t* (in theory a uint64_t[4], but (a) it
-- doesn't really matter in the grand scheme of things and (b) I'm using it in a
-- situation where I need to use a uint64_t* anyways) in lieu of the hardcoded
-- static uint64_t s[4]
local function next(state)
    -- const uint64_t result = rotl(s[1] * 5, 7) * 9;
    local result = rotl(state[1]*5,7)*9
    -- const uint64_t t = s[1] << 17;
    local t = bit.lshift(state[1],17)
    -- s[2] ^= s[0];
    state[2]=bit.bxor(state[2],state[0])
    -- s[3] ^= s[1];
    state[3]=bit.bxor(state[3],state[1])
    -- s[1] ^= s[2];
    state[1]=bit.bxor(state[1],state[2])
    -- s[0] ^= s[3];
    state[0]=bit.bxor(state[0],state[3])
    -- s[2] ^= t;
    state[2]=bit.bxor(state[2],t)
    -- s[3] = rotl(s[3],45);
    state[3]=rotl(state[3],45)
    -- return result;
    return result
end

-- end public domain code

local Peripheral = require"console.peripherals.base"

function RNG(mem)
    local obj = Peripheral("RNG",mem)

    function obj.memhook(address,value)
        if value then
            -- it's a write; object to any writes over our hardware register
            return (address>=0xff04 and address<=0xff0b)
        else
            -- if it's a read to 0xff04, generate a value and write it to memory
            if address==0xff04 then
                result = next(ffi.cast("uint64_t*",obj.mem.ptr_to_offset(0xf160)))
                obj.mem.write(0xff04,{result},"uint64_t",true)
            end
        end
    end

    return obj
end

return RNG
