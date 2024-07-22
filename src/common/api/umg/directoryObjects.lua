

local DirObj = {}
local DirObj_mt = {__index=DirObj}


local SEP = constants.FILE_SEP
local function newDirObj(fsysObj, append_path)
    local self = setmetatable({}, DirObj_mt)
    function self:getInfo(fname, filtertype)
        return fsysObj:getInfo(self.pth .. SEP .. fname, filtertype)
    end

    function self:foreachFile(fname, func)
        return fsysObj:foreachFile(self.pth .. SEP .. fname, func)
    end

    function self:getDirectoryItems(dir)
        return fsysObj:getDirectoryItems(self.pth .. SEP .. dir)
    end

    function self:read(fname)
        return fsysObj:read(self.pth .. SEP .. fname)
    end

    self.pth = append_path
    return self
end


return newDirObj