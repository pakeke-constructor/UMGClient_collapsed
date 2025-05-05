
local newBuses = require("src.common.api.umg.buses")

local newModFSysObj = require("src.common.api.umg.filesystemObjects")

local analyticsService = require("src.common.analytics.analytics_service")



local function namespaceByContext(lobj, str)
    --[[
        returns a string, namespaced by the modname of the 
        *CURRENT mod that is being loaded.*
        This seems *weird,* but consider this:

        -- doom mod:
        function doom.defineEnemy(name, ...)
        end

        -- zombies mod:
        doom.defineEnemy("zombie1", {....})
        -- `zombie1` will either be namespaced as
            "zombies:zombie1" (namespaceByContext)
            OR,
            "doom:zombie1" (namespaceByModname)
        
        CLEARLY, namespaceByContext is better here!!!
    ]]
    local ctx = lobj.modLoader:getLoadingContext()
    if ctx then
        return tools.toNamespaced(ctx.modname, str)
    end
end


local function namespaceByModname(lobj, str)
    return tools.toNamespaced(lobj.modname, str)
end



local function assertNamespaced(lobj, str)
    if not lobj:isNamespaced(str) then
        local namespace, name = tools.fromNamespaced(str)
        if not namespace then
            local loaderNs = namespaceByContext(lobj, str) or ""
            local modNs = namespaceByModname(lobj, str)
            error(("'%s' needs to be namespaced!'\nExample: '%s' or '%s'")
                :format(str, modNs, loaderNs), 3)
        else
            local loaderNs = namespaceByContext(lobj, name) or ""
            local modNs = namespaceByModname(lobj, name)
            error(("'%s' namespaced incorrectly.\nExpected: '%s' or '%s'")
                :format(str, modNs, loaderNs), 3)
        end
    end
end


local function assertIsLoading(lobj)
    local modLoader = lobj.modLoader
    if not modLoader:getLoadingContext() then
        error("Must be called during loading time!", 3)
    end
end




local function addEntityFunctions(umg, lobj)
    local modLoader = lobj.modLoader
    local cyWorld = modLoader.umgSession.cyWorld

    function umg.exists(ent)
        return cyWorld:exists(ent)
    end

    function umg.isEntity(x)
        return cyWorld:isEntity(x)
    end

    function umg.group(...)
        return cyWorld:group(...)
    end

    function umg.view(...)
        --[[
            In the future, when empty-groups are supported,
            this will be what a view is.
            For now tho, we are just using `cyWorld:group`,
            since that has all the features.

            This basically just allows us to write future-proof mod code.
        ]]
        return cyWorld:group(...)
    end

    function umg.getEntity(id)
        return cyWorld:getEntity(id)
    end

    local defineEntityTypeTc = tc.assert(tc.string, tc.table)
    function umg.defineEntityType(etypeName, etypeTable)
        defineEntityTypeTc(etypeName, etypeTable)
        assertNamespaced(lobj, etypeName)
        assertIsLoading(lobj)
        return modLoader:bufferDefineEntityType(etypeName, etypeTable)
    end
end


---@param lobj LObj
local function addSerializers(umg, lobj)
    local modLoader = lobj.modLoader
    local umgSession = modLoader.umgSession
    local packer = umgSession.packer

    function umg.register(resource, alias)
        -- since string registration is used internally in the entity_add_remove
        -- files, we cannot allow users to fiddle with it.
        if type(resource) == "string" then
            error("Cannot register strings as a resource!")
        end
        if type(alias) ~= "string" then
            error("register(resource, alias) Expected string as 2nd argument, got: " .. type(alias))
        end
        assertNamespaced(lobj, alias)

        -- We prepend this to ensure no overlap with existing
        alias = constants.PCKR_API_REGISTER_PREFIX .. alias
        packer:register(resource, alias)
    end

    local function rebuildOptions(opts)
        if opts then
            local newOpts = {
                entityTypeFallbackHandler = opts.entityTypeFallbackHandler
            }

            -- FIXME: We ideally want to flip this around in the future such that
            -- resources registered using `umg.register` won't have "@" prefix
            -- while entity types are registered with "@" prefix.
            -- However, currently it's the other way around because resources
            -- registered using `umg.register` has "@" prefix while entity types
            -- doesn't.
            -- Mod doesn't aware of any "@" prefix so intercept if resource didn't
            -- start with "@" and pssthrough otherwise. Again, we want this to be
            -- the other way around in the future.
            if opts.resourceFallbackHandler then
                function newOpts.resourceFallbackHandler(name)
                    if name:sub(1, #constants.PCKR_API_REGISTER_PREFIX) == constants.PCKR_API_REGISTER_PREFIX then
                        return opts.resourceFallbackHandler(name:sub(#constants.PCKR_API_REGISTER_PREFIX + 1))
                    end

                    return nil
                end
            end

            return newOpts
        end

        return nil
    end

    local deserializeTc = tc.assert(tc.string, "table?")

    function umg.serialize(...)
        return packer:serializeStable(...)
    end

    function umg.deserialize(data, options)
        deserializeTc(data, options)
        return packer:deserializeStable(data, rebuildOptions(options))
    end

    function umg.serializeVolatile(...)
        return packer:serializeVolatile(...)
    end

    function umg.deserializeVolatile(data, options)
        deserializeTc(data, options)
        return packer:deserializeVolatile(data, rebuildOptions(options))
    end
end



local function addNetworkFuncs(umg, lobj)
    local connection = lobj.modLoader.connection

    function umg.definePacket(packetName, options)
        assertNamespaced(lobj, packetName)
        return connection:definePacket(packetName, options)
    end

    function umg.getClientInfo(clientId)
        return connection.clientToInfo[clientId]
    end
end




local function addLoaderFuncs(umg, lobj)
    local modLoader = lobj.modLoader
    function umg.isNamespaced(str)
        return lobj:isNamespaced(str)
    end

    function umg.getLoadingContext()
        -- could return extra stuff here in future...?
        return modLoader:getLoadingContext()
    end

    function umg.getModName()
        return lobj.modname
    end

    function umg.makeNamespacedString(modname, str)
        return modname..":"..str
    end

    function umg.splitNamespacedString(str)
        local modname, string = str:match("([^:]+):(.+)")
        if modname and string then
            return modname, string
        end

        error("invalid namespaced string '"..str.."'")
    end
end



local function addAnalytics(umg, lobj)
    umg.analytics = {}

    function umg.analytics.collect(name, contents)
        assertNamespaced(lobj, name)
        local ok, encodedStr = pcall(json.encode, contents)
        if ok then
            analyticsService.add(not not CLIENT_SIDE, name, encodedStr)
        else
            log.error("UNABLE TO ENCODE ANALYTICS JSON: ", encodedStr)
        end
    end
end



local function addAchievements(umg, lobj)
    umg.achievements = {}

    function umg.achievements.getAchievement(name)
        if not luasteam.CONNECTED then return false end
        local ok, val = luasteam.userStats.getAchievement(name)
        if ok then
            return (not not val)
        end
        return nil
    end

    function umg.achievements.unlockAchievement(name)
        if not luasteam.CONNECTED then return false end
        local ok, achievementStatus = luasteam.userStats.getAchievement(name)
        if ok and (not achievementStatus) then
            luasteam.userStats.setAchievement(name)
            luasteam.userStats.storeStats()
            return ok
        end
    end
end



local function make_umg(lobj)
    local umg = {}

    addEntityFunctions(umg, lobj)

    addSerializers(umg, lobj)

    addNetworkFuncs(umg, lobj)

    addLoaderFuncs(umg, lobj)

    addAnalytics(umg, lobj)

    addAchievements(umg, lobj)

    local buses = newBuses(lobj)
    umg.defineEvent = buses.defineEvent
    umg.isEventDefined = buses.isEventDefined
    umg.call = buses.call
    umg.rawcall = buses.rawcall
    umg.on = buses.on

    umg.defineQuestion = buses.defineQuestion
    umg.getQuestionReducer = buses.getQuestionReducer
    umg.ask = buses.ask
    umg.rawask = buses.rawask
    umg.answer = buses.answer

    -- TODO: Remove this function maybe?
    umg.inspect = require("libs.nm_inspect.inspect")

    local env = lobj.env

    umg.melt = error
    -- umg.melt exists purely for cultural reasons.

    local expose_tc = tc.assert("string")
    local modLoader = lobj.modLoader
    function umg.expose(variable_name, value)
        expose_tc(variable_name)
        if modLoader.globals[variable_name] or env[variable_name] then
            error("Attempted to overwrite exposed variable: " .. variable_name, 2)
        end
        env[variable_name] = value
        rawset(modLoader.globals, variable_name, value)
    end

    function umg.getModFilesystem()
        return newModFSysObj(lobj.fsysObj)
    end

    umg.log = require("src.common.log")

    if constants.DEV_MODE then
        umg.DEVELOPMENT_MODE = true
    end

    if constants.DEMO_MODE then
        umg.DEMO_MODE = true
    end

    return umg
end


return make_umg

