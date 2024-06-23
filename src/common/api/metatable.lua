
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


local NIL_METATABLES = {
    -- all of these types return nil for their metatable
    number = true,
    boolean = true,
    ["nil"] = true
}


function api.getmetatable(x)
    if type(x) == "table" then
        return getmetatable(x)
    elseif NIL_METATABLES[type(x)] then
        return nil
    else
        error("getmetatable doesn't work on type: " .. tostring(type(x)))
    end
end


return api
