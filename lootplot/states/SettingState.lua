local Slider = require("src.client.ui.elements.Slider")
local Text = require("src.client.ui.elements.Text")
local Toggle = require("src.client.ui.elements.Toggle")

local COMMON_IMAGE = require("lootplot.common_image")
local StretchableBox = require("lootplot.elements.StretchableBox")
local StretchableButton = require("lootplot.elements.StretchableButton")
local AnalyticsPopupState = require("lootplot.states.AnalyticsPopupState")
local sfx = require("lootplot.sfx")

local SettingState = StateClass()


local SettingScene = LUI.Element()

local function formatSliderLabel(elem, prefix, newvalue)
    elem:setText(string.format("%s: %3d", prefix, newvalue))
end

local ANALYTICS_BUTTON_COLOR = {love.math.colorFromBytes(0x4b, 0xb3, 0xfa)}
local APPLY_BUTTON_COLOR = {love.math.colorFromBytes(0x69, 0xd1, 0x35)}

function SettingScene:init(args)
    assert(args.onClose and args.state)

    self.title = Text("Settings")

    self.sfxSliderLabel = Text(" ")
    self.sfxSlider = Slider({
        min = 0,
        max = 100,
        value = userService.getSFXVolume(),
        onValueChanged = function(_, value)
            userService.setSFXVolume(value)
            sfx.setVolume(value / 100)
            formatSliderLabel(self.sfxSliderLabel, "SFX Volume", userService.getSFXVolume())
        end
    })
    self.bgmSliderLabel = Text(" ")
    self.bgmSlider = Slider({
        min = 0,
        max = 100,
        value = userService.getBGMVolume(),
        onValueChanged = function(_, value)
            userService.setBGMVolume(value)
            formatSliderLabel(self.bgmSliderLabel, "BGM Volume", userService.getBGMVolume())
        end
    })

    -- FIXME: This will be incorrect when user pressed Alt+Enter directly. No clean way to fix it.
    self.fullscreenToggle = Toggle({
        label = "Fullscreen",
        value = love.window.getFullscreen(),
        onValueChanged = love.window.setFullscreen
    })

    self.analyticsButton = StretchableButton({
        color = ANALYTICS_BUTTON_COLOR,
        text = "Analytics Settings",
        scale = 2,
        onClick = function()
            sfx.click()
            args.state:push(AnalyticsPopupState(false))
        end
    })

    self.closeButton = StretchableButton({
        color = APPLY_BUTTON_COLOR,
        text = "Apply",
        scale = 2,
        onClick = function()
            userService.saveSettings()
            sfx.click()
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
end

local function debugRegion(region, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", region:get())
    love.graphics.setColor(1, 1, 1)
end

function SettingScene:onRender(x, y, w, h)
    -- Make below state slightly darker
    local settingWindowRegionBase = Region(x, y, w, h)
    local windowRegion = settingWindowRegionBase:padRatio(0.04)
    local titleBase, contentUnpad, buttonBase = windowRegion:splitVertical(3, 8, 5)

    local title = titleBase:padRatio(0.01)
    love.graphics.setColor(1, 1, 1)
    self.title:render(title:get())

    local content = contentUnpad:padRatio(0.04)
    local sfxLabel, sfx, _, bgmLabel, bgm, _, fullscreen = content:splitVertical(2, 3, 1, 2, 3, 1, 4)
    self.sfxSliderLabel:render(sfxLabel:get()) -- line 66
    self.sfxSlider:render(sfx:get())
    self.bgmSliderLabel:render(bgmLabel:get())
    self.bgmSlider:render(bgm:get())
    self.fullscreenToggle:render(fullscreen:get())

    local analyticsButton, closeButtonBase = buttonBase:splitVertical(3, 5)
    self.analyticsButton:render(analyticsButton:get())

    local closeButton = closeButtonBase:padRatio(0, 0.2, 0, 0)
    self.closeButton:render(closeButton:get())
end


local SettingSceneRoot = LUI.Element()

local BOX_COLOR = {love.math.colorFromBytes(133, 81, 21)}

function SettingSceneRoot:init(...)
    self.content = SettingScene(...)
    self.box = StretchableBox(COMMON_IMAGE.WHITE_PRESSED_BIG, 8, {
        content = self.content,
        scale = 2,
        color = BOX_COLOR,
        stretchType = "repeat"
    })

    self:addChild(self.box)
end

function SettingSceneRoot:onRender(x, y, w, h)
    -- Make below state slightly darker
    local region = Region(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", region:get())

    local horizontalWindow = select(2, region:splitHorizontal(1, 2, 1))
    local verticalWindow = select(2, region:splitVertical(1, 9, 1))
    local settingWindowRegionBase = horizontalWindow:intersection(verticalWindow)
    self.box:render(settingWindowRegionBase:get())
end


function SettingState:init()
    self.scene = SettingSceneRoot({
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
