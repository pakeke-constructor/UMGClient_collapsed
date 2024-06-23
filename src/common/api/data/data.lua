

local allowed = {
    "compress",
    "decompress",
    
    "decode",
    "encode",

    "getPackedSize",
    "hash",

    "newByteData",
    "newDataView",
    "pack",
    "unpack"
}

return function()
    local data = {}

    for _,k in pairs(allowed)do
        data[k] = love.data[k]
    end

    return data
end

