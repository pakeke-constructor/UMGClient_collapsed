
--[[

Server side only API

]]


local newModFSysObj = require("src.common.api.umg.filesystemObjects")


---@param lobj LObj
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
    serverConnection:broadcast(nil, packetName, ...)
end

function server.lazyBroadcast(packetName, ...)
    serverConnection:broadcast(OPT_UNRELIABLE, packetName, ...)
end




local string2_check = tc.assert(tc.str, tc.str)

function server.unicast(clientId, packetName, ...)
    string2_check(clientId, packetName)
    serverConnection:unicast(clientId, nil, packetName, ...)
end


function server.lazyUnicast(clientId, packetName, ...)
    string2_check(clientId, packetName)
    serverConnection:unicast(clientId, OPT_UNRELIABLE, packetName, ...)
end



function server.getPlayers()
    return serverConnection:getPlayers()
end



local rootDirObj = nil

function server.getSaveFilesystem()
    local fsysobj = serverSession.save:getFSysObjFor(lobj.modname)

    if not rootDirObj then
        rootDirObj = newModFSysObj(fsysobj)
    end

    return rootDirObj
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