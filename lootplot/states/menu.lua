

local ui = require("src.client.ui.ui")

local path = tools.path(...)


local LaunchOptions = require("src.common.misc.LaunchOptions")

local MenuElement = require(path .. ".MenuElement")
local PhysicsWorldScreen = require(path .. ".physics_background")
local helper = require("src.client.state.helper")

local HosterSetup = require("src.client.state.setup.HosterSetup")

local lg = love.graphics


local Host = StateClass()


local WORLD_WIDTH, WORLD_HEIGHT = 400, 300


local function startHost(self)
    --[[
        starts hosting a server with test mod loaded
    ]]
    local launchOptions = LaunchOptions({
        modlist = {"lootplot.main"},
        onlineMode = "offline",
    })
    local hosterSetupState = HosterSetup(launchOptions)
    self:push(hosterSetupState)
end


local function getScreenView()
    return 0,0,lg.getDimensions()
end


function Host:init()
    -- self.menuElement = MenuElement({
    --     onPlay = function()
    --         startHost(self)
    --     end
    -- })
    self.physicsTransform = love.math.newTransform()
    -- helper.injectInput(self, self.menuElement)
end

function Host:_updatePhysicsTransform()
    local x, y, w, h = getScreenView()
    -- Physics world center is (0, 0)
    -- But also we want to scale it to match the screen itself
    local sx = w / WORLD_WIDTH
    local sy = h / WORLD_HEIGHT
    local s = math.max(sx, sy)
    self.physicsTransform:reset()
    self.physicsTransform:translate(w/2, h/2)
    self.physicsTransform:scale(s, s)
end

function Host:_setup()
    self.physicsWorld = PhysicsWorldScreen(WORLD_WIDTH, WORLD_HEIGHT)
    self.physicsWorld:addButton({
        x = 0, y = 0,
        text = "Play",
        image = "src/client/ui/images/big_buttons/blue_big.png",
        onClick = function()
            startHost(self)
        end
    })
    self:_updatePhysicsTransform()
end

function Host:_free()
    self.physicsWorld = nil
end
Host.onEnter = Host._setup
Host.onExit = Host._free
Host.onWakeup = Host._setup
Host.onSuspend = Host._free

Host:on("update", function(self, dt)
    if self.physicsWorld then
        self.physicsWorld:update(dt)
    end
end)

Host:on("draw", function(self)
    local x, y, w, h = getScreenView()
    love.graphics.clear(love.math.colorFromBytes(151, 246, 247))

    -- Draw physics
    if self.physicsWorld then
        love.graphics.push()
        love.graphics.applyTransform(self.physicsTransform)
        self.physicsWorld:draw()
        love.graphics.pop()
    end

    --self.menuElement:render(x, y, w, h)
end)

Host:on("resize", function(self, w, h)
    self:_updatePhysicsTransform()
end)

Host:on("mousereleased", function(self, x, y, b)
    if b == 1 then
        self.physicsWorld:click(self.physicsTransform:inverseTransformPoint(x, y))
    end
end)

Host:on("keypressed", function(self, x, y, b)
    if x == "r" then
        self:_free()
        self:_setup()
    end
end)

return Host

