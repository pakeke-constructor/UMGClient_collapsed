

return function()
    local coro = {}

    for key,val in pairs(coroutine)do
        coro[key] = val
    end

    return coro
end

