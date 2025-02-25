local Text = require("src.client.ui.elements.Text")

---@class LoadingVisual
local LoadingVisual = tools.Class()

LoadingVisual.COLOR = {love.math.colorFromBytes(199, 157, 109)}

function LoadingVisual:init(itemAtlas, itemQuads)
    self.itemAtlas = itemAtlas -- AutoAtlas
    self.itemQuad = itemQuads -- tools.Array
    self.items = {}
    self.loadingText = Text({
        text = "Loading",
        color = {1,1,1},
        outlineColor = {0,0,0},
        outline = 1
    })
    self.loadingText:makeRoot()

    -- Make 10 random items in loading screen
    for i = 1, 10 do
        self.items[#self.items+1] = {
            quad = self.itemQuad[love.math.random(1, #self.itemQuad)],
            duration = love.math.random() * 2 + 0.75, -- duration and jump height
            time = 0
        }
    end
end

function LoadingVisual:_updateItem(dt, item)
    item.time = item.time + dt

    if item.time >= item.duration then
        local leftdt = item.time - item.duration

        -- Reroll
        item.quad = self.itemQuad[love.math.random(1, #self.itemQuad)]
        --item.duration = love.math.random() * 2 + 0.75
        item.time = leftdt
    end
end

if false then
    ---@param itemAtlas any
    ---@param itemQuads any
    ---@return LoadingVisual
    function LoadingVisual(itemAtlas, itemQuads) end
end

---@param dt number
function LoadingVisual:update(dt)
    for _, item in ipairs(self.items) do
        self:_updateItem(dt, item)
    end
end

function LoadingVisual:draw()
    local width, height = love.graphics.getDimensions()
    local itemScale = math.min(width, height) / 240
    love.graphics.setColor(LoadingVisual.COLOR)
    love.graphics.rectangle("fill", 0, 0, width, height)

    local region = Region(0, 0, width, height)
    local itemDrawArea, textDrawArea = region:padRatio(0.5):splitVertical(3, 1)

    local ix, iy, iw, ih = itemDrawArea:get()
    love.graphics.setColor(1, 1, 1)
    for i, item in ipairs(self.items) do
        local xpos = ix + (i - 1) * iw / #self.items
        local itemProgress = item.time / item.duration
        local itemHeight = math.sin(itemProgress * math.pi) * ih * item.duration / 3
        self.itemAtlas:draw(item.quad, xpos, iy - itemHeight + ih - 16 * itemScale, 0, itemScale, itemScale)
    end

    self.loadingText:render(textDrawArea:get())
end

return LoadingVisual
