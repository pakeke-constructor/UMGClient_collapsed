
local Packer = require("src.common.session.Packer.Packer")

local EntitySyncer = tools.SafeClass()


local setupAllGroup
local setupCallbacks


function EntitySyncer:init(args)
    tools.assertKeys(args,{"serverSession"})
    tools.inlineMethods(self)

    local serverSession = args.serverSession
    local umgSession = serverSession.umgSession
    local cyWorld = umgSession.cyWorld
    
    self.cyWorld = cyWorld
    self.packer = umgSession.packer
    self.serverConnection = serverSession.serverConnection
    self.createEntityBuffer = {}

    setupAllGroup(self)
    setupCallbacks(self)
end



local function deleteEntity(self, ent)
    if self.packer:isEntityKnown(ent) then
        self.serverConnection:broadcast(false, "@ent_delete", ent)
        -- Note: Make sure to removeKnownEntity AFTER call above.
        -- Otherwise, the setSerializeEntityForNetworkCallback callback
        -- below will try to re-mark the deleted entity as ENTITY_SENT_TO_NETWORK
        -- resulting in feedback loop.
        self.packer:removeKnownEntity(ent)
    end
end



function setupAllGroup(self)
    local createEntityBuffer = self.createEntityBuffer
    --[[
        The reason we need buffering, is because we need to ensure that
        ALL entities have been initialized (ie. added to groups) before sending them over.

        If ent1 owns ent2, and ent1 is added to allGroup before ent2,
        then ent2 would be sent over without being initialized.
            This ^^^ is why we need buffering.
    ]]
    local allGroup = self.cyWorld:group()
    local packer = self.packer

    allGroup:onAdded(function(ent)
        if packer:getEntityKnownState(ent) == Packer.ENTITY_SENT_TO_NETWORK then
            -- Already sent, no need to send it again.
            packer:makeEntityKnown(ent, Packer.ENTITY_INCORPORATED)
        else
            -- Send to create buffer
            table.insert(createEntityBuffer, ent)
        end
    end)

    allGroup:onRemoved(function(ent)
        deleteEntity(self, ent)
    end)
end




local function sendEntities(self, ents, markState)
    local packer = self.packer
    local entData = packer:serializeVolatile(ents)
    self.serverConnection:broadcast(false, "@spawn_entities", entData)
    for _, ent in ipairs(ents) do
        log.debug("entity-spawn: ", tostring(ent))
        self.packer:makeEntityKnown(ent, markState)
    end
end

function EntitySyncer:sendSpawnEntities()
    if #self.createEntityBuffer <= 0 then
        -- nothing in the creation-buffer!
        return
    end

    sendEntities(self, self.createEntityBuffer, Packer.ENTITY_INCORPORATED)
    table.clear(self.createEntityBuffer)
end



function setupCallbacks(self)
    local packer = self.packer
    local serverConnection = self.serverConnection

    local function addComponent(ent, compName)
        if not packer:isEntityKnown(ent) then
            -- no need to sync the change, since the entity isn't know about.
            return -- (the sync will be sent over in the future anyway)
        end
        if compName == "id" then
            return -- don't sync id.
        end

        local compVal = ent[compName]
        log.trace("add component: ", tostring(ent), compName, compVal)
        local data = packer:serializeVolatile(compVal)
        serverConnection:broadcast(false, "@ent_add_component", ent, compName, data)
    end

    local function removeComponent(ent, compName)
        if not packer:isEntityKnown(ent) then
            return -- no need to sync. Same as above.
        end
        log.trace("remove component: ", tostring(ent), compName)
        serverConnection:broadcast(false, "@ent_remove_component", ent, compName)
    end

    local function entityDeleted(ent)
        return deleteEntity(self, ent)
    end

    self.cyWorld:setCallbacks({
        addComponentCallback = addComponent,
        removeComponentCallback = removeComponent,
        deleteEntityCallback = entityDeleted -- Note: May be called twice if the entity is incorporated.
    })
    self.packer:setSerializeEntityForNetworkCallback(function(ent)
        -- Force send @spawn_entities with 1 member: the entity
        -- Why force send? Because a mod tries to send it through a packet.
        sendEntities(self, {ent}, Packer.ENTITY_SENT_TO_NETWORK)
    end)
end


return EntitySyncer

