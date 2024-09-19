
--[[

This lua file is the starting point for all
server threads.

]]
setmetatable(_G, {__index = function(t,k)
    error("Undefined variable: "..tostring(k))
end;
__newindex = function(t,k,v)
    error("Non local created: " .. tostring(k))
end})


require("love.timer")
require("love.physics")
require("love.math")
require("love.system")

rawset(_G, "CLIENT_SIDE", false)
rawset(_G, "SERVER_SIDE", true)

--[[
=============================
    Globals shared between client/server
=============================
]]
require("src.common.globals")
--=============================
--=============================


local function print(...)
    channelService.sendPrint(...)
end
rawset(_G, "print", print)

local serverInitOptions = channelService.getServerInitOptions()
rawset(_G, "serverInitOptions", serverInitOptions)

-- Init logs
log.registerLogger({
    level = serverInitOptions.loglevel,
    output = function(level, lineinfo, text)
        channelService.sendLog(level, lineinfo, text)
    end
})

log.info("Server thread started!")

rawset(_G, "luasteam",  require "src.common.misc.luasteam")



local time = love.timer.getTime()

log.trace("Server UMG modules loaded successfully.")


local launchOptions = serverInitOptions.launchOptions


local ServerSession = require("src.server.session.ServerSession")
rawset(_G, "serverSession", ServerSession({
    launchOptions = launchOptions
}))


local modlist = launchOptions.modlist
table.stable_sort(modlist)
local resolvedModlist = serverSession:loadMods(modlist)

local analyticsService = require("src.common.analytics.analytics_service")
analyticsService.setupServer(resolvedModlist)

local eventBus = serverSession.umgSession.eventBus



local function errhand(msg)
    local json = require("libs.nm_json.json")
    local tb = debug.traceback(msg)
    analyticsService.add(false, "@crash", json.encode({message = tb}))
    return tb
end

-- Begin xpcall
local serverResult, serverErrorMessage = xpcall(function()


log.trace("Calling @load")
eventBus:call("@load")






-- yay! booted.
print(("="):rep(50))
print(("-"):rep(50))
print("UMG SERVER BOOTED.")
print("LAUNCH OPTIONS:")
print(launchOptions:serialize())
print(("-"):rep(50))
print(("="):rep(50))



local timeSinceLastSend = 0


while not serverSession:isClosed() do
    love.timer.sleep(0.005)-- Give CPU some rest aye

    local now = love.timer.getTime()
    local dt = now - time
    time = now

    if channelService.shouldCloseServer() then
        serverSession:close()
        break
    end

    if timeSinceLastSend > 1 then
        timeSinceLastSend = 0
        channelService.sendMemoryUsage()
    end
    timeSinceLastSend = timeSinceLastSend + dt

    serverSession:update(dt)

    serverSession:flush()
end

-- end of xpcall
end, errhand)
if not serverResult then
    error(serverErrorMessage)
end
