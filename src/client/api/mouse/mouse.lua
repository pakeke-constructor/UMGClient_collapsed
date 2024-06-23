

return function()
    local mouse = {}

    for k,v in pairs(love.mouse)do
        mouse[k] = v
    end

    return mouse
end

