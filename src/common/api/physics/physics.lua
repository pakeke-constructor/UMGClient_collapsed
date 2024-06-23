

return function()
    local physics_api = {}

    for k,v in pairs(love.physics) do
        physics_api[k] = v
    end

    return physics_api
end
