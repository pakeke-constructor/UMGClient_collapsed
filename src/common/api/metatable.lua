
--[[

We override the default `getmetatable()` and `setmetatable()` to make
stuff more safe.

]]
local api = {}


function api.setmetatable(x, mt)
    if type(x) == "table" then
        return setmetatable(x, mt)
    else
        error("setmetatable doesn't work for type: " .. tostring(type(x)))
    end
end


function api.getmetatable(x)
    if type(x) == "table" then
        return getmetatable(x)
    else
        return nil
    end
end


return api
