local ffi=require"ffi"
function love.load()
    local maj, min = love.getVersion()
    if (maj<11) or (maj==11 and min<4) then
        love.errorhandler = function()
            if not love.window or not love.graphics or not love.event then
        		return
        	end
            if not love.graphics.isCreated() or not love.window.isOpen() then
            	local success, status = pcall(love.window.setMode, 800, 600)
            	if not success or not status then
            		return
            	end
            end
            love.graphics.reset()
            love.graphics.setNewFont(18)
            love.graphics.setBackgroundColor(0,0,0)
            love.graphics.setColor(255,255,255)
            return function()
                love.event.pump()
                for e, a in love.event.poll() do
                    if e=="quit" or (e=="keypressed" and a=="escape") then
                        return 1
                    end
                end
                love.graphics.clear(love.graphics.getBackgroundColor())
                love.graphics.print("Tsukidanshi cannot run on LOVE2D older than 11.4.",1,1)
                love.graphics.present()
                if love.timer then love.timer.sleep(0.1) end
            end
        end
        error()
    end
    if ffi.abi("be") then
        love.window.showMessageBox("Disclaimer","Tsukidanshi has not been thoroughly tested on big endian systems.\nWhile things should still work, if things break because of the endianness of your system, you're on your own.")
    end
end

local console=(require"console").Console()
console.load("cart.lua")

love.graphics.setDefaultFilter("nearest")
local canvas = love.graphics.newCanvas(256,256)
local t=0
function love.update(dt)
    t=t+dt
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(1,1,1,1)
    while t>(1/60) do
        console.tick()
        t=t-(1/60)
    end
    love.graphics.setCanvas()
end

function love.draw()
    love.graphics.setBackgroundColor(0,0,0,1)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(canvas,0,0,0,2,2)
end
