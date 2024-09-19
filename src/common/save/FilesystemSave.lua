local FSysObj = require("src.common.files.FSysObj")

local UMG_SAVE_JSON_FILE = "umg_save.json"

---@class FilesystemSave
local FilesystemSave = tools.Class()

---@param path string
function FilesystemSave:init(name, path)
    self.name = name
    self.fsysObjRoot = FSysObj(path)
    ---@type table<string, FSysObj>
    self.fsysobjOfMods = {}

    if not self.fsysObjRoot:exists(UMG_SAVE_JSON_FILE) then
        self.fsysObjRoot:write(UMG_SAVE_JSON_FILE, "")
    end
end

function FilesystemSave:getName()
    return self.name
end

---@param modname string
function FilesystemSave:getFSysObjFor(modname)
    if not self.fsysobjOfMods[modname] then
        self.fsysobjOfMods[modname] = self.fsysObjRoot:cloneWithSubpath(modname, true)
    end

    return self.fsysobjOfMods[modname]
end

function FilesystemSave:close()
end

---If save with "name" does not exist, throw error.
---@param name string
---@return FilesystemSave
function FilesystemSave.open(name)
    local path = constants.SAVE_DATA_PATH..name
    if not love.filesystem.exists(path) then
        error("save does not exist")
    end

    -- assert(love.filesystem.createDirectory(path), "cannot create save")
    return FilesystemSave(name, path)
end

---If save with "name" already exist, append numbers.
---@param name string
---@return FilesystemSave
function FilesystemSave.new(name)
    local currentName = name
    local path = constants.SAVE_DATA_PATH..name
    local i = 1

    while love.filesystem.exists(path) do
        currentName = name.."_"..i
        path = constants.SAVE_DATA_PATH..currentName
        i = i + 1
    end

    assert(love.filesystem.createDirectory(path), "cannot create save")
    return FilesystemSave(currentName, path)
end

---@param name string
---@return boolean
function FilesystemSave.exists(name)
    return love.filesystem.exists(constants.SAVE_DATA_PATH..name)
end

---@return string[]
function FilesystemSave.list()
    local result = {}

    for _, item in love.filesystem.getDirectoryItems(constants.SAVE_DATA_PATH) do
        if love.filesystem.exists(constants.SAVE_DATA_PATH..item.."/"..UMG_SAVE_JSON_FILE) then
            result[#result+1] = item
        end
    end

    return result
end

---@return FilesystemSave
function FilesystemSave.newTempSave()
    local path = constants.TEMP_PATH.."_SAVE_"
    while love.filesystem.exists(path) do
        path = path..love.math.random(0, 9)
    end

    assert(love.filesystem.createDirectory(path), "cannot create temp save")
    return FilesystemSave(path:sub(#constants.TEMP_PATH), path)
end

return FilesystemSave
