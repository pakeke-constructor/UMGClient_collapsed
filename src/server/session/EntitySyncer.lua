


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

    allGroup:onAdded(function(ent)
        table.insert(createEntityBuffer, ent)
    end)

    allGroup:onRemoved(function(ent)
        deleteEntity(self, ent)
    end)
end




function EntitySyncer:sendSpawnEntities()
    local packer = self.packer
    if #self.createEntityBuffer <= 0 then
        -- nothing in the creation-buffer!
        return
    end

    local entData = packer:serializeVolatile(self.createEntityBuffer)
    self.serverConnection:broadcast(false, "@spawn_entities", entData)
    for _, ent in ipairs(self.createEntityBuffer) do
        log.debug("entity-spawn: ", tostring(ent))
        packer:makeEntityKnown(ent)
    end
    
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

    self.cyWorld:setCallbacks({
        addComponentCallback = addComponent,
        removeComponentCallback = removeComponent,

        deleteEntityCallback = function(ent)
            deleteEntity(self, ent)
        end
    })
end


return EntitySyncer

