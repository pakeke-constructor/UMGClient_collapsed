

local BaseConnection = require("src.common.connection.Connection")

local connectJson = require("src.common.connection.connectJson")


local VERSION = constants.BOXER_PACKET_VERSION

local REGULAR_CHANNEL = constants.ENET_REGULAR_CHANNEL
local UNRELIABLE_CHANNEL = constants.ENET_UNRELIABLE_CHANNEL

--[[

=================================
ENet backend thin wrapper:

This makes it easy to swap networking backends in the future.
Ie. if we switch to Steam networking sockets.
=================================

]]
local function connect(self, ipport)
    self.enetHost = enet.host_create()
    self.enetHost:connect(ipport)
end


local function send(self, data, isUnreliable)
    local host = self.enetHost
    if isUnreliable then
        host:broadcast(data, UNRELIABLE_CHANNEL, "unreliable")
    else
        host:broadcast(data, REGULAR_CHANNEL)
    end
end

local function disconnect(self)
    -- a BIT hacky to assume that the server is peer 1, but its fine
    local peer = self.enetHost:get_peer(1)
    peer:disconnect()
end

local function flushPackets(self)
    -- flushes all outgoing packets
    self.enetHost:flush()
end


local function pollPackets(self)
    --[[
        poll for all received packets
    ]]
    local host = self.enetHost
    return function()
        return host:service()
    end
end
--[[

==================================================
    ENet backend END.
==================================================

]]












local ClientConnection = tools.Class(BaseConnection)


-- defining here, so we can use elsewhere.
local denyConnect





local KEYS = {
    "ip", "port",
    "cyWorld", "packer",
    "clientId", "username"
}

function ClientConnection:init(args)
    self:superInit(args)
    tools.assertKeys(args, KEYS)
    tools.injectKeys(self, args)

    -- Packet writer objects:
    -- (These are serve as "buffers" for outgoing packets. See boxing module for more info)
    self.writer = self.boxer:newWriter()
    self.unreliableWriter = self.boxer:newWriter() -- for unreliable packets
    -- NOTE: unsequenced packets are not supported- that would be too many channels.

    self.ip = args.ip
    self.port = args.port

    self.isTryingToConnect = false
    self.connectStartTime = false
    self.hasConnected = false
    self.tryingToDisconnect = false

    local callbacks = {}
    callbacks.onConnect = tools.nullFunction
    callbacks.onDisconnect = tools.nullFunction
    callbacks.onDeny = tools.nullFunction
    self.callbacks = callbacks
end




function ClientConnection:connect()
    local ipport = self.ip .. ":" .. self.port
    log.trace("ClientConnection connecting with ipport: " .. ipport)
    connect(self, ipport)
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

function ClientConnection:send(options, packetName, a,b,c,d,e,f)
    --[[
        send data to server.
    ]]
    options = options or NULL_OPT
    local writer
    if options.unreliable then
        writer = self.unreliableWriter
    else
        writer = self.writer
    end
    writePacket(self, writer, packetName, a,b,c,d,e,f)
end







function ClientConnection:onConnect(func)
    self.callbacks.onConnect = func
end
function ClientConnection:onDisconnect(func)
    self.callbacks.onDisconnect = func
end
function ClientConnection:onDeny(func)
    self.callbacks.onDeny = func
end





local function receivePacket(self, packetName, a,b,c,d,e,f)
    local func = self:getListenerFunction(packetName)
    if func then
        func(a,b,c,d,e,f)
    end
end



local function finalizeConnection(self, clientInitJson)
    local version = clientInitJson.packetVersion
    if version ~= VERSION then
        log.error("Server Packet Version discrepancy: ", version, VERSION)
        return denyConnect(self)
    end
    local data = clientInitJson.boxerData
    self.boxer:deserializeData(data)
    
    log.trace("Client connection finalized.")
    self.hasConnected = true
    self.isTryingToConnect = false
    self.callbacks.onConnect()
end


local function dispatchReceive(self, ev)
    if self.hasConnected then
        self:foreachPacket(ev.data, receivePacket)
    else
        -- look to load clientInitJson:
        local success, clientInitJson = pcall(json.decode, ev.data)
        if not success then
            log.error("Invalid clientInitJson!!??: ", clientInitJson, ev.data)
            return
        end
        finalizeConnection(self, clientInitJson)
    end
end

local function dispatchConnect(self)
    -- We have connected to the host!
    --  send connectJson.
    self.isTryingToConnect = true
    self.connectStartTime = love.timer.getTime()

    local data = connectJson.serialize({
        connect = "connect",
        username = userService.username,
        clientId = userService.clientId
    })
    send(self, data, false)
    log.trace("ConnectJson sent:\n" .. data)
end

local function dispatchDisconnect(self)
    --[[
        TODO: Do something! Check the old code.
    ]]
    if self.hasConnected then
        self.callbacks.onDisconnect("FIXME: Got disconnect in dispatchDisconnect")
    end
end

local dispatch = {
    receive = dispatchReceive,
    connect = dispatchConnect,
    disconnect = dispatchDisconnect
}



local function flushAndBroadcast(self, writer, isUnreliable)
    if writer.size <= 0 then
        return
    end
    local data = self:compress(writer:flush())
    send(self, data, isUnreliable)
end


function ClientConnection:flush()
    flushAndBroadcast(self, self.writer, false)
    flushAndBroadcast(self, self.unreliableWriter, true)

    flushPackets(self)
end




function denyConnect(self)
    log.warn("Connection to server was denied! (Timed out or server full)")
    self.callbacks.onDeny()
    disconnect(self)
    self.isTryingToConnect = false
end


function ClientConnection:update(_dt)
    for ev in pollPackets(self) do
        dispatch[ev.type](self, ev)
    end

    if self.isTryingToConnect then
        local time = love.timer.getTime()
        local hasTimedOut = time > (self.connectStartTime + constants.SERVER_CONNECT_TIMEOUT)
        if hasTimedOut then
            denyConnect(self)
        end
    end
end


function ClientConnection:forceDisconnect(reason)
    self.hasConnected = false
    self.isTryingToConnect = false
    self.tryingToDisconnect = false
    self.callbacks.onDisconnect(reason)
end


function ClientConnection:tryDisconnect()
    if not self.tryingToDisconnect then
        self:send(nil, "@client_wants_to_disconnect")
        self.tryingToDisconnect = true
    end
end


function ClientConnection:isDisconnecting()
    return self.tryingToDisconnect
end


return ClientConnection

