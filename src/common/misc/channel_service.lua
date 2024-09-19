
--[[

Represents bidirectional communication between client <--> server
threads, using love2d Channels

WARNING:
This is a SINGLETON module!!!
If two server-threads get launched at the same time, there WILL
BE CONFLICTS, because the threads will be shared.

]]


local channelService = tools.SafeTable()

local LaunchOptions = require("src.common.misc.LaunchOptions")
local log = require("src.common.log")


local function enum(t)
    -- TODO: this should prolly be in tools module        
    for _k,v in ipairs(t) do
        t[v] = v
    end
    return t
end




local serverToClient = enum({
    "server_memory", -- keep count of mem use on client
    "console_output", -- proxying prints to client
    "log_output", -- proxying log text from server to client
    "ipport" -- providing local port to clientside
})

local clientToServer = enum({
    "server_init_options", -- sending launch-options and other init options thru
    "close_server"
})



local SERVER = SERVER_SIDE
local CLIENT = CLIENT_SIDE






local function getChannel(enumTable, channelId)
    if not enumTable[channelId] then
        error("Invalid channel: " .. tostring(channelId) .. "\n" .. inspect(enumTable))
    end
    return love.thread.getChannel(channelId)
end


local function getSendChannel(channelId)
    local tabl
    if CLIENT then
        tabl = clientToServer
    elseif SERVER then
        tabl = serverToClient
    end
    return getChannel(tabl, channelId)
end

local function getReceiveChannel(channelId)
    local tabl
    if SERVER then
        tabl = clientToServer
    elseif CLIENT then
        tabl = serverToClient
    end
    return getChannel(tabl, channelId)
end







local function clearAndSend(channelId, msg)
    local channel = getSendChannel(channelId)
    channel:clear()
    channel:push(msg)
end


local function peek(channelId)
    local channel = getReceiveChannel(channelId)
    return channel:peek()
end

local function popLast(channelId)
    -- pops the last (most recent) message in the channel and returns it
    local channel = getReceiveChannel(channelId)
    local ret = channel:pop()
    while channel:peek() do
        ret = channel:pop()
    end
    return ret
end



function channelService.sendIPPort(peer)
    local ipport = tools.peer_to_ipport(peer)
    clearAndSend("ipport", ipport)
end
function channelService.tryGetIPPort()
    local peeked = peek("ipport")
    if peeked then
        return peeked
    end
end






function channelService.provideServerInitOptions(launchOptions)
    assert(CLIENT_SIDE)
    assert(getmetatable(launchOptions) == LaunchOptions, "?")

    local options = {
        clientId = userService.clientId,
        username = userService.username,
        loglevel = log.getLevel(),
        serializedLaunchOptions = launchOptions:serialize(),
    }
    clearAndSend("server_init_options", options)
end

function channelService.getServerInitOptions()
    local options = popLast("server_init_options")
    local launchOptions = LaunchOptions.deserialize(options.serializedLaunchOptions)

    assert(launchOptions, "no launch options given")
    assert(options.username, "needs username")
    assert(options.clientId, "needs clientId")
    assert(options.loglevel, "need server log level")
    options.clientId = tostring(options.clientId)
    options.serializedLaunchOptions = nil
    options.launchOptions = launchOptions
    return options
end






function channelService.sendPrint(...)
    local t = {}
    for i=1, select("#", ...) do
        local v = select(i, ...)
        t[i] = tostring(v)
    end
    local channel = getSendChannel("console_output")
    channel:push(t)
end
function channelService.executePrints()
    local channel = getReceiveChannel("console_output")
    local tabl = channel:pop()
    while tabl do
        print("[Server] ", unpack(tabl))
        tabl = channel:pop()
    end
end

function channelService.sendLog(level, lineinfo, text)
    local channel = getSendChannel("log_output")
    channel:push({level, lineinfo, text})
end

function channelService.executeLogs()
    local channel = getReceiveChannel("log_output")
    while true do
        local logdata = channel:pop()

        if not logdata then
            break
        end

        local level, lineinfo, text = unpack(logdata)
        log.logDirectly(level, "[Server] "..lineinfo, text)
    end
end


function channelService.sendMemoryUsage()
    local count = collectgarbage("count")
    clearAndSend("server_memory", count)
end
function channelService.getMemoryUsage()
    return popLast("server_memory")
end






do
local CLOSE = "CLOSE"
local SAVE_AND_CLOSE = "SAVE_AND_CLOSE"

function channelService.shouldCloseServer()
    local peeked = peek("close_server")
    if peeked then
        return peeked
    end
end
function channelService.closeServer()
    clearAndSend("close_server", CLOSE)
end
function channelService.saveAndCloseServer()
    clearAndSend("close_server", SAVE_AND_CLOSE)
end

end




function channelService.resetChannels()
    for _, channelId in ipairs(serverToClient) do
        getChannel(serverToClient, channelId):clear()
    end

    for _, channelId in ipairs(clientToServer) do
        getChannel(clientToServer, channelId):clear()
    end
end




return channelService

