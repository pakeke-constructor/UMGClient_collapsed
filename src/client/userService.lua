
--[[


userService

responsible for getting/setting username,
and providing clientId.


Right now, there is only ONE username / clientId per program.
Which means we can have userService be static.

]]

local userService = {}


local function getRandomUsername()
    return "plyr_" .. tostring(love.math.random(1000))
end


--[[
    In the future, we should save / load username from a file;
    So the player doesn't need to change username all the time.
    (And/Or we could use steams username by default)
]]
userService.username = getRandomUsername()


-- This should be a steam id!
userService.clientId = tostring(love.math.random(999999))
assert(type(userService.clientId) == "string")




local function parseUsername(username)
    -- Remove alphanumeric characters from username
    username = username:gsub(constants.INVALID_USERNAME_CHARACTERS,'')
    -- username can't be more than X characters:
    local maxSize = constants.MAX_USERNAME_LENGTH
    username = username:sub(1, math.min(#username, maxSize))
    return username
end


function userService.setUsername(name)
    name = parseUsername(name)
    userService.username = name
end




return userService

