

local function setup(serverSession)
    local serverConnection = serverSession.serverConnection
    local umgSession = serverSession.umgSession

    serverConnection:defineResponder("@gimme_world", {
        response = function(self, clientId)
            log.trace("Sending world data to client: ", clientId)
            local worlddata = umgSession:serializeWorld()
            self:unicast(clientId, false, "@world", worlddata)
        end,

        -- one response every 120 seconds, per clientId
        responsesPerSecond = 1/120;
    })
end


return setup

