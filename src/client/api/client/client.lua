
local saveService = require("src.common.save.save_service")
local newModFSysObj = require("src.common.api.umg.filesystemObjects")



local function makeClientAPI(lobj)

local client = {
    -- API Table, as used in mods
}


local on_check = tc.assert(tc.str, tc.func)




local clientConnection = lobj.modLoader.connection
assert(clientConnection,"?")


function client.on(event, func)
    on_check(event, func)
    clientConnection:on(event, func)
end


function client.isPaused()
    return variables.ingame_paused
end



function client.send(event, ...)
    if type(event) ~= "string" then
        error("expected string as first argument. Got: " .. tostring(type(event)), 2)
    end
    clientConnection:send(false, event, ...)
end



local LAZY_OPT = {
    unreliable = true
}
function client.lazySend(event, ...)
    if type(event) ~= "string" then
        error("expected string as first argument. Got: " .. tostring(type(event)), 2)
    end
    clientConnection:send(LAZY_OPT, event, ...)
end





function client.getMasterVolume()
    return userService.getMasterVolume() / 100
end

function client.getSFXVolume()
    return userService.getSFXVolume() / 100
end

function client.getMusicVolume()
    return userService.getBGMVolume() / 100
end


function client.getClient()
    return userService.clientId
end


function client.disconnect()
    clientConnection:tryDisconnect()
end


local rootDirObj = nil

function client.getSaveFilesystem()
    local save = saveService.getClientDataSave()
    local fsysobj = save:getFSysObjFor(lobj.modname)

    if not rootDirObj then
        rootDirObj = newModFSysObj(fsysobj)
    end

    return rootDirObj
end


local mLoader = lobj.modLoader

client.assets = {
    images = mLoader.name_to_quad,
    sounds = mLoader.name_to_source
}
client.atlas = mLoader.atlas


-- Clientside entities!
client.entities = lobj.modLoader.entities


return client


end



return makeClientAPI

