

local setup = require("src.server.session.setup")

local ServerConnection = require("src.server.session.connection.ServerConnection")

local EntitySyncer = require("src.server.session.EntitySyncer")

local WorldLoader = require("src.server.session.WorldLoader.WorldLoader")


---@class ServerSession
local ServerSession = tools.SafeClass()



---@param args {launchOptions:table}
function ServerSession:init(args)
    tools.assertKeys(args, {"launchOptions"})
    self.umgSession = UMGSession()

    local launchOptions = args.launchOptions
    self.launchOptions = launchOptions

    local isOnline = self.launchOptions.onlineMode ~= constants.ONLINE_MODES.offline

    self.serverConnection = ServerConnection({
        cyWorld = self.umgSession.cyWorld,
        packer = self.umgSession.packer,
        eventBus = self.umgSession.eventBus,
        isOnline = isOnline,
    })

    self.worldLoader = WorldLoader({
        serverSession = self,
        launchOptions = launchOptions
    })

    self.timeSinceLastTick = 0

    self.entitySyncer = EntitySyncer({
        serverSession = self
    })
    self.closed = false

    setup(self)
end

if false then
    ---@param args {launchOptions:table}
    ---@return ServerSession
    function ServerSession(args) end ---@diagnostic disable-line: cast-local-type, missing-return
end


function ServerSession:getWorldTime()
    --[[
        we should be calling `worldLoader:getWorldTime()` here,
        but i want it to be a bit more efficient :)
    ]]
    return self.worldLoader.worldTime
end



function ServerSession:isWorldPersistent()
    return self.launchOptions:isWorldPersistent()
end



---@param modlist string[]
function ServerSession:loadMods(modlist)
    local modLoader = ModLoader({
        session = self,
    })
    return modLoader:loadMods(modlist)
end




local function tick(self, dt)
    -- order of this is kinda important.
    -- (If its out of order, it'll be a bit more inefficient)
    self.umgSession:tick(dt)
    self.entitySyncer:sendSpawnEntities()
    self.serverConnection:tick(dt)
end


local function updateTick(self, dt)
    local tickrate = 1 / variables.ticks_per_second
    self.timeSinceLastTick = self.timeSinceLastTick + dt
    if self.timeSinceLastTick > tickrate then
        local tdt = self.timeSinceLastTick
        tick(self, tdt)
        self.timeSinceLastTick = 0
    end
end



function ServerSession:saveWorld()
    self.worldLoader:save()
end

function ServerSession:loadWorld()
    self.worldLoader:load()
end


---@param dt number
function ServerSession:update(dt)
    self.umgSession:update(dt)
    self.serverConnection:update(dt)
    self.worldLoader:update(dt)
    updateTick(self, dt)
end


function ServerSession:flush()
    self.umgSession:flush()
end


function ServerSession:close()
    if self.closed then
        return
    end

    self.umgSession.eventBus:call("@quit")

    if channelService.shouldSaveWorld() then
        local worldname = self.launchOptions.worldname
        local mod_struct = self.launchOptions.modstruct
        if worldname then
            serverSession:saveWorld(worldname, mod_struct)
        else
            log.error("Attempted to save world, but no world name exists!")
        end
    end

    self:flush()
    self.serverConnection:disconnectEveryone()
    self.serverConnection:flushPackets()
    self.closed = true
end

function ServerSession:isClosed()
    return self.closed
end

return ServerSession
