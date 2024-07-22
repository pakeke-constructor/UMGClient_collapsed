

local DirObj = {}
local DirObj_mt = {__index=DirObj}


local SEP = constants.FILE_SEP
local function newDirObj(fsysObj, append_path)
    local self = setmetatable({}, DirObj_mt)
    function self:getInfo(fname, filtertype)
        return fsysObj:getInfo(self.pth .. SEP .. fname, filtertype)
    end

    function self:foreachFile(fname, func)
        -- HACK: We don't want to expose `self.pth` to the mod callback, but the fsysObj:foreachFile requires it and
        -- pass it to the callback. So filter self.pth out before passing it back to mod.
        return fsysObj:foreachFile(self.pth .. SEP .. fname, function(path, filename, ext)
            if path:sub(-1) == "/" then
                path = path:sub(1, -2)
            end

            return func(path:sub(#self.pth + 1), filename, ext)
        end)
    end

    function self:getDirectoryItems(dir)
        return fsysObj:getDirectoryItems(self.pth .. SEP .. dir)
    end

    function self:read(fname)
        return fsysObj:read(self.pth .. SEP .. fname)
    end

    function self:newFileData(fname)
        return fsysObj:newFileData(self.pth .. SEP .. fname)
    end

    self.pth = append_path
    return self
end


return newDirObj