
local path = tools.path(...)


local nativefs = require("libs.nm_nativefs.nativefs")

local new_ugc_info = require("src.common.ugc_handler.ugc_info")
local publish = require(path .. ".publisher")
local versioning = require(path .. ".versioning")


local SEP = constants.FILE_SEP




local ugch = {}



ugch.publish = publish

ugch.versioning = versioning



local function check_id(id)
    --[[
        Takes in a string, or userdata,
        and check that it is a valid steam id. (64 bit int.)

        If `id` contains a dot, this function removed everything before
        the last dot.
        For example, `base.3489458956` becomes `3489458956`

        Returns a userdata u64, nil otherwise.
    ]]
    if not luasteam.CONNECTED then
        return nil, "LuaSteam not connected"
    end

    if type(id) == "userdata" then
        --eh, it's *probably* fine
        -- (TODO this is fucking dumb)
        return id
    end
    local id_uint64
    if type(id) ~= "string" then
        return nil, "Id wasn't string"
    end
    id_uint64 = luasteam.extra.parseUint64(id)
    -- id_uint64 will be a userdata. If the number is 0, it indicates a c++ error in parsing
    if tostring(id_uint64) == "0" then
        return nil, "Unable to parse uint64"
    end
    return id_uint64
end

ugch.check_id = check_id





function ugch.get_ugcs()
    local array = tools.Array()
    if not luasteam.CONNECTED then
        -- best we can do.
        return array
    end

    for _, id in ipairs(luasteam.UGC.getSubscribedItems()) do
        local itemState = luasteam.UGC.getItemState(id)
        if itemState then
            local info = ugch.get_ugc_info(id)
            if info then
                array:add(info)
            end
        else
            log.error("WTF??? Code should never reach here. Bug in luasteam?")
        end
    end

    return array
end





function ugch.subscribe(id, func)
    --[[
        id:  steamId_u64
        func: function( success, err? ), whether subscribe succeeded.
    ]]
    if not luasteam.CONNECTED then
        func(false, "Not connected to steam")
    end

    id=assert(check_id(id))
    luasteam.UGC.subscribeItem(id, function(tabl, io_fail)
        if io_fail then
            log.error("sub failed with id: ", tostring(id))
            func(false, "io fail")
            return
        end

        if tabl.result == "1" then
            assert(tostring(id) == tostring(tabl.publishedFileId), "I'm misunderstanding something.")
            func(true, io_fail)
        else
            func(false, "Bad SteamWorks EResult: " .. tabl.result)
        end
    end)
end



function ugch.unsubscribe(id)
    id=assert(check_id(id))
    luasteam.UGC.unsubscribeItem(id, function(tabl, io_fail)
        if io_fail then
            log.error("unsub failed w/ id: ", tostring(id))
            return
        end
        print(tabl.result)
        print(tabl.publishedFileId)
        assert(tostring(id) == tostring(tabl.publishedFileId), "I'm misunderstanding something.")
        log.trace("unsubscribed to ", id)
    end)
end




local function try_read_json(global_pth)
    if not nativefs.getInfo(global_pth) then
        return
    end
    local data = nativefs.read(global_pth)
    local ok, ret = pcall(json.decode,data)
    if ok then
        return ret
    end
    return nil, ret
end


local required_attrs = {
    -- All of these types should be strings
    "name", "description", "type", "version"
}


function ugch.is_config_valid(conf_tabl)
    for _, a in ipairs(required_attrs) do
        local val = conf_tabl[a]
        if not val then
            return false, "Missing attribute: " .. a
        end
        if type(val) ~= "string" then
            -- since every type must be a string
            -- (change this if we have numeric types or something)
            return false, "Attr value was not string: " .. a
        end
    end
    return true
end




function ugch.get_ugc_config(global_path)
    --[[
        gets the umg_ugc.json value, given a global path.
        (This is the value of the json object inside of the json file)
    ]]
    local ugc_config, err = try_read_json(global_path .. SEP .. constants.UGC_CONFIG_FILE)

    if not ugc_config then
        return nil, err
    end

    local valid, er = ugch.is_config_valid(ugc_config)
    if not valid then
        return nil, er
    end

    return ugc_config
end




--[[
    checks if a ugc is ready to be used or not
]]
function ugch.is_ready(id)
    if not luasteam.CONNECTED then
        return false
    end

    id = assert(check_id(id))
    local item_state = luasteam.UGC.getItemState(id)
    --[[
        luasteam.UGC.getItemState returns a table of booleans: 

        {
            subscribed – The current user is subscribed to this item. Not just cached.
            legacyItem – The item was created with the old workshop functions in ISteamRemoteStorage.
            installed – Item is installed and usable (but maybe out of date).
            needsUpdate – The items needs an update. Either because it’s not installed yet or creator updated the content.
            downloading – The item update is currently downloading.
            downloadPending
        }
    ]]
    if not item_state then
        return false
    end

    if (not item_state.installed) or item_state.needsUpdate then
        return false -- It's not ready!
    end
    return true
end




function ugch.get_downloaded_mods()
    local buffer = ugch.get_ugcs():filter(function(uinfo)
        return uinfo:is_mod()
    end)
    return buffer
end


function ugch.get_downloaded_worlds()
    local buffer = ugch.get_ugcs():filter(function(uinfo)
        return uinfo:is_world()
    end)
    return buffer
end





function ugch.get_ugc_info(id)
    --[[
        id: the steam id. If contains a dot, it only takes the id:
        Example:  "base.34894896" --> "34894896"

        returns:   {
            id = "3249495848758", // steam id
            steam_path = "directory/owned/by/steam/94495845",
            size = 2349,
            item_state = {...}

            ugc_config = {
                name = "base",
                version = "1.0.0",
                description = "this is the base mod",
                type = "mod" | "world"
            }
        }
    ]]
    if not luasteam then
        return nil, "Not connected to steam"
    end

    id = assert(check_id(id))
    local success, sze, pth = luasteam.UGC.getItemInstallInfo(id)
    if not success then
        return nil, "Couldn't get UGC install info for id: "
    end

    local istate = luasteam.UGC.getItemState(id)

    local ugc_config, er = ugch.get_ugc_config(pth)
    if not ugc_config then
        return nil, er
    end

    local ugc_info = {
        id = id,
        steam_path = pth,
        size = sze,
        item_state = istate,
        ugc_config = ugc_config
    }

    return new_ugc_info(ugc_info)
end





function ugch.get_existing_ugc_config(global_directory)
    --[[
        gets existing umg_ugc.json values.
        Returns nil if the directory doesn't have a umg_ugc.json file,
        or if the data is not able to be deserialized.
    ]]
    local fpath = global_directory .. SEP .. constants.UGC_CONFIG_FILE
    local data = nativefs.read(fpath)
    if not data then
        log.error("Couldn't read config!")
        return nil
    end
    local ok, tabl = pcall(json.decode, data)
    if ok then
        return tabl
    end
    log.error("Couldn't decode json data: ", tabl)
end





return ugch
