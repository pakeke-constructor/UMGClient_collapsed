
-- Constants are for real this time.
-- EVERYTHING HERE MUSTTT BE A CONSTANT!!!

return setmetatable({
    GAME_VERSION = "0.0.0";

    -- path to custom boot state
    CUSTOM_BOOT_STATE = "lootplot.states.menu",

    DISCORD_LINK = "https://discord.gg/Pd4nwmy2HJ";

    UDP_PORT = 57843; -- The source udp port to be used client-side, 
    -- by all udp sockets.
    -- (And by the ENet host.)

    HPUNCHER_REQUEST_TIMEOUT = 1; -- anything more than X seconds is a timeout.

    SERVER_CONNECT_TIMEOUT = 8; -- anything more than this is a timeout.

    ENET_REGULAR_CHANNEL = 0; -- ENet channel for regular packets
    ENET_UNRELIABLE_CHANNEL = 1; -- Channel for unreliable packets.

    SHOULD_COMPRESS = false; -- true/false, depending on whether compression
    -- should be used for ENet packets.  (uses LZ4)

    MAX_PLAYERS = 32;

    INVALID_USERNAME_CHARACTERS = "%W", -- any non-alphanumeric are invalid
    MAX_USERNAME_LENGTH = 16,

    MOD_TEXTURE_ATLAS_SIZE = 4096; -- X by X pixels

    COSMETIC_COLOURS = {
        GREY = {140/255, 140/255, 140/255}; -- default

        -- Now increasing with rarity
        BROWN = {100/255, 90/255, 80/255};
        DARK_GREY = {80/255; 80/255; 80/255};
        LIGHT_GREY_BLUE = {80/255, 90/255, 110/255};
        BLUE = {0.2,0.2, 1};
        GREEN = {0.1,0.8,0.1};
        RED = {0.9,0,0};
        GOLD = {255/255, 215/255, 0}
    };

    ONLINE_MODES = {
        -- server online modes enum
        "online", "raw", "offline",
        online = "online", -- online, thru hpuncher
        offline = "offline", -- offline
        raw = "raw" -- online, but not thru hpuncher. (Port forwd most likely)
    };

    SHOW_SPLASH = false;
    
    TEST = true; -- Do we want to do testing?

    --[[
        TODO: Combine all these debug options into one.
    ]]
    DEBUG = true; -- Do we want debug msgs?
    AGGRESSIVE_DEBUG = true, -- aggressive debugging?
    --[[
        TODO: AGGRESSIVE_DEBUG is broken!!!
        We should probably fix e2e tests before running AGGRESSIVE_DEBUG mode.
    ]]

    DEFAULT_LOG_LEVEL = "error",
    PRINT_LEVEL_ENVIRONMENT_VARIABLE = "UMG_PRINT_LEVEL",

    LOVE_EVENTS = {
        "load", "draw", "update", "keypressed", "keyreleased", 
        "textinput", "mousepressed", "mousemoved", "mousereleased",
        "wheelmoved", "focus", "resize", "threaderror",
        "filedropped", "directorydropped" -- There are some more
    };

    KNOWN_UMG_EVENTS = {
        "@tick",
        "@load", "@createWorld",
        "@playerJoin", "@playerLeave",
        "@quit",
        "@draw", "@update",
        "@keypressed", "@textinput", "@keyreleased",
        "@resize",
        "@wheelmoved", "@mousepressed", "@mousereleased", "@mousemoved",
        "@entityInit", "@newEntityType",
        "@debugComponentAccess", "@debugComponentChange",
    },

    KNOWN_UMG_QUESTIONS = {
        -- no questions are emitted by the engine (yet)
    },

    UMG_NAMESPACE_SEPARATOR = ":",

    PCKR_API_REGISTER_PREFIX = "@", -- prepend this to any register alias used while modding.

    BOXER_BUILTIN_PACKET_PREFIX = "@", -- prepend this to builtin packet names
    BOXER_PACKET_VERSION = 39,

    REBOOT_FILE = "REBOOT_OPTIONS",

    FILE_SEP = "/", -- use forward slash for file separation

    WORLD_PATH = "worlds/",
    WORLD_CONFIG_FILE = "/world_config.json",
    WORLD_MODS_FILE = "mods.json",
    ENTITY_DATA_FILE = "entity_data.pckr", -- stores entity-data
    WORLD_DATA_FILE = "world_data.json", -- stores meta-info, like world-time

    -- mod path for %appdata% only for experimental mods (see _modloader.md)
    LOCAL_MOD_PATH = "mods/",
    -- mod path for mods built INTO UMGClient
    BUILTIN_MOD_PATH = "builtin_mods/",

    MOD_CONFIG_FILE = "mod_config.json",

    MOD_REQUIRE_CHUNK_PREFIX = "[mods] ", -- when error is thrown, prefix with this

    MOD_DEFINITION_TYPESCRIPT = "/definitions/",
    MOD_DEFINITION_SELENE = "/definitions/",

    IMAGE_PREVIEW_FILES = {
        -- stored at the base of UGCs, that will show up as preview in steam's workshop.
        "preview.gif", "preview.png", "preview.jpg"
    },
    VIEWABLE_IMAGE_PREVIEW_FILES = {
        -- stored at the base of UGCs, that will show up as preview within game client.
        "preview.gif", "preview.png", "preview.jpg"
    },

    UGC_CONFIG_FILE = "/ugc_config.json", -- stored in the root directory of world/mods
    
    UGC_DISPLAY_FILE = "/display.json", -- stored within the folder of mods and worlds

    UGC_TYPES = {
        mod = "mod",
        world = "world"
    },

    MOD_TYPES = {
        base = "base",
        playable = "playable",
        addon = "addon",
        unknown = "unknown"
    },
    DEFAULT_MOD_TYPE = "unknown",

    MOD_STORAGE_TYPES = {
        ["downloaded"] = "downloaded", -- ie. from steam
        ["local"] = "local", -- ie. in %appdata%/mods
        ["builtin"] = "builtin" -- shipped with UMGClient
    },

    INTERNAL_PATH = "internal_DONT_TOUCH/", -- the directory path for interally used files
    TEMP_PATH = "temporary/" -- temporary files
},





--=======================================
{ -- METATABLE PROTECTION
    __index = function(t,k)
        error("Accessed unknown CONSTANT: " .. tostring(k))
    end;
    __newindex = function(t,k,v) error("??") end;
    __metatable = "protected"
})

