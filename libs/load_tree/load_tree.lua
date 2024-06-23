
local load
--[[

Function that automatically runs all
lua files in the given directory, 
including sub folders.


load(
    path,   // the path of the directory
    shover,  // the hashtable 
    func(path) // the func to pass the file paths into
)


]]

require("libs.nm_sort.sort")


local function default_lua(full_path)
    --[[
        `full_path` is the full path of the file.
    ]]
    local ending = full_path:sub(-4,-1)
    if ending == ".lua" then
        return require(full_path:gsub("/","."):sub(1, -5))
    end
end


local function remove_exten(fname)
    return fname:gsub("(.*)%..*$","%1")
end



function load(path, shover, func)
    func = func or default_lua

    local directory = love.filesystem.getDirectoryItems(path)

    -- selene: allow(incorrect_standard_library_use)
    table.stable_sort(directory) -- Sorts by alphabetical I think?? hopefully she'll be right
    -- (basically we just need to be consistent across different OS; because lf.getDirectoryItems isn't)

    shover = shover or {}

    for _,fname in ipairs(directory) do
        if fname:sub(1,1) ~= "_" then
            local full_path = path.."/"..fname
            local info = love.filesystem.getInfo(full_path)

            if info.type == "directory" then
                load(full_path, shover, func)
            else
                local proper_name = remove_exten(fname)
                if not shover[proper_name] then
                    shover[proper_name] = func(full_path)
                end
            end
        end
    end

    return shover
end


return load

