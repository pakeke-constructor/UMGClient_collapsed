

local PixelButton = LUI.Element()


local DEFAULT_PADDING = 0.15 -- % padding ratio
local OUTLINE_PADDING = 2 -- how wide the outline is


function PixelButton:init(args)
    self.onClick = args.onClick
    self.textPadding = args.textPadding or DEFAULT_PADDING -- padding for text
    self.text = args.text

    local image = ui.getImage(args.image)
    self.imageElement = ui.elements.Image({
        image = image
    })
    self:addChild(self.imageElement)
end


local function ensureTextElement(self)
    if not self.textElement then
        self.textElement = ui.elements.Text({
            text = self.text,
            outline = OUTLINE_PADDING
        })
        self:addChild(self.textElement)
    end

    if self.textElement.text ~= self.text then
        -- we need to update!
        self.textElement.text = self.text
    end
end



function PixelButton:onRender(x,y,w,h)
    local r = Region(x,y,w,h)

    local imgRegion = self.imageElement
        :scaleRegionToFit(r)
        :center(r)

    self.imageElement:render(imgRegion:get())

    if self.text then
        ensureTextElement(self)
        local textRegion = imgRegion:pad(self.textPadding)
        self.textElement:render(textRegion:get())
    end
end



function PixelButton:onMousePress(x,y)
    if self.onClick then
        self:onClick(x,y)
    end
end




return PixelButton

