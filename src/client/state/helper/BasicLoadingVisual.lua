

local BasicLoadingVisual = tools.SafeClass()


function BasicLoadingVisual:init()
end


function BasicLoadingVisual:draw()
    love.graphics.scale(2)
    love.graphics.print("BASIC LOADING VISUAL. UMG-" .. constants.VERSION, 10, 10)
end


function BasicLoadingVisual:update(dt)
end


return BasicLoadingVisual
