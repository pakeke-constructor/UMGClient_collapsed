---@class UMGModFSysObj
local FilesystemObject = {}
local FilesystemObject_mt = {__index=FilesystemObject}


---@param originalFsysobj FSysObj
---@param append_path string?
local function newModFSysObj(originalFsysobj, append_path)
    ---@class UMGModFSysObj
    local self = setmetatable({}, FilesystemObject_mt)
    local fsysObj = originalFsysobj

    if append_path and #append_path > 0 then
        fsysObj = originalFsysobj:cloneWithSubpath(append_path, originalFsysobj:isWritable())
    end

    ---@param fname string
    ---@param filtertype love.FileType
    ---@return {type:love.FileType,size:integer,modtime:integer,readonly: boolean}?
    function self:getInfo(fname, filtertype)
        return fsysObj:getInfo(fname, filtertype)
    end

    ---@param fname string
    ---@param func fun(path:string,filename:string,ext:string)
    function self:foreachFile(fname, func)
        return fsysObj:foreachFile(fname, func)
    end

    ---@param dir string
    ---@return string[]
    function self:getDirectoryItems(dir)
        return fsysObj:getDirectoryItems(dir)
    end

    ---@param dir string
    ---@return boolean
    function self:createDirectory(dir)
        return fsysObj:createDirectory(dir)
    end

    ---@param fname string
    ---@return string?,string?
    function self:read(fname)
        ---@diagnostic disable-next-line: return-type-mismatch
        return fsysObj:read(fname, "string")
    end

    ---@param fname string
    ---@param data string|love.Data
    ---@param size integer?
    ---@return boolean,string?
    function self:write(fname, data, size)
        return fsysObj:write(fname, data, size)
    end

    ---@param fname string
    ---@param data string|love.Data
    ---@param size integer?
    ---@return boolean,string?
    function self:append(fname, data, size)
        return fsysObj:append(fname, data, size)
    end

    ---@param fname string
    ---@param mode love.FileMode
    ---@return (love.File)?,string?
    function self:openFile(fname, mode)
        return fsysObj:openFile(fname, mode)
    end

    ---@param fname string
    ---@return love.FileData?,string?
    ---@diagnostic disable-next-line: duplicate-set-field
    function self:newFileData(fname)
    end

    ---@param contents string|love.Data
    ---@param fname string
    ---@return love.FileData
    ---@diagnostic disable-next-line: duplicate-set-field
    function self:newFileData(contents, fname)
        ---@diagnostic disable-next-line: return-type-mismatch
        return fsysObj:newFileData(contents, fname)
    end

    ---@param path string
    ---@return boolean
    function self:exists(path)
        return fsysObj:exists(path)
    end

    ---@param path string
    ---@return boolean
    function self:remove(path)
        return fsysObj:remove(path)
    end

    ---@return boolean
    function self:isWritable()
        return fsysObj:isWritable()
    end

    ---@param subpath string?
    ---@param readwrite boolean?
    ---@return UMGModFSysObj
    function self:cloneWithSubpath(subpath, readwrite)
        local newFsysObj = fsysObj:cloneWithSubpath(subpath, readwrite)
        return newModFSysObj(newFsysObj)
    end

    return self
end


return newModFSysObj
