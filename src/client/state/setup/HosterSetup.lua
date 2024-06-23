
--[[


Hoster-setup:

- starts server-thread
- waits for server-thread to send through local ipport
- When ipport is sent, pops self, pushes ingame-setup state



]]


local hoster = require("src.client.hoster")

local IngameSetup = require("src.client.state.setup.IngameSetup")




local HosterSetup = StateClass()



local function fail(self, reason)
    log.error(reason)
    self:pop()
end



function HosterSetup:init(launchOptions)
    assert(launchOptions)
    log.trace("Initialized HosterSetup state with LaunchOptions: " .. launchOptions:serialize())
    self.launchOptions = launchOptions
    self.isDone = false

    self.loadingLogo = LoadingLogo()

    if hoster.isHosting() then
        fail(self, "Unable to start host: Already hosting!")
        return
    end

    hoster.start(launchOptions)
end



HosterSetup:on("draw", function(self)
    self.loadingLogo:draw()
end)



HosterSetup:on("update", function(self, _dt)
    self.loadingLogo:update(_dt)
    local ipport = channelService.tryGetIPPort()
    if (not ipport) or self.isDone then
        return
    end

    self.isDone = true
    log.trace("Obtained ipport: ", ipport)
    local ip, port = tools.ipport_to_ip_port(ipport)

    local modlist = self.launchOptions.modlist
    
    local ingameOptions = {
        isHosting = true,

        ip = ip,
        port = port,

        modlist = modlist or nil
    }

    log.trace("HosterSetup transitioning to IngameSetup, with ingameOptions: ", inspect(ingameOptions))
    self:pop()
    self:push(IngameSetup(ingameOptions))
end)




return HosterSetup

