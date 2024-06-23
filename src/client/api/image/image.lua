


return function(lobj)
    local image = {}

    local function newImageData(a, ...)
        if type(a) == "string"  then
            -- its a filename, convert first arg to imagedata
            local path = a
            local filedata = lobj.fsysObj:newFileData(path)
            return love.image.newImageData(filedata)
        end
        return love.image.newImageData(a,...) -- a is not a path, so OK.
    end

    image.newImageData = newImageData
    image.isCompressed = love.image.isCompressed

    return image
end

