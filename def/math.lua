---@meta

---@param x number
---@param y number
---@param z number?
---@return number
function math.distance(x, y, z)
end

---@param x number
---@param minn number
---@param maxx number
---@return number
function math.clamp(x, minn, maxx)
end

---@param x number
---@param y number
---@param z number?
---@return number,number,number
function math.normalize(x, y, z)
end
math.normalise = math.normalize

---@param n number
---@return integer
function math.round(n)
end

---@param n integer
---@return integer
function math.factorial(n)
end

math.colorFromBytes = love.math.colorFromBytes
math.colorToBytes = love.math.colorToBytes
math.gammaToLinear = love.math.gammaToLinear
math.getRandomSeed = love.math.getRandomSeed
math.getRandomState = love.math.getRandomState
math.isConvex = love.math.isConvex
math.linearToGamma = love.math.linearToGamma
math.newBezierCurve = love.math.newBezierCurve
math.newRandomGenerator = love.math.newRandomGenerator
math.newTransform = love.math.newTransform
math.random = love.math.random
math.randomNormal = love.math.randomNormal
math.setRandomSeed = love.math.setRandomSeed
math.setRandomState = love.math.setRandomState
math.triangulate = love.math.triangulate
