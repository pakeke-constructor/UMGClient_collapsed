

local path = tools.path(...)
local setup = require(path .. ".setup")

local ServerConnection = require("src.server.session.connection.ServerConnection")

local EntitySyncer = require(path .. ".EntitySyncer")

local WorldLoader = require(path .. ".WorldLoader.WorldLoader")


local ServerSession = tools.SafeClass()



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
    
    setup(self)
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


function ServerSession:update(dt)
    self.umgSession:update(dt)
    self.serverConnection:update(dt)
    self.worldLoader:update(dt)
    updateTick(self, dt)
end


function ServerSession:flush()
    self.umgSession:flush()
end





return ServerSession
