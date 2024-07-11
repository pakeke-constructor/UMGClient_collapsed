


local container_types = {
    data = true,
    string = true
}



local function addFSysFuncs(lobj, tabl)
    -- adds filesystem functions:
    local fsysObj = lobj.fsysObj

    function tabl.lines(...)
        return fsysObj:lines(...)
    end

    function tabl.getInfo(...)
        return fsysObj:getInfo(...)
    end

    function tabl.getDirectoryItems(...)
        return fsysObj:getDirectoryItems(...)
    end
end


return function(lobj)
    local filesystem = {}

    addFSysFuncs(lobj, filesystem)

    filesystem.newFileData = function(contents, filename)
        if filename == nil then
            return lobj.fsysObj:newFileData(contents)
        else
            return love.filesystem.newFileData(contents, filename)
        end
    end

    filesystem.read = function(fname_or_ct, size_or_fname, size_or_nil)
        local fname = fname_or_ct
        local size = size_or_fname
        local container_type = "string"
        if container_types[fname_or_ct] and type(size_or_fname) == "string" then
            fname = size_or_fname
            size = size_or_nil
            return lobj:read(fname, container_type, size)
        else
            return lobj:read(fname, container_type, size)
        end
    end

    return filesystem
end

