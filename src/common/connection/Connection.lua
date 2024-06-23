

--[[

==========================
Abstract Connection class
==========================

This is the "abstract class" that both ClientConnection and ServerConnection
inherit from.



]]

local Boxer = require("src.common.connection.Boxer.Boxer")

local path = tools.path(...)
local compression = require(path .. ".compression")
local compress, decompress = compression.compress, compression.decompress


local Connection = tools.SafeClass()









local ARGS = {
    "packer", "cyWorld"
}

function Connection:superInit(args)
    --[[
        Should be called by child classes within the `:init`
    ]]
    tools.inlineMethods(self)
    tools.assertKeys(args, ARGS)

    self:setListener(self:newListener())

    self.packer = args.packer

    self.isDynamicPacket = {--[[
        [packetName] -> true
    ]]}

    self.clientIds = tools.Set()
    self.clientToInfo = {--[[
        [clientId] -> info
    ]]}

    local boxer = Boxer({
        packer = self.packer,
        cyWorld = args.cyWorld
    })
    self.boxer = boxer

    -- inline methods
    for k,v in pairs(Connection) do
        self[k] = v
    end
end



function Connection:compress(data)
    return compress(data)
end
function Connection:decompress(data)
    return decompress(data)
end






local addClientTc = tc.assert("string", "string")

function Connection:addClient(clientId, username)
    addClientTc(clientId, username)
    self.clientIds:add(clientId)
    self.clientToInfo[clientId] = {
        username = username
        -- TODO: we can put other data here if we want
    }
end


function Connection:removeClient(clientId)
    self.clientIds:remove(clientId)
    self.clientToInfo[clientId] = nil
end






--[[
    Packet listeners:
    Listen to packets and dispatch actions.

    We can swap out listeners if we want to; however most of the time,
    we will just be using one.
]]

function Connection:setListener(listener)
    self.currentListener = listener
end

function Connection:getCurrentListener()
    return self.currentListener
end

function Connection:newListener()
    return {} --listener is just a table
end

function Connection:on(packetName, func)
    local ok = self.boxer:isValidPacketname(packetName)
    if not ok then
        error("Invalid packet: " .. packetName, 3)
    end
    local listener = self.currentListener
    listener[packetName] = func
end

function Connection:getListenerFunction(packetName)
    local listener = self.currentListener
    return listener[packetName]
end




local function getDynamicData(self, packetName, a,b,c,d,e,f)
    local data = a
    a,b,c,d,e,f = self.packer:deserializeVolatile(data)
    if (not a) and b then
        log.error("Couldn't deserialize dynamic packet", packetName, b)
        return
    end
    return a,b,c,d,e,f
end


function Connection:foreachPacket(data, func)
    --[[
        loops over received `boxer` data, and calls `func` for
        every valid packet found.
    ]]
    data = decompress(data)
    local reader = self.boxer:newReader(data)
    local packetName, a,b,c,d,e,f = reader:read()
    while packetName do
        if self.isDynamicPacket[packetName] then
            a,b,c,d,e,f = getDynamicData(self, packetName, a,b,c,d,e,f)
        end
        func(self, packetName, a,b,c,d,e,f)
        packetName, a,b,c,d,e,f = reader:read()
    end

    if reader:hasFailed() then
        local err = a
        log.error("recieved bad packet: ", err)
    end
end








local PREFIX = constants.BOXER_BUILTIN_PACKET_PREFIX 

local VALID_PACKET_OPTIONS = {dynamic=true, typelist=true}

local definePacketTc = tc.assert(tc.string, tc.table)

function Connection:definePacket(packetName, options)
    --[[
        packetName, {
            dynamic = true / false,
            typelist = {"string", "number"}
        }
    ]]
    definePacketTc(packetName, options)
    for opt,_ in pairs(options) do
        assert(VALID_PACKET_OPTIONS[opt], "Invalid option: " .. opt)
    end
    assert(packetName:sub(1,1) ~= PREFIX, "Packets cannot start with " .. PREFIX)

    log.trace("definePacket: ", packetName)

    if options.dynamic then
        self.isDynamicPacket[packetName] = true
        self.boxer:definePacket(packetName, {
            typelist = {"string"} 
            -- All dynamic packets have a single pckr string as an argument
        })
    else
        self.boxer:definePacket(packetName, options)
    end

    self.boxer:generatePacketId(packetName)

    if SERVER_SIDE then
        -- This must be overridden on server-side
        self:broadcastNewPacketId(packetName)
    end
end








return Connection

