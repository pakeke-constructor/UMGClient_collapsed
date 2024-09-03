local https = require("https")
local constants = require("src.common.constants")
local json = require("libs.nm_json.json")

local analyticsStatusChannel = love.thread.getChannel("analytics:channel")



---@class AnalyticsThreadMessage
---@field public name "send"|"configure"|"quit"

---@class AnalyticsThreadConfigure: AnalyticsThreadMessage
---@field public steam_id string
---@field public random_value string

---@class AnalyticsThreadSend: AnalyticsThreadMessage
---@field public clientside boolean
---@field public host boolean
---@field public mod string
---@field public modlist string[]
---@field public data table<string, string>

local AnalyticsHandler = {}

-- This will contain token needed for X-Session-Token
local analyticsToken = ""
-- If this is true, then analytics system (either lua-https or the server) is broken and no attempt should be done
-- to send data.
local analyticsBroken = false
-- Retry count
local analyticsRetryCount = 0
local MAX_RETRY_COUNT = 3

local lastConfigureMessage = nil



---@param message AnalyticsThreadConfigure
function AnalyticsHandler.configure(message)
    lastConfigureMessage = message

    local statusCode, body = https.request(constants.BASE_ANALYTICS_SERVER_PATH.."/auth", {
        data = json.encode({
            steam_id = message.steam_id,
            random_value = message.random_value,
            -- TODO
            os = "Unknown",
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

---@param message AnalyticsThreadSend
function AnalyticsHandler.send(message)
    if analyticsBroken then
        -- Yea don't bother
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

            if analyticsRetryCount >= MAX_RETRY_COUNT then
                -- Stop trying.
                analyticsBroken = true
            end

            return -- This message will be lost sadly
        end
    end

    https.request(constants.BASE_ANALYTICS_SERVER_PATH.."/send", {
        data = json.encode({
            clientside = message.clientside,
            host = message.host,
            mod = message.mod,
            modlist = message.modlist,
            data = message.data
        }),
        headers = {
            ["Content-Type"] = "application/json",
            ["X-Session-Token"] = analyticsToken
        }
    })
    -- TODO: Check status code
end



while true do
    ---@type AnalyticsThreadMessage?
    local message = analyticsStatusChannel:demand(1)

    if message then
        if message.name == "quit" then
            break
        elseif AnalyticsHandler[message.name] then
            AnalyticsHandler[message.name](message)
        end
    end

    collectgarbage()
end
