
--[[

the parent element that holds the "host" screen

]]


local MenuElement = LUI.Element()



local intersect = require("libs.nm_batteries.intersect")

local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")

local GRAVITY = 100
local DIR = "lootplot/assets/items/"

local NUM_ITEMS = 400

local WORLD_WIDTH, WORLD_HEIGHT = 800,600



local PhysicsItem = tools.SafeClass()

local ITEM_SHAPE = love.physics.newCircleShape(10)

function PhysicsItem:init(world, quad)
    self.quad = quad
    -- In the future, have deterministic positioning.
    -- Perhaps a grid layout?
    local x,y = love.math.random(0,WORLD_WIDTH), love.math.random(0,WORLD_HEIGHT)
    local body = love.physics.newBody(world, x,y)
    self.fixture = love.physics.newFixture(body, ITEM_SHAPE)
end

function PhysicsItem:update(dt)
end

function PhysicsItem:draw(atlas)
    atlas:draw(self.quad)
end






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


local function setup(self)
    local quads
    self.atlas, quads = loadAtlas()
    self.world = love.physics.newWorld(0,GRAVITY)
    self.items = tools.Array()

    for _ = 1, NUM_ITEMS do
        local q = table.pick_random(quads)
        self.items:add(PhysicsItem(self.world, q))
    end
end

local function free(self)
    -- Clears all references to images and stuff
    self.atlas = nil
    self.items = nil
    self.world = nil
end



function MenuElement:init(options)
    tools.assertKeys(options, {"onPlay"})

    local elems = ui.elements

    self.playButton = elems.PixelButton({
        text = "Play",
        image = "red_long",
        onClick = options.onPlay
    })
    self:addChild(self.playButton)
    self:makeRoot()
end



function MenuElement:onRender(x,y,w,h)
    local region = Region(x,y,w,h)
    local a,_ = region:splitHorizontal(0.3,0.7)
    a,_ = a:splitVertical(0.2,0.8):pad(0.1)

    self.playButton:render(region:pad(0.25):get())
end





return MenuElement

