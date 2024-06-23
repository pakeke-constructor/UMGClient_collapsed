
--[[
    simple class impl
]]

local function new(class, ...)
    local obj = {}
    setmetatable(obj, class)
    obj:init(...)
    return obj
end


local classMt = {__call = new}


local function Class(extends)
    local class = {}
    class.__index = class

    if extends then
        if type(extends) ~= "table" then
            error("class(name, extends) expects a class as optional 2nd argument")
        end
        setmetatable(class, {
            __index = extends,
            __call = new
        })
    else
        setmetatable(class, classMt)
    end

    return class
end


return Class
