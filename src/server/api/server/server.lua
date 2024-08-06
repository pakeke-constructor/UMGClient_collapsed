
--[[

Server side only API

]]


local function loadServerAPI(lobj)
--[[
    (This function is not indented for readibility reasons)
]]

local server = {
    -- API Table, as used in mods
}




local serverConnection = serverSession.serverConnection


local onTc = tc.assert(tc.str, tc.func)
---
-- Listens to messages from all clients.
function server.on(ev_name, func)
    onTc(ev_name, func)
    serverConnection:on(ev_name, func)
end





local string_check = tc.assert(tc.str)

local OPT_UNRELIABLE = {isUnreliable = true}

function server.broadcast(packetName, ...)
    string_check(packetName)
    serverConnection:broadcast(false, packetName, ...)
end

function server.lazyBroadcast(packetName, ...)
    serverConnection:broadcast(OPT_UNRELIABLE, packetName, ...)
end




local string2_check = tc.assert(tc.str, tc.str)

function server.unicast(clientId, packetName, ...)
    string2_check(clientId, packetName)
    serverConnection:unicast(clientId, false, packetName, ...)
end


function server.lazyUnicast(clientId, packetName, ...)
    string2_check(clientId, packetName)
    serverConnection:unicast(clientId, OPT_UNRELIABLE, packetName, ...)
end



function server.getPlayers()
    return serverConnection:getPlayers()
end



local worldLoader = serverSession.worldLoader

-- we can call this here, because its not gonna change.
local isWorldPersistent = serverSession:isWorldPersistent()


function server.save(name, data)
    if not isWorldPersistent then
        error("Cannot save data to a non-persistent world! (Check with server.isWorldPersistent())")
    end
    if type(name) ~= "string" then
        error("save(name, data) expects a string as first argument, got: "..type(name), 2)
    end
    if not tools.is_valid_filename(name) then
        error("Invalid save data name: " .. tostring(name), 2)
    end
    if type(data) ~= "string" then
        error("save(name, data) expected string as 2nd argument, got: " .. type(data))
    end
    return worldLoader:saveData(name, data)
end


function server.load(name)
    if not isWorldPersistent then
        error("Cannot load data from a non-persistent world! (Check with server.isWorldPersistent())")
    end
    if type(name) ~= "string" then
        error("load(name) expects a string as first argument, got: "..type(name), 2)
    end
    if not tools.is_valid_filename(name) then
        error("Invalid save data name: " .. tostring(name), 2)
    end
    return worldLoader:readData(name)
end



--[[
    checks if a world is persistent or not
]]
function server.isWorldPersistent()
    return isWorldPersistent
end



function server.getHostClient()
    return serverInitOptions.clientId
end



function server.setTickrate(rate)
    assert(type(rate) == "number", "tickrate needs to be number")
    assert(rate >= 1 and rate <= 400, "tickrate needs to be between 1 and 400")
    variables.ticks_per_second = rate 
end


function server.getTickrate()
    return variables.ticks_per_second
end


function server.shutdown()
    serverSession:close()
end


server.entities = lobj.modLoader.entities

return server

end


return loadServerAPI