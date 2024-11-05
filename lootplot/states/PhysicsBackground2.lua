local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")
local n9p = require("libs.n9p.n9p")

local COMMON_COLOR = require("lootplot.common_color")
local COMMON_IMAGE = require("lootplot.common_image")

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

local function drawPlayButton(obj)
    ---@type n9p.Instance
    local n9pInst = obj.other.n9p
    local x, y, w, h = n9pInst:getContentArea(obj.shapeArgs[1], obj.shapeArgs[2])
    local offx, offy = obj.shapeArgs[1] / 2, obj.shapeArgs[2] / 2

    -- Draw 9-patch image
    -- Note: The physics automatically translate to center of object
    love.graphics.setColor(COMMON_COLOR.BLUE)
    n9pInst:draw(0, 0, obj.shapeArgs[1], obj.shapeArgs[2], 0, 1, 1, offx, offy)
    love.graphics.setColor(1, 1, 1)

    -- Draw text
    local font = love.graphics.getFont()
    local tw = font:getWidth(obj.other.text)
    local th = font:getHeight()

    local limit = math.max(tw, w)
    ---@cast limit number

    -- scale text to fit box
    local scale = math.min(w/tw, h/th)

    local drawX, drawY = x - (limit - w) / 2, y + (h - th) / 2
    local realLimit = limit / scale
    local outline = 1

    if outline > 0 then
        local am = outline
        love.graphics.setColor(0, 0, 0)
        for ox=-am, am, am do
            for oy=-am, am, am do
                local oxs, oys = ox * scale, oy * scale
                love.graphics.printf(obj.other.text, font, drawX + oxs - offx, drawY + oys - offy, realLimit, "center", 0, scale, scale)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(obj.other.text, font, drawX - offx, drawY - offy, realLimit, "center", 0, scale, scale)
end

function PhysicsBackground:init(transform, onPlayClick)
    self.world = love.physics.newWorld(0, GRAVITY)
    self.atlas, self.quads = loadAtlas()
    ---@type lootplot.PhysicsBackgroundObject[]
    self.objects = {}

    -- Add "Play" button (static at (0, 0))
    local w, h = COMMON_IMAGE.WHITE_BIG:getDimensions()
    local buttonN9P = n9p.newBuilder()
        :addHorizontalSlice(8, w - 8, true)
        :addVerticalSlice(8, h - 8, true)
        :setHorizontalPadding(8, w - 8)
        :setVerticalPadding(8, h - 8)
        :build(w, h)
    buttonN9P:setTexture(COMMON_IMAGE.WHITE_BIG)
    self.playButtonIndex = self:spawnObject({
        x = 0,
        y = 30,
        type = "static",
        shape = love.physics.newRectangleShape,
        shapeArgs = {78, 42},
        draw = drawPlayButton,
        other = {
            n9p = buttonN9P,
            text = "Play!"
        },
        onClick = onPlayClick
    })

    -- Add Lootplot logo
    do
        local lpLogo = love.graphics.newImage("lootplot/assets/LOGO_PIXELATED.png")
        local scale = 0.625
        local lpWidth, lpHeight = lpLogo:getDimensions()
        self:spawnObject({
            x = 0,
            y = -100,
            type = "dynamic",
            shape = love.physics.newRectangleShape,
            shapeArgs = {scale * lpWidth, scale * lpHeight},
            image = lpLogo,
            transform = love.math.newTransform(0, 0, 0, scale, scale, lpWidth / 2, lpHeight / 2)
        })
    end

    -- Add raining items
    do
        local width = love.graphics.getWidth()
        local screenTY = select(2, transform:inverseTransformPoint(width / 2, 0))
        for _ = 1, NUM_ITEMS do
            self:spawnItem(self.quads[math.random(1, #self.quads)], width * (math.random() - 0.5), screenTY - PHYSICS_ITEM_SIZE * 2)
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
        type = type,
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
                obj.body:setLinearVelocity(0, 0)
                obj.body:setAngularVelocity(0)

                if obj.other and obj.other.item then
                    -- Change quad
                    obj.quad = self.quads[math.random(1, #self.quads)]
                end
            end
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
