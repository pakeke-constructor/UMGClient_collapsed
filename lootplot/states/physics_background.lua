local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")

local GRAVITY = 100
local DIR = "lootplot/assets/items/"

local NUM_ITEMS = 400

---@class lootplot.PhysicsItem
local PhysicsItem = tools.SafeClass()

local PHYSICS_ITEM_SIZE = 6

---@param world lootplot.PhysicsWorldScreen
---@param quad love.Quad
function PhysicsItem:init(world, quad)
    self.quad = quad
    -- In the future, have deterministic positioning.
    -- Perhaps a grid layout?
    local worldWidth, worldHeight = world:getDimensions()
    local x,y = love.math.random(-worldWidth / 2, worldWidth / 2), love.math.random(-worldHeight / 2, worldHeight / 2)
    self.body = love.physics.newBody(world:getWorld(), x, y, "dynamic")
    self.shape = love.physics.newCircleShape(self.body, PHYSICS_ITEM_SIZE)
    self.width, self.height = select(3, quad:getViewport())
end

function PhysicsItem:getPosition()
    return self.body:getPosition()
end

function PhysicsItem:draw(atlas)
    local x, y = self:getPosition()
    local angle = self.body:getAngle()
    atlas:draw(self.quad, x, y, angle, 1, 1, self.width / 2, self.height / 2)
end

---@class lootplot.PhysicsButton
local PhysicsButton = tools.SafeClass()

---@param world lootplot.PhysicsWorldScreen
---@param x number
---@param y number
---@param scale number
---@param padding number
---@param quad love.Quad
---@param onclick fun()
function PhysicsButton:init(world, x, y, quad, scale, padding, text, onclick)
    self.scale = scale
    self.padding = padding
    self.width, self.height = select(3, quad:getViewport())
    self.quad = quad
    self.text = text
    self.body = love.physics.newBody(world:getWorld(), x, y, "dynamic")
    self.shape = love.physics.newRectangleShape(
        self.body,
        self.width * self.scale + self.padding,
        self.height * self.scale + self.padding
    )
    self.click = onclick
end

---@param x number
---@param y number
function PhysicsButton:tryTriggerClick(x, y)
    if self.shape:testPoint(x, y) then
        self.click()
        return true
    end

    return false
end

local function printWithOutline(text, x, y, r, sx, sy, ox, oy)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x-1, y-1, r, sx, sy, ox, oy)
    love.graphics.print(text, x-1, y+1, r, sx, sy, ox, oy)
    love.graphics.print(text, x+1, y-1, r, sx, sy, ox, oy)
    love.graphics.print(text, x+1, y+1, r, sx, sy, ox, oy)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x, y, r, sx, sy, ox, oy)
end

function PhysicsButton:draw(atlas)
    local x, y = self.body:getPosition()
    local angle = self.body:getAngle()
    local font = love.graphics.getFont()
    local fw = font:getWidth(self.text)
    local fh = font:getHeight()
    local fs = math.min(self.width / (fw + 4), self.height / (fh + 4))

    atlas:draw(self.quad, x, y, angle, self.scale, self.scale, self.width / 2, self.height / 2)
    printWithOutline(self.text, x, y, angle, fs * self.scale, fs * self.scale, fw / 2, fh / 2)
end

---@class lootplot.PhysicsWorldScreen
local PhysicsWorldScreen = tools.SafeClass()

local function loadAtlas()
    local atlas = AutoAtlas()
    local quads = tools.Array()

    local t = love.filesystem.getDirectoryItems(DIR)
    for _, file in ipairs(t) do
        local img = love.image.newImageData(DIR..file)
        local q = atlas:add(img)
        quads:add(q)
    end
    return atlas, quads
end

---@param width number
---@param height number
function PhysicsWorldScreen:init(width, height)
    self.atlas, self.quads = loadAtlas()
    self.width, self.height = width, height
    self.world = love.physics.newWorld(0, GRAVITY)
    self.items = tools.Array()
    self.buttons = tools.Array()
    ---@type table<string, love.Quad>
    self.namedQuads = {}

    -- Let's make the x=0 the center
    -- The X is +-8 because the rectangle width is 16 and physics object origin is center
    -- instead of top-left
    self.leftBoxBody = love.physics.newBody(self.world, -width/2 - 8, 0, "static")
    self.leftBoundary = love.physics.newRectangleShape(self.leftBoxBody, 16, height * 2)
    self.rightBoxBody = love.physics.newBody(self.world, width/2 + 8, 0, "static")
    self.leftBoundary = love.physics.newRectangleShape(self.rightBoxBody, 16, height * 2)
    self.bottomBoxBody = love.physics.newBody(self.world, 0, height/2 + 8, "static")
    self.bottomBoundary = love.physics.newRectangleShape(self.bottomBoxBody, width * 2, 16)

    for _ = 1, NUM_ITEMS do
        local q = table.pick_random(self.quads)
        self.items:add(PhysicsItem(self, q))
    end
end

function PhysicsWorldScreen:getAtlasAndItemQuads()
    return self.atlas, self.quads
end

function PhysicsWorldScreen:update(dt)
    return self.world:update(dt)
end

function PhysicsWorldScreen:getWorld()
    return self.world
end

function PhysicsWorldScreen:draw()
    for _, item in ipairs(self.items) do
        item:draw(self.atlas)
    end

    for _, button in ipairs(self.buttons) do
        button:draw(self.atlas)
    end
end

function PhysicsWorldScreen:getDimensions()
    return self.width, self.height
end

function PhysicsWorldScreen:addButton(def)
    if not self.namedQuads[def.image] then
        local image = love.image.newImageData(def.image)
        self.namedQuads[def.image] = self.atlas:add(image)
    end

    return self.buttons:add(PhysicsButton(self, def.x, def.y, self.namedQuads[def.image], def.scale or 1, def.padding or 0, def.text, def.onClick))
end


local function length(x, y)
	return math.sqrt(x * x + y * y)
end

function PhysicsWorldScreen:boom(x, y)
    for _, item in ipairs(self.items) do
        local xx,yy = item:getPosition()
        if length(x-xx, y-yy) < 50 then
            item.body:applyLinearImpulse(xx-x, yy-y)
        end
    end
end


function PhysicsWorldScreen:click(x, y)
    for _, button in ipairs(self.buttons) do
        if button:tryTriggerClick(x, y) then
            return
        end
    end
    self:boom(x,y)
end

return PhysicsWorldScreen
