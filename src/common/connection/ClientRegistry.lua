

--[[


Keeps track of what clients exist,
and stores info relative to each client on a server.


]]


local ClientRegistry = tools.SafeClass()


function ClientRegistry:init()
    self.clientIds = tools.Set()

    self.clientToInfo = {--[[
        [clientId] -> {
            id = clientId,
            username = username
        }
    ]]}
end





local strTc = tc.assert("string", "string")

function ClientRegistry:registerClient(clientId, username)
    strTc(clientId, username)
    assert(not self.clientToInfo[clientId], "Duplicate clientId")

    --[[
        TODO: parse username and check valid
        such as ensuring that there are no duplicate usernames
    ]]

    self.clientToInfo[clientId] = {
        clientId = clientId,
        username = username
    }

    self.clientIds:add(clientId)
end



function ClientRegistry:removeClient(clientId)
    self.clientToInfo[clientId] = nil
    self.clientIds:remove(clientId)
end



function ClientRegistry:getClientInfo(clientId)
    return self.clientToInfo[clientId]
end


function ClientRegistry:iter()
    return ipairs(self.clientIds)
end


return ClientRegistry

