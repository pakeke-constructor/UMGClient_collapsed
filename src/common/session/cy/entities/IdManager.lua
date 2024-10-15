

local IdManager = tools.SafeClass()

local START_ID = 60000
--[[
the reason we start with a high-id, is because we DONT want to invoke the array-part
of our lua table; or else, the table will keep growing forever, and it will suck.
(ie there will be 10s of thousands of wasteful nil-elements scattered within the array;
permanent memory leak as the program goes on.)

If we start with a big number, ie 60000, it will invoke the hashtable part;
and we wont need to worry about creating an infinitely-large array.

QUESTION: What if we run out of ids?
ANSWER: We wont. Ent ids aren't serialized stable, and we have 53 bits of integer precision.
]]

function IdManager:init()
    -- The highest/lowest entity ids in use:
    self.highestId = START_ID -- (The first ent id will be 1)
    self.lowestId = -START_ID -- (clientSide ids are negative. first id will be -1)

    self.id_to_ent = {--[[
        [id] -> entity
    ]]}
end





function IdManager:get(id)
    return self.id_to_ent[id]
end



local function updateIdBounds(self, id)
    --[[
        updates the highest id / lowest id.
    ]]
    id = id or 0
    if id < 0 then
        self.lowestId = math.min(self.lowestId, id)
    else
        self.highestId = math.max(self.highestId, id)
    end
end



local function generateId(self, ent)
    --[[
        gets a new id for `ent`.
        Attempts to pull from the existing pool; 
        but will create a new id if possible.
    ]]
    local clientEnt = ent:isClientSide()

    if not clientEnt then
        self.highestId = self.highestId + 1
        return self.highestId
    else
        self.lowestId = self.lowestId - 1
        return self.lowestId
    end
end



function IdManager:assignId(ent)
    -- assigns an id to an entity if it doesn't have one.
    -- (If it already has one, updates id bounds)
    if not ent.id then
        ent.id = generateId(self, ent)
    else
        updateIdBounds(self, ent.id)
    end
    local idEnt = self.id_to_ent[ent.id]
    assert(idEnt == ent or (not idEnt), "Overwriting pre-existing entity?")
    self.id_to_ent[ent.id] = ent
end




return IdManager

