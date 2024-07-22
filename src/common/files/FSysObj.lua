
local nativefs = require("libs.nm_nativefs.nativefs")

--[[
    a filesystem object that can read-write files,
    and traverse directories.

    Useful for mods, if we want to restrict where we can read files from,
    OR if we want to load files from an outside directory.
]]


local FSysObj = tools.SafeClass()


local SEP = constants.FILE_SEP


function FSysObj:init(path, is_local_path)
    self.path = path
    self.is_local_path = is_local_path
    self.append_path = path .. SEP
end




local read_tc = tc.assert("string", "string?", "number?")
function FSysObj:read(fname, container_type, size)
    -- Reads a filename in a mod directory.
    -- (This is guaranteed to be safe to call)
    read_tc(fname, container_type, size)
    container_type = container_type or "string"
    if self.is_local_path then
        return love.filesystem.read(container_type, self.append_path .. fname, size)
    else
        return nativefs.read(container_type, self.append_path .. fname, size)
    end
end



function FSysObj:getDirectoryItems(path)
    if self.is_local_path then
        return love.filesystem.getDirectoryItems(self.append_path .. path)
    else
        return nativefs.getDirectoryItems(self.append_path .. path)
    end
end



function FSysObj:newFileData(contents, filename)
    if contents and filename then
        return love.filesystem.newFileData(contents, filename)
    end

    if self.is_local_path then
        return love.filesystem.newFileData(self.append_path .. contents)
    else
        return nativefs.newFileData(self.append_path .. contents)
    end
end


function FSysObj:getInfo(path, filtertype)
    local ret
    if self.is_local_path then
        ret = love.filesystem.getInfo(self.append_path .. path, filtertype)
    else
        ret = nativefs.getInfo(self.append_path .. path, filtertype)
    end
    log.debug("FSysObj:getInfo", path, filtertype, ret)
    return ret
end


function FSysObj:foreachFile(pth, func)
    local directory = self:getDirectoryItems(pth)

    -- selene: allow(incorrect_standard_library_use)
    table.stable_sort(directory) -- Sorts by alphabetical I think?? hopefully she'll be right

    for _,file in ipairs(directory) do
        if file:sub(1,1) ~= "_" then
            local full_path = pth..SEP..file
            local info = self:getInfo(full_path)

            if info.type == "directory" then
                self:foreachFile(full_path, func)
            else
                local name, exten = tools.remove_extension(file), tools.get_extension(file)
                func(pth, name, exten)
            end
        end
    end
end



return FSysObj

