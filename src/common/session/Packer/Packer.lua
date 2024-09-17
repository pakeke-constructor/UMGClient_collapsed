
--[[


Packer object.

holds a pckr_volatile instance,
AND a pckr_stable instance.


volatile pckr:
    quick and dirty messages, broadcasting, unicasting,
    etc. runtime serialization.
    volatile is fast, but inconsistent across runtimes.
    (Uses a bunch of hacky resource registration.)
    If serialization fails, returns nil.

stable pckr:
    stable serialization.
    Useful for saving worlds, and persisting data.
    If serialization fails, attempts to recover
        by emitting events and questions and stuff.
        (^^^ NYI tho)


Provides a nice abstraction layer so the program isn't interfacing
with pckr_volatile or pckr_stable directly.


]]



if constants.DEBUG then
    require("src.common.session.Packer.pckr_tests")
end



local PckrState = require("src.common.session.Packer.pckr")


---@class Packer
local Packer = tools.SafeClass()


local function noIdDeserialization(_)
    error("Cannot deserialize entities by id in this context")
end

local function falsey()
    return false
end

local function truthy()
    return true
end



---@param s Packer
local function setupPckr(s, options)
    ---@class Packer
    local self = s
    --[[
        sets up pckr contexts, for EITHER client-side OR server-side.
    ]]
    tools.assertKeys(options, {
        "cyWorld", "deserializeEntity", 
        "shouldSerializeEntityById"
    })
    local cyWorld = self.cyWorld; assert(cyWorld)
    local deserializeEntity = options.deserializeEntity
    local shouldSerializeEntityById = options.shouldSerializeEntityById

    local canSerializeEntity
    if SERVER_SIDE then
        function canSerializeEntity(ent)
            return not ent:isDeleted(), "entity was deleted"
        end
    else -- CLIENT_SIDE:
        function canSerializeEntity(ent)
            return true
            -- in future, replace with:
            -- not ent:isClientSide(), "entity is client-side only!"
        end
    end

    local function getEntityById(id)
        return cyWorld:getEntity(id)
    end

    self.pckr_stable = PckrState({
        canSerializeEntity = canSerializeEntity,
        getEntityById = noIdDeserialization, -- never deserialize BY id with stable impl.
        deserializeEntity = deserializeEntity,
        shouldSerializeEntityById = falsey, -- never serialize WITH id with stable impl.
        shouldSerializeIdOfEntity = false
    })

    self.pckr_volatile = PckrState({
        canSerializeEntity = canSerializeEntity,
        getEntityById = getEntityById,
        deserializeEntity = deserializeEntity,
        shouldSerializeEntityById = shouldSerializeEntityById,
        shouldSerializeIdOfEntity = true
    })
end





if SERVER_SIDE then
--[[
    Only available on server-side!!!
    (On clientside, we ALWAYS serialize by id.)

    known-entities are entities that are "known" about on Client-side.
    Useful for checking whether we serialized by id or not.
]]

function Packer:isEntityKnown(ent)
    -- Should we serialize by id or not?
    return self.knownEntities[ent]
end

function Packer:removeKnownEntity(ent)
    -- We will NO LONGER serialize this entity by id.
    self.knownEntities[ent] = nil
end

function Packer:makeEntityKnown(ent)
    -- We will now serialize this entity by id.
    self.knownEntities[ent] = true
end

end




---@param self Packer
local function setupPckrServer(self)
    local function shouldSerializeEntityById(ent)
        return self.knownEntities[ent]
    end

    setupPckr(self, {
        cyWorld = self.cyWorld,
        shouldSerializeEntityById = shouldSerializeEntityById,

        deserializeEntity = function()
            -- If clientside sends us an entity, DON'T incorporate it!
            -- (If we did, hacked clients could spawn random entities!)
            log.error("Clientside attempted to send us an entity?")
            return nil
        end
    })
end



local function isImmutable(val)
    return type(val) ~= "table"
end


local function copyComponents(srcEnt, targEnt)
    -- copies all components from srcEnt to targEnt
    for comp,val in srcEnt:components() do
        -- selene: allow(empty_if)
        if isImmutable(val) then
            -- if the value is immutable, simply set it
            targEnt[comp] = val
        else
            -- hmm... wtf do we do with non-immutable values?
            -- I dont think we can reaaally do much here.
            -- Because other systems may be holding a reference to the object.
            -- In the future, we could deep-copy the immutable values from `val`.
        end
    end
end

---@param self Packer
local function setupPckrClient(self)
    local cyWorld = self.cyWorld
    local function deserializeEntity(ent)
        if not ent.id then
            error("Entity didn't have an id: " .. tostring(ent))
        end
        if cyWorld:getEntity(ent.id) then
            -- Ahh!! We have already deserialized this entity!
            -- This can occur when a previous serialization cycle has serialized this entity.
            -- What we need to do is update the existing entity with the data in the new entity,
            -- since it (could) be more up to date.
            -- (A common situation where this occurs is when nested entities are serialized)

            -- log.trace("Deserializing duplicate entity: ", ent.id)
            local oldEnt = cyWorld:getEntity(ent.id)
            copyComponents(ent, oldEnt)
            return oldEnt
        else
            -- Else, this is the first time we have seen this entity.
            -- Put the deserialized entity into the cyWorld.
            -- (We incorporate it instantly, because packets are guaranteed 
            -- to be received during flushes. Yes, this is a bit hacky.)
            cyWorld:incorporateEntityInstantly(ent)
        end
        return ent
    end

    setupPckr(self, {
        cyWorld = self.cyWorld,
        shouldSerializeEntityById = truthy, -- always serialize by id clientside
        deserializeEntity = deserializeEntity,
    })
end




function Packer:init(deps)
    --[[
        Creates a new Packer instance
    ]]
    tools.assertKeys(deps, {"cyWorld"})
    tools.inlineMethods(self)
    self.cyWorld = deps.cyWorld
    
    if CLIENT_SIDE then
        setupPckrClient(self)
    else -- server:
        self.knownEntities = {--[[
            Whether an entity is known by the client or not.
            This determines whether we serialize by id or not
            [ent] -> true
        ]]}
        setupPckrServer(self)
    end
end

if false then
    ---@param deps {cyWorld:CyWorld}
    ---@return Packer
    function Packer(deps) end ---@diagnostic disable-line: cast-local-type, missing-return
end


---@param etype_name string
---@param etype table
function Packer:registerEntityType(etype_name, etype)
    --[[
        registers an entity type;
        (For BOTH volatile AND stable protocols)
    ]]
    self.pckr_stable:registerEntityType(etype_name, etype)
    self.pckr_volatile:registerEntityType(etype_name, etype)
end



function Packer:register(resource, alias)
    -- registers for BOTH volatile and stable impls
    self.pckr_stable:register(resource, alias)
    self.pckr_volatile:register(resource, alias)
end


function Packer:registerVolatile(resource, alias)
    --[[
        registers a resource, but only for pckr_volatile implementation.
        Useful for temporary, hacky
    ]]
    self.pckr_volatile:register(resource, alias)
end



function Packer:serializeStable(...)
    return self.pckr_stable:serialize(...)
end


function Packer:serializeVolatile(...)
    return self.pckr_volatile:serialize(...)
end


function Packer:serializeVolatileNoIdReferences(...)
    --[[
        serialize volatile, 
        WITHOUT serializing ents by id.

        TODO: This is really hacky and terrible!!!
        But at least its "local" hackyness.
    ]]
    local pckr_volatile = self.pckr_volatile
    local old_cb = pckr_volatile.shouldSerializeEntityById
    pckr_volatile.shouldSerializeEntityById = falsey
    local data = self:serializeVolatile(...)
    pckr_volatile.shouldSerializeEntityById = old_cb
    return data
end




function Packer:deserializeStable(data)
    return self.pckr_stable:deserialize(data)
end


function Packer:deserializeVolatile(data)
    return self.pckr_volatile:deserialize(data)
end



return Packer
