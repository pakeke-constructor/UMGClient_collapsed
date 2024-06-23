


local UGCInfo = tools.SafeClass()


function UGCInfo:get_id()
    return self.id
end

function UGCInfo:get_steam_path()
    return self.steam_path
end

function UGCInfo:get_size()
    return self.size
end


function UGCInfo:get_item_state()
   --[[
        (table) A table with flags for the item state, or nil if the item is not tracked on client. All flags are boolean values.

        subscribed – The current user is subscribed to this item. Not just cached.
        legacyItem – The item was created with the old workshop functions in ISteamRemoteStorage.
        installed – Item is installed and usable (but maybe out of date).
        needsUpdate – The items needs an update. Either because it’s not installed yet or creator updated the content.
        downloading – The item update is currently downloading.
        downloadPending – UGC.downloadItem() (missing) was called for this item, the content isn’t available until the callback is fired.
    ]]
    return self.item_state
end

function UGCInfo:get_ugc_config()
    --[[
        ugc_config = {
            name = "base",
            version = "1.0.0",
            description = "this is the base mod",
            type = "mod" | "world"
        }
    ]]
    return self.ugc_config
end


function UGCInfo:is_mod()
    return self:get_ugc_config().type == constants.UGC_TYPES.mod
end

function UGCInfo:is_world()
    return self:get_ugc_config().type == constants.UGC_TYPES.world
end

function UGCInfo:needs_update()
    local istate = self:get_item_state()
    return not istate.needsUpdate
end


function UGCInfo:get_name()
    -- gets from ugc_config
    return self:get_ugc_config().name
end

function UGCInfo:get_version()
    -- gets from ugc_config
    return self:get_ugc_config().version
end

function UGCInfo:get_description()
    -- gets from ugc_config
    return self:get_ugc_config().description
end



local REQUIRED = {
    "id", "steam_path",
    "size", "item_state", "ugc_config"
}


function UGCInfo:init(tabl)
    tools.assertKeys(tabl, REQUIRED)
    for key, val in pairs(tabl) do
        self[key] = val
    end
end


return UGCInfo

