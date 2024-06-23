

local IdManager = tools.SafeClass()


function IdManager:init()
    -- The highest/lowest entity ids in use:
    self.highestId = 0 -- (The first ent id will be 1)
    self.lowestId = 0 -- (clientSide ids are negative. first id will be -1)

    self.id_to_ent = {--[[
        [id] -> entity
    ]]}
    self.idBuffer = tools.Array() -- a buffer of available ent ids
    self.clientIdBuffer = tools.Array() -- a buffer of reusable ent ids
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
    local ids 
    if clientEnt then
        ids = self.clientIdBuffer
    else
        ids = self.idBuffer
    end

    if ids:size() > 0 then
        return ids:pop()
    end

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
    self.id_to_ent[ent.id] = ent
end



function IdManager:recycleId(ent)
    --[[
        restores an id to the buffer, for reuse
    ]]
    local id = ent.id
    if ent:isClientSide() then
        self.clientIdBuffer:add(id)
    else
        self.idBuffer:add(id)
    end
    self.id_to_ent[id] = nil
end



return IdManager

