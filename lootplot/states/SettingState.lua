local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")

local analyticsService = require("src.common.analytics.analytics_service")

local Button = require("src.client.ui.elements.Button")
local PixelButton = require("lootplot.elements.PixelButton")
local Slider = require("src.client.ui.elements.Slider")
local Text = require("src.client.ui.elements.Text")
local Toggle = require("src.client.ui.elements.Toggle")
local AnalyticsPopupState = require("lootplot.states.AnalyticsPopupState")

local SettingState = StateClass()

local DIR = "lootplot/assets/items"

---@param ... string
---@return love.ImageData
local function loadImage(...)
    return love.image.newImageData(table.concat({...}, "/"))
end

local SettingScene = LUI.Element()

local function formatSliderLabel(elem, prefix, newvalue)
    elem:setText(string.format("%s: %3d", prefix, newvalue))
end

function SettingScene:init(args)
    assert(args.onClose and args.state)

    self.oldSettings = {
        sfx = userService.getSFXVolume(),
        bgm = userService.getBGMVolume(),
        fullscreen = love.window.getFullscreen()
    }
    if userService.isAnalyticsConsentAsked() then
        self.oldSettings.analytics = userService.isUserConsentedForAnalytics()
    end


    self.title = Text("Settings")

    self.sfxSliderLabel = Text(" ")
    self.sfxSlider = Slider({
        min = 0,
        max = 100,
        value = self.oldSettings.sfx,
        onValueChanged = function(_, value)
            userService.setSFXVolume(value)
            formatSliderLabel(self.sfxSliderLabel, "SFX Volume", userService.getSFXVolume())
        end
    })
    self.bgmSliderLabel = Text(" ")
    self.bgmSlider = Slider({
        min = 0,
        max = 100,
        value = self.oldSettings.bgm,
        onValueChanged = function(_, value)
            userService.setBGMVolume(value)
            formatSliderLabel(self.bgmSliderLabel, "BGM Volume", userService.getBGMVolume())
        end
    })

    self.fullscreenToggle = Toggle({
        label = "Fullscreen",
        value = self.oldSettings.fullscreen,
        onValueChanged = love.window.setFullscreen
    })

    self.analyticsButton = PixelButton({
        color = "blue",
        text = "Analytics",
        onClick = function()
            args.state:push(AnalyticsPopupState(false))
        end
    })

    self.closeButton = PixelButton({
        color = "green",
        text = "Apply",
        onClick = function()
            userService.saveSettings()
            return args.onClose()
        end,
    })
    self.closeButtonAlt = Button({
        image = love.graphics.newImage("lootplot/assets/ui/red_square_1.png"),
        onClick = function()
            userService.setSFXVolume(self.oldSettings.sfx)
            userService.setBGMVolume(self.oldSettings.bgm)
            if self.oldSettings.analytics ~= nil then
                userService.setAnalyticsConsent(self.oldSettings.analytics)
            end
            love.window.setFullscreen(self.oldSettings.fullscreen)
            return args.onClose()
        end,
    })

    formatSliderLabel(self.sfxSliderLabel, "SFX Volume", userService.getSFXVolume())
    formatSliderLabel(self.bgmSliderLabel, "BGM Volume", userService.getBGMVolume())

    self:addChild(self.title)
    self:addChild(self.sfxSliderLabel)
    self:addChild(self.sfxSlider)
    self:addChild(self.bgmSliderLabel)
    self:addChild(self.bgmSlider)
    self:addChild(self.fullscreenToggle)
    self:addChild(self.analyticsButton)
    self:addChild(self.closeButton)
    self:addChild(self.closeButtonAlt)
end

local function debugRegion(region, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", region:get())
    love.graphics.setColor(1, 1, 1)
end

function SettingScene:onRender(x, y, w, h)
    -- Make below state slightly darker
    local region = Region(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", region:get())

    local horizontalWindow = select(2, region:splitHorizontal(3, 4, 3))
    local verticalWindow = select(2, region:splitVertical(1, 8, 1))
    local settingWindowRegionBase = horizontalWindow:intersection(verticalWindow)
    love.graphics.setColor(love.math.colorFromBytes(133, 81, 21))
    love.graphics.rectangle("fill", settingWindowRegionBase:get())

    local windowRegion = settingWindowRegionBase:pad(0.04)
    local titleBase, contentUnpad, buttonBase = windowRegion:splitVertical(3, 8, 4)

    local titleArea = titleBase:splitVertical(1, 1)
    do
        local closeButtonAlt = Region(0, 0, 18, 18):scaleToFit(titleArea)
        local wx, wy, ww = settingWindowRegionBase:get()
        local rw, rh = select(3, closeButtonAlt:get())
        self.closeButtonAlt:render(wx + ww - rw / 2, wy - rh / 2, rw, rh)
    end

    local title = titleBase:pad(0.01)
    love.graphics.setColor(1, 1, 1)
    self.title:render(title:get())

    local content = contentUnpad:pad(0.04)
    local sfxLabel, sfx, _, bgmLabel, bgm, _, fullscreen = content:splitVertical(2, 3, 1, 2, 3, 1, 4)
    self.sfxSliderLabel:render(sfxLabel:get()) -- line 66
    self.sfxSlider:render(sfx:get())
    self.bgmSliderLabel:render(bgmLabel:get())
    self.bgmSlider:render(bgm:get())
    self.fullscreenToggle:render(fullscreen:get())

    local analyticsButtonBase, _, closeButtonBase = buttonBase:splitVertical(4, 0.2, 5)

    local analyticsButton = Region(0, 0, 70, 18):scaleToFit(analyticsButtonBase):center(analyticsButtonBase):pad(0.05)
    self.analyticsButton:render(analyticsButton:get())

    local closeButton = Region(0, 0, 70, 18):scaleToFit(closeButtonBase):center(closeButtonBase):pad(0.05)
    self.closeButton:render(closeButton:get())
end

function SettingState:init()
    self.scene = SettingScene({
        state = self,
        onClose = function()
            return self:pop()
        end
    })
    self.scene:makeRoot()
end

SettingState:on("update", function(self, dt)
    return self:broadcastBelow("update", dt)
end)

SettingState:on("draw", function(self)
    love.graphics.setColor(1, 1, 1)
    self:broadcastBelow("draw")
    return self.scene:render(0, 0, love.graphics.getDimensions())
end)

local function forwardToScene(name)
    SettingState:on(name, function(self, ...)
        return self.scene[name](self.scene, ...)
    end)
end

forwardToScene("mousepressed")
forwardToScene("mousereleased")
forwardToScene("mousemoved")

return SettingState
