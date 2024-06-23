
--[[
    prevent modification of the string metatable
]]

-- selene: allow(incorrect_standard_library_use)
local str_mt = getmetatable("")
str_mt.__metatable = "string metatable is defended"

