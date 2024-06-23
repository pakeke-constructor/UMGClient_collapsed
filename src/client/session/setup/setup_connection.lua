

--[[

Sets up some packet receivers.

This is kinda a weird file... but oh well lol!

]]

local function setup(ingameSession)
    local clientConnection = ingameSession.clientConnection
    local eventBus = ingameSession.umgSession.eventBus

    clientConnection:on("@tick", function(dt)
        -- Clientside tick rate should mimic that of the server's
        ingameSession:tick(dt)
    end)

    clientConnection:on("@define_packet_id", function(packetId, packetName)
        clientConnection.boxer:definePacket(packetId, packetName)
    end)

    clientConnection:on("@client_join", function(clientId, jsonData)
        local ok, jsonTable = pcall(json.decode, jsonData)
        if not ok then
            log.error("what the fuck? ", jsonTable)
            return
        end
        clientConnection:addClient(clientId, jsonTable.username)
        eventBus:call("@playerJoin", clientId)
    end)

    clientConnection:on("@client_leave", function(clientId)
        eventBus:call("@playerLeave", clientId)
        clientConnection:removeClient(clientId)
    end)
end


return setup

