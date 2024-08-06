
--[[

====================
SetupPipeline object.

 SETUP PIPELINE SUMMARY:
====================

Client -> Server: sends ConnectJson

Server -> Client: sends box @accept_client

Request/receive mods 
    download mods if needed

Load mods

Request/receive world data
Load world


]]


local hoster = require("src.client.hoster")


local SetupPipeline = tools.SafeClass()



local function setListener(self, l)
    local connObj = self.ingameSession.clientConnection
    connObj:setListener(l)
end



local function loadMods(self)
    local modlist = self.ingameOptions.modlist
    self.ingameSession:loadMods(modlist)
end





local function done(self)
    setListener(self, self.mainListener)
    local connObj = self.ingameSession.clientConnection
    connObj:send(tools.EMPTY, "@ready_to_play")
    self.onSuccess()
end


local function fail(self)
    local connObj = self.ingameSession.clientConnection
    local emptyListener = connObj:newListener()
    -- set to an empty listener.
    setListener(self, emptyListener)
    self.onFail()
end




local function setupListeners(self)
    local ingameSession = self.ingameSession
    local umgSession = ingameSession.umgSession
    local connObj = ingameSession.clientConnection
    
    connObj:setListener(self.setupListener)
    -- isolate the listener so its cleaner

    connObj:onConnect(function()
        local knowsMods = self.ingameOptions.modlist
        if not knowsMods then
            error("Dynamic mod downloading is NYI; must pass in modlist")
        end

        -- ok, we have received cache; time to load mods:
        setListener(self, self.mainListener)
        -- set to the main listener, so the mods can do their thing.
        -- In the future, use an AsyncTask for this
        loadMods(self)
        setListener(self, self.setupListener)

        -- Now, request world:
        log.trace("Requesting world...")
        connObj:send(false,"@gimme_world")
    end)

    connObj:onDeny(function(reason_str)
        if self.isHosting then
            log.error("Server denied access to localhost client: ", reason_str)
            hoster.close()
        else
            log.warn("Server denied access: " .. tostring(reason_str))
        end
        fail(self)
    end)

    connObj:on("@world", function(pckr_data)
        log.trace("Received world pckr data, with size: ", #pckr_data)
        umgSession:deserializeWorld(pckr_data)

        umgSession.eventBus:call("@load")
        done(self)
    end)
end




function SetupPipeline:init(args)
    --[[
        args = {
            ingameSession = IngameSession(),
            onSuccess = onSuccess,
            onFail = onFail,
            onDisconnect = onDisconnect
        }
    ]]
    self.ingameSession = args.ingameSession
    self.ingameOptions = args.ingameSession.ingameOptions
    self.isHosting = self.ingameOptions.isHosting

    local connObj = self.ingameSession.clientConnection
    self.mainListener = connObj:getCurrentListener()
    self.setupListener = connObj:newListener()

    self.onSuccess = args.onSuccess
    self.onFail = args.onFail
    self.onDisconnect = args.onDisconnect

    setupListeners(self)
end


function SetupPipeline:start()
    log.trace("Starting SetupPipeline")
    local connObj = self.ingameSession.clientConnection
    connObj:connect()
end


return SetupPipeline

