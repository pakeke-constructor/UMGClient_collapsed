

local Image = LUI.Element()


function Image:init(args)
    self.image = args.image
end


function Image:onRender(x,y,w,h)
    local iw, ih = self.image:getDimensions()
    local ox, oy = iw/2, ih/2
    local region = Region(x,y,w,h)
    local imgRegion = Region(0,0,iw,ih)

    local padded = region:pad(0.05)
    local scale = imgRegion:getScaleToFit(padded)
    -- useful idiom when we want to scale image/text ^^^^

    local drawX, drawY
    drawX = padded.x + padded.w/2
    drawY = padded.y + padded.h/2
    love.graphics.setColor(1,1,1)
    love.graphics.draw(self.image,drawX,drawY,0,scale,scale,ox,oy)
end


function Image:scaleRegionToFit(region)
    --[[
        Scales `region` such that it fits the image perfectly.
    ]] 
    local iw, ih = self.image:getDimensions()
    local imgRegion = Region(0,0,iw,ih)
    return imgRegion:scaleToFit(region)
end


return Image
