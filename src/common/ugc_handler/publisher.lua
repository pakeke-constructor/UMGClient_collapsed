
local nativefs = require("libs.nm_nativefs.nativefs")

local ugch

local pth = tools.path(...)


local SEP = constants.FILE_SEP




local publish_in_progress = false


local PREVIEW_FILES = constants.IMAGE_PREVIEW_FILES


local function set_item_preview(handle, options)
    if options.global_preview_file and nativefs.getInfo(options.global_preview_file) then
        luasteam.UGC.setItemPreview(handle, options.global_preview_file)
    else
        for _, fname in ipairs(PREVIEW_FILES) do
            local preview_path = options.global_directory .. SEP .. fname
            if nativefs.getInfo(preview_path) then
                luasteam.UGC.setItemPreview(handle, preview_path)
            end
        end
    end
end



local function write_ugc_config(options)
    --[[
        write a ugc_config.json file to the directory.
    ]]
    -- avoid circular require loop
    ugch = ugch or require(pth .. ".ugch")

    local global_path = options.global_directory .. SEP .. constants.UGC_CONFIG_FILE

    local ugc_config_json = {
        -- ugc_config.json
        name = options.name,
        description = options.description,
        type = options.type,
        version = options.version
    }

    assert(ugch.is_config_valid(ugc_config_json))
    local data = json.encode(ugc_config_json)
    log.trace("No ugc_config.json found! Writing ugc_config.json : ", data)
    nativefs.write(global_path, data)
end





local function create_item_success(data, options)
    local id = data.publishedFileId
    assert(publish_in_progress, "publish not in progress?")
    assert(id and options)
    assert(options.callback)
    assert(options.type == "mod" or options.type == "world")

    log.trace("start item update!")

    write_ugc_config(options)

    local handle = luasteam.UGC.startItemUpdate(luasteam.utils.getAppID(), id)

    log.trace(inspect(options))
    local ok = luasteam.UGC.setItemContent(handle, options.global_directory)
    log.trace("content ok: ", ok)
    local ok2 = luasteam.UGC.setItemTitle(handle, options.name)
    log.trace("title ok: ", ok2)
    local ok3 = luasteam.UGC.setItemDescription(handle, options.description)
    log.trace("description ok: ", ok3)
    
    set_item_preview(handle, options)

    log.trace("Submit item update.")
    luasteam.UGC.submitItemUpdate(handle, nil, function(submit_data, err)
        log.trace("Submit item update response!")
        if err or data.result ~= 1 then
            options.callback(nil)
            log.error('Update failed with Steamworks SubmitItemUpdateResult_t k_EResult:', data.result)
            if data.result == 2 or data.result == 15 then
                log.error("(Maybe try closing open files of the mod while uploading?)")
            end
        else
            --error("todo todo: Item has been published... what do we do?")
            options.callback(submit_data)
            log.trace("UGC Item update success!!!!")
        end
        publish_in_progress = false
    end)
end





local VALID_OPTIONS = {
    mod = true, world = true    
}

local function assert_publish_options_ok(options)
    assert(not publish_in_progress, "Cannot publish two things at once!")
    publish_in_progress = true
    assert(VALID_OPTIONS[options.type],"?")
    assert(type(options) == "table")
    assert(options.callback)
    assert(options.global_directory)
    assert(options.name)
    assert(options.description)
    assert(options.version)
end



-- "Community"  normal file type    k_EWorkshopFileTypeCommunity
-- "Collection"  used for dependency mods    k_EWorkshopFileTypeCollection 
local workshop_file_type = "Community"


local function publish(options)
    --[[ options = {
        name = "my_mod" or "my_world",
        description = "blah blah",
        type = "mod" | "world",
        global_directory = "C:/.../.../.../directory"
        callback = function() end -- called when published
    }
    ]]
    assert_publish_options_ok(options)

    log.trace("publish start!")
    luasteam.UGC.createItem(luasteam.utils.getAppID(), workshop_file_type, function(data, err)
        log.trace("Create item callback!")
        if err or data.result ~= 1 then
            publish_in_progress = false
            log.error('Failure to create item with Steamworks EResult: ', data.result, " and error: ", tostring(err))
            options.callback(nil)
        else
            -- This is the big cheese VVVV
            create_item_success(data, options)
        end
    end)
end



return publish

