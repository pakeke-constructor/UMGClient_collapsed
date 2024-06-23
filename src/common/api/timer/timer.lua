

return function()
    local love_timer_api = {}

    for k,v in pairs(love.timer) do
        love_timer_api[k] = v
    end

    return love_timer_api
end
