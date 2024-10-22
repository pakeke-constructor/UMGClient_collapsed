

local path = tools.path(...)

local ClientConnectionObject = require("src.client.session.connection.ClientConnection")



local IngameSession = tools.SafeClass()



local assertIngameOptions = require("src.client.session.IngameOptions")


local setupConnection = require(path .. ".setup.setup_connection")
local setupEntitySyncer = require(path .. ".setup.setup_entity_syncer")




function IngameSession:init(ingameOptions)
    assertIngameOptions(ingameOptions)
    tools.inlineMethods(self)


    self.umgSession = UMGSession()
    self.setupPipeline = false

    self.quitFlag = false
    self.disconnectReason = false

    self.clientConnection = ClientConnectionObject({
        cyWorld = self.umgSession.cyWorld,
        packer = self.umgSession.packer,
        ip = ingameOptions.ip,
        port = ingameOptions.port,
        username = userService.username,
        clientId = userService.clientId
    })

    self.ingameOptions = ingameOptions

    setupConnection(self)
    setupEntitySyncer(self)
end



function IngameSession:update(dt)
    self.umgSession:update(dt)
    self.clientConnection:update(dt)

    -- flush ECS every frame
    self.umgSession:flush()
end



function IngameSession:tick(dt)
    self.umgSession:tick(dt)
    self.clientConnection:flush()
end



function IngameSession:draw()
    love.graphics.push("all")
    self.umgSession.eventBus:call("@draw")
    love.graphics.pop()
end



function IngameSession:loadMods(modlist)
    local modLoader = ModLoader({
        session = self,
    })
    return modLoader:loadMods(modlist)
end




--[[

TODO:
im not happy with this useless layer of coupling.
The only purpose of these two functions are to serve as "glue"
between clientConnection -> IngameSession -> Ingame state.

Is there an easier way to pop Ingame state...??
]]
function IngameSession:shouldQuit()
    return self.quitFlag
end

function IngameSession:disconnectFromServer(reason)
    self.disconnectReason = reason
    self.quitFlag = true

    if constants.PROFILE_EVENT_BUS then
        self.umgSession:generateProfilerReport("client")
    end
end




local SetupPipeline = require(path .. ".setup.SetupPipeline")


local KEYS = {"onSuccess", "onFail"}

function IngameSession:startSetupPipeline(args)
    tools.assertKeys(args, KEYS)
    assert(not self.setupPipeline, "SetupPipeline already started...?")

    args = table.copy(args)
    args.ingameSession = self

    self.setupPipeline = SetupPipeline(args)
    self.setupPipeline:start()
end


return IngameSession

