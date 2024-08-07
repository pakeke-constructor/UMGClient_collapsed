local Slider = LUI.Element()



local Thumb = LUI.Element()


local function clamp(x, min, max)
    return math.min(max, math.max(min, x))
end



local SCROLL_BUTTON = 1

local function getLimitedDelta(elem, mouseX, dx)
    --[[
        This is to ensure that the thumb is moved in-tune with
        the mouse.
    ]]
    local x,_y,w,_h = elem:getView()
    if dx > 0 then
        -- If mouse is behind elem, and we are dragging forward:
        if mouseX < x then
            return 0 -- set delta to 0
        end
    else
        -- If mouse is ahead of elem, and we are dragging back:
        if mouseX > x+w then
            return 0 -- set delta to 0
        end
    end
    return dx
end



local function computeValue(elem, position)
    -- computes value from position
    local mag = elem.max - elem.min
    return elem.min + ((position/elem.totalSize) * mag)
end


local function computePosition(elem, value)
    -- computes position from value
    local mag = elem.max - elem.min
    return ((value - elem.min) / mag) * elem.totalSize
end


function Thumb:init(atlas, left, center, right)
    self.atlas = atlas
    self.leftQuad = left
    self.centerQuad = center
    self.rightQuad = right
end


function Thumb:onMouseMoved(x, y, dx, dy, istouch)
    if self:isClickedOnBy(SCROLL_BUTTON) then
        local parent = self:getParent()
        dx = getLimitedDelta(self, x, dx)
        parent.position = clamp(parent.position + dx, 0, parent.totalSize)
        parent.value = computeValue(parent, parent.position)
        if parent.onValueChanged then
            parent:onValueChanged(parent.value)
        end
    end
end

function Thumb:onRender(x,y,w,h)
    ui.style:rectangle(x,y,w,h)
end






-- FIXME: Don't rely on hardcoded dimension values.
function Slider:init(args)
    tools.assertKeys(args, {"onValueChanged", "min", "max"})
    self.onValueChanged = args.onValueChanged
    self.min = args.min
    self.max = args.max
    assert(self.min<=self.max,"wot wot")
    self.value = clamp(args.value or 0, self.min, self.max)
    self.valueNormalized = (self.value - self.min) / (self.max - self.min)
    self.lastWidth = 100
    self.lastX = 0
    self.scrollBarImage = love.graphics.newImage("src/client/ui/images/slider/scrollbar.png")
    self.handleImage = love.graphics.newImage("src/client/ui/images/slider/handle_4.png")

    -- TODO: Invent or reuse an existing 9 patch library.
    self.scrollBarQuadLeft = love.graphics.newQuad(0, 0, 5, 7, self.scrollBarImage:getDimensions())
    self.scrollBarQuadResizable = love.graphics.newQuad(5, 0, 17, 7, self.scrollBarImage:getDimensions())
    self.scrollBarQuadRight = love.graphics.newQuad(22, 0, 4, 7, self.scrollBarImage:getDimensions())
end


function Slider:onMouseMoved(x, y, dx, dy, istouch)
    if self:isClickedOnBy(SCROLL_BUTTON) then
        local clampedX = clamp(x, self.lastX, self.lastX + self.lastWidth)
        self.valueNormalized = (clampedX - self.lastX) / self.lastWidth
        self.value = (1 - self.valueNormalized) * self.min + self.valueNormalized * self.max
        if self.onValueChanged then
            self:onValueChanged(self.value)
        end
    end
end


local THUMB_RATIO = 4


function Slider:onRender(x,y,w,h)
    self.lastWidth = w
    self.lastX = x
    local region = Region(x,y,w,h)

    -- love.graphics.setColor(0.5,0.5,0.5)
    -- local lineRegion = region:pad(0,0.4,0,0.4)
    -- ui.style:darkRectangle(lineRegion:get())

    -- local thumbWidth = w/THUMB_RATIO
    -- self.totalSize = w - thumbWidth
    -- self.position = computePosition(self, self.valueNormalized)
    -- local thumbRegion = region
    --     :set(nil,nil,w/THUMB_RATIO,nil)
    --     :offset(self.position, 0)
    --     :clampInside(region)
    -- self.thumb:render(thumbRegion:get())

    -- FIXME: Don't hardcode sizes
    local sliderWidth = 9 * THUMB_RATIO
    local sliderResizableWidth = 17 * THUMB_RATIO
    local sliderWidthResizable = math.max(w - sliderWidth, 0)
    love.graphics.draw(self.scrollBarImage, self.scrollBarQuadLeft, x, y, 0, THUMB_RATIO, THUMB_RATIO)
    love.graphics.draw(self.scrollBarImage, self.scrollBarQuadResizable, x + 5 * THUMB_RATIO, y, 0, THUMB_RATIO * sliderWidthResizable / sliderResizableWidth, THUMB_RATIO)
    love.graphics.draw(self.scrollBarImage, self.scrollBarQuadRight, x + 5 * THUMB_RATIO + sliderWidthResizable, y, 0, THUMB_RATIO, THUMB_RATIO)

    local handleMaxValue = math.max(w - self.handleImage:getWidth() * THUMB_RATIO, 1)
    love.graphics.draw(self.handleImage, x + self.valueNormalized * handleMaxValue, y, 0, THUMB_RATIO, THUMB_RATIO)
end


return Slider
