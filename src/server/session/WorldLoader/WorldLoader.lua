

local WorldLoader = tools.SafeClass()



local worlds = require("src.common.worlds.worlds")


local ENTITY_DATA_FILE = constants.ENTITY_DATA_FILE
local WORLD_MODS_FILE = constants.WORLD_MODS_FILE


assert(SERVER_SIDE, "piss off m8")





function WorldLoader:init(args)
    tools.assertKeys(args, {
        "serverSession",
        "launchOptions",
    })
    tools.inlineMethods(self)
    tools.injectKeys(self, args)

    self.modlist = self.launchOptions.modlist
    self.worldname = self.launchOptions.worldname

    self.worldTime = 0

    self.umgSession = self.serverSession.umgSession
    self.packer = self.umgSession.packer
end






local function loadFromData(self, world_pckr_data)
    --[[
        loads world from pckr data.
        This function assumes that all of the 
    ]]
    assert(world_pckr_data, "No pckr data given")
    local success, err = self.packer:deserializeStable(world_pckr_data)
    if (not success) and err then
        log.error("Error deserializing world pckr data: ", err)
    end
end




local function loadExistingWorld(self)
    --[[
        loads an existing world from file.
        `worldname` is the path to the world folder.
    ]]
    local worldname = self.worldname
    local pth = worlds.getWorldPath(worldname)
    log.trace("Loading world:", worldname)
    
    local world_pckr_data, er1 = love.filesystem.read(pth .. "/" .. ENTITY_DATA_FILE)
    if not world_pckr_data then
        log.error("error reading world pckr data: ", er1)
    end

    log.trace("Loading world from pckr data: ", worldname)
    loadFromData(self, world_pckr_data)


    self.worldTime = error([[
        TODO: Load worldTime here!
    ]])
end


function WorldLoader:load()
    if worlds.exists(self.worldname) then
        loadExistingWorld(self)
    else
        log.trace("Creating new world: ", self.worldname)
        local eventBus = self.umgSession.eventBus
        eventBus:call("@createWorld")
    end
end




local function save_mods(worldname, modstruct)
    local pth = worlds.getWorldPath(worldname)
    local data = modstruct:serialize()
    local fname = pth .. "/" .. WORLD_MODS_FILE
    local succ, err = love.filesystem.write(fname, data)
    if not succ then
        log.error("error saving mods.json data: ", err)
    end
end



function WorldLoader:save()
    --[[
        saves world to file
    ]]
    local worldname = self.worldname
    local pth = worlds.getWorldPath(worldname)

    if not love.filesystem.getInfo(pth) then
        love.filesystem.createDirectory(pth)
    end

    log.trace("saving world data:", worldname)
    local data = self.umgSession:serializeWorld()
    local success, err = love.filesystem.write(pth .. "/" .. ENTITY_DATA_FILE, data)
    if not success then
        log.error("error writing entity data: ", err)
    end

    log.trace("saving mod json for world: ", worldname)
    save_mods(worldname, self.modstruct)

    error([[
        TODO: save worldTime!
    ]])
end




function WorldLoader:update(dt)
    self.worldTime = self.worldTime + dt
end

function WorldLoader:getWorldTime()
    return self.worldTime
end






function WorldLoader:saveData(key, data)
    error([[
        TODO:
        this isnt tested!
    ]])

    if not tools.is_valid_filename(key) then
        error("Invalid save data filename: " .. tostring(key))
    end
    if type(data) ~= "string" then
        error("save_data(key, data) expected string as 2nd arg, got: " .. tostring(data))
    end

    local pth = worlds.make_save_path(self.worldname, key)
    local success, err = love.filesystem.write(pth, data)
    if (not success) and constants.DEBUG then
        log.trace("couldn't write data: ", err)
    end
end

function WorldLoader:readData(key)
    error([[
        TODO:
        this isnt tested!
    ]])

    if not tools.is_valid_filename(key) then
        error("Invalid save data filename: " .. tostring(key))
    end
    
    local pth = worlds.make_save_path(self.worldname, key)
    return love.filesystem.read(pth)
end




return WorldLoader

