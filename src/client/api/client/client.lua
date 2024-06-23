



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
    return variables.ingame_master_volume
end

function client.getSFXVolume()
    return variables.ingame_sfx_volume
end

function client.getMusicVolume()
    return variables.ingame_music_volume
end


function client.getClient()
    return userService.clientId
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

