

local LOADED_BOOLEAN_CACHE_KEY = {"LOADED_BOOLEAN_CACHE_KEY"}
-- a unique key used for `cache` that tells whether a file has been loaded or not.

local SEEN_BOOLEAN_CACHE_KEY = {"SEEN_BOOLEAN_CACHE_KEY"}
-- a unique key used for `cache` that tells whether a file has been SEEN or not.
-- This is used to detect circular dependencies, and throw error if required.





local function load_file(path, lobj, cache, load_string)
    --[[
        user_path is the path supplied by the user
        global_mod_path is of the format:  `mods/pakeke_constructor.zug_rush/`
        env is the _G env
        cache is the require cache
    ]]
    if path:find("/", 1, true) or path:find("\\", 1, true) then
        error("forward slashes is not allowed, use dots as separator")
    end
    local pathkey = path:lower() -- lowercase the path so we don't get weird key issues

    if not cache[LOADED_BOOLEAN_CACHE_KEY] then
        cache[LOADED_BOOLEAN_CACHE_KEY] = {
            -- [user_path] --> boolean:   whether this file has been loaded or not
            -- The reason we need this is because files can return nil.
        }
    end
    if not cache[SEEN_BOOLEAN_CACHE_KEY] then
        cache[SEEN_BOOLEAN_CACHE_KEY] = {
            -- [user_path] --> boolean:   whether this file has been seen or not.
            -- This protects against circular requires.
        }       
    end

    local isLoaded = cache[LOADED_BOOLEAN_CACHE_KEY]
    local seenCache = cache[LOADED_BOOLEAN_CACHE_KEY]

    if isLoaded[pathkey] then
        return cache[pathkey]
    end

    if seenCache[pathkey] then
        error("Circular require loop: " .. tostring(path))
    end
    seenCache[pathkey] = true
    
    local env = lobj.env
    local modname = lobj.modname

    log.trace("Loading file: ", tools.toNamespaced(lobj.modname, path))
    local path_slash = path:gsub("%.", "/")

    -- Fix module name
    local requireFolder = false
    if lobj.fsysObj:getInfo(path_slash, "directory") and not lobj.fsysObj:getInfo(path_slash .. ".lua", "file") then
        path_slash = path_slash.."/init"
        requireFolder = true
    elseif pathkey:sub(-5) == ".init" then
        -- strip .init out
        pathkey = pathkey:sub(1, -6)
        requireFolder = true
    end

    local str, err = lobj.fsysObj:read(path_slash .. ".lua")
    if not str then
        error("couldn't load: " .. path_slash, 2)
    end

    local prefix = "="..constants.MOD_REQUIRE_CHUNK_PREFIX
    local chunk_name = prefix .. modname .. ": " .. path_slash .. ".lua"
    local chunk, load_err = load_string(str, chunk_name)
    if not chunk then
        error("Error loading file: \n" .. tostring(load_err))
    end

    setfenv(chunk, env)
    local result = chunk(pathkey)
    cache[pathkey] = result
    isLoaded[pathkey] = true

    if requireFolder then
        cache[pathkey..".init"] = result
        isLoaded[pathkey..".init"] = true
    end

    return result
end





local make_require_tc = tc.assert("table", "function")
local requireTc = tc.assert(tc.string)

local function make_require(lobj, load_string, preloaded)
    make_require_tc(lobj, load_string)
    --[[
        generates the require function that is used by the modder.
        Server files are unable to be loaded on client, (and vice versa)
    ]]
    local illegal_start
    local err
    if CLIENT_SIDE then
        err = "Unable to load a serverside file from clientside!"
        illegal_start = "server."
    elseif SERVER_SIDE then
        err = "Unable to load a clientside file from serverside!"
        illegal_start = "client."
    end

    local cache = {}

    local function require(pth)
        requireTc(pth)
        if preloaded[pth] then
            return preloaded[pth]
        end

        -- This is the require function used by modders.
        if pth:sub(1,7) == illegal_start then
            error(err, 2)
        end
        return load_file(pth, lobj, cache, load_string)
    end

    return require
end


return make_require
