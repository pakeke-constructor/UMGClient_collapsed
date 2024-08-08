


local path = tools.path(...)

local Button = require("src.client.ui.elements.Button")
local PixelButton = require("lootplot.elements.PixelButton")

local LaunchOptions = require("src.common.misc.LaunchOptions")

local PhysicsWorldScreen = require(path .. ".physics_background")

local HosterSetup = require("src.client.state.setup.HosterSetup")
local SettingState = require("lootplot.states.SettingState")

local lg = love.graphics


local Host = StateClass()

love.filesystem.setIdentity("lootplot")




local PHYSICS_WORLD_WIDTH, PHYSICS_WORLD_HEIGHT = 360, 180


local function getModsInSaveDirectory()
    local result = {}

    for _, mod in ipairs(love.filesystem.getDirectoryItems("mods")) do
        if mod:sub(1, 1) ~= "_" and mod:sub(1, 1) ~= "." then
            if love.filesystem.getInfo("mods/"..mod, "directory") then
                result[#result+1] = "/"..mod
            end
        end
    end

    return result
end


local function startHost(self)
    --[[
        starts hosting a server with test mod loaded
    ]]
    local modlist = getModsInSaveDirectory()
    modlist[#modlist+1] = "lootplot.bundle.s0"

    local launchOptions = LaunchOptions({
        modlist = modlist,
        onlineMode = "offline",
    })
    local hosterSetupState = HosterSetup(launchOptions)
    self:push(hosterSetupState)
end


local function getScreenView()
    return 0,0,lg.getDimensions()
end


function Host:init()
    self.physicsTransform = love.math.newTransform()
    self.doNotFree = false
    self.settingState = SettingState()

    -- LUI always consumes our inputs while we only want it
    -- to be consumed if the children really consume it.
    -- So make everything a root element for now.
    self.discordButton = Button({
        image = love.graphics.newImage("lootplot/assets/ui/modified_discord_logo.png"),
        onClick = function()
            love.system.openURL(constants.DISCORD_LINK)
        end
    })
    self.wishlistButton = PixelButton({
        color = "green",
        text = "Wishlist!",
        onClick = function()
            print("Wishlist link goes here")
        end
    })
    self.settingButton = Button({
        image = love.graphics.newImage("lootplot/assets/ui/settings.png"),
        onClick = function()
            return self:_gotoSettings()
        end
    })
    self.discordButton:makeRoot()
    self.wishlistButton:makeRoot()
    self.settingButton:makeRoot()
end

function Host:_performLUIButtonsPress(...)
    return
        self.discordButton:mousepressed(...) or
        self.wishlistButton:mousepressed(...) or
        self.settingButton:mousepressed(...)
end

function Host:_performLUIButtonsRelease(...)
    self.discordButton:mousereleased(...)
    self.wishlistButton:mousereleased(...)
    self.settingButton:mousereleased(...)
end

-- Since we're making all the button a root element, we have to render them ourselves.
function Host:_performLUIRender(x, y, w, h)
    local region = Region(x, y, w, h)
    local footer = select(2, region:splitVertical(8, 1))
    local fx, fy, fw, fh = footer:get()

    -- Uh this is ugly. We have to compute the position ourself.
    -- Unfortunately Kirigami doesn't offer a way to position element based on
    -- other position of an existing elements.
    local wishlistButton = Region(0, 0, 70, 18):scaleToFit(footer)
    self.wishlistButton:render(fx + 10, fy - 10, select(3, wishlistButton:get()))

    do
        local discordButton = Region(0, 0, 26, 26):scaleToFit(footer)
        local wh = select(4, wishlistButton:get())
        self.discordButton:render(fx + 10, fy - wh - 15, select(3, discordButton:get()))
    end

    do
        local settingsButton = Region(0, 0, 26, 26):scaleToFit(footer)
        local sw, sh = select(3, settingsButton:get())
        self.settingButton:render(fx + fw - sw - 10, fy - 10, sw, sh)
    end
end

function Host:_gotoSettings()
    self.doNotFree = true
    self:push(self.settingState)
end

function Host:_updatePhysicsTransform()
    local x, y, w, h = getScreenView()
    -- Physics world center is (0, 0)
    -- But also we want to scale it to match the screen itself
    local sx = w / PHYSICS_WORLD_WIDTH
    local sy = h / PHYSICS_WORLD_HEIGHT
    local s = math.max(sx, sy)
    self.physicsTransform:reset()
    self.physicsTransform:translate(w/2, h/2)
    self.physicsTransform:scale(s, s)
end

function Host:_setup()
    if not self.physicsWorld then
        self.physicsWorld = PhysicsWorldScreen(PHYSICS_WORLD_WIDTH, PHYSICS_WORLD_HEIGHT)
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
    self.doNotFree = false
end

function Host:_free()
    if not self.doNotFree then
        self.physicsWorld = nil
    end
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
    love.graphics.clear(love.math.colorFromBytes(151, 246, 247))

    -- Draw physics
    if self.physicsWorld then
        love.graphics.push()
        love.graphics.applyTransform(self.physicsTransform)
        self.physicsWorld:draw()
        love.graphics.pop()
    end

    self:_performLUIRender(0, 0, love.graphics.getDimensions())
end)

Host:on("resize", function(self, w, h)
    self:_updatePhysicsTransform()
end)

Host:on("mousepressed", function(self, x, y, b)
    if not self:_performLUIButtonsPress(x, y, b) then
        if b == 1 then
            self.physicsWorld:click(self.physicsTransform:inverseTransformPoint(x, y))
        end
    end
end)

Host:on("mousereleased", function(self, x, y, b)
    self:_performLUIButtonsRelease(x, y, b)
end)

Host:on("keypressed", function(self, x, y, b)
    if x == "r" then
        self:_free()
        self:_setup()
    end
end)

return Host

