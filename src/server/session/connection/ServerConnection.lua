

local ClientHandler = require("src.server.session.connection.ClientHandler")


local BaseConnection = require("src.common.connection.Connection")

---@class ServerConnection
local ServerConnection = tools.Class(BaseConnection)


local REGULAR_CHANNEL = constants.ENET_REGULAR_CHANNEL
local UNRELIABLE_CHANNEL = constants.ENET_UNRELIABLE_CHANNEL





--[[

=================================
ENet backend thin wrapper:

This makes it easy to swap networking backends in the future.
Ie. if we switch to Steam networking sockets.
=================================

]]
local function makeHost(ipport)
    return enet.host_create(ipport)
end


local function unicast(self, clientId, data, isUnreliable)
    -- using ENet backend, identifiers are ENet peers.
    local peer = self.clientHandler:getIdentifier(clientId)
    if isUnreliable then
        peer:send(data, UNRELIABLE_CHANNEL, "unreliable")
    else
        peer:send(data, REGULAR_CHANNEL)
    end
end


local broadcast
do
local function bcast(host, data, isUnreliable)
    if isUnreliable then
        host:broadcast(data, UNRELIABLE_CHANNEL, "unreliable")
    else
        host:broadcast(data, REGULAR_CHANNEL)
    end
end

function broadcast(self, data, isUnreliable)
    bcast(self.offlineEnetHost, data, isUnreliable)
    if self.isOnline then
        bcast(self.enetHost, data, isUnreliable)
    end
end
end

local function flushPackets(self)
    -- flushes all outgoing packets
    self.offlineEnetHost:flush()
    if self.isOnline then
        self.enetHost:flush()
    end
end

--[[
    TODO: combine into one call:
        pollPackets(self)
]]
local function pollLocalPackets(self)
    --[[
        poll for all received packets
    ]]
    local host = self.offlineEnetHost
    return function()
        return host:service()
    end
end

local function pollOnlinePackets(self)
    if not self.isOnline then
        return tools.nullFunction
    end
    return function()
        return self.enetHost:service()
    end
end


--[[

==================================================
    ENet backend END.
==================================================

]]








local function initializeOnlineHost()
    -- Hosting online via port forwarding or public IP
    local host, err
    local port = serverInitOptions.launchOptions.raw_port

    local ip = tools.get_computer_ip()
    log.trace("starting raw host on ip port: ", ip, port)

    host, err = makeHost(ip .. ":" .. tostring(port))

    if not host then
        error("host failed creation: " .. tostring(err))
    end
    return host
end



local function makeWriterPair(self)
    --[[
        a writer pair is a pair of writers that is responsible for
        Writing packets. Each pair has two writers:
        one for unreliable packets, and one for normal packets.
    ]]
    local boxer = self.boxer
    return {
        unreliableWriter = boxer:newWriter(),
        normalWriter = boxer:newWriter()
    }
end


---@param args {isOnline:boolean,eventBus:EventBus}
function ServerConnection:init(args)
    tools.assertKeys(args, {"isOnline", "eventBus"})
    tools.inlineMethods(self)
    self:superInit(args)

    -- port 0 --> OS will pick ephermeral port
    self.offlineEnetHost = makeHost("127.0.0.1:0")
    channelService.sendIPPort(tools.peer_to_ipport(self.offlineEnetHost))

    self.isOnline = args.isOnline
    if self.isOnline then
        self.enetHost = initializeOnlineHost()
    end

    self.isReady = false

    self.clientHandler = ClientHandler({
        serverConnection = self,
        eventBus = args.eventBus --[[
            TODO::: wtf? should we really be passing the eventBus
            in thru here...? ]]
    })

    self.globalWriters = makeWriterPair(self)

    self.clientIdToWriterPair = {--[[
        [clientId] -> {
            writer = Boxer:newWriter()
            unreliableWriter = Boxer:newWriter()
        }
    ]]}
    self.bufferedDisconnections = tools.Set()
end

if false then
    ---@param args {isOnline:boolean,eventBus:EventBus}
    ---@return ServerConnection
    function ServerConnection(args) end ---@diagnostic disable-line: cast-local-type, missing-return
end




local function getWriterFromPair(writerPair, options)
    if options.isUnreliable then
        return writerPair.unreliableWriter
    else
        return writerPair.normalWriter
    end
end

local function getWriterFromClientId(self, clientId, options)
    local map = self.clientIdToWriterPair
    if not map[clientId] then
        map[clientId] = makeWriterPair(self)
    end
    local writerPair = map[clientId]
    return getWriterFromPair(writerPair, options)
end


local function writePacket(self, writer, packetName, a,b,c,d,e,f)
    if self.isDynamicPacket[packetName] then
        local data = self.packer:serializeVolatile(a,b,c,d,e,f)
        writer:write(packetName, data)
    else
        writer:write(packetName, a,b,c,d,e,f)
    end
end


local NULL_OPT = {}

---@param options table|nil
---@param packetName string
---@param a any
---@param b any
---@param c any
---@param d any
---@param e any
---@param f any
function ServerConnection:broadcast(options, packetName, a,b,c,d,e,f)
    options = options or NULL_OPT
    if packetName == "items:setInventorySlot" then
        log.trace("items:setInventorySlot:::: ", a,b,c)
    end
    assert(type(options) == "table", "?")
    if not self.isReady then
        return -- no point in sending data if we aint ready!
    end
    local writer = getWriterFromPair(self.globalWriters, options)
    writePacket(self, writer, packetName, a,b,c,d,e,f)
end

---@param options table|nil
---@param packetName string
---@param a any
---@param b any
---@param c any
---@param d any
---@param e any
---@param f any
function ServerConnection:unicast(clientId, options, packetName, a,b,c,d,e,f)
    options = options or NULL_OPT
    assert(type(options) == "table", "?")
    if not self.isReady then
        return -- no point in sending data if we aint ready!
    end
    local writer = getWriterFromClientId(self, clientId, options)
    writePacket(self, writer, packetName, a,b,c,d,e,f)
end





---@param self ServerConnection
---@param clientId string
local function broadcastClientJoin(self, clientId)
    local info = self.clientToInfo[clientId]
    local data = json.encode(info)
    self:broadcast(nil, "@client_join", clientId, data)
end


---@param self ServerConnection
---@param clientId string
local function broadcastClientLeave(self, clientId)
    self:broadcast(nil, "@client_leave", clientId)
end






---@param self ServerConnection
local function flushAndBroadcast(self, writer, isUnreliable)
    local data = writer:flush()
    broadcast(self, data, isUnreliable)
end


---@param self ServerConnection
local function flushAndUnicast(self, clientId, writer, isUnreliable)
    local data = writer:flush()
    unicast(self, clientId, data, isUnreliable)
end

---@param self ServerConnection
local function flushClientWriters(self, clientId)
    local writerPair = self.clientIdToWriterPair[clientId]
    if not writerPair then
        -- no unicasting has been done for this client
        return
    end

    local writer = writerPair.normalWriter
    flushAndUnicast(self, clientId, writer)

    local unreliableWriter = writerPair.unreliableWriter
    flushAndUnicast(self, clientId, unreliableWriter, true)
end

---@param self ServerConnection
---@param clientId string
local function disconnectClientReal(self, clientId)
    local peer = self.clientHandler:getIdentifier(clientId)
    peer:disconnect_later()
end

---@param dt number
function ServerConnection:tick(dt)
    self:broadcast(nil, "@tick", dt)
    self:flushPackets()
end

function ServerConnection:flushPackets()
    -- unicasts:
    for clientId in self.clientHandler:iter() do
        -- flush client unicast buffers
       flushClientWriters(self, clientId)
    end

    -- broadcasts:
    local writerPair = self.globalWriters
    flushAndBroadcast(self, writerPair.normalWriter)
    flushAndBroadcast(self, writerPair.unreliableWriter, true)
    
    flushPackets(self)

    for _, clientId in ipairs(self.bufferedDisconnections) do
        disconnectClientReal(self, clientId)
    end
    self.bufferedDisconnections:clear()
end

function ServerConnection:getPlayers()
    local tabl = {}
    for clientId in self.clientHandler:iter() do
       table.insert(tabl, clientId)
    end
    return tabl
end




local defineResponderTc = tc.assert("string", "table")

---@param packetName string
---@param options {responsesPerSecond:number,response:fun(self:any,clientId:string,...:any)}
function ServerConnection:defineResponder(packetName, options)
    defineResponderTc(packetName, options)
    --[[
        :defineResponder("@my_packet", {
            response = function(self, clientId, a,b,c,d,e,f)
                broadcast(...)
            end,
            
            responsesPerSecond = 1/60; 1 response every 60 seconds.
        })
    ]]
    local lastRequestTime = {--[[
        [clientId] --> time
    ]]}

    -- delay = time in seconds between packet responses
    local delay = 1 / (options.responsesPerSecond or math.huge)

    local function okayToRespond(clientId)
        local time = love.timer.getTime()
        local lastTime = lastRequestTime[clientId] or -0xfffffffff
        local hasAuth = self.clientHandler:isAuthenticated(clientId) 
        return hasAuth and ((lastTime + delay) <= time)
    end

    self:on(packetName, function(clientId, a,b,c,d,e,f)
        if okayToRespond(clientId) then
            options.response(self, clientId, a,b,c,d,e,f)
            lastRequestTime[clientId] = love.timer.getTime() 
        end
    end)
end




---@param self ServerConnection
local function dispatchConnect(self, ev)
    self.isReady = true
end

---@param self ServerConnection
local function dispatchDisconnect(self, ev)
    local clientId = self.clientHandler:getClientId(ev.peer)

    if clientId then
        self:disconnectClient(clientId)
    else
        log.fatal("Trying to disconnect nil clientId")
    end
end


---@param self ServerConnection
local function acceptClient(self, identifier)
    local clientId = self.clientHandler:getClientId(identifier)
    local clientInitJson = {
        -- Can put more data here if we want.
        packetVersion = constants.BOXER_PACKET_VERSION,
        boxerData = self.boxer:serializeData(),
    }
    local data = json.encode(clientInitJson)
    -- unicast raw json data:
    unicast(self, clientId, data)
    broadcastClientJoin(self, clientId)
    log.trace("ACCEPTING CLIENT: ", clientId)
end



---@param self ServerConnection
local function dispatchReceive(self, ev)
    local identifier = ev.peer
    local data = ev.data
    local clientHandler = self.clientHandler
    local listener = self:getCurrentListener()
    local clientId = clientHandler:getClientId(identifier)

    if (not clientId) then
        -- Then we need to attempt to authenticate the client.
        -- Read and try accept the connectJson:
        local connectJson = data
        local success = clientHandler:tryAuthenticateClient(identifier, connectJson)
        if success then
            acceptClient(self, identifier)
        end

    elseif clientHandler:isAuthenticated(clientId) then
        --[[
            HMMM: should we be checking whether clientId is ready
            before reading the packets..?
            That could be a good idea.
        ]]
        self:foreachPacket(data, function(_self, packetName, a,b,c,d,e,f)
            local func = listener[packetName]
            if func then
                func(clientId, a,b,c,d,e,f)
            end
        end)
    else
        log.trace("Wot wot??")
    end
end

local dispatch = {
    receive = dispatchReceive,
    disconnect = dispatchDisconnect,
    connect = dispatchConnect
}


---@param dt number
function ServerConnection:update(dt)
    for ev in pollLocalPackets(self) do
        dispatch[ev.type](self, ev)
    end

    for ev in pollOnlinePackets(self) do
        dispatch[ev.type](self, ev)
    end
end

---@param self ServerConnection
---@param clientId string
local function unicastServerDisconnect(self, clientId)
    -- TODO: Allow specifying reason
    return self:unicast(clientId, nil, "@server_disconnect", "Disconnected normally by server")
end


---@param packetName string
function ServerConnection:broadcastNewPacketId(packetName)
    local packetId = self.boxer:getPacketId(packetName)
    assert(packetId,"?")
    self:broadcast(nil, "@define_packet_id", packetId, packetName)
end

---TODO: Pass reason string or number, whatever lighter.
---Example:
---```lua
---function ban(clientId)
---    serverConnection:disconnectClient(clientId, BANNED_IDENTIFIER)
---    banlistManager:addToBans(clientId)
---end
---```
---@param clientId string
function ServerConnection:disconnectClient(clientId)
    unicastServerDisconnect(self, clientId)
    broadcastClientLeave(self, clientId)
    self.bufferedDisconnections:add(clientId)
end


function ServerConnection:disconnectEveryone()
    for clientId in self.clientHandler:iter() do
        self:disconnectClient(clientId)
    end
end


return ServerConnection

