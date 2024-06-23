
--[[
    This file translates mod-identifiers into better formats.

    For example:
    "@base"     -->    "@base"
    "dimensions:348945"  -->  "348945"
    "/items"   -->   "/items"
    "items"  -->  "/items"


    It doesn't do any downloading or dependency stuff.


    see _modloader.md for an explanation
]]
local mod_identifiers = {}


local ugch = require("src.common.ugc_handler.ugch")


local HARDCODED_MOD_IDENTIFIERS_FILE = "assets/mod_identifiers/HARDCODED_MOD_IDENTIFIERS.json"

local DOWNLOADED_MOD_SEPARATOR_CHARACTER = ":"


local LOCAL_PREFIX = "/" -- prefix for local mods
local BUILTIN_PREFIX = "@" -- prefix for builtin mods



local LOCAL_MOD_PATH = constants.LOCAL_MOD_PATH
local BUILTIN_MOD_PATH = constants.BUILTIN_MOD_PATH




local fdata = assert(love.filesystem.read(HARDCODED_MOD_IDENTIFIERS_FILE))

--[[
    If players have issues with HARDCODED_MOD_IDENTIFIERS.json, then they
    can always create their own overwrite in %appdata%.
    (This is absolutely a last ditch resort ^^^^)
]]
local HARDCODED_MODS = json.decode(fdata)
--[[
    should look something like:

    ["@modname"] ->  "394845845",
    ["@base"] ->  "90956876589",
    ...
]]

do
for k,v in pairs(HARDCODED_MODS) do
    if not k:sub(1,1) == BUILTIN_PREFIX then
        error("Badly hardcoded mod identifier key: " .. tostring(k))
    end
    if (type(v) ~= "string") or (not ugch.check_id(v)) then
        error("Badly hardcoded mod identifier value: " .. tostring(v))
    end
end
end



local function get_path_builtin(modname)
    local pth = BUILTIN_MOD_PATH .. modname
    local info = love.filesystem.getInfo(pth, "directory")
    if info then
        return pth
    end
end

local function get_path_local(modname)
    local pth = LOCAL_MOD_PATH .. modname
    local info = love.filesystem.getInfo(pth, "directory")
    if info then
        return pth
    end
end


local function get_path_locally_installed(modname)
    --[[
        gets a (local) path for a locally installed mod.
        (UGC mods don't work with this function!!!)
    ]]
    -- first, check in %appdata%,
    -- then, check in builtin.
    return get_path_local(modname) or get_path_builtin(modname)
end




function mod_identifiers.get_mod_name(mod_iden)
    local iden = mod_identifiers.parse_mod_identifier(mod_iden)
    if not iden then
        return nil
    end

    local start_char = iden:sub(1,1)
    if start_char == LOCAL_PREFIX or start_char == BUILTIN_PREFIX then
        return iden:sub(2)
    else
        return iden
    end
end




function mod_identifiers.parse_mod_identifier(mod_iden)
    --[[
        takes a mod identifier, and returns either
        a local-path   (example: "/mod_name")
        or steam-id    (example: "39548958946")

        mod_idens are case-insensitive. This will return the lowercased version.
    ]]
    mod_iden = mod_iden:lower()
    local start_char = mod_iden:sub(1,1)

    if start_char == LOCAL_PREFIX then
        -- local folder
        return mod_iden
    
    elseif ugch.check_id(mod_iden) then
        -- it's already an id
        return mod_iden

    elseif start_char == BUILTIN_PREFIX then
        -- builtin folder
        return mod_iden

    elseif mod_iden:find(DOWNLOADED_MOD_SEPARATOR_CHARACTER) then
        -- downloaded mod:   `my_mod:348955896`
        -- The first part is discarded, we only care about the id (second part)
        local s = mod_iden:find(DOWNLOADED_MOD_SEPARATOR_CHARACTER)
        local id = mod_iden:sub(s+1) 
        if ugch.check_id(id) then
            return id
        end
    end

    -- Lets do some last ditch efforts to resolve this.
    if get_path_local(mod_iden) then
        return LOCAL_PREFIX .. mod_iden
    end
    if get_path_builtin(mod_iden) then
        return BUILTIN_PREFIX .. mod_iden
    end

    return nil -- invalid mod identifier!
end





local function get_path_downloaded(id)
    if ugch.check_id(id) then
        local ugc_info, err = ugch.get_ugc_info(id)
        if ugc_info then
            return ugc_info:get_steam_path()
        end
        return nil, err
    end
    return nil, "Unknown UGC id or invalid id"
end



function mod_identifiers.get_path(mod_iden)
    --[[
        returns path, and true/false whether it's a local path.
        nil, err on failure.
    ]]
    local er
    mod_iden, er = mod_identifiers.parse_mod_identifier(mod_iden)
    if not mod_iden then
        return nil, "Couldn't parse mod identifier: " .. tostring(er)
    end

    local start_char = mod_iden:sub(1,1)

    local isLocal
    if (start_char == LOCAL_PREFIX) or (start_char == BUILTIN_PREFIX) then
        -- local folder
        local foldername = mod_iden:sub(2)
        isLocal = true
        return get_path_locally_installed(foldername), isLocal

    elseif ugch.check_id(mod_iden) then
        -- it's an id
        isLocal = false
        return get_path_downloaded(mod_iden), isLocal
    end

    return nil, "Unknown err"
end




return mod_identifiers
