
local path = tools.path(...)

local QuestionBus = require(path..".buses.QuestionBus.QuestionBus")
local EventBus = require(path..".buses.EventBus.EventBus")

local CyWorld = require("src.common.session.cy.cy").World


local Packer = require(path .. ".Packer.Packer")



local UMGSession = tools.SafeClass()





function UMGSession:init()
    self.eventBus = EventBus()
    self.questionBus = QuestionBus()

    self.cyWorld = CyWorld({
        eventBus = self.eventBus
    })

    self.packer = Packer({
        cyWorld = self.cyWorld
    })
end



function UMGSession:serializeWorld()
    self.cyWorld:flush()
    local allGroup = self.cyWorld:group()
    local cpy = {}
    for _, ent in ipairs(allGroup) do
        table.insert(cpy, ent)
    end
    return self.packer:serializeVolatileNoIdReferences(cpy)
end


function UMGSession:deserializeWorld(data)
    self.cyWorld:flush()
    local ok, err = self.packer:deserializeVolatile(data)
    if (not ok) and err then
        log.error("Unable to deserialize world: ", err)
    end
    self.cyWorld:flush()
end





function UMGSession:saveWorld()
    -- TODO
end

function UMGSession:loadWorld()
    -- TODO
end





function UMGSession:group(...)
    local group = self.cyWorld:group(...)
    
    local alias = tostring(group) -- 
    self.packer:register(group, alias)
    return group
end



function UMGSession:newEntityType(typename, tabl)
    -- we call @newEntityType with the table BEFORE we define with cy.
    -- (This allows systems to mutate the definition before its registered.)
    self.eventBus:call("@newEntityType", tabl, typename)

    local etype = self.cyWorld:newEntityType(typename, tabl)

    self.packer:registerEntityType(typename, etype)

    return etype
end



function UMGSession:tick(dt)
    self.eventBus:call("@tick", dt)
end



function UMGSession:flush()
    self.cyWorld:flush()
end


function UMGSession:update(dt)
    self.eventBus:call("@update", dt)
end





return UMGSession

