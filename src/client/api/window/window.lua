
return function()
    local window = {}

    for k,v in pairs(love.window)do
        window[k] = v
    end

    return window
end

