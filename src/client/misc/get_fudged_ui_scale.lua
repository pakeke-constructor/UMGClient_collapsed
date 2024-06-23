
--[[
    provides a cross-platform way of setting the scale

    TODO: This is dogshit.
    im pretty sure this will look trash on many displays

    (LUI will allow us to remove this, thankfully)
]]



-- Oli's personal screen width and height
-- (used to get a good ui scale for differing screen sizes)
local OLI_WIDTH, OLI_HEIGHT = 1536, 793
local OLI_DISPLAY_SIZE = math.sqrt(OLI_WIDTH^2 + OLI_HEIGHT^2)

local function get_fudged_ui_scale(scale, w, h)
    --[[
        Returns a new `scale` value that corresponds correctly
        with the screen size.

        since different computers have different screen sizes,
        we must scale the UI scale with the screensize.
        bigger sized screens should get larger UI scales to compensate.
    ]]
    if not (w and h) then
        w,h = love.graphics.getDimensions()
    end
    local screensize = math.sqrt(w^2 + h^2)
    return math.floor((((scale / OLI_DISPLAY_SIZE) * screensize) + 0.5) * 10) / 10
end


return get_fudged_ui_scale
