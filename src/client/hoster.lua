--[[

hoster is a module on clientside to handle the server_thread.

It holds HostContext, which is a struct that holds info about
the current host context.

]]

local reboot = require("src.client.misc.reboot")


assert(CLIENT_SIDE, "this shouldn't be ran on server")


local hoster = tools.SafeTable()



local ctx --[[
    ctx -> the current host context.

    The reason we keep it as global-state is because there can
    only be ONE server active at once.
    This is because UMG servers use a pre-defined local udp port,
    (also it's because Channel ids are global too.)

]]

local HostContext = tools.SafeClass()

function HostContext:init()
    self.thread = false
    self.launchOptions = false
    self.serverCrash = false
end





function hoster.dump_crash_reboot_config()
    --[[
        should be called if the program crashes.
        Basically we write launchOptions to a JSON file for easy reboot
    ]]
    if ctx then
        reboot.write_options(ctx.launchOptions)
    end
end


function hoster.start(launchOptions)
    --[[
        options table:

        .online = true/false  whether this server is online or not
        .modlist = {}  array of mods to use
        .save_name = "save_1" or nil      nil means use temp save.
        .online_mode = ONLINE_MODE
        .raw_port = 34545  (ie for port forwarding)
    ]]
    assert(launchOptions, "wot wot")
    log.info("[Server started]")
    if ctx then
        error("Server already running")
    end
    ctx = HostContext()
    
    channelService.resetChannels()

    channelService.provideServerInitOptions(launchOptions)
    ctx.launchOptions = launchOptions

    ctx.thread = love.thread.newThread("src/server/server_thread.lua")
    ctx.thread:start()
end





local function wait_until_closed()
    -- wait for thread to finish 
    local MAX_WAIT_TIME = 10 -- this amount of seconds seems reasonable.
    local wait_time = 0
    while ctx.thread and ctx.thread:isRunning() do
        if wait_time > MAX_WAIT_TIME then
            log.warn("Server thread didn't terminate!!!")
            break; -- well, shit.
        end
        channelService.executePrints()
        channelService.executeLogs()
        wait_time = wait_time + 0.1
        love.timer.sleep(0.1)
    end
end



local function closeServer()
    log.trace("Closing server...")
    wait_until_closed()
    ctx.thread = false
    log.trace("Server closed.")
end


function hoster.close()
    log.trace("hoster.close()")
    if not ctx then return end
    channelService.closeServer()
    closeServer()
    hoster.update()
    ctx = false
end


function hoster.saveAndClose()
    log.trace("hoster.saveAndClose()")
    if not ctx then return end
    ctx = false
    channelService.closeServer()
    closeServer()
end




function hoster.threaderror(_, errorstr)
    channelService.executePrints()
    channelService.executeLogs()
    if ctx then
        ctx.serverCrash = true
    end
    error("Server error:\n" .. errorstr)
end




function hoster.update()
    channelService.executePrints()
    channelService.executeLogs()
end


function hoster.isHosting()
    return not not ctx
end


function hoster.isServerCrashed()
    return not not (ctx and ctx.serverCrash)
end


return hoster

