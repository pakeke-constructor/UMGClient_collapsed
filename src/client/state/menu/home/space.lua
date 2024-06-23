

local space = {}

local lg = love.graphics


local img

function space.init()
    -- Load image with linear format, so the pixels aren't jagged
    local r = love.math.random()
    if r < 0.5 then
        img = lg.newImage("assets/images/menu_backgrounds/bg2.png")
    elseif r < 0.99 then
        img = lg.newImage("assets/images/menu_backgrounds/bg1.png")
    else
        img = lg.newImage("assets/images/menu_backgrounds/bg5.png")
    end
end



function space.exit()
    --[[
        destroys the image reference so we don't use up
        GPU memory.
    ]]
    img = nil
end



local get_fudged_ui_scale = require("src.client.misc.get_fudged_ui_scale")


local SCALE_FACTOR = 4

local X_SCROLL_SPEED = 0.01 -- pretty arbitrary numbers
local Y_SCROLL_SPEED = 0.08

function space.draw()
    lg.push()
    local scale = get_fudged_ui_scale(SCALE_FACTOR)
    local tick = love.timer.getTime()

    lg.scale(scale)
    lg.setColor(1,1,1)

    local iw, ih = img:getDimensions()

    local w,h = lg.getDimensions()
    local x_mag = iw - w/scale
    local y_mag = ih - h/scale

    local x = -x_mag * ((math.sin(tick * X_SCROLL_SPEED)/2)+0.5)
    local y = -y_mag * ((math.sin(tick * Y_SCROLL_SPEED)/2)+0.5)

    lg.draw(img, x, y)
    lg.pop()
end



return space

