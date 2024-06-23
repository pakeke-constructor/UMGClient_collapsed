
--[[

A SafeTable is a regular lua table,
Except if you access an undefined key, an error is thrown.

you can create any keys you want, tho

]]

local function index(_t,k)
    error("Attempted to access undefined key: " .. tostring(k))
end


local mt = {
    __index = index
}


local function newSafeTable()
    return setmetatable({}, mt)
end


return newSafeTable
