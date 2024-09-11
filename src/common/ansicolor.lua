local los = love.system.getOS()
local usecolor = true
if los == "Windows" then
    usecolor = not not os.getenv("WT_PROFILE_ID")
elseif los == "Android" or los == "iOS" then
    -- Assume false
    usecolor = false
else
    -- Assume true
    usecolor = true
end

local ansicolor = {}

ansicolor.BLUE = "\27[34m"
ansicolor.CYAN = "\27[36m"
ansicolor.GREEN = "\27[32m"
ansicolor.YELLOW = "\27[33m"
ansicolor.RED = "\27[31m"
ansicolor.MAGENTA = "\27[35m"

---@param color string?
---@param text string
function ansicolor.wrap(color, text)
    if usecolor and color then
        return string.format("%s%s\27[0m", color, text)
    else
        return text
    end
end

return ansicolor
