local PixelButton = LUI.Element()

local DIR = "src/client/ui/images/long_buttons/"

function PixelButton:init(args)
    self.onClick = args.onClick
    self.text = args.text
    self.imageElement = ui.elements.Image({
        image = love.graphics.newImage(DIR..args.color:lower().."_long.png")
    })
    self.textElement = ui.elements.Text({
        text = self.text,
        outline = 2
    })
    self:addChild(self.imageElement)
    self:addChild(self.textElement)
end

function PixelButton:_ensureTextElement()
    if self.textElement.text ~= self.text then
        -- we need to update!
        self.textElement.text = self.text
    end
end

function PixelButton:onRender(x,y,w,h)
    local r = Region(x,y,w,h)
    self:_ensureTextElement()

    love.graphics.setColor(1, 1, 1)
    self.imageElement:render(x,y,w,h)

    local region = r:pad(0.15, 0, 0.15, 0.15)
    self.textElement:render(region:get())
end

function PixelButton:onMousePress(x,y)
    if self.onClick then
        self:onClick(x,y)
    end
end

return PixelButton
