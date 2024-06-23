
--[[

a class implementation,
except if you access an undefined variable on an instance,
it will throw an error.

Inheritance is NOT supported.

]]


local function new(class, ...)
    local obj = {}
    setmetatable(obj, class)
    obj:init(...)
    return obj
end


local function index(_t,k)
    error("Attempted to access undefined key: " .. tostring(k), 2)
end




local classMt = {
    __call = new,
    __index = index
}


local function SafeClass()
    local class = {}
    class.__index = class
    setmetatable(class, classMt)
    return class
end


return SafeClass
