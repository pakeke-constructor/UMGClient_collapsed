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

---@class lootplot.PhysicsObject
local PhysicsObject = tools.SafeClass()

---@param world lootplot.PhysicsWorldScreen
---@param def {x: number, y:number, quad:love.Quad, text?: string, scale?: number, padding?: number, onClick?:fun()}
function PhysicsObject:init(world, def) --x, y, quad, scale, padding, text, onclick)
    self.scale = def.scale or 1
    self.padding = def.padding or 0
    self.quad = def.quad
    self.width, self.height = select(3, def.quad:getViewport())
    self.text = def.text or false
    self.body = love.physics.newBody(world:getWorld(), def.x, def.y, "dynamic")
    self.shape = love.physics.newRectangleShape(
        self.body,
        self.width * self.scale + self.padding,
        self.height * self.scale + self.padding
    )
    self.onClick = def.onClick or false
end

function PhysicsObject:isButton()
    return self.onClick
end

---@param x number
---@param y number
function PhysicsObject:tryTriggerClick(x, y)
    if self.shape:testPoint(x, y) then
        self.onClick()
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

function PhysicsObject:draw(atlas)
    local x, y = self.body:getPosition()
    local angle = self.body:getAngle()

    atlas:draw(self.quad, x, y, angle, self.scale, self.scale, self.width / 2, self.height / 2)

    if self.text then
        local font = love.graphics.getFont()
        local fw = font:getWidth(self.text)
        local fh = font:getHeight()
        local fs = math.min(self.width / (fw + 4), self.height / (fh + 4))
        printWithOutline(self.text, x, y, angle, fs * self.scale, fs * self.scale, fw / 2, fh / 2)
    end
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
    self.objects = tools.Array()

    ---@type table<string, love.Quad>
    self.namedQuads = {}

    -- Let's make the x=0 the center
    -- The X is +-8 because the rectangle width is 16 and physics object origin is center
    -- instead of top-left
    local wallHeight = height * 100
    self.leftBoxBody = love.physics.newBody(self.world, -width/2 - 8, 0, "static")
    self.leftBoundary = love.physics.newRectangleShape(self.leftBoxBody, 16, wallHeight * 2)
    self.rightBoxBody = love.physics.newBody(self.world, width/2 + 8, 0, "static")
    self.leftBoundary = love.physics.newRectangleShape(self.rightBoxBody, 16, wallHeight * 2)
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

    for _, obj in ipairs(self.objects) do
        obj:draw(self.atlas)
    end
end

function PhysicsWorldScreen:getDimensions()
    return self.width, self.height
end


---@param def {x: number, y:number, image:string, text?: string, scale?: number, padding?: number, onClick?:fun()}
function PhysicsWorldScreen:addObject(def)
    if not self.namedQuads[def.image] then
        local image = love.image.newImageData(def.image)
        self.namedQuads[def.image] = self.atlas:add(image)
    end
    def.quad = self.namedQuads[def.image]
    return self.objects:add(PhysicsObject(self, def))
end


function PhysicsWorldScreen:addButton(def)
    assert(def.onClick, "Button needs onClick")
    self:addObject(def)
end

local function length(x, y)
	return math.sqrt(x * x + y * y)
end

---@param body love.Body
---@param x any
---@param y any
local function boomBody(body, x, y)
    local xx,yy = body:getPosition()
    local dx,dy = xx-x, yy-y
    local mass = body:getMass()
    local l = length(dx,dy)
    local s = (mass*3000)/(l*l)
    body:applyLinearImpulse(s*dx, s*dy)
end

function PhysicsWorldScreen:boom(x, y)
    for _, item in ipairs(self.items) do
        boomBody(item.body, x, y)
    end
    for _, obj in ipairs(self.objects) do
        boomBody(obj.body, x, y)
    end
end


function PhysicsWorldScreen:click(x, y)
    for _, obj in ipairs(self.objects) do
        if obj:isButton() and obj:tryTriggerClick(x, y) then
            return
        end
    end
    self:boom(x,y)
end

return PhysicsWorldScreen
