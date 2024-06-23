

local worlds = {}


local mods = require("src.common.mods.mods")



local WORLD_MODS_FILE = constants.WORLD_MODS_FILE



local SEP = constants.FILE_SEP



-- the files that belong in a world folder
local REQUIRED_WORLD_FILES = {
    constants.WORLD_CONFIG_FILE,
    constants.WORLD_MODS_FILE,
    constants.ENTITY_DATA_FILE,
    constants.WORLD_DATA_FILE
}


function worlds.getWorldPath(worldname_or_path)
    local len = #constants.WORLD_PATH
    local start = worldname_or_path:sub(1, len)

    if start == constants.WORLD_PATH then
        -- it's a path
        return worldname_or_path
    else
        -- its a worldname
        return worlds.getWorldPath(constants.WORLD_PATH, worldname_or_path)
    end
end




function worlds.checkValidity(worldname)
    -- returns true if folder is a valid world, false otherwise
    local folder = worlds.getWorldPath(worldname)
    local info, err = love.filesystem.getInfo(folder, "directory")
    if not info then
        return false, err
    end

    local valid_world = true
    local er2 = ""
    for _, f in ipairs(REQUIRED_WORLD_FILES) do
        if not (love.filesystem.getInfo(folder .. "/" .. f)) then
            valid_world = false
            er2 = "\nMissing file: " .. f
        end
    end
    return valid_world, er2
end




local WORLD_PATH = constants.WORLD_PATH

function worlds.getWorldPath(worldname)
    -- see world_folder_structure.md
    return WORLD_PATH .. worldname
end


local SAVEDATA_PATH = "world_specific_savedata"

function worlds.ensure_save_path(worldname)
    love.filesystem.createDirectory(WORLD_PATH .. worldname .. SEP .. SAVEDATA_PATH)
end

function worlds.make_save_path(worldname, key)
    return WORLD_PATH .. worldname .. SEP .. SAVEDATA_PATH .. SEP .. key
end







function worlds.get_modstruct(worldname)
    local pth = worlds.getWorldPath(worldname)
    local fname = pth .. "/" .. WORLD_MODS_FILE
    local json_data, err = love.filesystem.read(fname)
    if not json_data then
        log.error("error reading mods.json data: ", err)
    else
        local mod_struct = mods.ModStruct(json_data)
        return mod_struct
    end
end




function worlds.exists(worldname)
    local pth = worlds.getWorldPath(worldname)
    local info = love.filesystem.getInfo(pth)
    if not info then
        return false
    end
    local ok = worlds.is_valid_world(pth)
    if not ok then
        return false
    end
end



function worlds.get_worlds()
    local total_worlds = {}
    for _, worldname in ipairs(love.filesystem.getDirectoryItems("worlds")) do
        local fst = worldname:sub(1,1)
        local pth = worlds.getWorldPath(worldname)
        local info = love.filesystem.getInfo(pth)
        if fst ~= "_" and fst ~= "." and info.type == "directory" then
            local ok, errtab = worlds.is_valid_world(pth)
            if ok then
                table.insert(total_worlds, worldname)
            else
                -- I guess we keep the world, maybe mark it as corrupted...?
                -- TODO: 
                -- These corrupted worlds should be moved to a different folder.
                -- Maybe like, "corrupted_worlds" folder or something.
                local json_data = json.encode(errtab)
                love.filesystem.write(pth .. "/CORRUPTED_WORLD.txt", json_data)
            end
        end
    end
    return total_worlds
end




local function delete_recursively(pth)
    if love.filesystem.getInfo(pth, "directory" ) then
        for _, child in pairs(love.filesystem.getDirectoryItems(pth)) do
            delete_recursively(pth .. '/' .. child )
            love.filesystem.remove(pth .. '/' .. child )
        end
    elseif love.filesystem.getInfo(pth) then
        love.filesystem.remove(pth)
    end
    love.filesystem.remove(pth)
end


function worlds.delete_world(worldname)
    local pth = worlds.getWorldPath(worldname)
    delete_recursively(pth)
end



return worlds
