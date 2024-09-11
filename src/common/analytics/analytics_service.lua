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
                    isHost = false,
                    modlist = {}
                },
                server = {
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

        local randomValueHex = table.concat(randomValue)
        log.info("Configuring analytics service with steamID = "..steamid.." and randomValue = "..randomValueHex)
        analyticsChannel:push({
            name = "configure",
            steam_id = steamid,
            random_value = randomValueHex
        })
    end
end

---@param isHost boolean
---@param modlist string[]
function analyticsService.setupClient(isHost, modlist)
    assert(modlist)
    if analyticsChannel then
        analyticsModlistChannel:performAtomic(function()
            local modlistInfo = analyticsModlistChannel:pop()

            modlistInfo.client = {
                isHost = isHost,
                modlist = modlist
            }
            analyticsModlistChannel:push(modlistInfo)
        end)
    end
end

---@param modlist string[]
function analyticsService.setupServer(modlist)
    assert(modlist)
    if analyticsChannel then
        analyticsModlistChannel:performAtomic(function()
            local modlistInfo = analyticsModlistChannel:pop()

            modlistInfo.server = {
                modlist = modlist
            }
            analyticsModlistChannel:push(modlistInfo)
        end)
    end
end



---@param clientside boolean
---@param name string
---@param content string
function analyticsService.add(clientside, name, content)
    if analyticsChannel then
        analyticsChannel:push({
            name = "add",
            clientside = clientside,
            dataname = name,
            contents = content
        })
    end
end

function analyticsService.forceFlush()
    if analyticsChannel then
        analyticsChannel:push({name = "flush"})
    end
end

function analyticsService.quit()
    if analyticsThread then
        -- Clean buffers
        while analyticsChannel:getCount() > 0 do
            analyticsChannel:pop()
        end

        analyticsService.forceFlush()

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
2. In client, call analyticsService.setupClient(hoster, modname, modlist)
3. In server, call analyticsService.setupServer(modname, modlist)
4. Call analyticsService.add(...) to insert data
5. Analytics thread will flush if necessary. To force flush, call analyticsService.forceFlush()
6. In love.quit (or the equivalent if erroring), call analyticsService.quit() to ensure threads are cleared.
]]


return analyticsService
