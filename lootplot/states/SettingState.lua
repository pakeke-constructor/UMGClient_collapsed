local Slider = require("src.client.ui.elements.Slider")
local Text = require("src.client.ui.elements.Text")
local Toggle = require("src.client.ui.elements.Toggle")

local COMMON_COLOR = require("lootplot.common_color")
local COMMON_IMAGE = require("lootplot.common_image")
local StretchableBox = require("lootplot.elements.StretchableBox")
local StretchableButton = require("lootplot.elements.StretchableButton")
local AnalyticsPopupState = require("lootplot.states.AnalyticsPopupState")
local LanguageSelectState = require("lootplot.states.LanguageSelectState")
local sfx = require("lootplot.sfx")

local SettingState = StateClass()


local SettingScene = LUI.Element()

local function formatSliderLabel(elem, newvalue)
    elem:setText(string.format("%3d", newvalue))
end

---@param size number
---@param parent Region
local function rescaleHeightBy(size, parent)
    local x, y, w, h = parent:get()
    return Region(x, y, w, h * size):center(parent)
end

local ANALYTICS_TEXT = {
    [false] = localization.localize"OFF",
    [true] = localization.localize"ON"
}

function SettingScene:init(args)
    assert(args.onClose and args.state)

    self.title = Text({text = localization.localize"Settings", outline = 2})

    self.sfxSliderLabel0 = Text({text = localization.localize"SFX Volume", align = "left", outline = 1})
    self.sfxSliderLabel = Text({text = "", align = "right", outline = 1})
    self.sfxSlider = Slider({
        min = 0,
        max = 100,
        value = userService.getSFXVolume(),
        onValueChanged = function(_, value)
            userService.setSFXVolume(value)
            sfx.setVolume(value / 100)
            formatSliderLabel(self.sfxSliderLabel, userService.getSFXVolume())
        end
    })
    self.bgmSliderLabel0 = Text({text = localization.localize"BGM Volume", align = "left", outline = 1})
    self.bgmSliderLabel = Text({text = "", align = "right", outline = 1})
    self.bgmSlider = Slider({
        min = 0,
        max = 100,
        value = userService.getBGMVolume(),
        onValueChanged = function(_, value)
            userService.setBGMVolume(value)
            formatSliderLabel(self.bgmSliderLabel, userService.getBGMVolume())
        end
    })

    -- FIXME: This will be incorrect when user pressed Alt+Enter directly. No clean way to fix it.
    self.fullscreenLabel = Text({text = localization.localize"Fullscreen", align = "left", outline = 1})
    self.fullscreenToggle = Toggle({
        value = love.window.getFullscreen(),
        onValueChanged = userService.setFullscreen
    })

    self.analyticsLabel = Text({text = localization.localize"Analytics", align = "left", outline = 1})
    self.analyticsButton = StretchableButton({
        color = COMMON_COLOR.BLUE,
        text = localization.localize"Change",
        scale = 2,
        onClick = function()
            sfx.click()
            args.state:push(AnalyticsPopupState(false))
        end
    })

    self.languageLabel = Text({text = localization.localize"Language", align = "left", outline = 1})
    self.languageButton = StretchableButton({
        color = COMMON_COLOR.BLUE,
        text = localization.localize"Change",
        scale = 2,
        onClick = function()
            sfx.click()
            args.state:push(LanguageSelectState())
        end
    })

    self.closeButton = StretchableButton({
        color = COMMON_COLOR.GREEN,
        text = localization.localize"Apply",
        scale = 2,
        onClick = function()
            userService.saveSettings()
            sfx.click()
            return args.onClose()
        end,
    })

    formatSliderLabel(self.sfxSliderLabel, userService.getSFXVolume())
    formatSliderLabel(self.bgmSliderLabel, userService.getBGMVolume())

    self:addChild(self.title)
    self:addChild(self.sfxSliderLabel0)
    self:addChild(self.sfxSliderLabel)
    self:addChild(self.sfxSlider)
    self:addChild(self.bgmSliderLabel0)
    self:addChild(self.bgmSliderLabel)
    self:addChild(self.bgmSlider)
    self:addChild(self.fullscreenLabel)
    self:addChild(self.fullscreenToggle)
    self:addChild(self.analyticsLabel)
    self:addChild(self.analyticsButton)
    self:addChild(self.languageLabel)
    self:addChild(self.languageButton)
    self:addChild(self.closeButton)
end

local function debugRegion(region, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("line", region:get())
    love.graphics.setColor(1, 1, 1)
end

function SettingScene:onRender(x, y, w, h)
    -- Make below state slightly darker
    local settingWindowRegionBase = Region(x, y, w, h)
    local windowRegion = settingWindowRegionBase:padRatio(0.04)
    local contentUnpad, closeButtonBase = windowRegion:splitVertical(8, 2)

    local content = contentUnpad:padRatio(0.04)
    local sfxLabelBase, sfx, _, bgmLabelBase, bgm, _, fullscreenBase, _, analyticsBase, _, languageBase = content:splitVertical(1, 1, 0.4, 1, 1, 0.4, 1, 0.4, 1, 0.4, 1, 0.4)

    local sfxLabel0, _, sfxLabel = rescaleHeightBy(0.6, sfxLabelBase):splitHorizontal(3, 0.1, 1)
    self.sfxSliderLabel0:render(sfxLabel0:get())
    self.sfxSliderLabel:render(sfxLabel:get())
    self.sfxSlider:render(sfx:get())

    local bgmLabel0, _, bgmLabel = rescaleHeightBy(0.6, bgmLabelBase):splitHorizontal(3, 0.1, 1)
    self.bgmSliderLabel0:render(bgmLabel0:get())
    self.bgmSliderLabel:render(bgmLabel:get())
    self.bgmSlider:render(bgm:get())

    local fullscreenLabel, _, fullscreen = fullscreenBase:splitHorizontal(3, 0.1, 1)
    -- HACK: Increase the size of fullscreen toggle height
    local fs = math.min(fullscreen.w, fullscreen.h * 1.5)
    fullscreen = Region(0, 0, fullscreen.w, fs):center(fullscreen)
    self.fullscreenLabel:render(rescaleHeightBy(0.6, fullscreenLabel):get())
    self.fullscreenToggle:render(fullscreen:get())

    local analyticsLabel, _, analyticsButton = analyticsBase:splitHorizontal(3, 0.05, 1)
    self.analyticsLabel:setText(localization.localize("Analytics")..": "..ANALYTICS_TEXT[userService.isUserConsentedForAnalytics()])
    self.analyticsLabel:render(rescaleHeightBy(0.6, analyticsLabel):get())
    -- HACK: Increase the size of analytics button height
    local ah = math.min(analyticsButton.w, analyticsButton.h * 1.5)
    analyticsButton = Region(0, 0, analyticsButton.w, ah):center(analyticsButton)
    self.analyticsButton:render(analyticsButton:get())

    local languageLabelR, _, languageButtonR = languageBase:splitHorizontal(3, 0.05, 1)
    self.languageLabel:setText(localization.localize("Language")..": "..userService.getLanguage())
    self.languageLabel:render(rescaleHeightBy(0.6, languageLabelR):get())
    -- HACK: Increase the size of language button height
    local lh = math.min(languageButtonR.w, languageButtonR.h * 1.5)
    languageButtonR = Region(0, 0, languageButtonR.w, lh):center(languageButtonR)
    self.languageButton:render(languageButtonR:get())

    local closeButton = closeButtonBase:padRatio(0, 0.2, 0, 0)
    self.closeButton:render(closeButton:get())
end


local SettingSceneRoot = LUI.Element()

function SettingSceneRoot:init(...)
    self.content = SettingScene(...)
    self.box = StretchableBox(COMMON_IMAGE.WHITE_PRESSED_BIG, 8, {
        content = self.content,
        scale = 2,
        color = COMMON_COLOR.DARK_BROWN,
        stretchType = "repeat"
    })

    self:addChild(self.box)
end

function SettingSceneRoot:onRender(x, y, w, h)
    -- Make below state slightly darker
    local region = Region(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", region:get())

    local horizontalWindow = select(2, region:splitHorizontal(2, 7, 2))
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
