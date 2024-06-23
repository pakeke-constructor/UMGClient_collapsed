
--[[

A struct is just a regular lua table,
except you can't add new keys, and you can't access undefined keys either.


For example:

local vec = Struct({
    "x", "y"
})
-- now vec can only contain x,y values


local other = Struct({
    x = true,
    y = true
})
-- (same as above)


]]

local function index(_t,k)
    error("Attempted to access undefined value: " .. tostring(k))
end


local function newindex(t,k,_v)
    if not t._allowed[k] then
        error("Attempted to define invalid value!")
    end
    if type(k) ~= "string" then
        error("Struct keys must be strings. Not: " .. type(k))
    end
end


local function ensureMap(keys)
    -- converts an array -> map if possible so its easier to check
    for _, key in ipairs(keys) do
        keys[key] = true
    end
end


local mt = {
    __index = index,
    __newindex = newindex
}


local function newStruct(keys)
    return setmetatable({
        _allowed = ensureMap(keys)
    }, mt)
end


return newStruct
