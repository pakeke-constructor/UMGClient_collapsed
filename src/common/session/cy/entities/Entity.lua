

local Entity = {}
--[[

QUESTION: Why is `Entity` not a class?

A: Because the methods are copied into each entity-type.
In UMG, different entity-types have different metatables.

See the entity-manager for now this is done.

]]




function Entity.type(ent)
    return ent.___type.___typename
end


function Entity.deleteInstantly(ent)
    --[[
        deletes an entity instantly, without care for buffering.
        WARNING: This is quite dangerous to call!
    ]]
    ent.___type.___entityManager:deleteInstantly(ent)
end





local function exists(ent, ctx)
    return ctx.groupManager:exists(ent)
end



local function should_recurse_into(obj, ctx)
    if type(obj) ~= "table" then
        return false -- dont recurse into non tables
    end
    if ctx.seen[obj] then
        return false -- we have already seen the object, dont recurse
    end
    if ctx.groupManager:isGroup(obj) then
        return false -- it's a group, dont recurse
    end

    return true
end

local function deep_delete(obj, ctx)
    ctx.seen[obj] = true
    if type(obj) == "table" then
        for k,v in pairs(obj) do
            -- delete all the key values
            if should_recurse_into(v, ctx) then
                deep_delete(v, ctx)
            end
            if should_recurse_into(k, ctx) then
                deep_delete(k, ctx)
            end
        end
    end
    if exists(obj, ctx) then
        -- it's an entity!
        obj:delete(ctx)
    end
end



local function newRecurseContext(ent)
    return {
        seen = {[ent] = true},
        groupManager = ent.___type.___groupManager
    }
end


local function assertOwned(ent)
    if not ent:isOwned() then
        error("Attempt to delete a serverside entity on clientside: " .. tostring(ent), 3)
    end
end


function Entity.shallowDelete(ent)
    assertOwned(ent)
    -- deletes an entity through buffering (recommended)
    ent.___type.___entityManager:deleteBuffered(ent)
end



function Entity.delete(ent, ctx)
    assertOwned(ent)
    -- deletes an entity, and also deletes all entities inside of `ent`
    ctx = ctx or newRecurseContext(ent)
    for _,v in ent:components() do
        if should_recurse_into(v, ctx) then
            deep_delete(v, ctx)
        end
    end
    ent:shallowDelete()
end


local DONT_CLONE = {
    id = true -- dont clone ent.id
}

function Entity.shallowClone(ent)
    assertOwned(ent)
    -- shallow clones an entity
    local components = {}
    for k,v in ent:components() do
        if not DONT_CLONE[k] then
            components[k] = v
        end
    end
    local eType = ent:getEntityType()
    local entityManager = eType.___entityManager 
    local newEnt = eType:entityFromData(components)
    entityManager:incorporateEntity(newEnt)
    return newEnt
end


local function deep_clone(x, ctx)
    local seen = ctx.seen
    if seen[x] then
        return seen[x]
    end
    if should_recurse_into(x, ctx) then
        if exists(x, ctx) then
            -- its an entity
            return x:clone(ctx)
        else
            -- its a table or some other object
            local new_x = {}
            seen[x] = new_x
            for k,v in pairs(x) do
                new_x[deep_clone(k, ctx)] = deep_clone(v, ctx)
            end
            setmetatable(new_x, getmetatable(x))
            return new_x
        end
    end
    if type(x) == "userdata" and type(x.clone) == "function" then
        -- probably is a love2d object
        local cloned = x:clone()
        seen[x] = cloned
        return cloned
    end
    -- else, it's probably just POD
    return x
end


function Entity.clone(ent, ctx)
    assertOwned(ent)
    -- deep clones an entity
    ctx = ctx or newRecurseContext(ent)
    local seen = ctx.seen
    local eType = ent:getEntityType()
    local entityManager = eType.___entityManager 
    local newEnt = eType:entityFromData({})

    -- `ctx.seen` NEEDS a reference to the cloned entity
    -- BEFORE we clone any components:
    seen[ent] = newEnt
    -- this is because some components may be self-referencing.

    for k, v in ent:components() do
        if not DONT_CLONE[k] then
            -- rawset is OK since newEnt is being incorporated anyway
            newEnt:rawsetComponent(k, deep_clone(v, ctx))
        end
    end
    entityManager:incorporateEntity(newEnt)
    return newEnt
end


function Entity.removeComponent(ent, comp_name)
    if ent:hasComponent(comp_name) then
        local etype = ent.___type
        etype.___entityManager:removeComponentBuffered(ent, comp_name)
    else
        log.trace("ent has no comp:", comp_name)
    end
end



function Entity.printComponents(ent)
    local typename = ent:type()
    local start = "[" .. tostring(typename) .. "] {"
    local keys = "\n"
    for key, value in ent:components() do
        keys = keys .. "   " .. key .. " = " .. tostring(value) .. "\n"
    end
    return start .. keys .. "}"
end





if constants.AGGRESSIVE_DEBUG then
    function Entity.rawsetComponent(ent, comp, value)
        rawset(ent.___debugproxy, comp, value)
    end
else
    -- In normal mode, setting a component is just rawset :)
    Entity.rawsetComponent = rawset
end

local rawsetComponent = Entity.rawsetComponent


function Entity.addComponent(ent, comp, value)
    value = value or false -- components can't be nil
    rawsetComponent(ent, comp, value)
    ent.___type.___entityManager:addComponentBuffered(ent, comp, value)
end



function Entity.addComponentInstantly(ent, comp_name, comp_value)
    --[[
        adds a component to an entity, and INSTANTLY
        adds the entity to all worthy groups.
    ]]
    rawsetComponent(ent, comp_name, comp_value)
    ent.___type.___groupManager:addComponentInstantly(ent, comp_name)
end


function Entity.removeComponentInstantly(ent, comp_name)
    --[[
        removes a component to an entity, and INSTANTLY
        removes the entity from all worthy groups.
    ]]
    rawsetComponent(ent, comp_name, nil)
    ent.___type.___groupManager:removeComponentInstantly(ent, comp_name)
end





if constants.AGGRESSIVE_DEBUG then
    function Entity.components(ent)
        return pairs(ent.___debugproxy)
    end
else
    function Entity.components(ent)
        return pairs(ent)
    end
end


function Entity.getComponent(ent, comp)
    return ent[comp]
end


function Entity.hasComponent(ent, comp)
    return ent[comp] ~= nil
end

function Entity.isSharedComponent(ent, comp)
    return ent.___type.___shared_to_bool[comp]
end

function Entity.isRegularComponent(ent, comp)
    return ent[comp] ~= nil
end



if SERVER_SIDE then
    function Entity.isOwned()
        -- entities are ALWAYS owned on the server;
        -- since UMG operates in a server-authoritative fashion
        return true
    end
else
    function Entity.isOwned(ent)
        -- entities are ALWAYS owned on the server;
        -- since UMG operates in a server-authoritative fashion
        return ent.___clientside
    end
end



function Entity.isClientSide(ent)
    return ent.___clientside
end


function Entity.getEntityType(ent)
    return ent.___type
end


function Entity.isDeleted(ent)
    return ent.___deleted
end


return Entity

