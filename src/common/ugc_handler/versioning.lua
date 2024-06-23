
local path = tools.path(...)
local ugch 

local versioning = {}


local MAX_VERSION_NUM = 1000000

local VERSION_SEP = "."


function versioning.to_string(version_number)
    local fst = math.floor(version_number / MAX_VERSION_NUM)
    local snd = version_number % MAX_VERSION_NUM

    return tostring(fst) .. VERSION_SEP .. tostring(snd)
end



function versioning.get_version_number(version_str)
    local _, count = version_str:gsub("%.", "")
    if count ~= 1 then
        return false
    end

    local i = version_str:find("%.")
    local fst = version_str:sub(1, i-1)
    local snd = version_str:sub(i+1)

    fst = tonumber(fst)
    snd = tonumber(snd)
    if fst and snd then
        return (fst * MAX_VERSION_NUM) + snd
    end
end



function versioning.is_valid_version(version_str)
    return versioning.get_version_number(version_str)
end


function versioning.increment_version(version_str)
    -- Use this to generate unique versions
    local number = versioning.get_version_number(version_str)
    assert(number, "Invalid version string")
    number = number + 1
    return versioning.to_string(number)
end


versioning.DEFAULT_VERSION = "0.0"

function versioning.get_version(global_path)
    ugch = ugch or require(path .. ".ugch")
    local ugc_conf = ugch.get_ugc_config(global_path)
    if not ugc_conf then
        return versioning.DEFAULT_VERSION
    end
    return ugc_conf.version
end




return versioning

