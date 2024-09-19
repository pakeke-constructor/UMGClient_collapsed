local FSysObj = require("src.common.files.FSysObj")

local UMG_SAVE_JSON_FILE = "umg_save.json"

---@class Save
local Save = tools.Class()

---@param path string
function Save:init(name, path)
    self.name = name
    self.fsysObjRoot = FSysObj(path, true, true)
    ---@type table<string, FSysObj>
    self.fsysobjOfMods = {}

    if not self.fsysObjRoot:exists(UMG_SAVE_JSON_FILE) then
        self.fsysObjRoot:write(UMG_SAVE_JSON_FILE, "")
    end
end

function Save:getName()
    return self.name
end

---@param modname string
function Save:getFSysObjFor(modname)
    if not self.fsysobjOfMods[modname] then
        self.fsysObjRoot:createDirectory(modname)
        self.fsysobjOfMods[modname] = self.fsysObjRoot:cloneWithSubpath(modname, true)
    end

    return self.fsysobjOfMods[modname]
end

function Save:close()
    -- Do nothing for now
end

local saveService = {}

---If save with "name" does not exist, throw error.
---@param name string
---@return Save
function saveService.loadSave(name)
    local path = constants.SAVE_DATA_PATH..name
    if not love.filesystem.exists(path) then
        error("save does not exist")
    end

    -- assert(love.filesystem.createDirectory(path), "cannot create save")
    return Save(name, path)
end

---If save with "name" already exist, append numbers.
---@param name string
---@return Save
function saveService.newSave(name)
    local currentName = name
    local path = constants.SAVE_DATA_PATH..name
    local i = 1

    while love.filesystem.exists(path) do
        currentName = name.."_"..i
        path = constants.SAVE_DATA_PATH..currentName
        i = i + 1
    end

    assert(love.filesystem.createDirectory(path), "cannot create save")
    return Save(currentName, path)
end

---@param name string
---@return boolean
function saveService.hasSave(name)
    return love.filesystem.exists(constants.SAVE_DATA_PATH..name)
end

---@return string[]
function saveService.listSaves()
    local result = {}

    for _, item in love.filesystem.getDirectoryItems(constants.SAVE_DATA_PATH) do
        if love.filesystem.exists(constants.SAVE_DATA_PATH..item.."/"..UMG_SAVE_JSON_FILE) then
            result[#result+1] = item
        end
    end

    return result
end

---@return Save
function saveService.newTempSave()
    local path = constants.TEMP_PATH.."_SAVE_"
    while love.filesystem.exists(path) do
        path = path..love.math.random(0, 9)
    end

    assert(love.filesystem.createDirectory(path), "cannot create temp save")
    return Save(path:sub(#constants.TEMP_PATH), path)
end



return saveService
