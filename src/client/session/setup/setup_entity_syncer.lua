

--[[


Sets up the clientside EntitySyncer.

Receives events related to entity-syncing


]]



local function setupSpawnAndDelete(ingameSession)
    local clientConnection = ingameSession.clientConnection
    local packer = ingameSession.umgSession.packer

    clientConnection:on("@spawn_entities", function(entityPckrData)
        local t, err = packer:deserializeVolatile(entityPckrData)
        if constants.DEBUG then
            if (not t) then
                log.error("@spawn_entities: Couldn't deserialize: ", err)
            else
                for _, ent in ipairs(t)do
                    log.debug("entity-spawn: ", tostring(ent))
                end
            end
        end
    end)

    clientConnection:on("@ent_delete", function(ent)
        --[[
            we want to delete the entity INSTANTLY, to keep up with the server.
            We are "allowed" to do this, because `ent_spawn` events are polled
            inbetween frames, so deletion doesn't need to be buffered.
        ]]
        ent:deleteInstantly()
    end)
end



local function setupAddRemoveComponent(ingameSession)
    local umgSession = ingameSession.umgSession
    local clientConnection = ingameSession.clientConnection
    local packer = umgSession.packer

    clientConnection:on("@ent_add_component", function(ent, comp_name, comp_data)
        local comp_value, err = packer:deserializeVolatile(comp_data)
        if comp_value then
            log.trace("add-comp", ent, comp_name)
            ent:addComponentInstantly(comp_name, comp_value)
        elseif err then
            log.error("addComponent: bad data: comp, err", comp_name, err)
        end
    end)

    clientConnection:on("@ent_remove_component", function(ent, comp_name)
        log.trace("rem-comp", ent, comp_name)
        ent:removeComponentInstantly(comp_name)
    end)
end



local function setup(ingameSession)
    setupSpawnAndDelete(ingameSession)
    setupAddRemoveComponent(ingameSession)
end




return setup

