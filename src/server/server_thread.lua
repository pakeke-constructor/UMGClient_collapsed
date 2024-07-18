
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
do

log.setLevel("trace")
log.registerLogger({
    level = serverInitOptions.loglevel,
    output = function(level, lineinfo, text)
        channelService.sendLog(level, lineinfo, text)
    end
})
end

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
serverSession:loadMods(modlist)

local eventBus = serverSession.umgSession.eventBus






log.trace("Calling @load")
eventBus:call("@load")






if launchOptions:isWorldPersistent() then
    -- then we either load or create a new world, depending on what mods are loaded
    serverSession:loadWorld()
else
    -- else, our world is non-persistent. So just emit a createWorld event.
    log.trace("Creating anonymous world")
    eventBus:call("@createWorld")
end



-- yay! booted.
print(("="):rep(50))
print(("-"):rep(50))
print("UMG SERVER BOOTED.")
print("LAUNCH OPTIONS:")
print(launchOptions:serialize())
print(("-"):rep(50))
print(("="):rep(50))






local function close()
    eventBus:call("@quit")

    if channelService.shouldSaveWorld() then
        local worldname = launchOptions.worldname
        local mod_struct = launchOptions.modstruct
        if worldname then
            serverSession:saveWorld(worldname, mod_struct)
        else
            log.error("Attempted to save world, but no world name exists!")
        end
    end

    --[[ TODO: DO THIS ]]
    serverSession:close()
end






local timeSinceLastSend = 0


while 1 do
    love.timer.sleep(0.005)-- Give CPU some rest aye

    local now = love.timer.getTime()
    local dt = now - time
    time = now

    if channelService.shouldCloseServer() then
        close()
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


