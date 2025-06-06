local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")

local PHYSICS_ITEM_SIZE = 6
local GRAVITY = 15
local NUM_ITEMS = 400
local MAX_VELOCITY_SCALAR = 50
local INVISIBLE_Y = 100
local ITEMS_DIR = "lootplot/assets/items/"

local PhysicsBackground = tools.SafeClass()


local function loadAtlas()
    local atlas = AutoAtlas()
    local quads = tools.Array()

    local t = love.filesystem.getDirectoryItems(ITEMS_DIR)
    for _, file in ipairs(t) do
        local img = love.image.newImageData(ITEMS_DIR..file)
        local q = atlas:add(img)
        quads:add(q)
    end
    return atlas, quads
end

function PhysicsBackground:init(transform)
    self.world = love.physics.newWorld(0, GRAVITY)
    self.atlas, self.quads = loadAtlas()
    ---@type lootplot.PhysicsBackgroundObject[]
    self.objects = {}

    -- Add raining items
    do
        local screenTX, screenTY = transform:inverseTransformPoint(0, 0)
        local screenBX, screenBY = transform:inverseTransformPoint(love.graphics.getDimensions())
        local ty = screenTY - INVISIBLE_Y
        for _ = 1, NUM_ITEMS do
            self:spawnItem(
                self.quads[math.random(1, #self.quads)],
                screenTX + math.random() * (screenBX - screenTX),
                ty + math.random() * (screenBY - ty)
            )
        end
    end
end

function PhysicsBackground:getAtlasAndItemQuads()
    return self.atlas, self.quads
end

function PhysicsBackground:getDimensions()
    return self.width, self.height
end

---@param obj lootplot.PhysicsBackgroundObject
local function defaultDraw(obj)
    if not obj.image then return end

    if obj.quad then
        local w, h = select(3, obj.quad:getViewport())
        love.graphics.draw(obj.image, obj.quad, 0, 0, 0, 1, 1, w / 2, h / 2)
    else
        local w, h = obj.image:getDimensions()
        love.graphics.draw(obj.image, 0, 0, 0, 1, 1, w / 2, h / 2)
    end
end

---@param args {x:number,y:number,shape:(fun(body:love.Body,...):love.Shape),shapeArgs:any[],image:love.Texture?,quad:love.Quad?}
function PhysicsBackground:spawnObject(args)
    local body = love.physics.newBody(self.world, args.x, args.y, "dynamic")
    body:setLinearDamping(3)
    local shape = args.shape(body, unpack(args.shapeArgs))
    ---@class lootplot.PhysicsBackgroundObject
    local t = {
        body = body,
        shape = shape,
        image = args.image,
        quad = args.quad,
    }
    self.objects[#self.objects+1] = t
    return #self.objects
end

function PhysicsBackground:spawnItem(quad, x, y)
    return self:spawnObject({
        x = x,
        y = y,
        shape = love.physics.newCircleShape,
        shapeArgs = {PHYSICS_ITEM_SIZE},
        image = self.atlas.image,
        quad = quad,
    })
end

---@param body love.Body
local function limitVelocity(body)
    do return end
    local vx, vy = body:getLinearVelocity()
    local dist = math.sqrt(vx * vx + vy * vy)

    if dist > MAX_VELOCITY_SCALAR then
        local p = math.atan2(vy, vx)
        body:setLinearVelocity(
            math.cos(p) * MAX_VELOCITY_SCALAR,
            math.sin(p) * MAX_VELOCITY_SCALAR
        )
    end
end

local function pointInRect(x1, y1, x2, y2, x, y, l)
    return x >= (x1 - l) and y >= (y1 - l) and x < (x2 + l) and y < (y2 + l)
end

local function smolRectInBigRect(sx1, sy1, sx2, sy2, bx1, by1, bx2, by2, l)
    return
        pointInRect(bx1, by1, bx2, by2, sx1, sy1, l) or
        pointInRect(bx1, by1, bx2, by2, sx2, sy1, l) or
        pointInRect(bx1, by1, bx2, by2, sx2, sy2, l) or
        pointInRect(bx1, by1, bx2, by2, sx1, sy2, l)
end

function PhysicsBackground:update(dt, transform)
    dt = math.min(dt, 1/60) -- cap at 60fps
    self.world:update(dt)

    -- Note: Center of the screen is (0, 0)
    local width, height = love.graphics.getDimensions()
    local halfWidth = width / 2
    local screenTX, screenTY = transform:inverseTransformPoint(0, 0)
    local screenBX, screenBY = transform:inverseTransformPoint(love.graphics.getDimensions())

    for _, obj in ipairs(self.objects) do
        local x, y = obj.body:getPosition()
        local angle = obj.body:getAngle()
        local tx, ty, bx, by = obj.shape:computeAABB(x, y, angle)
        local maxSideSize = math.max(bx - tx, by - ty)

        if not smolRectInBigRect(tx, ty, bx, by, screenTX, screenTY - INVISIBLE_Y, screenBX, screenBY, maxSideSize) then
            -- Relocate
            local maxSideSize = math.max(bx - tx, by - ty)
            obj.body:setPosition(width * (math.random() - 0.5), screenTY - maxSideSize - 10)
            -- Change quad
            obj.quad = self.quads[math.random(1, #self.quads)]
        end
    end
end

-- X and Y needs to be in physics world space (use inverseTransformPoint)
function PhysicsBackground:mousepressed(x, y, b)
    -- Make items react go away froom the mouse cursor
    -- when clicked.
    local STRENGTH = 3000
    local dir

    if b == 1 then
        dir = 1
    elseif b == 2 then
        dir = -1 -- left click sucks items in
    else
        return
    end

    for _, obj in ipairs(self.objects) do
        if obj.type ~= "static" then
            local xx, yy = obj.body:getPosition()
            local dx, dy = xx - x, yy - y
            local mass = obj.body:getMass()
            local l = math.sqrt(dx * dx + dy * dy)

            if l > 0 then
                local s = (mass * STRENGTH) / (l^1.7)
                obj.body:applyLinearImpulse(s*dx*dir, s*dy*dir)
            end
        end
    end
end

function PhysicsBackground:draw()
    for _, obj in ipairs(self.objects) do
        love.graphics.push()
        love.graphics.translate(obj.body:getPosition())
        love.graphics.rotate(obj.body:getAngle())
        defaultDraw(obj)
        love.graphics.pop()
    end
end

return PhysicsBackground
