require("love.timer")
require("love.system")

local https = require("https")
local constants = require("src.common.constants")
local json = require("libs.nm_json.json")

local analyticsStatusChannel = love.thread.getChannel("analytics:channel")
local analyticsModlistChannel = love.thread.getChannel("analytics:modlist")
local analyticsChannel = analyticsStatusChannel:peek()

local userOS = love.system.getOS()



local function getModinfo()
    return assert(analyticsModlistChannel:performAtomic(function()
        return analyticsModlistChannel:peek()
    end))
end



---@class AnalyticsThreadMessage
---@field public name "configure"|"add"|"flush"|"quit"

---@class AnalyticsThreadConfigure: AnalyticsThreadMessage
---@field public steam_id string
---@field public random_value string

---@class AnalyticsThreadSend: AnalyticsThreadMessage
---@field public clientside boolean
---@field public host boolean
---@field public mod string
---@field public modlist string[]
---@field public data table<string, string>

---@class AnalyticsThreadAdd: AnalyticsThreadMessage
---@field public clientside boolean
---@field public dataname string
---@field public contents string

-- Contains list of message handlers.
local AnalyticsHandler = {}

-- This will contain token needed for X-Session-Token
local analyticsToken = ""
-- If this is true, then analytics system (either lua-https or the server) is broken and no attempt should be done
-- to send data.
local analyticsBroken = false
-- Retry count
local analyticsRetryCount = 0
local MAX_RETRY_COUNT = 3
-- Counter when to flush
local analyticsFlushTime = -math.huge
-- Time to flush
local ANALYTICS_FLUSH_TIME = 3
-- Contains last "configure" message, for reconfig if previous one fails.
local lastConfigureMessage = nil


local messageBuffer = {
    ---@type AnalyticsThreadAdd[]
    client = {},
    ---@type AnalyticsThreadAdd[]
    server = {}
}

---@param buffer AnalyticsThreadAdd[]
local function convertBufferToSendDataRequest(buffer)
    local result = {
        clientside = false,
        host = false,
        modlist = {},
        data = {},
    }

    for _, data in ipairs(buffer) do
        result.data[#result.data+1] = {
            name = data.dataname,
            content = data.contents
        }
    end

    return result
end


---@param message AnalyticsThreadConfigure
---@param keepRetry boolean?
function AnalyticsHandler.configure(message, keepRetry)
    analyticsBroken = false
    lastConfigureMessage = message

    if not keepRetry then
        analyticsRetryCount = 0
    end

    local statusCode, body = https.request(constants.BASE_ANALYTICS_SERVER_PATH.."/auth", {
        data = json.encode({
            steam_id = message.steam_id,
            random_value = message.random_value,
            -- TODO
            os = userOS,
            os_version = "TODO"
        }),
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if statusCode then
        if math.floor(statusCode / 100) == 2 then
            -- Works
            analyticsToken = json.decode(body).token
            return true
        elseif statusCode ~= 0 then
            -- Server is broken/not comply
            analyticsBroken = true
        end
    -- This is hacky, but oh well
    elseif body == "No applicable HTTPS implementation found" then
        analyticsBroken = true
    end

    return false
end

---@param message AnalyticsThreadAdd
function AnalyticsHandler.add(message)
    if analyticsBroken then
        -- Yea don't bother
        return
    end

    local modinfo = getModinfo()
    local modinfodata = modinfo[message.clientside and "client" or "server"]
    if #modinfodata.modlist == 0 then
        -- Modlist not configured
        return
    end

    local t = message.clientside and messageBuffer.client or messageBuffer.server
    t[#t+1] = message

    if analyticsFlushTime < 0 then
        analyticsFlushTime = 0
    end
end

function AnalyticsHandler.flush()
    if analyticsBroken then
        -- Yea don't bother
        return
    end

    if (#messageBuffer.client + #messageBuffer.server) == 0 then
        -- Nothing to send
        analyticsFlushTime = -math.huge
        return
    end

    if #analyticsToken == 0 then
        if not lastConfigureMessage then
            -- Not configured. Don't bother
            return
        end

        -- Try configuring it
        local configured = AnalyticsHandler.configure(lastConfigureMessage)

        if not configured then
            if not analyticsBroken then
                -- Increase retry count
                analyticsRetryCount = analyticsRetryCount + 1
            end

            if analyticsRetryCount > MAX_RETRY_COUNT then
                -- Stop trying.
                analyticsBroken = true
            end

            return
        end
    end

    local request = {}
    local modinfo = getModinfo()

    if #modinfo.client.modlist > 0 and #messageBuffer.client > 0 then
        local clientSendRequest = convertBufferToSendDataRequest(messageBuffer.client)
        clientSendRequest.clientside = true
        clientSendRequest.host = modinfo.client.isHost
        clientSendRequest.modlist = modinfo.client.modlist
        request[#request+1] = clientSendRequest
    end

    if #modinfo.server.modlist > 0 and #messageBuffer.server > 0 then
        local serverSendRequest = convertBufferToSendDataRequest(messageBuffer.server)
        serverSendRequest.modlist = modinfo.server.modlist
        request[#request+1] = serverSendRequest
    end

    local headers = {
        ["Content-Type"] = "application/json",
        ["X-Session-Token"] = analyticsToken
    }
    local dataToSend = json.encode(request)
    -- dataToSend = love.data.compress("string", "gzip", dataToSend, 9)
    -- headers["Content-Encoding"] = "gzip"

    local code = https.request(constants.BASE_ANALYTICS_SERVER_PATH.."/send", {
        data = dataToSend,
        headers = headers
    })

    if code == 200 then
        -- OK
        analyticsFlushTime = -math.huge
        analyticsRetryCount = 0
        -- flush buffers
        messageBuffer.client = {}
        messageBuffer.server = {}
    else
        -- Fail
        analyticsFlushTime = 0

        if code and code ~= 0 then
            -- Broken
            analyticsBroken = true
        else
            -- Maybe broken?
            analyticsRetryCount = analyticsRetryCount + 1
            if analyticsRetryCount > MAX_RETRY_COUNT then
                analyticsBroken = true
            end
        end
    end
end



local function pullData(chan)
    return chan:demand(0.05)
end



local currentTime = love.timer.getTime()

-- Main loop
while true do
    -- compute dt
    local newTime = love.timer.getTime()
    local dt = newTime - currentTime
    currentTime = newTime

    ---@type AnalyticsThreadMessage?
    local message = analyticsChannel:performAtomic(pullData)

    if message then
        if message.name == "quit" then
            break
        elseif AnalyticsHandler[message.name] then
            AnalyticsHandler[message.name](message)
        end
    end

    analyticsFlushTime = analyticsFlushTime + dt
    if analyticsFlushTime >= ANALYTICS_FLUSH_TIME then
        AnalyticsHandler.flush()
    end

    collectgarbage()
    collectgarbage()
end
