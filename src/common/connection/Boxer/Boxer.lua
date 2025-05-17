
local path = tools.path(...)

local Writer = require(path .. ".Writer")
local Reader = require(path .. ".Reader")

local packetTypes = require(path .. ".packet_types")



local Boxer = tools.SafeClass()




local MAX_ARG_SIZE = 8 -- maximum number of arguments for a packet type




local type = _G.type


local makeTypechecker
--[[
    Boxer can serialize 4 basic types:
        numbers, booleans, strings, entities

    On client -> server, entities are ALWAYS represented as integer ids (ent id)

    But server -> client, entities may be represented as a pckr data string,
        OR they may be represented by an id, (if they have already been serialized)

    Packer handles (most) of the nasty logic for this, so we don't really
    need to worry much.
]]
do
local types = {}

local function makeCheckFunction(typ)
    local expectStr = "Expected " .. typ .. ", got: "
    local function check(x)
        if type(x) ~= typ then
            return nil, expectStr .. tostring(x)
        end
        return true
    end
    return check
end

types.number = makeCheckFunction("number")
types.string = makeCheckFunction("string")
types.boolean = makeCheckFunction("boolean")

function makeTypechecker(self)
    local basicTypes = {}
    local cyWorld = self.cyWorld
    local function isEntity(x)
        --[[
            On clientside, this could also be a pckr string!
            But clientside doesn't need to do typechecking;
                since it trusts the server 100%.
            So this typecheck function is only used on server-side.
        ]]
        if cyWorld:exists(x) then
            return true
        end
        return nil, "Not an entity: " .. tostring(x)
    end

    basicTypes.entity = isEntity
    for k,v in pairs(types) do
        basicTypes[k] = v
    end

    local function typechecker(x, typ)
        if not typ then
            return nil, "Packet too long!"
        end
        return basicTypes[typ](x)
    end
    return typechecker
end

end




local function makeConversionFunctionsServer(self)
    local packer = self.packer
    local cyWorld = self.cyWorld

    local function entityToData(ent)
        --[[
            this function is confusing:
                Basically, Boxer allows us to serialize entities by id (number)
                OR, serialize by value (string).
                This only works for server --> client.
        ]]
        if packer:isEntityKnown(ent) then
            return ent.id
        else
            return packer:serializeVolatile(ent)
        end
    end

    local function dataToEntity(data)
        --[[
            if data is not a number here, it wont matter,
            since cyWorld:getEntity will just return nil :)
        ]]
        return cyWorld:getEntity(data)
    end

    return entityToData, dataToEntity
end


local function makeConversionFunctionsClient(self)
    local packer = self.packer
    local cyWorld = self.cyWorld

    local function entityToData(ent)
        -- always serialize by id on client
        if ent:isClientSide() then
            --[[
                TODO: Should we be erroring here?
                Or should we fail silently?
            ]]
            error("Attempt to serialize a clientside entity: " .. tostring(ent))
        end
        return ent.id
    end

    local function dataToEntity(data)
        --[[
            If data is a string: Deserialize it
            If data is a number: Assume that it's an entity id
        ]]
        if type(data) == "string" then
            return packer:deserializeVolatile(data)
        elseif type(data) == "number" then
            return cyWorld:getEntity(data)
        end
    end

    return entityToData, dataToEntity
end











local function defineDefaultPackets(self)
    for _, packetType in ipairs(packetTypes) do
        self:definePacket(packetType.name, packetType)
        self:generatePacketId(packetType.name)
    end
end



function Boxer:init(options)
    tools.assertKeys(options, {"packer", "cyWorld"})
    tools.inlineMethods(self)

    self.packer = options.packer
    self.cyWorld = options.cyWorld

    local entityToData, dataToEntity
    if CLIENT_SIDE then
        entityToData, dataToEntity = makeConversionFunctionsClient(self)
    elseif SERVER_SIDE then
        entityToData, dataToEntity = makeConversionFunctionsServer(self)
    end
    self.entityToData, self.dataToEntity = entityToData, dataToEntity

    self.packetMapper = StringIdMapper()

    self.nameToPacketTypelist = {--[[
        [packetName] -> typelist
        typelist is a list of string (ie. string, number ...)
    ]]}

    self.typechecker = makeTypechecker(self)

    defineDefaultPackets(self)
end



function Boxer:getPacketName(id, sender)
    return self.packetMapper:getName(id, sender)
end

function Boxer:getPacketId(packetName)
    return self.packetMapper:getId(packetName)
end

function Boxer:generatePacketId(packetName)
    return self.packetMapper:generate(packetName)
end

function Boxer:setPacketId(packetId, packetName)
    self.packetMapper:add(packetId, packetName)
end



function Boxer:getPacketTypelist(packetName)
    return self.nameToPacketTypelist[packetName]
end

Boxer.isValidPacketname = Boxer.getPacketTypelist




function Boxer:newWriter()
    return Writer({
        boxer = self
    })
end



local decode = string.buffer.decode

function Boxer:newReader(data)
    local success, buffer = pcall(decode, data)
    if not success then
        local err = tostring(buffer)
        return nil, "Unable to decode string.buffer data: " .. err
    end

    return Reader(buffer, {
        boxer = self,
    })
end




local validDataTypes = {
    number = true, entity = true,
    string = true, boolean = true
}

local function checkTypelistOk(typelist)
    if #typelist > MAX_ARG_SIZE then
        error("Packet size too big: " .. tostring(#typelist))
    end
    for _,v in ipairs(typelist) do
        if not validDataTypes[v] then
            error("Invalid type: " .. tostring(v))
        end
    end
end


function Boxer:definePacket(packetName, options)
    --[[
        :definePacket("myPacket", {
            typelist = {"number", "number"}, -- types within the packet.
        })

        FOR FUTURE: Do we want to add packet direction here...?
        So clientside can't accidentally send packets that are meant for server
    ]]
    local typelist = options.typelist -- a list of types for the packet
    checkTypelistOk(typelist)
    self.nameToPacketTypelist[packetName] = typelist
end


function Boxer:serializeData()
    return self.packetMapper:serialize()
end

function Boxer:deserializeData(jsonData)
    assert(CLIENT_SIDE,"must be called on client..?")
    local packetMapper = StringIdMapper.deserialize(jsonData)
    self.packetMapper = packetMapper
end




return Boxer

