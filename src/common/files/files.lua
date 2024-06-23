

local nativefs = require("libs.nm_nativefs.nativefs")

--[[

this file automatically generates two types of utility functions:

`global_` functions, that use nativefs, and have access to the whole filesystem
and `local_` functions, that just use love's default save directory.

Global functions (whole filesystem) are prefixed with `global_`
Local functions (local filesystem) are prefixed with `local_`

]]



local files = {}


files.FSysObj = require(tools.path(...) .. ".FsysObj")


local file_funcs = {}



function file_funcs.get_size(directory_or_file, fs)
    -- returns size (in bytes) of directory or file
    local info = fs.getInfo()
    if not info then return 0 end
    if info.size then
        return info.size
    end
    if info.type == "directory" then
        local sum = 0
        local dir = directory_or_file
        for _, fname in ipairs(fs.getDirectoryItems(dir)) do
            local sze = file_funcs.get_size(fs, dir .. "/" .. fname)
            sum = sum + sze
        end
    end
    return 0
end



function file_funcs.is_valid_mod(fs, folder)
    -- returns true if folder is a valid mod, false otherwise
    -- Valid mods will always have 
    local info, err = fs.getInfo(folder, "directory")
    if not info then
        return nil, "No folder found: " .. tostring(err)
    end
    local serverside = fs.getInfo(folder .. "/server")
    local clientside = fs.getInfo(folder .. "/client")
    local assets = fs.getInfo(folder .. "/assets")
    local entities = fs.getInfo(folder .. "/entities")
    return serverside or clientside or assets or entities
end


function file_funcs.recursively_delete(fs, dir)
    assert(dir:lower() ~= "worlds" and dir:lower() ~= "/worlds")
    assert(dir:lower() ~= "mods" and dir:lower() ~= "/mods")
    assert(fs == love.filesystem, "AINT NO WAY")
    if fs.getInfo(dir, "directory") then
        for _, child in pairs(fs.getDirectoryItems(dir)) do
            file_funcs.recursively_delete(fs, dir .. '/' .. child )
            fs.remove(dir .. '/' .. child)
        end
        fs.remove(dir)
    elseif fs.getInfo(dir) then
        fs.remove(dir)
    end
end


function file_funcs.mimic_dir_skeleton(fs, src, dest)
    if not fs.getInfo(dest) then
        fs.createDirectory(dest)
    end

    for _, fname in ipairs(fs.getDirectoryItems(src)) do
        local info = fs.getInfo(src .. "/" .. fname)
        if info and info.type == "directory" then
            file_funcs.mimic_dir_skeleton(fs, src .. "/" .. fname, dest .. "/" .. fname)
        end
    end
end


function file_funcs.get_info(fs, ...)
    return fs.getInfo(...)
end


local function copy_file(fs, src_path, dest_path)
    local data, err = fs.read(src_path)
    if not data then
        log.error("Error copying file: " .. err)
    else
        fs.write(dest_path, data)
    end
end



function file_funcs.copy(fs, src, dest)
    assert(#src>0, "src?")
    assert(#dest>0, "dest?")
    assert(fs.getInfo(src), "src doesn't exist")

    local src_info = fs.getInfo(src)
    if src_info.type == "file" then
        copy_file(fs, src, dest)
        return
    end

    if not fs.getInfo(dest) then
        fs.createDirectory(dest)
    end

    for _, fname in ipairs(fs.getDirectoryItems(src)) do
        local info = fs.getInfo(src .. "/" .. fname)
        if info then
            local src_path = src .. "/" .. fname
            local dest_path = dest .. "/" .. fname
            if info.type == "directory" then
                -- copy directory
                file_funcs.copy(fs, src_path, dest_path)
            elseif info.type == "file" then
                -- copy file
                copy_file(fs, src_path, dest_path)
            end
        end
    end
end


function file_funcs.move(fs, src, dest)
    file_funcs.copy(fs, src, dest)
    file_funcs.recursively_delete(fs, src)
end


function file_funcs.get_directory_items(fs, path)
    return fs.getDirectoryItems(path)
end




function file_funcs.read(fs, fullpath, size)
    return fs.read(fullpath, size)
end



function file_funcs.write(fs, path, data, size)
    return fs.write(path, data, size)
end


function file_funcs.create_directory(fs, dir)
    return fs.createDirectory(dir)
end


local SEP = constants.FILE_SEP
local HASH_ALGO = "sha256"

local function hash(data)
    return love.data.hash(data, HASH_ALGO)
end

function file_funcs.hash(fs, dir, ignore)
    if ignore[dir] then
        return ""
    end
    if fs.getInfo(dir, "directory") then
        -- It's a directory, hash contents
        -- (we basically combine all strings here.)
        local lis = fs.getDirectoryItems(dir)
        local sum_str = {}
        for _, fname in ipairs(lis) do
            local pth = dir .. SEP .. fname
            table.insert(sum_str, pth)
        end
        local data = table.concat(sum_str)
        return hash(data)
    elseif fs.getInfo(dir, "file") then
        -- It's a file, hash it directly
        local data = love.filesystem.read(dir)
        return hash(data)
    end
    return "" -- else, hash nothing
end






function files.unique_world_name(worldname)
    --[[
        takes a world name and generates a new unique one if there is a collision
        (or returns the current name if there is no collision)
    ]]
    local fs = love.filesystem 
    local path = constants.WORLD_PATH .. worldname
    if fs.getInfo(path) then
        local s,_ = worldname:find("_%d+$")
        local num = 1
        local raw_name = worldname
        if s then
            local num_str = worldname:sub(s+1)
            raw_name = worldname:sub(1,s-1)
            num = tonumber(num_str, 10)
        end
        repeat 
            num = num + 1
            worldname = raw_name .. "_" .. tostring(num)
            path = constants.WORLD_PATH .. worldname
        until not fs.getInfo(path)
        return worldname
    else
        return worldname
    end
end




function files.clear_temp_folder()
    files.local_recursively_delete(constants.TEMP_PATH)
end



function files.ensure_game_folders_exist()
    local paths = {
        constants.INTERNAL_PATH,
        constants.TEMP_PATH,
        constants.WORLD_PATH,
        constants.LOCAL_MOD_PATH
    }
    for _, path in ipairs(paths) do
        if not love.filesystem.getInfo(path) then
            love.filesystem.createDirectory(path)
        end
    end
end





local GLOBAL_PREFIX = "global_"
local LOCAL_PREFIX = "local_"

for name, func in pairs(file_funcs) do
    files[GLOBAL_PREFIX .. name] = function(...)
        return func(nativefs, ...)        
    end
    files[LOCAL_PREFIX .. name] = function(...)
        return func(love.filesystem, ...)
    end
end


return files
