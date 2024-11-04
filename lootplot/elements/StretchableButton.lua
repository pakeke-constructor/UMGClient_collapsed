local StretchableBox = require("lootplot.elements.StretchableBox")
local globalScale = require("lootplot.globalScale")
local COMMON_IMAGE = require("lootplot.common_image")
local Text = require("src.client.ui.elements.Text")

local StretchableButton = LUI.Element("lootplot.main:StretchableButton")

local lg=love.graphics

local BUTTON_PADDING = {4, 5, 5, 7}

local function giveTextElement(self, elem)
    if not self.text then
        return
    end

    local textElement = Text({
        text = tostring(self.text),
        color = {1, 1, 1},
        outline = 1,
        outlineColor = {0, 0, 0},
        getScale = function()
            return globalScale.get() * self.scale
        end,
        rescale = true
    })
    elem:setContent(textElement)
end

function StretchableButton:init(args)
    self.click = args.onClick
    self.text = args.text
    self.color = args.color
    self.scale = args.scale or 1

    self.buttonPressed = StretchableBox(COMMON_IMAGE.WHITE_PRESSED_BIG, BUTTON_PADDING, {
        scale = self.scale,
        stretchType = "repeat",
    })

    self.button = StretchableBox(COMMON_IMAGE.WHITE_BIG, BUTTON_PADDING, {
        scale = self.scale,
        stretchType = "repeat",
    })

    self:addChild(self.buttonPressed)
    self:addChild(self.button)

    giveTextElement(self, self.button)
    giveTextElement(self, self.buttonPressed)
end

function StretchableButton:onRender(x,y,w,h)
    local c = self.color
    if self:isHovered() then
        local r,g,b,a = c[1],c[2],c[3],c[4]
        lg.setColor(r*0.5,g*0.5,b*0.5,a)
    else
        lg.setColor(c)
    end

    local usedButton = self:isClickedOnBy(1) and self.buttonPressed or self.button
    if tools.get_callable(self.text) then
        usedButton:getContent():setText(self.text())
    end

    usedButton:render(x, y, w, h)
end


function StretchableButton:mousereleased(cont)
    if cont == 1 then
        self:click()
    end
end

return StretchableButton
