
local path = tools.path(...)


local uutil = {
    --[[
        ui helper functions.
    ]]
}



local lg = love.graphics
local floor = math.floor



function uutil.get_wh(ratio_w, ratio_h)
    -- Gets the width, height of window given ratios
    assert(ratio_w, ratio_h)
    local scale = Slab.GetScale()
    local lgw, lgh = lg.getWidth() / scale, lg.getHeight() / scale
    return floor(ratio_w * lgw), floor(ratio_h * lgh)
end


function uutil.get_xy(ratio_x, ratio_y, w, h)
    -- Gets the x,y position that a window should be at,
    -- given width and height.
    assert(w and h)
    local scale = Slab.GetScale()
    local lgw, lgh = lg.getWidth() / scale, lg.getHeight() / scale
    return floor((ratio_x * lgw) - (w/2)), floor((ratio_y * lgh) - h/2)
end





local imgname_to_lgimage = {}

function uutil.image_button(image_name, conf)
    conf = conf or {}

    local img = imgname_to_lgimage[image_name]
    if not img then
        local parsed = "assets/ui/" .. image_name .. ".png"
        img = love.graphics.newImage(parsed)
        imgname_to_lgimage[image_name] = img
    end

    local w, h = img:getDimensions()
    conf.Image = {Image = img}
    conf.W = w
    conf.H = h
    return Slab.Button("t", conf)
end




return uutil
