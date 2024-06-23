
--[[

ClientHandler:

only used SERVER_SIDE.
Handles peers/clientIds, and stuff like authentication.


]]

local ClientHandler = tools.SafeClass()


local connectJson = require("src.common.connection.connectJson")

assert(SERVER_SIDE, "?")



-- Enums
-- These enums represent peer state
local AUTHENTICATED = 1 -- Client is authenticated; has username and steam-id
local READY = 2 -- Is ready to go

local setup



function ClientHandler:init(args)
    tools.assertKeys(args, {"serverConnection", "eventBus"})
    tools.inlineMethods(self)

    self.connection = args.serverConnection
    self.eventBus = args.eventBus

    --[[
    We also need a map: clientId <--> enet-peer.
    However, we may want to use other types of identifiers in the future.
        (ie. if we switch to steam sockets; we won't use enet-peers.)
    For this reason, we use it "identifiers"; for future-compat.
    ]]
    self.clientToIdentifier = {--[[
        [clientId] --> identifierObj
    ]]}
    self.identifierToClient = {--[[
        [identifierObj] --> clientId
    ]]}

    self.clientToStatus = {--[[
        [clientId] -> status
    ]]}

    setup(self)
end


function ClientHandler:disconnectClient(identifier)
    local clientId = self.identifierToClient[identifier]
    if clientId then
        self.clientToIdentifier[clientId] = nil
        self.identifierToClient[identifier] = nil
    end
end


function ClientHandler:getClientId(identifier)
    return self.identifierToClient[identifier]
end
function ClientHandler:getIdentifier(clientId)
    return self.clientToIdentifier[clientId]
end



function ClientHandler:iter()
    return pairs(self.clientToIdentifier)
end




function ClientHandler:isReady(clientId)
    return self.clientToStatus[clientId] == READY
end

function ClientHandler:isAuthenticated(clientId)
    return self.clientToStatus[clientId] >= AUTHENTICATED
end









function ClientHandler:tryAuthenticateClient(identifier, jsonData)
    local cJson = connectJson.tryDeserialize(jsonData)
    if not cJson then 
        return false
    end

    --[[
        TODO: authenticate properly using steam API!!!!
            We should check the steamId (clientId),
            and we should check the auth key too; 
            should be passed in thru the connectJson table.
    ]]
    
    local clientId = cJson.clientId
    self.clientToIdentifier[clientId] = identifier
    self.identifierToClient[identifier] = clientId

    self.connection:addClient(clientId, cJson.username)

    self.clientToStatus[clientId] = AUTHENTICATED
    return true
end



function setup(self)
    self.connection:on("@ready_to_play", function(clientId)
        self.clientToStatus[clientId] = READY
        self.eventBus:call("@playerJoin", clientId)
    end)

end




return ClientHandler

