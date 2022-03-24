-- The renderer is in charge of rendering the sprites, the palettes, the BG,
-- basically, everything that appears on screen is the purview of the renderer.

local ffi = require"ffi"

-- used to check a specific bit in a uint8_t (LSB=0,MSB=7)
local checkbit=setmetatable({},{__index=function(t,k)t[k]=function(n)return bit.band(n,math.pow(2,k))==math.pow(2,k)end return t[k]end})

-- ptr is a uint8_t* to the tile data
function decode_indexed_color(ptr)
    local tiledata = {}
    for i=0,14,2 do
        local y=(i/2)+1
        tiledata[y]={}
        for j=7,0,-1 do
            tiledata[y][8-j]=(checkbit[j](ptr[i+1]) and 2 or 0)+(checkbit[j](ptr[i]) and 1 or 0)
        end
    end
    return tiledata
end

-- ptr is a uint8_t* to the palette data
function decode_palette(ptr)
    local palette = {}
    for i=0,3 do
        local c = {}
        c[1]=(ptr[(i*3)]/255)
        c[2]=(ptr[(i*3)+1]/255)
        c[3]=(ptr[(i*3)+2]/255)
        c[4]=1 -- always fully opaque
        palette[i]=c
    end
    return palette
end

-- id is the number of the tile (from 0 to 255)
-- palnum is the number of the palette (from 0 to 7)
-- ptr is a uint8_t* to the tile data
-- palptr is a uint8_t* to the palette data
-- id and palnum are used to cache the rendered tile so we only render it once
-- cache is invalidated when the tile or the palette changes
-- structure is _cache[id][palnum]
local _tilecache = setmetatable({},{__index=function(t,k)t[k]={}return t[k]end})
function mem_to_tile(id, palnum, ptr, palptr)
    -- step 0: have we already done this?
    if _tilecache[id][palnum] then return _tilecache[id][palnum] end
    -- step 1: decode tile to indexed color
    local tiledata = decode_indexed_color(ptr)
    -- step 2: decode palette from 8-bit RGB to normalized RGBA
    local palette = decode_palette(palptr)
    -- step 3: use palette to create ImageData from indexed color
    local imgdata = love.image.newImageData(8,8)
    for y=1,8 do
        for x=1,8 do
            imgdata:setPixel(x-1,y-1,palette[tiledata[y][x]])
        end
    end
    -- step 4: cache result (it's expensive to make an ImageData)
    _tilecache[id][palnum]=imgdata
    -- step 5: return result
    return imgdata
end
-- structure is _cache[id][palnum]
local _spritecache = setmetatable({},{__index=function(t,k)t[k]={}return t[k]end})
function mem_to_sprite(id, palnum, ptr, palptr)
    -- step 0: have we already done this?
    if _spritecache[id][palnum] then return _spritecache[id][palnum] end
    -- step 1: decode tile to indexed color
    local tiledata = decode_indexed_color(ptr)
    -- step 2: decode palette from 8-bit RGB to normalized RGBA
    local palette = decode_palette(palptr)
    -- step 2.5: force color 0 to transparent black
    palette[0]={0,0,0,0}
    -- step 3: use palette to create ImageData from indexed color
    local imgdata = love.image.newImageData(8,8)
    for y=1,8 do
        for x=1,8 do
            imgdata:setPixel(x-1,y-1,palette[tiledata[y][x]])
        end
    end
    -- step 4: cache result (it's expensive to make an ImageData)
    _spritecache[id][palnum]=imgdata
    -- step 5: return result
    return imgdata
end
-- invalidates all palettes for tile `id`
function invalidate_tile(id)
    _tilecache[id]=nil
    _spritecache[id]=nil
end
-- invalidates palette `palnum` for all tiles
function invalidate_palette(palnum)
    for id, cached in pairs(_tilecache) do
        cached[palnum]=nil
    end
    for id, cached in pairs(_spritecache) do
        cached[palnum]=nil
    end
end

local Peripheral = require"console.peripherals.base"

function Renderer(mem)
    local obj = Peripheral("Renderer",mem)

    -- set up palette 0
    local _ptr = ffi.cast("uint8_t*",obj.mem.ptr_to_offset(0xf100))
    local palette0 = {0,0,0,0x55,0x55,0x55,0xaa,0xaa,0xaa,0xff,0xff,0xff}
    for i=1,#palette0 do _ptr[i-1]=palette0[i] end

    -- establish bg and bgi
    obj.bg = {}
    obj.bgi = love.image.newImageData(64*8,64*8)
    for y=1,64 do
        obj.bg[y]={}
        for x=1,64 do
            obj.bg[y][x]=0
        end
    end
    obj.bg_scroll_x = 0
    obj.bg_scroll_y = 0
    obj.bg_palette = 0
    obj.bg_scroll_x_add_128=false
    obj.bg_scroll_x_add_256=false
    obj.bg_scroll_y_add_128=false
    obj.bg_scroll_y_add_256=false
    obj.enabled = true
    obj.mem.write(0xff03,{0x80},nil,true)

    local tile0sprite = love.graphics.newImage(mem_to_sprite(0,0,ffi.cast("uint8_t*",obj.mem.ptr_to_offset(0x8000)),_ptr))
    -- establish sprites
    obj.sprites = {}
    obj.sprite_image_cache={}
    for i=1,64 do
        local sprite={}
        sprite.id=0
        sprite.x=0
        sprite.y=-8
        sprite.double_width=false
        sprite.double_height=false
        sprite.sub_x_or_y=false
        sprite.hflip=false
        sprite.vflip=false
        sprite.palette=0
        obj.sprites[i]=sprite
        obj.sprite_image_cache[i]=tile0sprite
    end

    function obj.redraw_bgi()
        obj.should_redraw_bgi = false
        local ptr = ffi.cast("uint8_t*",obj.mem.ptr_to_offset(0xf100+(obj.bg_palette*12)))
        for y=1,64 do
            for x=1,64 do
                local t = obj.bg[y][x]
                obj.bgi:paste(mem_to_tile(t,obj.bg_palette,ffi.cast("uint8_t*",obj.mem.ptr_to_offset(0x8000+(t*16))),ptr),(x-1)*8,(y-1)*8,0,0,8,8)
            end
        end
        obj.bgim = love.graphics.newImage(obj.bgi)
    end
    obj.redraw_bgi()

    function obj.sprite(index)
        if not obj.sprite_image_cache[index] then
            local w, h = 8, 8
            if obj.sprites[index].double_width then w=16 end
            if obj.sprites[index].double_height then h=16 end
            local palnum = obj.sprites[index].palette
            local palptr = ffi.cast("uint8_t*",obj.mem.ptr_to_offset(0xf100+(12*palnum)))
            local imgdata = love.image.newImageData(w,h)
            local n = obj.sprites[index].id
            for y=0,h-8,8 do
                for x=0,w-8,8 do
                    local s = mem_to_sprite(n,palnum,obj.mem.ptr_to_offset(0x8000+(n*16)),palptr)
                    imgdata:paste(s,x,y,0,0,8,8)
                    n=n+1
                end
            end
            obj.sprite_image_cache[index]=love.image.newImage(imgdata)
        end
        return obj.sprite_image_cache[index]
    end

    obj.should_redraw_bgi = false
    function obj.memhook(addr,value)
        if value and (addr>=0x8000 and addr<=0x8fff) then -- write to character memory
            local tile = math.floor((addr-0x8000)/16)
            invalidate_tile(tile)
            for y=1,64 do
                for x=1,64 do
                    if obj.bg[y][x]==tile then obj.should_redraw_bgi=true end
                end
            end
            for i=1,64 do
                if (obj.sprites[i].id==n)
                or (obj.sprites[i].double_width and obj.sprites[i].id==(n-1))
                or (obj.sprites[i].double_height and obj.sprites[i].id==(n-1))
                or (obj.sprites[i].double_width and obj.sprites[i].double_height
                and (obj.sprites[i].id==(n-2) or obj.sprites[i].id==(n-3))) then
                    obj.sprite_image_cache[index]=nil
                end
            end
        end
        if value and (addr>=0x9000 and addr<=0x9fff) then -- write to tilemap
            local v = (addr-0x9000)
            local y, x = math.floor(v/64)+1, math.fmod(v,64)+1
            obj.bg[y][x]=tonumber(value)
            obj.should_redraw_bgi=true
        end
        if value and (addr>=0xf000 and addr<=0xf0ff) then -- write to sprite memory
            local index = math.floor((addr-0xf000)/4)
            local baseaddr = 0xf000+(index*4)
            index=index+1 -- now we're using it as an index into a lua table
            local redrawsprite = false
            if (addr-baseaddr)==0 then
                obj.sprites[index].y=tonumber(value)-(obj.sprites[index].sub_x_y and 0 or (obj.sprites[index].double_height and 16 or 8))
            elseif (addr-baseaddr)==1 then
                obj.sprites[index].x=tonumber(value)-(obj.sprites[index].sub_x_y and (obj.sprites[index].double_width and 16 or 8) or 0)
            elseif (addr-baseaddr)==2 then
                obj.sprites[index].id=tonumber(value)
                redrawsprite=true
            elseif (addr-baseaddr)==3 then
                local hflip, vflip, double_width, double_height, sub_x_y, palette
                obj.sprites[index].hflip = (bit.band(value,0x80))>0
                obj.sprites[index].vflip = (bit.band(value,0x40))>0
                double_width = (bit.band(value,0x20))>0
                double_height = (bit.band(value,0x10))>0
                if (double_width and not obj.double_width)
                    or (obj.double_width and not double_width)
                    or (double_height and not obj.double_height)
                    or (obj.double_height and not double_height) then
                    redrawsprite=true
                end
                obj.sprites[index].double_width, obj.sprites[index].double_height = double_width, double_height
                sub_x_y = (bit.band(value,0x08))>0
                if (sub_x_y and not obj.sprites[index].sub_x_y) then
                    obj.sprites[index].x=obj.sprites[index].x-(obj.sprites[index].double_width and 16 or 8)
                    obj.sprites[index].y=obj.sprites[index].y+(obj.sprites[index].double_height and 16 or 8)
                elseif (obj.sprites[index].sub_x_y and not sub_x_y) then
                    obj.sprites[index].x=obj.sprites[index].x+(obj.sprites[index].double_width and 16 or 8)
                    obj.sprites[index].y=obj.sprites[index].y-(obj.sprites[index].double_height and 16 or 8)
                end
                palette = (bit.band(value,0x07))
                if palette~=obj.sprites[index].palette then redrawsprite=true end
                obj.sprites[index].palette=palette
            end
            if redrawsprite then
                obj.sprite_image_cache[index]=nil
            end
        end
        if value and (addr>=0xf100 and addr<=0xf15f) then -- write to palette data
            local palette = math.floor((addr-0xf100)/12)
            invalidate_palette(palette)
            obj.should_redraw_bgi=(palette==obj.bg_palette)
            obj.bg_palette=palette
            for i=1,64 do
                if obj.sprites[i].palette==palette then
                    obj.sprite_image_cache[i]=nil
                end
            end
        end
        if value and (addr>=0xff01 and addr<=0xff03) then -- write to screen registers
            if addr==0xff01 then
                obj.bg_scroll_x=tonumber(value)
            elseif addr==0xff02 then
                obj.bg_scroll_y=tonumber(value)
            elseif addr==0xff03 then
                local palette
                obj.enabled = (bit.band(value,0x80))>0
                obj.bg_scroll_x_add_128=(bit.band(value,0x40))>0
                obj.bg_scroll_x_add_256=(bit.band(value,0x20))>0
                obj.bg_scroll_y_add_128=(bit.band(value,0x10))>0
                obj.bg_scroll_y_add_256=(bit.band(value,0x08))>0
                palette=bit.band(value,0x07)
                if palette~=obj.bg_palette then obj.should_redraw_bgi=true end
                obj.bg_palette=palette
            end
        end
    end

    function obj.tick()
        -- step 1: if we're not on then don't show anything (i.e; leave it blank)
        if not obj.enabled then return end
        -- step 2: if we are on, then make sure BG is up to date
        if obj.should_redraw_bgi then obj.redraw_bgi() end
        -- step 3: draw BG at coordinates
        local scroll_x, scroll_y
        scroll_x=obj.bg_scroll_x + (obj.bg_scroll_x_add_128 and 128 or 0) + (obj.bg_scroll_x_add_256 and 256 or 0)
        scroll_y=obj.bg_scroll_y + (obj.bg_scroll_y_add_128 and 128 or 0) + (obj.bg_scroll_y_add_256 and 256 or 0)
        love.graphics.draw(obj.bgim,-scroll_x,-scroll_y)
        -- step 4: draw sprites
        for i=1,64 do
            love.graphics.draw(obj.sprite(i),obj.sprites[i].x,obj.sprites[i].y)
        end
    end

    return obj
end

return Renderer
