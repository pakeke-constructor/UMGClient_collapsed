local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")

local Button = require("src.client.ui.elements.Button")
local PixelButton = require("lootplot.elements.PixelButton")
local Slider = require("src.client.ui.elements.Slider")
local Text = require("src.client.ui.elements.Text")

local SettingState = StateClass()

local DIR = "lootplot/assets/items"

---@param ... string
---@return love.ImageData
local function loadImage(...)
    return love.image.newImageData(table.concat({...}, "/"))
end

local SettingScene = LUI.Element()

local function formatSliderLabel(elem, prefix, newvalue)
    elem:setText(string.format("%s: %3d", prefix, newvalue * 100))
end

function SettingScene:init(args)
    self.title = Text("Settings")
    self.sfxSliderLabel = Text(" ")
    self.sfxSlider = Slider({
        min = 0,
        max = 100,
        value = variables.ingame_sfx_volume * 100,
        onValueChanged = function(_, value)
            value = math.floor(value + 0.5) -- floating imprecision
            variables.ingame_sfx_volume = value / 100
            formatSliderLabel(self.sfxSliderLabel, "SFX Volume", value / 100)
        end
    })
    self.bgmSliderLabel = Text(" ")
    self.bgmSlider = Slider({
        min = 0,
        max = 100,
        value = variables.ingame_music_volume * 100,
        onValueChanged = function(_, value)
            value = math.floor(value + 0.5)
            variables.ingame_music_volume = value / 100
            formatSliderLabel(self.bgmSliderLabel, "BGM Volume", value / 100)
        end
    })
    self.closeButton = PixelButton({
        color = "green",
        text = "Close",
        onClick = assert(args.onClose),
    })
    self.closeButtonAlt = Button({
        image = love.graphics.newImage("lootplot/assets/ui/red_square_1.png"),
        onClick = assert(args.onClose),
    })

    formatSliderLabel(self.sfxSliderLabel, "SFX Volume", variables.ingame_sfx_volume)
    formatSliderLabel(self.bgmSliderLabel, "BGM Volume", variables.ingame_music_volume)

    self:addChild(self.title)
    self:addChild(self.sfxSliderLabel)
    self:addChild(self.sfxSlider)
    self:addChild(self.bgmSliderLabel)
    self:addChild(self.bgmSlider)
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
    local titleBase, contentUnpad, closeButtonBase = windowRegion:splitVertical(3, 8, 2)

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
    local sfxLabel, sfx, _, bgmLabel, bgm = content:splitVertical(2, 3, 1, 2, 3)
    self.sfxSliderLabel:render(sfxLabel:get()) -- line 66
    self.sfxSlider:render(sfx:get())
    self.bgmSliderLabel:render(bgmLabel:get())
    self.bgmSlider:render(bgm:get())

    local closeButton = Region(0, 0, 70, 18):scaleToFit(closeButtonBase):center(closeButtonBase):pad(0.05)
    self.closeButton:render(closeButton:get())
end

function SettingState:init()
    self.scene = SettingScene({
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
