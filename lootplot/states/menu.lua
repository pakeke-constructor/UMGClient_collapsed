
local Button = require("src.client.ui.elements.Button")
local StretchableButton = require("lootplot.elements.StretchableButton")

local LaunchOptions = require("src.common.misc.LaunchOptions")

local PhysicsBackground = require("lootplot.states.PhysicsBackground2")

local HosterSetup = require("src.client.state.setup.HosterSetup")
local AnalyticsPopupState = require("lootplot.states.AnalyticsPopupState")
local SettingState = require("lootplot.states.SettingState")
local CreditsState = require("lootplot.states.CreditsState")

local LoadingVisual = require("lootplot.states.LoadingVisual")
local TransitionState = require("lootplot.states.TransitionState")

local COMMON_COLOR = require("lootplot.common_color")
local sfx = require("lootplot.sfx")
local globalScale = require("lootplot.globalScale")

local analyticsService = require("src.common.analytics.analytics_service")

local lg = love.graphics

local windowIcon = love.image.newImageData("lootplot/assets/window_icon.png")
love.window.setIcon(windowIcon)


---@class MenuState: State
local MenuState = StateClass()





local PERSISTENT_SAVE_NAME = "save1"


local function getModsInSaveDirectory()
    assert(love.filesystem.getIdentity() == "lootplot")
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


---@param self MenuState
local function startHost(self)
    --[[
        starts hosting a server with test mod loaded
    ]]
    local modlist = getModsInSaveDirectory()
    modlist[#modlist+1] = "lootplot.s0.bundle"

    local launchOptions = LaunchOptions({
        modlist = modlist,
        onlineMode = "offline",
        save_name = PERSISTENT_SAVE_NAME
    })
    local hosterSetupState = HosterSetup(launchOptions, LoadingVisual(self.physicsWorld:getAtlasAndItemQuads()))

    -- Setup analytics
    local steamid = "0"
    if luasteam.CONNECTED then
        steamid = tostring(luasteam.user.getSteamID())
    end

    if userService.isUserConsentedForAnalytics() then
        analyticsService.configure(steamid)
    end

    self:push(TransitionState(hosterSetupState, 0.15, true))
end


local LOOTPLOT_WISHLIST_LINK = "https://store.steampowered.com/app/3057190/LOOTPLOT/"


function MenuState:init()
    self.physicsTransform = love.math.newTransform()
    self.doNotFree = false

    self.settingState = SettingState()
    self.creditsState = CreditsState()

    self.playButton = StretchableButton({
        color = COMMON_COLOR.BLUE,
        text = "Play!",
        scale = 2,
        onClick = function()
            self.doNotFree = true
            sfx.click()
            startHost(self)
        end
    })
    self.discordButton = Button({
        image = love.graphics.newImage("lootplot/assets/ui/modified_discord_logo.png"),
        onClick = function()
            sfx.click()
            love.system.openURL(constants.DISCORD_LINK)
        end
    })
    self.creditsButton = StretchableButton({
        color = COMMON_COLOR.RED,
        text = "Credits",
        scale = 2,
        onClick = function()
            sfx.click()
            self:_openCredits()
        end
    })
    self.wishlistButton = StretchableButton({
        color = COMMON_COLOR.GREEN,
        text = "Wishlist!",
        scale = 2,
        onClick = function()
            sfx.click()
            love.system.openURL(LOOTPLOT_WISHLIST_LINK)
        end
    })
    self.settingButton = Button({
        image = love.graphics.newImage("lootplot/assets/ui/settings.png"),
        onClick = function()
            sfx.click()
            return self:_gotoSettings()
        end
    })

    self.logo = love.graphics.newImage("lootplot/assets/LOGO_PIXELATED.png")

    -- LUI always consumes our inputs while we only want it
    -- to be consumed if the children really consume it.
    -- So make everything a root element for now.
    self.playButton:makeRoot()
    self.discordButton:makeRoot()
    self.creditsButton:makeRoot()
    self.wishlistButton:makeRoot()
    self.settingButton:makeRoot()
end

function MenuState:_performLUIButtonsPress(...)
    return
        self.playButton:mousepressed(...) or
        self.discordButton:mousepressed(...) or
        self.wishlistButton:mousepressed(...) or
        self.settingButton:mousepressed(...) or
        self.creditsButton:mousepressed(...)
end

function MenuState:_performLUIButtonsRelease(...)
    self.playButton:mousereleased(...)
    self.discordButton:mousereleased(...)
    self.wishlistButton:mousereleased(...)
    self.settingButton:mousereleased(...)
    self.creditsButton:mousereleased(...)
end

-- Since we're making all the button a root element, we have to render them ourselves.
function MenuState:_performLUIRender(x, y, w, h)
    local s = globalScale.get() * 2
    local region = Region(x, y, w, h)

    local titleLogo, playbuttonBase = region:splitVertical(3, 2)
    local playButton = Region(0, 0, 100 * s, 30 * s)
        :centerX(playbuttonBase)
        :attachToTopOf(playbuttonBase)
        :moveRatio(0, 1)
    local creditsButton = Region(0, 0, 70 * s, 18 * s)
        :attachToLeftOf(region)
        :attachToBottomOf(region)
        :moveRatio(1, -1)
        :moveUnit(10, -10)
    -- Where 70, 18 comes from?
    local wishlistButton = Region(0, 0, 70 * s, 18 * s)
        :attachToLeftOf(region)
        :attachToTopOf(creditsButton)
        :moveRatio(1, 0)
        :moveUnit(10, -10)
    -- Where 26 comes from? Icon dimension
    local discordButton = Region(0, 0, 26 * s, 26 * s)
        :attachToTopOf(wishlistButton)
        :attachToLeftOf(region)
        :moveRatio(1, 0)
        :moveUnit(10, -10)
    -- Where 32 comes from? Icon dimension
    local settingButton = Region(0, 0, 32 * s, 32 * s)
        :attachToBottomOf(region)
        :attachToRightOf(region)
        :moveRatio(-1, -1)
        :moveUnit(-10, -10)

    self.playButton:render(playButton:get())
    self.creditsButton:render(creditsButton:get())
    self.wishlistButton:render(wishlistButton:get())
    self.discordButton:render(discordButton:get())
    self.settingButton:render(settingButton:get())

    -- Render logo
    local lw, lh = self.logo:getDimensions()
    local cx, cy = titleLogo:getCenter()
    cy = cy + 7 * math.sin(love.timer.getTime() % 5 / 5 * 2 * math.pi)
    love.graphics.draw(self.logo, cx, cy, 0, s * 0.75, s * 0.75, lw / 2, lh / 2)
end

function MenuState:_gotoSettings()
    self.doNotFree = true
    self:push(self.settingState)
end

function MenuState:_openCredits()
    self.doNotFree = true
    self:push(self.creditsState)
end

function MenuState:_showConsent()
    self.doNotFree = true
    self:push(AnalyticsPopupState(true))
end

function MenuState:_updatePhysicsTransform()
    local w, h = love.graphics.getDimensions()
    local s = globalScale.get() * 2
    -- Physics world center is (0, 0)
    self.physicsTransform:reset()
    self.physicsTransform:translate(w/2, h/2)
    self.physicsTransform:scale(s, s)
end

function MenuState:onEnter()
    if not self.physicsWorld then
        self:_updatePhysicsTransform()
        self.physicsWorld = PhysicsBackground(self.physicsTransform)
    end
    self.doNotFree = false

    if not userService.isAnalyticsConsentAsked() then
        self:_showConsent()
    end
end

function MenuState:onExit()
    if not self.doNotFree then
        self.physicsWorld = nil
    end
end


---@param dt number
MenuState:on("update", function(self, dt)
    if self.physicsWorld then
        self.physicsWorld:update(dt, self.physicsTransform)
    end
end)

MenuState:on("draw", function(self)
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

MenuState:on("resize", function(self, w, h)
    self:_updatePhysicsTransform()
end)

MenuState:on("mousepressed", function(self, x, y, b)
    if not self:_performLUIButtonsPress(x, y, b) then
        local xx, yy = self.physicsTransform:inverseTransformPoint(x, y)
        self.physicsWorld:mousepressed(xx, yy, b)
    end
end)

MenuState:on("mousereleased", function(self, x, y, b)
    self:_performLUIButtonsRelease(x, y, b)
end)

---@param key love.KeyConstant
---@param scancode love.Scancode
MenuState:on("keypressed", function(self, key, scancode)
    if scancode == "escape" then
        love.event.quit()
    end
end)

---@param key love.KeyConstant
---@param scancode love.Scancode
MenuState:on("keyreleased", function(sekf, key, scancode)
    if scancode == "return" and love.keyboard.isScancodeDown("lalt", "ralt") then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end)


return MenuState

