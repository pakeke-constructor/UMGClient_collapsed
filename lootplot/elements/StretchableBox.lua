local n9p = require("libs.n9p.n9p")
local globalScale = require("lootplot.globalScale")

local StretchableBox = LUI.Element("lootplot.main:StretchableBox")



---@alias n9slice.StretchType
--- Scale to fit.
---| "stretch"
--- Tile to fit (don't scale).
---| "repeat"


---@param image love.Texture
---@param padding number[]|number
---@param args? {stretchType?: n9slice.StretchType, content?: any, color:number[], scale:number?}
function StretchableBox:init(image, padding, args)
    args = args or {}

    self.content = nil
    self.scale = args.scale or 1

    local shouldTile = args.stretchType == "repeat"
    local tW, tH = image:getDimensions()
    local padLeft, padTop, padRight, padBottom
    if type(padding) == "number" then
        padLeft = padding
        padTop = padding
        padRight = padding
        padBottom = padding
    else
        if #padding == 1 then
            padLeft = padding[1]
            padTop = padding[1]
            padRight = padding[1]
            padBottom = padding[1]
        elseif #padding == 2 then
            padLeft, padRight = padding[1], padding[1]
            padTop, padBottom = padding[2], padding[2]
        elseif #padding >= 4 then
            padLeft = padding[1]
            padTop = padding[2]
            padRight = padding[3]
            padBottom = padding[4]
        else
            umg.melt("invalid number of padding arguments")
        end
    end

    local endX = tW - padRight
    local endY = tH - padBottom

    self.n9p = n9p.newBuilder()
        :addHorizontalSlice(padLeft, endX, shouldTile)
        :addVerticalSlice(padTop, endY, shouldTile)
        :setHorizontalPadding(padLeft, endX)
        :setVerticalPadding(padTop, endY)
        :build(tW, tH)
    self.n9p:setTexture(image)

    self.color = args.color
    if args.content then
        self:setContent(args.content)
    end
end

function StretchableBox:setContent(content)
    if self.content then
        self:removeChild(self.content)
    end

    self.content = content

    if self.content then
        self:addChild(self.content)
    end
end

function StretchableBox:getContent()
    return self.content
end

function StretchableBox:onRender(x, y, w, h)
    love.graphics.push("all")
    if self.color then
        love.graphics.setColor(self.color)
    end
    local scale = globalScale.get() * self.scale
    local width, height = w / scale, h / scale
    self.n9p:draw(x, y, width, height, 0, scale, scale)

    if self.content then
        local cx, cy, cw, ch = self.n9p:getContentArea(width, height)
        self.content:render(
            cx * scale + x,
            cy * scale + y,
            cw * scale,
            ch * scale
        )
    end
    love.graphics.pop()
end

return StretchableBox
