

local allowed_functions = {
    "getClipboardText",
    "setClipboardText",
    "vibrate",
    "openURL",
    "getPowerInfo",
    "getOS"
}

return function()
    local system = {}

    for _, key in ipairs(allowed_functions) do
        system[key] = love.system[key]
    end

    return system
end


