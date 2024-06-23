
--[[

Mod loader object.

this object is passed around when we are loading a mod.

----------------------

QUESTION:
What's the difference between this object, and ModLoader object?

ANSWER:
LObj is responsible for loading one mod ONLY.
ModLoader object is responsible for loading A GROUP OF mods.

Specifically, ModLoader will create multiple LObj's internally!


]]

local files = require("src.common.files.files")


local LObj = tools.SafeClass()





local new_lobj_tc = tc.assert("table", "table")

function LObj:init(modLoader, options)
    --[[
        options: {
            modname = "x",
            path = "path/to/mod",
            is_local_path = true or false
            -- whether the path should be used with love.filesystem or not
        }
    ]]
    new_lobj_tc(modLoader, options)
    assert(options.modname)
    assert(options.path)
    assert(options.is_local_path ~= nil)

    -- `modLoader` is shared between multiple LObjs
    self.modLoader = modLoader
    self.path = options.path
    self.modname = options.modname
    self.is_local_path = options.is_local_path

    -- `env` is the global environment (_G) of this mod.
    self.env = setmetatable({}, modLoader.env_mt)

    -- used for interacting with files within the mod
    self.fsysObj = files.FSysObj(options.path, options.is_local_path)
end





function LObj:isNamespaced(str)
    --[[
        returns true if `str` starts with "<modname>:"
        false otherwise.

        Useful for namespacing, eg:
            mortality:entityDeath
            rendering:drawEntity
        
        This function will ALSO return true if the prefix matches the
        mod that is *currently being loaded.*
        (This allows mods to do stuff on behalf of other mods)
        (For example; sync.autoSyncComponent can register packets 
            on behalf of another mod.)
    ]]
    local namespace, name = tools.fromNamespaced(str)
    if not namespace then
        return false
    end

    local currModname = false
    local loadCtx = self.modLoader:getLoadingContext() 
    if loadCtx then
        currModname = loadCtx.modname
    end

    local matches = (namespace == self.modname) or (namespace == currModname)
    local not_blank = name:len()>0
    return matches and not_blank
end




local SEP = constants.FILE_SEP



local find = string.find
local function find_last_dot(haystack)
    local i, j
    local k = 0
    repeat
        i = j
        j, k = find(haystack, ".", k + 1, true)
    until j == nil
    return i
end


local function get_path_name(path)
    local match = path:match("^.+(%/.+)$"):sub(2)
    local i = find_last_dot(match)
    if i then
        match = match:sub(1, i-1)
    end
    return match
end





local STATIC_SOUND_SIZE = 40000 -- 40_000 bytes is a good size for small sounds.
--[[
    TODO: This should be done differently.
    IDEA:
        sort all sound assets by lowest-biggest size,
        Allocated X bytes for static-loading,
        and then load N sounds such that X amount of memory is used up.
]]

local function put(self, hsh, name, obj)
    local modname = self.modname
    local nsName = tools.toNamespaced(modname, name)

    if hsh[name] then
        log.info("Overwriting asset name: ", name)
    end
    hsh[name] = obj
    hsh[nsName] = obj
end


local function load_src(self, path)
    local src_type = "stream"
    local env = self.env

    local info = env.love.filesystem.getInfo(path)
    if not info then
        log.error("couldnt find src")
        return
    end
    local size = info.size

    if size and size <= STATIC_SOUND_SIZE then
        src_type = "static"
    end

    local src = env.love.audio.newSource(path, src_type)
    local name = get_path_name(path)
    local modLoader = self.modLoader
    put(self, modLoader.name_to_source, name, src)
end


local err_out_of_space = [[
Texture atlas ran out of space whilst loading image:
%s
Make sure all the mod images fit within the atlas.
]]


local function load_quad(self, path)
    --[[
        A quad can be accessed by
        `image_name`,
        `modname:image_name`,
        OR   `author.modname:image_name`
    ]]
    local modLoader = self.modLoader
    local atlas = modLoader.atlas
    local imgData = self.env.love.image.newImageData(path)
    --[[
        TODO:
        Emit `@loadImage` event here or something...?
    ]]
    local quad = atlas:add(imgData)
    if quad then
        local name = get_path_name(path)
        put(self, modLoader.name_to_quad, name, quad)
    else
        error(err_out_of_space:format(path))
    end
end


local extension_to_loader = {
    -- audio files
    [".wav"] = load_src;
    [".mp3"] = load_src;

    -- image files
    [".png"] = load_quad;
    [".jpeg"] = load_quad;
    [".jpg"] = load_quad;
    [".bmp"] = load_quad;
    [".tga"] = load_quad;
    [".hdr"] = load_quad;
    [".pic"] = load_quad;
    [".exr"] = load_quad
}


local function loadAssetFile(self, path, extension)
    if extension_to_loader[extension] then
        return extension_to_loader[extension](self, path)
    end
end



local function iterDirectory(self, path, func)
    local directory = self.fsysObj:getDirectoryItems(path)
    -- selene: allow(incorrect_standard_library_use)
    table.stable_sort(directory) -- Sorts by alphabetical I think
    -- (we just want consistency)

    for _,fname in ipairs(directory) do
        if fname:sub(1,1) ~= "_" then
            local extension = tools.get_extension(fname)
            func(fname, extension)
        end
    end
end


local function loadTree(self, path, func)
    --[[
        Recursively enters `path` directory, calling
        `func` on every file.
    ]]
    assert(func)
    iterDirectory(self, path, function(fname, extension)
        local filepath = path .. SEP .. fname
        local info = self.fsysObj:getInfo(filepath)

        if info.type == "directory" then
            loadTree(self, filepath, func)
        else
            func(filepath, extension)
        end
    end)
end





local function loadAssets(self, path)
    if not CLIENT_SIDE then
        -- dont load assets on server.
        return
    end
    local asset_info = self.fsysObj:getInfo(path)
    if asset_info then
        loadTree(self, path, function(pth, extension)
            return loadAssetFile(self, pth, extension)
        end)
    end
end


local function isExecutable(extension)
    return extension == ".lua"
end



local function loadLuaFiles(self, path)
    -- Loads ALL lua files in a directory, including nested.
    local modRequire = self.env.require
    loadTree(self, path, function(pth, exten)
        if isExecutable(exten) then
            pth = tools.remove_extension(pth)
            modRequire(pth)
        end
    end)
end

local function loadLuaFilesFlat(self, path)
    -- loads lua files in a directory, 
    -- WITHOUT nested traversal.
    local modRequire = self.env.require
    iterDirectory(self, path, function(pth, exten)
        if isExecutable(exten) then
            pth = tools.remove_extension(pth)
            modRequire(pth)
        end
    end)
end




local function makeEnv(lobj)
    if CLIENT_SIDE then
        return require("src.client.api._G")(lobj)
    elseif SERVER_SIDE then
        return require("src.server.api._G")(lobj)
    end
    error("wot")
end




function LObj:loadMod()
    local env = makeEnv(self)
    for k,v in pairs(env) do
        self.env[k] = v
    end

    loadAssets(self, "assets")

    loadLuaFilesFlat(self, "") -- load root dir first

    if CLIENT_SIDE then
        loadLuaFiles(self, "client")
    elseif SERVER_SIDE then
        loadLuaFiles(self, "server")
    end
    loadLuaFiles(self, "shared")
    
    -- In entities/ folder, we load lua files, AND assets:
    loadLuaFiles(self, "entities")
    loadAssets(self, "entities")
end



return LObj

