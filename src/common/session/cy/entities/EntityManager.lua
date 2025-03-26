

local path = (...):gsub("%.EntityManager", "")

local Entity = require(path..".Entity")
local IdManager = require(path .. ".IdManager")

local path2 = (...):gsub("%.entities%.EntityManager", "")
local Bufferer = require(path2 .. ".Bufferer")


local EntityManager = tools.SafeClass()


function EntityManager:init(deps)
    tools.assertKeys(deps, {"groupManager", "eventBus"})
    tools.inlineMethods(self)

    self.groupManager = deps.groupManager
    self.eventBus = deps.eventBus

    self.addComponentCallback = false
    self.removeComponentCallback = false
    self.createEntityCallback = false
    self.deleteEntityCallback = false

    self.validEntityMetatables = {--[[
        [metatable] -> true
        Used to check whether something is an entity or not
    ]]}

    self.componentBuffers = {--[[
        [component] -> Bufferer()

        Instead of removing a component instantly, we buffer the entity,
        and then remove it's component.
        This is because some entities may still require 
        the component whilst it's inside of groups.
    ]]}

    -- buffer for entity deletion/creation
    self.existanceBuffer = Bufferer()

    -- Entity ids:
    ------
    self.idManager = IdManager()
end



function EntityManager:isEntity(x)
    if type(x) ~= "table" then
        return nil
    end
    local meta = getmetatable(x)
    return self.validEntityMetatables[meta]
end



local assert = assert


local function ent_tostring(ent)
    return string.format("<ent: %s id=%s>", ent:type(), tostring(ent.id))
end





function EntityManager:deleteInstantly(ent)
    --[[
        instantly deletes an entity, with no buffering

        TODO: This is inefficient because it loops over all groups.
        In the future, we should do an optimization with ent archetypes
    ]]
    local all_groups = self.groupManager:get_all_groups()
    for i=1, #all_groups do
        local g = all_groups[i]
        g:_remove(ent)
    end
    if self.deleteEntityCallback then
        self.deleteEntityCallback(ent, true)
    end
    ent.___deleted = true
end


function EntityManager:deleteBuffered(ent)
    --[[
        Buffers an entity for deletion.
    ]]
    if not self.existanceBuffer:removeBuffered(ent) then
        if self.deleteEntityCallback then
            self.deleteEntityCallback(ent, false)
        end
    end
end





local function newEntity(etype, ...)
    --[[
        used for creating new entities
    ]]
    local self = etype.___entityManager

    local ent = etype:entityFromData({})
    if CLIENT_SIDE then
        ent.___clientside = true
    end

    -- assign the ent's id BEFORE we call `init`s,
    -- so that init-functions can know the id, and send packets with ent.
    self.idManager:assignId(ent)

    self.eventBus:call("@entityInit", ent, ...)
    if ent.init then
        ent:init(...)
    end

    -- incorporate AFTER init; because init may have added components.
    self:incorporateEntity(ent)
    return ent
end





function EntityManager:incorporateEntity(ent)
    --[[
        `ent` is an entity that has everything set-up,
        it just doesn't exist in groups or anything yet,
        and it doesn't have an id.

        This function incorporates `ent` into the ecs world.
        (Used for sending new entities across the network.)
        (Also used for cloning.)
    ]]
    if self.createEntityCallback then
        self.createEntityCallback(ent)
    end
    self.idManager:assignId(ent)
    self.existanceBuffer:addBuffered(ent)

    return ent
end



function EntityManager:incorporateEntityInstantly(ent)
    --[[
        previously named:  
        `instant_new_ent_fromtable`
    ]]
    --[[
        Same as incorporateInstantly, but without buffering.
        
        this needs to be done on the client instantly,
        because if we wait for the cy.flush, we may miss important events.

        Example: 
        Lets say we are sending `setInventoryItem` over from server -> client.
        This event references an entity.
        If the client buffers the entity this event will be discarded;
        since invalid data was sent over.
        thus, we must avoid buffering on clientside when creating entities.
    ]]
    -- assign id BEFORE we add to groups
    self.idManager:assignId(ent)

    -- add to known groups: (shared components)
    local etype = ent.___type
    for _, group in ipairs(etype.___groups) do
        group:_add(ent)
    end
    -- add regular components:
    for comp_name, comp_value in ent:components() do
        ent:addComponentInstantly(comp_name, comp_value)
    end
end




local EntityType = {}
function EntityType:getTypename()
    return self.___typename
end

function EntityType:getEntityMetatable()
    return self.___ent_mt
end





function EntityType.entityFromData(etype, components)
    --[[
        creates a new entity from an existing bag of components.
        components = {
            [compName] -> compValue
        }

        IMPORTANT NOTE:
        This does NOT add the entity to any systems or anything!!!
        It just creates an empty "shell".

        (ie, its likely that this entity is a clone, or a deserialized ent.)
    ]]
    if components.id then
        error("Cannot have `id` as a component!")
    end
    local ent
    if constants.AGGRESSIVE_DEBUG then
        ent = {
            ___type = etype,
            ___debugproxy = setmetatable(components, etype.___proxy_mt)
        }
        -- holy FUCK this is weird and hacky.
        -- basically, ent's debugproxy needs a ref to `ent` 
        -- so it can perform the appropriate tasks within the newindex fn.
        rawset(ent.___debugproxy, "___ent", ent)
    else
        ent = components
    end

    setmetatable(ent, etype.___ent_mt)
    return ent
end




local Etype_mt = {
    __index = EntityType
}



local function etype_tostring(etype)
    return "<entityType: " .. tostring(etype:getTypename()) .. ">"
end



local function createDebugProxyMt(self, etype)
    local ent_mt = {
        __index = function(ent, compName)
            if Entity[compName] then
                -- Not a component; a method!
                return Entity[compName]
            end
            if compName == "___type" then
                return etype
            end
            self.eventBus:call("@debugComponentAccess", ent, compName)
            return ent.___debugproxy[compName]
        end,

        __newindex = function(ent, compName, compValue)
            self.eventBus:call("@debugComponentChange", ent, compName, compValue)
            ent.___debugproxy[compName] = compValue
        end,

        __tostring = ent_tostring;
    }
    return ent_mt
end



-- creates new etype  
function EntityManager:newEntityType(typename, tabl)
    assert(type(tabl) == "table", "etype should be table")
    assert(type(typename) == "string", "each entity needs a typename")

    local shared_to_bool = {}

    local parent = {}
    for key, value in pairs(tabl) do 
        -- Don't care about JIT breaking; 
        -- this is only for entity type initialization.
        if type(key)~="string" then
            error("Bad entity definition: " .. typename .. "\nComponent names must be strings. Got: " .. tostring(key))
        end
        if key == "id" then
            error(("Error with entity %s:\nEntities cannot have a .id member!"):format(typename))
        end
        if EntityType[key] then
            error(("Invalid shared component name %s for entity %s.\nThis name is reserved for internal use."):format(key, typename))
        end

        shared_to_bool[key] = true
        parent[key] = value
    end

    -- clone all Entity methods into our new EntityType:
    -- (This is slightly better than __index)
    for name, func in pairs(Entity) do
        parent[name] = func
    end

    local ent_mt = {
        __index = parent;
        __newindex = Entity.addComponent;
        __tostring = ent_tostring;
    }

    local etype = {
        ___ent_mt = ent_mt,
        ___typename = typename,
        ___shared_to_bool = shared_to_bool,
        ___groups = self.groupManager:get_worthy_groups(tabl),
        ___entityManager = self,
        ___groupManager = self.groupManager,
    }

    parent.___type = etype

    if constants.AGGRESSIVE_DEBUG then
        --  Proxying: debug mode only.
        -- proxy_mt will be the metatable of the entity proxy: ent.___debugproxy
        etype.___proxy_mt = {
            __index = parent;
            __newindex = function(debugproxy, comp, val)
                local ent = debugproxy.___ent
                ent:addComponent(comp, val)
            end
        }
        -- this will be the metatable of the entity itself.
        etype.___ent_mt = createDebugProxyMt(self, etype)
    end

    self.validEntityMetatables[etype.___ent_mt] = true

    local etype_mt = {
        __index = setmetatable(tabl, Etype_mt);
        __call = newEntity;
        __tostring = etype_tostring
    }

    return setmetatable(etype, etype_mt)
end



function EntityManager:getEntity(id)
    return self.idManager:get(id)
end


local function getCompBuffer(self, compName)
    local compBuf = self.componentBuffers[compName]
    if not compBuf then
        compBuf = Bufferer()
        self.componentBuffers[compName] = compBuf
    end
    return compBuf
end


function EntityManager:removeComponentBuffered(ent, compName)
    local compBuf = getCompBuffer(self, compName)
    compBuf:removeBuffered(ent)
end

function EntityManager:addComponentBuffered(ent, compName)
    local compBuf = getCompBuffer(self, compName)
    compBuf:addBuffered(ent)
end




function EntityManager:setCallbacks(tabl)
    self.addComponentCallback = tabl.addComponentCallback or self.addComponentCallback
    self.removeComponentCallback = tabl.removeComponentCallback or self.removeComponentCallback
    self.createEntityCallback = tabl.createEntityCallback or self.createEntityCallback
    self.deleteEntityCallback = tabl.deleteEntityCallback or self.deleteEntityCallback
end



local function addComponent(self, ent, compName)
    if self.addComponentCallback then
        self.addComponentCallback(ent, compName)
    end
    self.groupManager:addComponentInstantly(ent, compName)
end


local function removeComponent(self, ent, compName)
    if self.removeComponentCallback then
        self.removeComponentCallback(ent, compName)
    end
    if constants.AGGRESSIVE_DEBUG then
        rawset(ent.___debugproxy, compName, nil)
    else
        rawset(ent, compName, nil)
    end
    self.groupManager:removeComponentInstantly(ent, compName)
end




local function flushComponentBuffer(self, compName, buffer)
    for _, ent in ipairs(buffer.addBuffer) do
        addComponent(self, ent, compName)
    end
    for _, ent in ipairs(buffer.remBuffer) do
        removeComponent(self, ent, compName)
    end
    buffer:clear()
end



local function flushComponentChanges(self)
    local compBuffers = self.componentBuffers
    for compName, buffer in pairs(compBuffers) do
        flushComponentBuffer(self, compName, buffer)
    end
end





local function flushExistanceChanges(self)
    local existanceBuffer = self.existanceBuffer

    -- we remove first, since its probably slightly more efficient
    for _, ent in ipairs(existanceBuffer.remBuffer) do
        self:deleteInstantly(ent)
    end

    for _, ent in ipairs(existanceBuffer.addBuffer) do
        self:incorporateEntityInstantly(ent)
    end

    existanceBuffer:clear()
end



function EntityManager:flush()
    flushComponentChanges(self)
    flushExistanceChanges(self)
end




return EntityManager
