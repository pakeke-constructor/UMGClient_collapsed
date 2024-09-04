local analyticsStatusChannel = love.thread.getChannel("analytics:channel")
local analyticsModlistChannel = love.thread.getChannel("analytics:modlist")
local analyticsChannel -- if this is nil, then analytics is not enabled in this build
local analyticsThread

if #constants.BASE_ANALYTICS_SERVER_PATH > 0 then
    analyticsStatusChannel:performAtomic(function()
        analyticsChannel = analyticsStatusChannel:peek()
        if not analyticsChannel then
            log.info("Initializing analytics")
            analyticsChannel = love.thread.newChannel()
            analyticsStatusChannel:push(analyticsChannel)

            analyticsThread = love.thread.newThread("src/common/analytics/analytics_thread.lua")
            analyticsThread:start()
        end
    end)

    analyticsModlistChannel:performAtomic(function()
        if analyticsModlistChannel:getCount() == 0 then
            analyticsModlistChannel:push({
                client = {
                    name = "???",
                    isHost = false,
                    modlist = {}
                },
                server = {
                    name = "???",
                    modlist = {}
                }
            })
        end
    end)
else
    log.info("Analytics has been disabled in this build")
end



local analyticsService = {}

---@param steamid string
function analyticsService.configure(steamid)
    if analyticsChannel then
        local randomValue = {}
        for _ = 1, 32 do
            randomValue[#randomValue+1] = string.format("%02x", love.math.random(0, 255))
        end

        analyticsChannel:push({
            name = "configure",
            steam_id = steamid,
            random_value = table.concat(randomValue)
        })
    end
end

---@param isHost boolean
---@param playableModname string
---@param modlist string[]
function analyticsService.setupClient(isHost, playableModname, modlist)
    if analyticsChannel then
        analyticsModlistChannel:performAtomic(function()
            local modlistInfo = analyticsModlistChannel:pop()

            modlistInfo.client = {
                name = playableModname,
                isHost = isHost,
                modlist = modlist
            }
            analyticsModlistChannel:push(modlistInfo)
        end)
    end
end

---@param playableModname string
---@param modlist string[]
function analyticsService.setupServer(playableModname, modlist)
    if analyticsChannel then
        analyticsModlistChannel:performAtomic(function()
            local modlistInfo = analyticsModlistChannel:pop()

            modlistInfo.server = {
                name = playableModname,
                modlist = modlist
            }
            analyticsModlistChannel:push(modlistInfo)
        end)
    end
end



local SEND_KEYS = {
    clientside = true,
    host = true,
    mod = true,
    modlist = true,
    data = true
}

function analyticsService.forceFlush()
    if analyticsChannel then
        analyticsChannel:push({name = "flush"})
    end
end

---@param data {clientside:boolean,host:boolean,mod:string,modlist:string[],data:table<string,string>}
function analyticsService.send(data)
    tools.assertKeys(data, SEND_KEYS)

    if analyticsChannel then
        analyticsChannel:push({
            name = "send",
            clientside = data.clientside,
            host = data.host,
            mod = data.mod,
            modlist = data.modlist,
            data = data.data
        })
    end
end

function analyticsService.quit()
    if analyticsThread then
        analyticsChannel:performAtomic(function()
            -- Clean buffers
            while analyticsChannel:getCount() > 0 do
                analyticsChannel:pop()
            end

            analyticsService.forceFlush()
        end)

        analyticsChannel:push({name = "quit"})
        analyticsStatusChannel:pop()
        log.info("Waiting for analytics thread to terminate")
        analyticsThread:wait()
        analyticsThread = nil
    end
end


--[[
Analytics service API usage:
1. When hosting or joining a game, call analyticsService.configure(steam_id)
2. Call analyticsService.send({...}) to send analytics data.
3. In love.quit (or the equivalent if erroring), call analyticsService.quit() to ensure threads are cleared.
]]


return analyticsService
