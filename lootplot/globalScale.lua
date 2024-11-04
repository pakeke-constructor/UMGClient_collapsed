local globalScale = {}

local GLOBAL_SCALE_INCREMENT = 0.5

function globalScale.get()
    local w, h = love.graphics.getDimensions()
    local wscale = w / 600
    local hscale = h / 400
    local scale = math.min(wscale, hscale)
    return math.floor(scale / GLOBAL_SCALE_INCREMENT + 0.5) * GLOBAL_SCALE_INCREMENT
end

return globalScale
