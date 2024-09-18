
--[[
    a filesystem object that can read-write files,
    and traverse directories.

    Useful for mods, if we want to restrict where we can read files from,
    OR if we want to load files from an outside directory.
]]

---@class FSysObj
local FSysObj = tools.SafeClass()


local SEP = constants.FILE_SEP


---@param path string
---@param is_local_path boolean?
function FSysObj:init(path, is_local_path)
    if is_local_path == false then
        error("attempt to use nativefs: "..path)
    end

    if path:sub(-1) == SEP then
        self.append_path = path
    else
        self.append_path = path .. SEP
    end
end

if false then
    ---@param path string
    ---@param is_local_path boolean?
    ---@return FSysObj
    function FSysObj(path, is_local_path) end ---@diagnostic disable-line: cast-local-type, missing-return
end

---@param subpath string?
function FSysObj:clone(subpath)
    subpath = subpath or ""
    return FSysObj(self.append_path..subpath)
end



function FSysObj:getBasePath()
    return self.append_path
end

---Convert path relative to this FSysObj to path relative to love.filesystem.
---@param path string
function FSysObj:translatePath(path)
    if path:sub(1, 1) == SEP then
        path = path:sub(2)
    end

    return self.append_path..path
end



local read_tc = tc.assert("string", "string?", "number?")
---@param fname string
---@param container_type love.ContainerType
---@param size integer?
---@return (string|love.FileData)?,integer|string
---@overload fun(fname:string,container_type:"string",size:integer?):string
---@overload fun(fname:string,container_type:"data",size:integer?):love.FileData
function FSysObj:read(fname, container_type, size)
    -- Reads a filename in a mod directory.
    -- (This is guaranteed to be safe to call)
    read_tc(fname, container_type, size)
    container_type = container_type or "string"

    ---@diagnostic disable-next-line: redundant-return-value
    return love.filesystem.read(container_type, self:translatePath(fname), size)
end



---@param path string
---@return string[]
function FSysObj:getDirectoryItems(path)
    return love.filesystem.getDirectoryItems(self:translatePath(path))
end



---@param contents string|love.Data
---@param filename string
---@overload fun(self:FSysObj,filename:string):love.FileData
---@return love.FileData?,string?
function FSysObj:newFileData(contents, filename)
    if contents and filename then
        return love.filesystem.newFileData(contents, filename)
    end

    ---@cast contents string
    return love.filesystem.newFileData(self:translatePath(contents))
end


---@param path string
---@param filtertype love.FileType?
---@return {type:love.FileType,size:integer,modtime:integer,readonly:boolean}?
function FSysObj:getInfo(path, filtertype)
    return love.filesystem.getInfo(self:translatePath(path), filtertype)
end


---@param pth string
---@param func fun(path:string,name:string,exten:string)
function FSysObj:foreachFile(pth, func)
    local directory = self:getDirectoryItems(pth)

    -- selene: allow(incorrect_standard_library_use)
    table.stable_sort(directory) -- Sorts by alphabetical I think?? hopefully she'll be right

    for _,file in ipairs(directory) do
        if file:sub(1,1) ~= "_" then
            local full_path = pth..SEP..file
            local info = self:getInfo(full_path)
            ---@cast info -nil

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

