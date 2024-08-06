

local CyWorld = tools.SafeClass()


local path = (...):gsub("%.CyWorld", "")

local newEntityManager = require(path..".entities.EntityManager")
local newGroupManager = require(path..".groups.GroupManager")



function CyWorld:init(deps)
    tools.assertKeys(deps, {"eventBus"})
    tools.inlineMethods(self)

    local groupManager = newGroupManager()
    local entityManager = newEntityManager({
        groupManager = groupManager,
        eventBus = deps.eventBus
    })

    self.entityManager = entityManager
    self.groupManager = groupManager
end



function CyWorld:clear()
    -- Clears all entities
    self:flush()
    local all = self.groupManager.all.view
    local ent
    for i=1, all:size() do
        ent = all[i]
        ent:delete()        
    end
    self:flush() -- flush to ensure entities are gone
    self.groupManager:clear()
end



function CyWorld:exists(ent)
    -- Returns `true` if an entity exists, false otherwise
    return self.entityManager:isEntity(ent) and (not ent:isDeleted())
end

function CyWorld:isEntity(x)
    return self.entityManager:isEntity(x)
end





function CyWorld:flush()
    -- flushes entity deletion/creation, and component additions/removals.
    self.entityManager:flush()
end





function CyWorld:newEntityType(typename, tabl) -- Creates a new entity type
    local etype = self.entityManager:newEntityType(typename, tabl)
    assert(etype.___ent_mt)
    return etype
end





function CyWorld:group(...) -- gets an entity group
    return self.groupManager:newGroup(...)
end



function CyWorld:getEntity(id)
    local ent = self.entityManager:getEntity(id)
    if not ent then
        return nil, "Entity id did not exist"
    end
    return ent
end




local function isInGroups(self, ent)
    return self.groupManager.all:has(ent)
end

function CyWorld:incorporateEntity(ent)
    --[[
        incorporates an existing entity into the CyWorld.
        The entity will already have it's metatable set.

        Useful for when we are deserializing entities,
        (or if we ever moved entities between cyWorlds)
    ]]
    if isInGroups(self, ent) then
        return -- already exists within the CyWorld
    end
    return self.entityManager:incorporateEntity(ent)
end



function CyWorld:incorporateEntityInstantly(ent)
    --[[
        same as incorporateInstantly, but without buffering
    ]]
    if isInGroups(self, ent) then
        return -- already exists within the CyWorld
    end
    return self.entityManager:incorporateEntityInstantly(ent)
end




function CyWorld:setCallbacks(tabl)
    --[[
        Sets callbacks for cy context
    ]]
    if tabl.deleteEntityCallback then error("nyi") end

    self.entityManager:setCallbacks(tabl)
end





return CyWorld

