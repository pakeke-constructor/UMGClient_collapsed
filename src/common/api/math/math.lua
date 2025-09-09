


local sqrt = math.sqrt
local min, max = math.min, math.max

local type = type


local xtra_math = {}



function xtra_math.distance(x, y, z)
    --[[
        finds the magnitude of a (x,y,z=0) vector,
        or the distance between two entities if entities are passed in
    ]]
    z = z or 0
    if type(x) == "table" then
        assert(type(y) == "table", "math.distance requires 2 entities, or two numbers.")
        local dx = x.x - y.x
        local dy = x.y - y.y
        local dz = (x.z or 0) - (y.z or 0)
        dx = dx * dx
        dy = dy * dy
        dz = dz * dz
        return sqrt(dx + dy + dz)
    end
    return sqrt(x*x + y*y + z*z)
end


function xtra_math.clamp(x, minn, maxx)
    return min(max(x, minn), maxx)
end


function xtra_math.normalize(x, y, z)
    -- normalizes (x,y,z) vector
    x = x or 0
    y = y or 0
    z = z or 0
    local d = xtra_math.distance(x,y,z)
    if d > 0 then
        return x/d, y/d, z/d
    end
    return x,y,z
end

xtra_math.normalise = xtra_math.normalize


function xtra_math.round(n)
    return math.floor(n+0.5)
end


function xtra_math.factorial(n)
    --[[
        factorial function
    ]]
    local res = 1
    while n > 0 do
        res = res * n
        n = n - 1
    end
    return res
end


-- We write the functions as a whitelist because its safer.
-- If Love updates, and there is a new function that is dangerous,
-- we dont want that to be loaded.
local love_math_functions = {
    "colorFromBytes",
    "colorToBytes",
    "compress",
    "decompress",
    "gammaToLinear",
    "getRandomSeed",
    "getRandomState",
    "isConvex",
    "linearToGamma",
    "newBezierCurve",
    "newRandomGenerator",
    "newTransform",
    "perlinNoise",
    "random",
    "randomNormal",
    "setRandomSeed",
    "setRandomState",
    "simplexNoise",
    "triangulate"
}



function xtra_math.randomseed()
    -- We need to disallow usage of math.randomseed, because math.random is overriden by
    -- Love's random number generator.
    error("math.randomseed is not supported, use math.setRandomSeed instead.", 2)
end


return function()
    local math_api = {}

    for k,v in pairs(math) do
        math_api[k] = v
    end

    for _, love_key in ipairs(love_math_functions) do
        math_api[love_key] = love.math[love_key]
    end

    for key, func in pairs(xtra_math) do
        math_api[key] = func
    end
    
    return math_api
end

