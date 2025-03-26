

local cy = require("src.common.session.cy.cy")

local EventBus = require("src.common.session.buses.EventBus.EventBus")




local function makeBasicContext()
    -- sets up a basic cyWorld, with etypes and groups
    local world = cy.World({
        eventBus = EventBus()
    })

    local ctx = {
        world = world,
        groups = {},
        entityTypes = {}
    }

    -- define a bunch of test groups:
    local g = ctx.groups
    g.all = world:group()
    g.a = world:group("a")
    g.b = world:group("b")
    g.ab = world:group("a", "b")

    -- define a bunch of test entityTypes:
    local et = ctx.entityTypes
    et.a = world:newEntityType("a", {a = "a"})
    et.b = world:newEntityType("b", {b = "b"})
    et.ab = world:newEntityType("ab", {a = "a", b = "b"})
    return ctx
end




local function makeEntities(etype, count, func)
    --[[
        makes a bunch of entities for testing
    ]]
    for _=1, count do
        local e = etype()
        if func then
            func(e)
        end
    end
end



local function flush(ctx)
    ctx.world:flush()
end
























-- =============================================================
-- =============================================================
-- 
--  VVVVV Testing below VVVVV
--
-- =============================================================
-- =============================================================




do 
    -- All-group test
    local ctx = makeBasicContext()
    local NUM = 50
    makeEntities(ctx.entityTypes.a, NUM)

    assert(ctx.groups.all:size() == 0, "groups populated b4 flush")
    assert(#ctx.groups.all == 0)

    flush(ctx)

    assert(ctx.groups.all:size() == NUM, "entities not added to all group")
end




do
    -- Simple group test (1 component)
    local ctx = makeBasicContext()
    makeEntities(ctx.entityTypes.b, 15)
    assert(ctx.groups.all:size() == 0, "groups populated b4 flush")
    flush(ctx)
    assert(ctx.groups.b:size() == 15)
end





do
    -- Complex group test (more components)
    local ctx = makeBasicContext()
    makeEntities(ctx.entityTypes.a, 55)
    makeEntities(ctx.entityTypes.b, 45)
    makeEntities(ctx.entityTypes.ab, 35)
    assert(ctx.groups.all:size() == 0, "groups populated b4 flush")
    flush(ctx)
    assert(ctx.groups.a:size() == 55 + 35)
    assert(ctx.groups.b:size() == 45 + 35)
    assert(ctx.groups.ab:size() == 35)
    assert(ctx.groups.all:size() == 55+45+35)
end




do
    -- Deletion test
    local ctx = makeBasicContext()
    local NUM = 50
    makeEntities(ctx.entityTypes.a, NUM)
    flush(ctx)
    local group = ctx.groups.a
    local DEL = 16
    for i=1, DEL do
        local e = group[i]
        e:delete()
    end
    assert(group:size() == NUM)
    flush(ctx)
    assert(group:size() == NUM - DEL)
end




do
    -- Add component test
    local ctx = makeBasicContext()
    makeEntities(ctx.entityTypes.a, 15)
    flush(ctx)
    assert(ctx.groups.a:size() == 15)
    for _, e in ipairs(ctx.groups.a) do
        e.b = "foo"
    end
    flush(ctx)
    assert(ctx.groups.ab:size() == 15)
end




do
    -- Remove component test
    local ctx = makeBasicContext()
    makeEntities(ctx.entityTypes.a, 20, function(ent)
        ent.b = "b comp"
    end)
    flush(ctx)
    for _, e in ipairs(ctx.groups.ab) do
        e:removeComponent("b")
        assert(e.b, "component should onyl be removed after flush")
    end
    flush(ctx)
    assert(ctx.groups.ab:size() == 0)
end




do
    -- Basic entity functions test
    local ctx = makeBasicContext()
    makeEntities(ctx.entityTypes.ab, 1, function(ent)
        ent.reg = "value"
        ent._ephemeral = "hi"
        assert(ctx.world:exists(ent))
        assert(not ctx.groups.all:has(ent))
    end)
    flush(ctx)
    local ent = ctx.groups.all[1]
    assert(ent:hasComponent("a"))
    assert(ent:isRegularComponent("reg"))
    assert(ent:isSharedComponent("b"))
    assert(tostring(ent))
    assert(ctx.world:isEntity(ent))
    assert(ctx.world:exists(ent))
    ent:delete()
    flush(ctx)
    assert(not ctx.world:exists(ent))
    assert(ctx.world:isEntity(ent))
end




--[[

------------------------------
--- Ephemeral components test!!!
-----  (unused atm)
------------------------------

do
    -- Ephemeral components test
    -- (Tests that ephemeral components aren't cloned / deleted)
    local function checkEph(e, comp)
        return e:isEphemeralComponent(comp) and e:hasComponent(comp)
    end

    local ctx = makeBasicContext()
    makeEntities(ctx.entityTypes.ab, 1)
    flush(ctx)
    local reffedEnt = ctx.groups.all[1]
    makeEntities(ctx.entityTypes.a, 1, function(ent)
        ent._foo = reffedEnt
    end)
    flush(ctx)
    local ent = ctx.groups.all[2]
    assert(checkEph(ent, "_foo"))

    local e2 = ent:clone(); flush(ctx)
    assert(not checkEph(e2, "_foo"), "cloned entity had eph comp!!!")

    ent:delete(); flush(ctx)
    assert(ctx.world:exists(reffedEnt), "eph component deleted!")
end

]]



do
    -- EntityType tests:
    local ctx = makeBasicContext()
    makeEntities(ctx.entityTypes.ab, 1)
    flush(ctx)
    local ent = ctx.groups.all[1]
    local etype = ent:getEntityType()
    assert(getmetatable(ent) == etype:getEntityMetatable())
    assert(etype:getTypename())
end




log.info("[CY_TESTS]: All tests passed")
