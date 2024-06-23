
return function()
    local keyboard = {}

    for k,v in pairs(love.keyboard)do
        keyboard[k] = v
    end

    return keyboard
end

