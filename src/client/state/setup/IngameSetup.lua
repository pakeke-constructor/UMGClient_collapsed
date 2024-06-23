

--[[


]]


local IngameSession = require("src.client.session.IngameSession")

local assertIngameOptions = require("src.client.session.IngameOptions")

local Ingame = require("src.client.state.ingame.ingame")



local IngameSetup = StateClass()





function IngameSetup:init(ingameOptions)
    assertIngameOptions(ingameOptions)
    local ingameSession = IngameSession(ingameOptions)
    self.ingameSession = ingameSession
    self.isHosting = ingameOptions.isHosting
    self.ingameOptions = ingameOptions

    self.loadingLogo = LoadingLogo()
end



IngameSetup:on("draw", function(self)
    self.loadingLogo:draw()
end)



IngameSetup:on("update", function(self, dt)
    self.ingameSession:update(dt)
    self.ingameSession:tick(dt)
    self.loadingLogo:update(dt)
end)



function IngameSetup:onEnter()
    if self.running then
        log.warn("Wtf, already running?")
        return -- already running..?
    end
    log.trace("Starting IngameSetup.")
    self.running = true

    local function onSuccess()
        log.trace("Setup pipeline succeeded. Pushing IngameState.")
        self:pop()
        local state = Ingame(self.ingameSession)
        self:push(state)
    end

    local function onFail()
        log.warn("Setup pipeline failed.")
        self:pop()
    end

    self.ingameSession:startSetupPipeline({
        onSuccess = onSuccess,
        onFail = onFail
    })
end



return IngameSetup

