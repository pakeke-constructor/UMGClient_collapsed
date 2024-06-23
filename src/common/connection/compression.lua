

local compression = {}

local SHOULD_COMPRESS = constants.SHOULD_COMPRESS

function compression.compress(data)
    if SHOULD_COMPRESS then
        data = love.data.compress("string", "lz4", data)
    end
    return data
end


function compression.decompress(data)
    if SHOULD_COMPRESS then
        data = love.data.decompress("string", data)
    end
    return data
end



return compression
