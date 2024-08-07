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

function SettingScene:init(args)
    self.title = Text("Settings")
    self.sfxSliderLabel = Text("SFX Volume")
    self.sfxSlider = Slider({
        min = 0,
        max = 100,
        value = variables.ingame_sfx_volume * 100,
        onValueChanged = function(_, value)
            print("new sfx slider value", value)
        end
    })
    self.bgmSliderLabel = Text("BGM Volume")
    self.bgmSlider = Slider({
        min = 0,
        max = 100,
        value = variables.ingame_music_volume * 100,
        onValueChanged = function(_, value)
            print("new bgm slider value", value)
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
    local region = Region(x, y, w, h):pad(0.04)
    local titleBase, contentUnpad, closeButtonBase = region:splitVertical(3, 8, 2)

    local titleArea = titleBase:splitVertical(1, 1)
    do
        local closeButtonAlt = Region(0, 0, 18, 18):scaleToFit(titleArea)
        local rw, rh = select(3, closeButtonAlt:get())
        self.closeButtonAlt:render(x + w - rw, y, rw, rh)
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

    local region = Region(0, 0, love.graphics.getDimensions())

    -- Make below state slightly darker
    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", region:get())

    local horizontalWindow = select(2, region:splitHorizontal(3, 4, 3))
    local verticalWindow = select(2, region:splitVertical(1, 8, 1))
    local settingWindowRegion = horizontalWindow:intersection(verticalWindow)
    love.graphics.setColor(love.math.colorFromBytes(133, 81, 21))
    love.graphics.rectangle("fill", settingWindowRegion:get())
    return self.scene:render(settingWindowRegion:get())
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
