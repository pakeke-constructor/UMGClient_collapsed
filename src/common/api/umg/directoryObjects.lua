---@class DirObj
local DirObj = {}
local DirObj_mt = {__index=DirObj}


local SEP = constants.FILE_SEP

---@param originalFsysobj FSysObj
---@param append_path string
local function newDirObj(originalFsysobj, append_path)
    ---@class DirObj
    local self = setmetatable({}, DirObj_mt)
    local fsysObj = originalFsysobj:clone(append_path)

    ---@param fname string
    ---@param filtertype love.FileType
    ---@return {type:love.FileType,size:integer,modtime:integer,readonly: boolean}?
    function self:getInfo(fname, filtertype)
        return fsysObj:getInfo(fname, filtertype)
    end

    ---@param fname string
    ---@param func fun(path:string,filename:string,ext:string)
    function self:foreachFile(fname, func)
        -- HACK: We don't want to expose `self.pth` to the mod callback, but the fsysObj:foreachFile requires it and
        -- pass it to the callback. So filter self.pth out before passing it back to mod.
        return fsysObj:foreachFile(fname, func)
    end

    ---@param dir string
    function self:getDirectoryItems(dir)
        return fsysObj:getDirectoryItems(dir)
    end

    ---@param fname string
    ---@return string?,string?
    function self:read(fname)
        return fsysObj:read(fname, "string")
    end

    ---@param fname string
    function self:newFileData(fname)
        return fsysObj:newFileData(fname)
    end

    return self
end


return newDirObj
