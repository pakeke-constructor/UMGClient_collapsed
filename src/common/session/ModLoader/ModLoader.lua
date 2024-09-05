
--[[

ModLoader object.
Responsible for loading a GROUP of mods.


The reason this is an object, as opposed to a `loadMods()` function,
is because we will *probably* want to laod mods asynchronously
sometime in the future.



]]

local rpath = tools.path(...)

local LObj = require(rpath .. ".LObj")

local mods = require("src.common.mods.mods")




local ModLoader = tools.SafeClass()






local ATLAS_SIZE = constants.MOD_TEXTURE_ATLAS_SIZE


local ARGS = {"session"}

function ModLoader:init(args)
    --[[
        ModLoader is an object that is "shared" between multiple
        mods, when a group of mods are loaded.

        This is because mods share common resources,
        such as the entity cache, and the runtime texture atlas.
    ]]
    tools.assertKeys(args, ARGS)
    tools.inlineMethods(self)

    local sesh = args.session
    if CLIENT_SIDE then
        self.ingameSession = sesh
        self.connection = sesh.clientConnection
    else
        self.serverSession = sesh
        self.connection = sesh.serverConnection
    end
    self.umgSession = sesh.umgSession

    if CLIENT_SIDE then
        local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")
        self.atlas = AutoAtlas(ATLAS_SIZE)
        self.name_to_source = {}
        self.name_to_quad = {}
    end

    self.loadedMods = {--[[
        [modname] -> boolean
        checks whether a modname has been loaded or not.
        Ensures that we don't load duplicate modnames
    ]]}

    self.knownEvents = {--[[
        A hasher of all known events (umg.call, umg.on)
        [eventName] --> true
    ]]}
    for _, ev in ipairs(constants.KNOWN_UMG_EVENTS) do
        self.knownEvents[ev] = true -- add UMG's engine events
    end

    self.knownQuestions = {--[[
        A hasher of all known questions (umg.ask, umg.answer)
        [questionName] --> reducer function
    ]]}
    for _, q in ipairs(constants.KNOWN_UMG_QUESTIONS) do
        self.knownQuestions[q] = true
    end

    self.done = false -- whether we are done
    self.currentlyLoadingModname = false -- current mod-name that is being loaded. (Useful for namespacing)

    self.bufferedETypes = tools.Array(--[[
        an array of (uninitialized) entityTypes, as tables.
        Entity-types will be initialize all at once, at the end.
        {
            etypeName = "modname.etype",
            etypeTable = {...definition}
        }
    ]]) 

    self.entities = {--[[
        [typename] -> EType
    ]]}
    self.globals = {} -- where umg.expose() variables are stored
    self.env_mt = {__index = self.globals} -- metatables for mod envs
end






local function finalizeEnts(self)
    -- Loads entity types and puts them into `entities` if appropriate
    for _, entry in ipairs(self.bufferedETypes) do
        local fullName = entry.etypeName
        local _ns, name = tools.fromNamespaced(fullName)
        local etype = self.umgSession:newEntityType(fullName, entry.etypeTable)
        if self.entities[name] then
            log.warn("Duplicate entity definition: ", name)
        end
        self.entities[name] = etype
        self.entities[fullName] = etype
    end
end



local function loadMod(self, mod_iden)
    local modInfo = mods.get_basic_mod_info(mod_iden)
    
    local pth, is_local = modInfo.path, modInfo.is_local
    local modname = modInfo.modname
    self.currentlyLoadingModname = modname or false -- `or false` because of SafeClass

    log.info("Loading mod: ", modname)

    if (not pth) or (not modname) then
        log.warn("Couldn't load mod: ", mod_iden, is_local)
        return
    end

    -- Create singular mod loader object:
    local lobj = LObj(self, {
        modname = modname,
        path = pth,
        is_local_path = is_local
    })

    lobj:loadMod()
end





function ModLoader:getLoadingContext()
    --[[
        If a mods is currently being loaded, returns
        {
            filename = "file-thats-being-loaded", <-- should we return this?
            modname = "mod-thats-being-loaded"
        }
    ]]
    if not self.done then
        return {
            -- could return extra stuff here in future...? like filename?
            modname = self.currentlyLoadingModname
        }
    end
end



function ModLoader:bufferDefineEntityType(etypeName, etypeTable)
    --[[
        QUESTION:
            why do we buffer etype definitions?
        ANSWER:
            because we must wait until ALL mods are loaded before we define entities.
            Why? cy needs a complete list of groups to properly register the etype.
            ALSO, some mods will tag onto `@entityInit` callback; hence we need buffering
    ]]
    self.bufferedETypes:add({
        etypeName = etypeName,
        etypeTable = etypeTable
    })
end


-- Give some rest to CPU
local MODLOAD_SLEEP_TIME = 0.01

function ModLoader:loadMods(modlist_)
    local startTime = love.timer.getTime()
    assert(not self.done, "wot wot?")
    local modStruct = mods.ModStruct(modlist_)
    if #modlist_ < 1 and constants.DEBUG then
        log.warn("empty modlist passed in!")
    end

    local modlist = modStruct:get_topo_sorted_dependencies()
    -- modlist is now topologically sorted

    for i=1, #modlist do
        loadMod(self, modlist[i])
        love.timer.sleep(MODLOAD_SLEEP_TIME)
    end
    self.currentlyLoadingModname = false

    -- We must finalize all entity defs ONCE, at the very end:
    finalizeEnts(self)
    self.done = true

    local timeTaken = love.timer.getTime() - startTime
    log.trace("================================")
    log.trace(("%d mods loaded in %.3f seconds"):format(#modlist, timeTaken))
    log.trace("================================")
    return modlist
end


return ModLoader

