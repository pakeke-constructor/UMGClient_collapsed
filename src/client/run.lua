

--[[

This file handles the love.run loop.

The main reason we need this is so we can restart upon error.


Question:  Why aren't we using love2d's errorhandler for this?
A: Because you can't call love.event.quit("restart") from the errorhandler.

So in this file, we are kinda rolling our own love.run setup that
handles errors and restarting for us.


]]

local constants = require("src.common.constants")
local utf8 = require("utf8")

local hoster = require("src.client.hoster")
local analyticsService = require("src.common.analytics.analytics_service")


local function dbgcall(f, ...)
    local ok, er = pcall(f, ...)
    if not ok then
        log.error("dbgcall failed: ", er)
    end
end

function love.quit()
    -- we gotta ensure that threads are closed, before quit,
    -- so we call hoster.close() here, which blocks.
    dbgcall(function()
        hoster.close()
    end)
    analyticsService.quit()
end





--[[
    A lot of this code is adapted from Love's source code.
    (specifically, love.run)

    Original love.run taken from commit hash:  e559fd5e
]]


-- its OK to keep global state here, because the lua_State
-- resets fully when we restart.  (i.e. this file will be reloaded)
local loop
local errmsg





local draw_error
do
local BORDER = 100


local function sanitize_message(msg)
	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)
    if #sanitizedmsg ~= #msg then
        return "Invalid UTF-8 string in error message"
    end
    return sanitize_message
end



function draw_error()
    love.graphics.origin()
    love.graphics.setColor(1,1,1)
    local w = love.graphics.getWidth()
    local font = love.graphics.getFont()
    local h = font:getHeight()
    local h2 = h*2
    love.graphics.clear(0,0,0)
    love.graphics.setColor(0.6,0.6,1)
    
    local height = 15
    love.graphics.printf("THE MELT ZONE", 0, height, w / 2, "center", 0, 2, 2)
    love.graphics.printf("There has been a melt! (This is normal)", 0, height + h2, w / 2, "center", 0, 2, 2)
    love.graphics.printf("Press R to restart in offline mode.", 0, height + 2*h2, w / 2, "center", 0, 2, 2)

    love.graphics.setColor(0,0.8,0)
    love.graphics.printf(errmsg, BORDER, BORDER + 3*h2, w)
    love.graphics.present()
end

end


local function copy_to_clipboard()
    love.system.setClipboardText(errmsg)
end


local function crash_restart()
    -- Called when we want to quick restart on crash
    -- TODO: We should use `love.event.quit("restart", value)` + `love.restart` variable.
    dbgcall(hoster.dump_crash_reboot_config)
    love.event.quit("restart")
end


local function errorloop()
    -- process events:
    love.event.pump()
    for name, a, b, c in love.event.poll() do
        if name == "quit" then
            if not love.quit or not love.quit() then
                return a or 0
            end
        elseif name == "keypressed" then
            local key = a
            if key == "r" then
                crash_restart()
            elseif key == "escape" then
                return 0
            elseif key == "c" and love.keyboard.isDown("lctrl", "rctrl") then
                copy_to_clipboard()
            end
        end
    end

    draw_error()

    if love.timer then
        love.timer.sleep(0.01)
    end
end




local function parse_error_msg(msg, trace)
    --[[
        gets the error message in a string readable format.
    ]]
	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)
 
	local err = {}
    
	table.insert(err, sanitizedmsg)
 
	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end
 
	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")
 
	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

    return p
end


local error_occured = false

local function handle_error(msg)
    -- dump the error messages, do some preparation,
    -- and switch to the errorloop
    error_occured = true
	love.graphics.setFont(love.graphics.newFont(14))

    local trace = debug.traceback(msg)
    errmsg = parse_error_msg(msg, trace)

    print(errmsg)

    if love.audio then
        love.audio.stop()
    end

    if not hoster.isServerCrashed() then
        analyticsService.add(true, "@crash", json.encode({message = trace}))
    end
    analyticsService.forceFlush()

    loop = errorloop
end


local function safe_call(func, a,b,c,d,e,f)
    if func and (not error_occured) then
        xpcall(func, handle_error, a,b,c,d,e,f)
    end
end


--[[
    adapted from love2d default love.run
]]
local function mainloop()
    local dt = 0

    -- Process events.
    love.event.pump()
    for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
            if not love.quit or not love.quit() then
                return a or 0
            end
        end

        safe_call(love.handlers[name], a,b,c,d,e,f)
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then dt = love.timer.step() end

    -- Call update and draw
    safe_call(love.update, dt)

    if love.graphics and love.graphics.isActive() then
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())

        safe_call(love.draw)

        love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.001) end
end




function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

    loop = mainloop
    return function()
        return loop()
    end
end

