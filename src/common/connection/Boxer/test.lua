
local inspect = require("libs.nm_inspect.inspect")

local path = tools.path(...)

local Boxer = require(path..".Boxer")






local function equals(a,b)
    --[[
        recursive equals checker
    ]]
    if (a == b) then
        return true
    end

    if (type(a) == "table") then
        return table.deep_equal(a,b)
    end
    return false
end





local function checkBoxes(boxer, packets)
    local writer = boxer:newWriter()

    for _, box in ipairs(packets) do
        writer:write(unpack(box))
    end
    local data = writer:flush()

    local reader = boxer:newReader(data)

    for _, box in ipairs(packets) do
        local result = {reader:read()}
        local ok = equals(result, box)
        if not ok then
            log.error("EXPECTED: ", inspect(box))
            log.error("GOT:      ", inspect(result))
            error("disparity in boxer test!")
        end
    end
end



local NUM_ENTS = 10

local function isClientSide()
    return false
end

local function mockBoxer()
    -- make a bunch of mock entities:
    local entities = tools.Array()
    local id_to_ent = {}
    local ent_to_id = {}
    for id=1, NUM_ENTS do
        local ent = {id=id}
        ent.isClientSide = isClientSide
        entities:add(ent)
        id_to_ent[id] = ent
        ent_to_id[ent] = id
    end

    local mockCyWorld = {}
    function mockCyWorld:getEntity(id)
        return id_to_ent[id]
    end
    function mockCyWorld:exists(x)
        return type(x) == "table" and x.id
    end

    local mockPacker = {}
    function mockPacker:serializeVolatile(...)
        return json.encode({...})
    end
    function mockPacker:deserializeVolatile(data)
        return unpack(json.decode(data))
    end
    function mockPacker:isEntityKnown(ent)
        -- serialize half of entities by id, half not.
        return ent.id % 2 == 0
    end

    local boxer = Boxer({
        packer = mockPacker,
        cyWorld = mockCyWorld,
        broadcastOutgoingPacketId = tools.nullFunction
    })

    return boxer, entities
end








--[[
===================================================
    Boxer tests!
===================================================
]]

do
-- Basic packet tests:
local packets = {
    {"@kick_player"},
    {"@box_version", 32},
}
checkBoxes(mockBoxer(), packets)
end



-- More complex packet tests:
do
local boxer, entities = mockBoxer()
local e = entities[1]
local packets2 = {
    {"@kick_player"},
    {"@box_version", 32},
    {"@tick"},
    {"@ent_add_component", e, "abc", "03340fdf"},
    {"@ent_add_component", e, "abc", "03340fdf"},
    {"@kick_player"},
    {"@ent_add_component", e, "abc", "03340fdf"},
    {"@box_version", 32},
}
checkBoxes(mockBoxer(), packets2)
end






-- Entity ser test:
do
local boxer, entities = mockBoxer()
local e1,e2,e3 = entities[1], entities[2], entities[3]
assert(e1 and e2 and e3)
local packets3 = {
    {"@test_entity", e1,e2,e3},
    {"@test_entity", e1,e3,e2},
    {"@kick_player"},
    {"@test_entity", e1,e3,e2}
}
checkBoxes(boxer, packets3)
end






log.info("[BOXER]: All tests passed")
