
--[[

Ingame-state:

The state for where the game is actually being played

]]


local path = tools.path(...)

local Settings = require(path .. ".settings.settings")

local hoster = require("src.client.hoster")




local Ingame = StateClass()



function Ingame:init(ingameSession)
    self.ingameSession = ingameSession
    self.umgSession = ingameSession.umgSession
    self.eventBus = self.umgSession.eventBus

    variables.ingame_paused = false

    -- -- these fields are only set if we are hosting:
    -- settings_ui.is_hosting = is_hosting
end

function Ingame:onEnter(ingameSession)
end




Ingame:on("update", function(self, dt)
    self.ingameSession:update(dt)

    if self.ingameSession:shouldQuit() then
        self.umgSession.eventBus:call("@quit")
        self:pop()
    end
end)



function Ingame:onExit()
    if hoster.isHosting() then
        hoster.close()
    end

    -- HACK: If this is the root of the state, exit immediately
    if self:getRoot() == self then
        love.event.quit()
    end
end




local function onQuit()
    hoster.close()
end

local function onSaveQuit()
    hoster.saveAndClose()
end




local function on_reload()
    error([[
        TODO: 
        how about we create a new state, `reload_state`,
        and push that state onto the stack....?
        Do some thinking.
    ]])
end



local function draw_settings()
    love.graphics.push("all")
    love.graphics.setColor(0.2,0.2,0.2,0.7)
    love.graphics.rectangle("fill", -10, -10, 100000, 100000)
    love.graphics.setColor(1,1,1)
    -- settings_ui:draw()
    love.graphics.pop()
end


local serv_mem = nil
local graphics_state = {}
local renderinfo = nil
local function draw_nerd_stats()
    if not renderinfo then
        renderinfo = table.concat({love.graphics.getRendererInfo()}, " ")
    end
    local mem = channelService.getMemoryUsage()

    local client_mem = math.floor(collectgarbage("count") / 100) / 10
    if mem then
        serv_mem = math.floor(mem / 100) / 10
    end
    love.graphics.push()
    local stats = love.graphics.getStats(graphics_state)
    love.graphics.setColor(0.1,0.1,0.1, 0.6)
    love.graphics.rectangle("fill", 0,0, 240, 62)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(renderinfo, 2, 2)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.print("clnt (MB):" .. client_mem, 2, 12)
    love.graphics.setColor(0.8,0.2,0.2,1)
    love.graphics.print("serv (MB):" .. tostring(serv_mem), 2, 22)
    love.graphics.setColor(0.6,0.6,0.8)
    love.graphics.print("clnt fps: " .. tostring(love.timer.getFPS()), 2, 32)
    love.graphics.print("drawcall: "..stats.drawcalls.." ("..stats.drawcallsbatched.." b)", 2, 42)
    love.graphics.pop()
end


Ingame:on("draw", function(self)
    self.ingameSession:draw()

    if variables.show_ingame_nerd_stats then
        draw_nerd_stats()
    end
end)


local function togglePause(self)
    
end



Ingame:on("keypressed", function(self, key,scancode,c,d,e,f)
    if scancode == "escape" then
        togglePause(self)
    elseif scancode == "f3" then
        variables.show_ingame_nerd_stats = not variables.show_ingame_nerd_stats
    end
    self.eventBus:call("@keypressed",key,scancode,c,d,e,f)        
end)


Ingame:on("keyreleased", function(self, a,b,c,d,e,f)
    if b == "return" and love.keyboard.isScancodeDown("lalt", "ralt") then
        love.window.setFullscreen(not love.window.getFullscreen())
    end

    self.eventBus:call("@keyreleased", a,b,c,d,e,f)
end)

Ingame:on("textinput", function(self, a,b,c,d,e,f)
    self.eventBus:call("@textinput", a,b,c,d,e,f)
end)

Ingame:on("mousepressed", function(self, a,b,c,d,e,f)
    self.eventBus:call("@mousepressed", a,b,c,d,e,f)
end)

Ingame:on("mousereleased", function(self, a,b,c,d,e,f)
    self.eventBus:call("@mousereleased", a,b,c,d,e,f)
end)

Ingame:on("mousemoved", function(self, a,b,c,d,e,f)
    self.eventBus:call("@mousemoved", a,b,c,d,e,f)
end)

Ingame:on("wheelmoved", function(self, a,b,c,d,e,f)
    self.eventBus:call("@wheelmoved", a,b,c,d,e,f)
end)


Ingame:on("resize", function(self, x,y)
    self.eventBus:call("@resize", x,y)
end)



return Ingame

