

local Style = {}


local DEFAULTS = {
    LINE_WIDTH = 2,
    CORNER_RADIUS = 0,
    FOREGROUND_COLOR = {0,0,0,1},
    BACKGROUND_COLOR = {1,1,1,1},
    OUTLINE_COLOR = {0.2,0.2,0.2,1},
    INNER_COLOR = {0.6,0.6,0.6,1},
}

function Style:get(styleName)
    if not DEFAULTS[styleName] then
        error("Unknown style: " .. tostring(styleName))
    end
    return self[styleName] or DEFAULTS[styleName]
end


function Style:setColor(opt)
    love.graphics.setColor(self:get(opt))
end

function Style:setLineWidth()
    love.graphics.setLineWidth(self:get("LINE_WIDTH"))
end

function Style:outline(x,y,w,h)
    self:setLineWidth()
    self:setColor("OUTLINE_COLOR")
    love.graphics.rectangle("line",x,y,w,h,self:get("CORNER_RADIUS"))
end


function Style:rectangle(x,y,w,h)
    self:setLineWidth()
    self:setColor("BACKGROUND_COLOR")
    love.graphics.rectangle("fill",x,y,w,h,self:get("CORNER_RADIUS"))
    self:outline(x,y,w,h)
end


function Style:darkRectangle(x,y,w,h)
    self:setLineWidth()
    self:setColor("INNER_COLOR")
    love.graphics.rectangle("fill",x,y,w,h,self:get("CORNER_RADIUS"))
    self:outline(x,y,w,h)
end


function Style:line(x1,y1, x2,y2)
    self:setLineWidth()
    love.graphics.line(x1,y1, x2,y2)
end


function Style:printf(...)
  self:setColor("FOREGROUND_COLOR")
  love.graphics.printf(...)
end

return Style
