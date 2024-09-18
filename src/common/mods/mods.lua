

local rpath = tools.path(...)


local ModStruct = require(rpath .. ".ModStruct.ModStruct")
local generate_mod_folder = require(rpath .. ".generate_mod_folder")
local mod_identifiers = require(rpath .. ".mod_identifiers")
local new_mod_downloader = require(rpath .. ".mod_downloader")
local mod_config = require(rpath .. ".mod_config")
local mod_objects = require(rpath .. ".mod_objects")

local ugch = require("src.common.ugc_handler.ugch")


local SEP = constants.FILE_SEP


local mods = {}







function mods.get_shallow_dependencies(mod_iden)
    -- resolves mod dependencies using `umg_mod.json`
    assert(mods.mod_is_ready(mod_iden))

    local config = mods.get_mod_config(mod_iden)
    if config and config.uses then
        local arr = tools.Array(config.uses)
        if not arr:find(mod_iden) then
            arr:add(mod_iden)
        end
        local mapped = arr:map(mod_identifiers.parse_mod_identifier)
        if #mapped ~= #arr then
            -- then one (or more) of the mod_idens was invalid.
            -- (since the size of arrays are different, nils aren't added)
            return nil, "One or more mod identifiers was invalid"
        end
        return mapped
    else
        return tools.Array({mod_iden})
    end
end



function mods.get_deep_dependencies(modlist)
    -- resolves dependencies across the whole mod dependency tree
    assert(type(modlist) == "table")
    local seen_mods = {}
    for _, modname in ipairs(modlist) do
        seen_mods[modname] = true
    end

    local added = true
    while added do
        added = false
        for modname, _ in pairs(seen_mods) do
            local mod_deps = mods.get_shallow_dependencies(modname)
            for _, mname in ipairs(mod_deps) do
                if not seen_mods[mname] then
                    added = true
                    seen_mods[mname] = true
                end
            end
        end
    end

    local buffer = {}
    for modn, _ in pairs(seen_mods) do
        table.insert(buffer, modn)
    end
    return buffer
end




function mods.is_world_persistent(modStruct)
    --[[
        Since mods may disagree on whether a world is persistent
        or not, we should search through all non-nil option values,
        and take the is_persistent value that is the "highest" dependency.
    ]]
    local mod_list = modStruct:get_topo_sorted_dependencies()
    -- iterate over backwards to take the "highest" dependency
    for i =#mod_list, 1, -1 do
        local modname = mod_list[i]
        local cfg = mods.get_mod_config(modname)
        local is_persistent = cfg.isWorldPersistent
        if is_persistent ~= nil then
            return is_persistent
        end
    end
    return false -- by default, worlds aren't persistent.
    -- We don't want to bloat user's world folder.
end





--[[
    returns true if a mod is ready to go  (installed + updated),
    false otherwise.
]]
function mods.mod_is_ready(mod_iden)
    mod_iden = mod_identifiers.parse_mod_identifier(mod_iden)
    local pth, err = mod_identifiers.get_path(mod_iden)
    if not pth then
        -- no path, so obviously isn't gonna work
        return nil, err
    end

    if ugch.check_id(mod_iden) then
        -- it's an id: check if it's outdated
        local id = mod_iden
        return ugch.is_ready(id)
    end

    return true -- it's a local mod, return true
end



local function new_fdata(path, is_local)
    if is_local then
        return love.filesystem.newFileData(path)
    else
        local f = assert(io.open(path, "rb"))
        local fdata = love.filesystem.newFileData(f:read("*a"), path)
        f:close()
        return fdata
    end
end


local IMAGE_PREVIEW_FILES = constants.VIEWABLE_IMAGE_PREVIEW_FILES

function mods.get_preview_image(mod_iden)
    local pth, is_local = mod_identifiers.get_path(mod_iden)
    if pth then
        for _, fname in ipairs(IMAGE_PREVIEW_FILES) do
            local path = pth .. SEP .. fname
            local filedata = new_fdata(path, is_local)
            if filedata then
                local image_data = love.image.newImageData(filedata)
                local image = love.graphics.newImage(image_data)
                return image
            end
        end
        return nil, "No image file in mod"
    end
    return nil, "Invalid mod identifier"
end



function mods.get_local_mods_folder()
    return love.filesystem.getSaveDirectory() .. SEP .. constants.LOCAL_MOD_PATH
end


mods.get_mod_config = mod_config.get_mod_config
mods.get_mod_config_from_path = mod_config.get_mod_config_from_path
mods.set_mod_config = mod_config.set_mod_config


mods.get_mod_objects = mod_objects.get_mod_objects
mods.get_base_mods = mod_objects.get_base_mods
mods.filter_compatible_mod_objs = mod_objects.filter_compatible_mod_objs


function mods.get_basic_mod_info(mod_iden)
    mod_iden = mod_identifiers.parse_mod_identifier(mod_iden)
    local path, is_local = mod_identifiers.get_path(mod_iden)
    local modname = mod_identifiers.get_mod_name(mod_iden)
    return {
        modname = modname,
        path = path,
        is_local = is_local
    }
end


mods.generate_mod_folder = generate_mod_folder.generate_folder

mods.ModStruct = ModStruct

mods.new_mod_downloader = new_mod_downloader


return mods

