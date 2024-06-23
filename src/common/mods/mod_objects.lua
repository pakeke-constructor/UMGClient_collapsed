
--[[

Mod objects are (primarily) used by UI.
(Just regular tables that contain useful information about mods.)


returns a list of mod objects:
{
    modname = modname,
    mod_identifier = "34894545",
    description = "...",
    storage_type = constants.MOD_STORAGE_TYPES[...]
    config = config, -- from mod_config.json
}

]]

local rpath = tools.path(...)


local mod_config = require(rpath .. ".mod_config")
local mod_identifiers = require(rpath .. ".mod_identifiers")
local mod_struct = require(rpath .. ".ModStruct.ModStruct")

local ugch = require("src.common.ugc_handler.ugch")



local mod_objects = {}


local function get_stored_mod_obj(modname, root_path, storage_type, seen)
    --[[
        Gets a mod_obj for either a `builtin` mod, or a `local` mod.
        See MOD_STORAGE_TYPES.
    ]]
    local info = love.filesystem.getInfo(root_path .. modname)
    if not info then return
        nil
    end
    local fst = modname:sub(1,1)
    if fst == "_" or fst == "." or info.type ~= "directory" then
        return nil -- not a valid directory
    end

    local pth, _is_local = mod_identifiers.get_path(modname)
    if not pth then
        return nil -- no path
    end
    local config = mod_config.get_mod_config(modname)
    if (not config) or seen[modname] then
        return nil -- no config, or already seen
    end

    -- dont want to add two of the same mods
    seen[modname] = true
    return {
        mod_identifier = mod_identifiers.parse_mod_identifier(modname),
        modname = modname,
        description = "", -- TODO: Read ugc_info here if exists?
        type = storage_type,
        config = config
    }
end


local function add_stored_mods(total_mods)
    --[[
        Adds builtin and local mods:
    ]]
    local seen = {} -- to double check we dont add mods twice.

    -- Add builtin mods:
    local builtin_mods = love.filesystem.getDirectoryItems(constants.BUILTIN_MOD_PATH)
    for _,modname in ipairs(builtin_mods) do
        local mobj = get_stored_mod_obj(modname, constants.BUILTIN_MOD_PATH, constants.MOD_STORAGE_TYPES.builtin, seen)
        if mobj then
            total_mods:add(mobj)
        end
    end
    -- Add %appdata mods:
    local local_mods = love.filesystem.getDirectoryItems(constants.LOCAL_MOD_PATH)
    for _,modname in ipairs(local_mods) do
        local mobj = get_stored_mod_obj(modname, constants.LOCAL_MOD_PATH, constants.MOD_STORAGE_TYPES["local"], seen)
        if mobj then
            total_mods:add(mobj)
        end
    end
end



function mod_objects.get_mod_objects()
    --[[
        returns a list of mod objects:
        {
            modname = modname,
            mod_identifier = "34894545",
            description = "...",
            type = constants.MOD_STORAGE_TYPES[...]
            config = config, -- from mod_config.json
        }
    ]]
    local total_mods = tools.Array()

    local ugcs = ugch.get_downloaded_mods()
    for _, uinfo in ipairs(ugcs) do
        local id = tostring(uinfo:get_id())
        local config = mod_config.get_mod_config(id)
        local pth, _is_local = mod_identifiers.get_path(id)
        if pth and config then
            total_mods:add({
                mod_identifier = mod_identifiers.parse_mod_identifier(id),
                modname = uinfo:get_name(),
                description = uinfo:get_description(),
                type = constants.MOD_STORAGE_TYPES["downloaded"],
                config = config
            })
        end
    end

    add_stored_mods(total_mods)

    return total_mods
end




local MOD_TYPES = constants.MOD_TYPES

local function is_base_mod(mod_obj)
    return mod_obj.config.type == MOD_TYPES.base
end

local function is_playable_mod(mod_obj)
    return mod_obj.config.type == MOD_TYPES.playable
end

local function is_addon_mod(mod_obj)
    return mod_obj.config.type == MOD_TYPES.addon
end

local function is_unknown_mod(mod_obj)
    return mod_obj.config.type == MOD_TYPES.unknown
end

function mod_objects.get_mod_type(mod_obj)
    return mod_obj.config.type
end


function mod_objects.get_base_mods()
    return mod_objects.get_mod_objects():filter(is_base_mod)
end


local function equals(mobj1, mobj2)
    return mobj1.mod_identifier == mobj2.mod_identifier
end




local two_table_tc = tc.assert("table", "table")


local function is_selectable_by_user(mod_obj, mods_in_use)
    two_table_tc(mod_obj, mods_in_use)
    --[[
        mod_obj: the mod object to check
        mods_in_use: { ... list of modObjs }

        - base mods are never selectable by user.
        - playable mods are only selectable, if no other playable mods are in use.
        - addon mods are only selectable if everything in `<mod_config>.needs` is already selected.
    ]]
    if is_base_mod(mod_obj) then
        return false
    end
    if is_unknown_mod(mod_obj) then
        return false
    end
    
    local in_use = {}
    for _, mobj in ipairs(mods_in_use) do
        in_use[mobj.mod_identifier] = true
    end

    local config = mod_obj.config
    if is_playable_mod(mod_obj) then
        -- playable mods are only selectable if there are no other playable mods.
        for _, mobj in ipairs(mods_in_use) do
            if is_playable_mod(mobj) and (not equals(mobj, mod_obj)) then
                -- can't have 2 playable mods.
                return false
            end
        end
        return true

    elseif is_addon_mod(mod_obj) then
        -- addon mods are only selectable if everything in `<mod_config>.needs` is already selected.
        local needs = config.needs
        if (not needs) or (#needs == 0) then
            return false
        end

        for _, m_iden in ipairs(needs) do
            if not in_use[m_iden] then
                -- Missing one (or more) requirements in `needs`
                return false 
            end
        end
        return true
    end
    return false -- unknown mod type
end






function mod_objects.filter_compatible_mod_objs(total_mod_objs, in_use_mod_objs)
    --[[
        Takes a list of total_mod_objs (`mod_objects.get_mod_objects()`)
        and a list of in_use mod objects,
        and returns a list of mod objects that
            are compatible with the existing in_use mod_objs.

        WARNING: This function is inefficient,
        since it polls dependencies.  Try not to call every frame.

    ]]
    two_table_tc(total_mod_objs, in_use_mod_objs)

    in_use_mod_objs = tools.Array(in_use_mod_objs)
    total_mod_objs = tools.Array(total_mod_objs)

    local modlist = in_use_mod_objs:map(function(mobj)
        return mobj.mod_identifier
    end)

    local mstruct = mod_struct(modlist)

    local mod_iden_to_modobj = {
        --[[   [mod_iden] -> mod_obj   ]]
    }
    total_mod_objs:map(function(mod_obj)
        mod_iden_to_modobj[mod_obj.mod_identifier] = mod_obj
    end)

    local mods_in_use = tools.Array(mstruct:get_topo_sorted_dependencies())
    -- convert mods_in_use to mod_objects based on previous mapping.
    local function convert_to_modobj(mod_iden)
        return mod_iden_to_modobj[mod_iden]
    end

    mods_in_use = mods_in_use:map(convert_to_modobj)

    local ret = tools.Array()
    for _, mod_obj in ipairs(total_mod_objs) do
        if is_selectable_by_user(mod_obj, mods_in_use) then
            ret:add(mod_obj)
        end
    end

    return ret
end


return mod_objects
