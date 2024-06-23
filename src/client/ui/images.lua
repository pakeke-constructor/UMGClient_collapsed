

local images = {}



local IMAGE_CACHE = {}

local FILENAME_CACHE = {--[[
    [name] --> fullpath
]]}


local function lazyLoadImage(fullpath)
    local filename = tools.get_filename(fullpath)
    local name = tools.remove_extension(filename)

    FILENAME_CACHE[name] = fullpath
end



tools.load_tree("src/client/ui/images", {}, lazyLoadImage)




function images.getImage(name)
    if IMAGE_CACHE[name] then
        -- if UI image has been loaded, return existing
        return IMAGE_CACHE[name]
    end

    local fullpath = FILENAME_CACHE[name]
    if not fullpath then
        error("Invalid name: " .. tostring(name))
    end

    IMAGE_CACHE[name] = love.graphics.newImage(fullpath)
    return IMAGE_CACHE[name]
end



return images
