local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")

local PHYSICS_ITEM_SIZE = 6
local GRAVITY = 100
local NUM_ITEMS = 400
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
        for _ = 1, NUM_ITEMS do
            self:spawnItem(
                self.quads[math.random(1, #self.quads)],
                screenTX + math.random() * (screenBX - screenTX),
                screenTY + math.random() * (screenBY - screenTY)
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
        love.graphics.draw(obj.image, obj.quad, obj.transform)
    else
        love.graphics.draw(obj.image, obj.transform)
    end
end

---@param args {x:number,y:number,type:love.BodyType,shape:(fun(body:love.Body,...):love.Shape),shapeArgs:any[],onClick:function,image:love.Texture?,quad:love.Quad?,transform:love.Transform?,draw:(fun(obj:lootplot.PhysicsBackgroundObject))?,other:any}
function PhysicsBackground:spawnObject(args)
    local body = love.physics.newBody(self.world, args.x, args.y, args.type)
    local shape = args.shape(body, unpack(args.shapeArgs))
    ---@class lootplot.PhysicsBackgroundObject
    local t = {
        body = body,
        shape = shape,
        shapeArgs = args.shapeArgs,
        type = args.type,
        onClick = args.onClick,
        image = args.image,
        quad = args.quad,
        transform = args.transform,
        draw = args.draw or defaultDraw,
        other = args.other
    }
    self.objects[#self.objects+1] = t
    return #self.objects
end

local ITEM_TRANSFORM = love.math.newTransform(0, 0, 0, 1, 1, PHYSICS_ITEM_SIZE, PHYSICS_ITEM_SIZE)

function PhysicsBackground:spawnItem(quad, x, y)
    return self:spawnObject({
        x = x,
        y = y,
        type = "dynamic",
        shape = love.physics.newCircleShape,
        shapeArgs = {PHYSICS_ITEM_SIZE},
        image = self.atlas.image,
        quad = quad,
        transform = ITEM_TRANSFORM,
        other = {item = true}
    })
end

local MAX_VELOCITY_SCALAR = 50

---@param body love.Body
local function limitVelocity(body)
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

function PhysicsBackground:update(dt, transform)
    self.world:update(dt)

    -- Note: Center of the screen is (0, 0)
    local width, height = love.graphics.getDimensions()
    local halfWidth = width / 2
    local screenTY = select(2, transform:inverseTransformPoint(halfWidth, 0))
    local screenBY = select(2, transform:inverseTransformPoint(halfWidth, height))

    for _, obj in ipairs(self.objects) do
        if obj.type ~= "static" then
            local x, y = obj.body:getPosition()
            local angle = obj.body:getAngle()
            local tx, ty, bx, by = obj.shape:computeAABB(x, y, angle)

            if ty > screenBY and by > screenBY then
                -- Relocate
                -- TODO: Relocate by taking AABB into account
                obj.body:setPosition(width * (math.random() - 0.5), screenTY - math.max(bx - tx, by - ty))

                if obj.other and obj.other.item then
                    -- Change quad
                    obj.quad = self.quads[math.random(1, #self.quads)]
                end
            end

            limitVelocity(obj.body)
        end
    end
end

-- X and Y needs to be in physics world space (use inverseTransformPoint)
function PhysicsBackground:click(x, y)
    for _, obj in ipairs(self.objects) do
        if obj.onClick and obj.shape:testPoint(x, y) then
            obj.onClick()
            return
        end
    end

    -- Make items react go away froom the mouse cursor
    -- when clicked.
    -- Only executed if there's no valid click
    for _, obj in ipairs(self.objects) do
        if obj.type ~= "static" then
            local xx, yy = obj.body:getPosition()
            local dx, dy = xx - x, yy - y
            local mass = obj.body:getMass()
            local l = math.sqrt(dx * dx + dy * dy)

            if l > 0 then
                local s = (mass * 3000) / ( l * l)
                obj.body:applyLinearImpulse(s*dx, s*dy)
            end
        end
    end
end

function PhysicsBackground:draw()
    for _, obj in ipairs(self.objects) do
        love.graphics.push()
        love.graphics.translate(obj.body:getPosition())
        love.graphics.rotate(obj.body:getAngle())
        obj:draw()
        love.graphics.pop()
    end
end

return PhysicsBackground
