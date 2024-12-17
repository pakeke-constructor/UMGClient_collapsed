

local success, luasteam = pcall(require, "luasteam")

if success then
    success = luasteam.init()
end

if not success then
    log.error("steam connection failed.")
end



local luasteamModule = setmetatable({}, {__index = luasteam})


function luasteamModule.update()
    if success and CLIENT_SIDE then
        -- We only want to run callbacks on clientside.
        -- TODO: do some more checks for this!!!
        -- Serverside may need to use callbacks at some point!!
        luasteam.runCallbacks()
    end
end


function luasteamModule.shutdown()
    if success and CLIENT_SIDE then
        -- We only want to shut down luasteam on clientside.
        log.trace("shutting down luasteam")
        luasteam.shutdown()
    end
end



if success then
    luasteamModule.CONNECTED = true
    return luasteamModule
else
    local t = {
        CONNECTED = false,
        update = tools.nullFunction,
        shutdown = tools.nullFunction
    }
    return setmetatable(t, {
        __call = function()
            error("Oli, you should be checking if luasteam is connected!")
        end,
        __index = function()
            return t
        end
    })
end

