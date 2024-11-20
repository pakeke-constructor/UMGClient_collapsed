

--[[

This file handles the love.run and the custom love.errorhandler loop.

]]

local utf8 = require("utf8")

local hoster = require("src.client.hoster")
local analyticsService = require("src.common.analytics.analytics_service")
local saveService = require("src.common.save.save_service")


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
    analyticsService.quit(false)
    saveService.getClientDataSave():close()
end





--[[
    A lot of this code is adapted from Love's source code.
    (specifically, love.run)

    Original love.run taken from commit hash:  e559fd5e
]]


-- its OK to keep global state here, because the lua_State
-- resets fully when we restart.  (i.e. this file will be reloaded)
local canvas, prevCanvas, blurredCanvas




local BORDER = 100


local blur = [[
extern vec2 resolution;
extern vec2 dir;

// https://github.com/Experience-Monks/glsl-fast-gaussian-blur
vec4 effect(vec4 c, Image image, vec2 uv, vec2 sc)
{
    vec4 color = vec4(0.0);
    vec2 off1 = vec2(1.3846153846) * dir;
    vec2 off2 = vec2(3.2307692308) * dir;
    color += Texel(image, uv) * 0.2270270270;
    color += Texel(image, uv + (off1 / resolution)) * 0.3162162162;
    color += Texel(image, uv - (off1 / resolution)) * 0.3162162162;
    color += Texel(image, uv + (off2 / resolution)) * 0.0702702703;
    color += Texel(image, uv - (off2 / resolution)) * 0.0702702703;
    return vec4(color.rgb, 1.0) * c;
}
]]

local function drawBlur(s, func, ...)
    local canvas1 = love.graphics.newCanvas()
    local canvas2 = love.graphics.newCanvas()
    local shader = love.graphics.newShader(blur)

    love.graphics.push("all")
    love.graphics.reset()
    love.graphics.setCanvas(canvas1)
    love.graphics.clear(0, 0, 0, 0)
    func(...)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setShader(shader)
    shader:send("resolution", {love.graphics.getPixelDimensions()})

    while s > 0 do
        local ms = math.min(s, 1)
        love.graphics.setCanvas(canvas2)
        love.graphics.clear(0, 0, 0, 0)
        shader:send("dir", {ms, 0})
        love.graphics.draw(canvas1)
        love.graphics.setCanvas(canvas1)
        love.graphics.clear(0, 0, 0, 0)
        shader:send("dir", {0, ms})
        love.graphics.draw(canvas2)
        s = s - 1
    end

    love.graphics.pop()
    canvas2:release()
    return canvas1
end



local function crash_restart()
    -- Called when we want to quick restart on crash
    -- TODO: We should use `love.event.quit("restart", value)` + `love.restart` variable.
    dbgcall(hoster.dump_crash_reboot_config)
    love.event.quit("restart")
    analyticsService.quit(true)
end


function love.errorhandler(msg)
    msg = tostring(msg)

    local bt = debug.traceback(msg)
    log.error(bt)
    if not hoster.isServerCrashed() then
        analyticsService.add(true, "@crash", json.encode({message = bt}))
    end
    analyticsService.forceFlush()

    if not love.window or not love.graphics or not love.event then
        return
    end

    if not love.graphics.isCreated() or not love.window.isOpen() then
        local success, status = pcall(love.window.setMode, 800, 600)
        if not success or not status then
            return
        end
    end

    -- Reset state.
    if love.mouse then
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
        love.mouse.setRelativeMode(false)
        if love.mouse.isCursorSupported() then
            love.mouse.setCursor()
        end
    end
    if love.joystick then
        -- Stop all joystick vibrations.
        for i,v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration()
        end
    end
    if love.audio then love.audio.stop() end

    love.graphics.reset()
    local f = love.graphics.newFont(15)
    f:setFilter("linear", "linear")
    love.graphics.setFont(f)

    love.graphics.setColor(1, 1, 1)

    local trace = debug.traceback()

    love.graphics.origin()

    local sanitizedmsg = {}
    for char in msg:gmatch(utf8.charpattern) do
        table.insert(sanitizedmsg, char)
    end
    sanitizedmsg = table.concat(sanitizedmsg)

    local err = {}

    table.insert(err, "Error\n")
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

    local function draw()
        if not love.graphics.isActive() then return end

        -- Setup canvas
        if canvas and not blurredCanvas then
            blurredCanvas = drawBlur(8, love.graphics.draw, prevCanvas)
            canvas:release()
        end

        love.graphics.origin()
        love.graphics.setColor(1,1,1)
        local w = love.graphics.getWidth()
        local font = love.graphics.getFont()
        local h = font:getHeight()
        local h2 = h*2
        love.graphics.clear(0,0,0)
        if blurredCanvas then
            local gh = love.graphics.getHeight()
            local cw, ch = blurredCanvas:getDimensions()
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.draw(blurredCanvas, 0, 0, 0, w / cw, gh / ch)
        end
        love.graphics.setColor(0.6,0.6,1)

        local height = 15
        love.graphics.printf("THE MELT ZONE", 0, height, w / 2, "center", 0, 2, 2)
        love.graphics.printf("There has been a melt! (This is normal)", 0, height + h2, w / 2, "center", 0, 2, 2)
        love.graphics.printf("Press Ctrl+C to copy error message.", 0, height + 2*h2, w / 2, "center", 0, 2, 2)
        love.graphics.printf("Press R to restart in offline mode.", 0, height + 3*h2, w / 2, "center", 0, 2, 2)

        love.graphics.setColor(0,0.8,0)
        love.graphics.printf(p, BORDER, BORDER + 3*h2, w)
        love.graphics.present()
    end

    local fullErrorText = p
    local function copyToClipboard()
        if not love.system then return end
        love.system.setClipboardText(fullErrorText)
        p = p .. "\nCopied to clipboard!"
    end

    if love.system then
        p = p .. "\n\nPress Ctrl+C or tap to copy this error"
    end

    local function isCtrlCPressed(a)
        return
            (a == "c" and love.keyboard.isDown("lctrl", "rctrl")) or
            ((a == "lctrl" or a == "rctrl") and love.keyboard.isDown("c"))
    end

    return function()
        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" then
                return a or 1, b
            elseif e == "keypressed" then
                if isCtrlCPressed(a) then
                    copyToClipboard()
                elseif a == "escape" then
                    return 1
                elseif a == "r" then
                    crash_restart()
                end
            elseif e == "touchpressed" then
                local name = love.window.getTitle()
                if #name == 0 or name == "Untitled" then name = "Game" end
                local buttons = {"OK", "Cancel"}
                if love.system then
                    buttons[3] = "Copy to clipboard"
                end
                local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
                if pressed == 1 then
                    return 1
                elseif pressed == 3 then
                    copyToClipboard()
                end
            end
        end

        draw()

        if love.timer then
            love.timer.sleep(0.1)
        end
    end
end

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    return function()
        local dt = 0

        -- Process events.
        love.event.pump()
        for name, a,b,c,d,e,f in love.event.poll() do
            if name == "quit" then
                if not love.quit or not love.quit() then
                    return a or 0, b
                end
            elseif name == "resize" and canvas then
                prevCanvas:release()
                canvas:release()
                canvas = nil
                prevCanvas = nil
            end

            love.handlers[name](a,b,c,d,e,f)
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- Call update and draw
        love.update(dt)

        if love.graphics and love.graphics.isActive() then
            if not canvas then
                canvas = love.graphics.newCanvas()
                prevCanvas = love.graphics.newCanvas()
                canvas:setFilter("linear", "linear")
                prevCanvas:setFilter("linear", "linear")
            end

            love.graphics.push("all")
            love.graphics.setCanvas(canvas)
            love.graphics.clear(love.graphics.getBackgroundColor())

            love.graphics.push("all")
            love.draw()
            love.graphics.pop()

            love.graphics.setCanvas()
            love.graphics.setBlendMode("none")
            love.graphics.draw(canvas)
            love.graphics.pop()
            love.graphics.present()

            prevCanvas, canvas = canvas, prevCanvas
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end

