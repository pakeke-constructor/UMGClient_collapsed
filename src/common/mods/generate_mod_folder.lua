

local files = require("src.common.files.files")



local generate_mod_folder = {}







local REGULAR_MOD_TEMPLATE_PATH = "assets/mod_gen/regular_mod_template/"
local BASE_MOD_TEMPLATE_PATH = "assets/mod_gen/base_mod_template/"


-- where auto-generated type definitions are kept,
-- i.e. selene config and typescript declarations from other mods.
local TYPES_PATH = "_types/"

local TYPESCRIPT_DECL_PATH = "/declarations/typescript"
local SELENE_DECL_PATH = "/declarations/selene.yml"

local SELENE_DECL_EXTEN = ".yml"

local SELENE_PATH = "/selene.toml"



local SELENE_CONFIG = [[

[rules]
multiple_statements = "allow"
parenthese_conditions = "allow"
global_usage = "allow"
comments_count = "allow"
    
]]



local LOCAL_MODPATH = constants.LOCAL_MOD_PATH

--[[
    Adding definitions from `mod` into `parent_mod`.
]]
local function add_definitions(parent_mod, mod, typescript_paths, selene_paths)
    local tsfolder = LOCAL_MODPATH .. mod .. TYPESCRIPT_DECL_PATH
    local selfile = LOCAL_MODPATH .. mod .. SELENE_DECL_PATH
    
    local full_typespath = LOCAL_MODPATH .. parent_mod .. "/" .. TYPES_PATH
    
    if love.filesystem.getInfo(tsfolder) then
        local dest = full_typespath .. mod 
        files.local_copy(tsfolder, dest)
        local localpath = TYPES_PATH .. mod
        table.insert(typescript_paths, localpath)
    end

    if love.filesystem.getInfo(selfile) then
        local dest = full_typespath .. mod .. SELENE_DECL_EXTEN
        files.local_copy(selfile, dest)
        local localpath = TYPES_PATH .. mod .. SELENE_DECL_EXTEN
        table.insert(selene_paths, localpath) 
    end
end


--[[
    Populates a mod's `_types` folder according to the `uses` field.

    this function can be called safely, even if a mod folder already exists.
    It will only delete/change stuff inside of `_types`.
]]
function generate_mod_folder.renew_typings(options)
    assert(options.modname)

    if not options.uses then
        local cfg = mods.get_mod_config(options.modname)
        options.uses = cfg.uses or {}
    end
    assert(type(options.uses) == "table", "wat?")

    local ms = mods.ModStruct(options.uses)
    -- Add mod dependencies to `uses` table  (use mod struct)
    
    files.local_create_directory(LOCAL_MODPATH .. options.modname .. "/" .. TYPES_PATH)        
    -- ensure `_types` folder exists. Clear `_types` folder if neccessary.

    -- For all mods in uses, 
    local selene_paths, typescript_paths = {}, {}
    for _, mod in ipairs(ms:get_modlist()) do
        add_definitions(options.modname, mod, typescript_paths, selene_paths) 
    end
    
    -- update selene.toml file
    local std_libs_line = table.concat(selene_paths, "+")
    local std_line = "std = \"types/umg.yml"
    if std_libs_line:len() > 0 then
        std_line = std_line .. std_libs_line
    end
    std_line = std_line .. "\""
    local selene_config = std_line .. SELENE_CONFIG
    love.filesystem.write(
        LOCAL_MODPATH .. options.modname .. SELENE_PATH,
        selene_config
    )
end





--[[
    generates a mod folder skeleton
    returns the path it was placed in.
]]
function generate_mod_folder.generate_folder(options)
    assert(options.modname)
    assert(type(options.uses) == "table")
    assert(options.is_basemod ~= nil)
    assert(options.use_typescript ~= nil)

    local dest_path = LOCAL_MODPATH .. options.modname .. "/"

    if love.filesystem.getInfo(dest_path) then
        return false, "Folder already existed!"
    end

    -- copy skeleton over 
    local src_path = (options.is_basemod and BASE_MOD_TEMPLATE_PATH) or REGULAR_MOD_TEMPLATE_PATH
    for _, fname in ipairs(love.filesystem.getDirectoryItems(src_path)) do
        local src = src_path  .. fname
        local dst = dest_path .. fname
        files.local_copy(src, dst)
    end

    -- Add gitignore
    local gitignore_pth = dest_path .. ".gitignore"
    files.local_copy("assets/mod_gen/.gitignore", gitignore_pth)

    generate_mod_folder.renew_typings(options)

    -- Add umg_mod.json
    local mod_config = {}
    mod_config.uses = options.uses
    if options.is_basemod then mod_config.type = constants.MOD_TYPES.base end
    mods.set_mod_config(options.modname, mod_config)

    return true
end




return generate_mod_folder
