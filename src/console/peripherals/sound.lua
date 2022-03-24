-- The sound hardware consists of 2 sound buffers that play signed 8bit PCM data
-- at 11025Hz. In order to achieve steady playback, one must average 183.75
-- samples every frame (3 frames of 184 and 1 frame of 183). However, samples
-- can be queued up well in advance of that mark.

-- TODO: figure out how to load sample data from a file

local ffi = require"ffi"
local Peripheral = require"console.peripherals.base"

function SoundProcessor(mem)
    local obj = Peripheral("SoundProcessor",mem)
    obj.music = love.audio.newQueueableSource(11025,8,1,64)
    obj.sfx = love.audio.newQueueableSource(11025,8,1,64)
    obj.music_q = {}
    obj.sfx_q = {}
    obj.music_qs = 256
    obj.sfx_qs = 256

    local MUSIC_PLAYING = math.pow(2,7)
    local SFX_PLAYING = math.pow(2,6)
    local SFX_WRITE = math.pow(2,1)
    local MUSIC_WRITE = math.pow(2,0)

    function obj.tick()
        while #obj.music_q>0 and obj.music:getFreeBufferCount()>0 do
            obj.music:queue(table.remove(obj.music_q,1))
        end
        while #obj.sfx_q>0 and obj.sfx:getFreeBufferCount()>0 do
            obj.sfx:queue(table.remove(obj.sfx_q,1))
        end
    end

    local function queue(t,offset,amt)
        local ptr=ffi.cast("int8_t*",obj.mem.ptr_to_offset(offset))
        local snddata = love.sound.newSoundData(amt,11025,8,1)
        for i=1,amt do
            i=i-1
            snddata:setSample(i,tonumber(ptr[i])/128)
        end
        if obj[t]:getFreeBufferCount()>0 then
            obj[t]:queue(snddata)
        else
            table.insert(obj[t.."_q"],snddata)
        end
    end

    function obj.memhook(addr,val)
        if addr==0xff0c then
            if not val then -- read
                local v = (obj.music:isPlaying() and MUSIC_PLAYING or 0)+(obj.sfx:isPlaying() and SFX_PLAYING or 0)
                obj.mem.write(0xff0c,{v},nil,true)
            else -- write
                if bit.band(val,SFX_WRITE)==SFX_WRITE then queue("sfx",0xf300,obj.sfx_qs) end
                if bit.band(val,MUSIC_WRITE)==MUSIC_WRITE then queue("music",0xf200,obj.music_qs) end

                if bit.band(val,MUSIC_PLAYING)==0 and obj.music:isPlaying() then obj.music:stop() end
                if bit.band(val,SFX_PLAYING)==0 and obj.sfx:isPlaying() then obj.sfx:stop() end
                if bit.band(val,MUSIC_PLAYING)==MUSIC_PLAYING and not obj.music:isPlaying() then obj.music:play() end
                if bit.band(val,SFX_PLAYING)==SFX_PLAYING and not obj.sfx:isPlaying() then obj.sfx:play() end
            end
        end
        if addr==0xff0d then
            if val then obj.music_qs=tonumber(val)+1 end
        end
        if addr==0xff0e then
            if val then obj.sfx_qs=tonumber(val)+1 end
        end
    end

    return obj
end

return SoundProcessor
