

local ui = require("src.client.ui.ui")

local path = tools.path(...)


local LaunchOptions = require("src.common.misc.LaunchOptions")

local HostElement = require(path .. ".HostElement")
local helper = require("src.client.state.helper")

local HosterSetup = require("src.client.state.setup.HosterSetup")

local lg = love.graphics


local Host = StateClass()



local function startHost(self)
    --[[
        starts hosting a server with test mod loaded
    ]]
    local launchOptions = LaunchOptions({
        modlist = {"test"},
        onlineMode = "offline",
    })
    local hosterSetupState = HosterSetup(launchOptions)
    self:push(hosterSetupState)
end


local function fitScreen(self)
    self.elem:setPreferredSize(lg.getDimensions())
end


function Host:init()
    self.scene = LUI.Scene()
    helper.injectInput(self, self.scene)

    local elem = HostElement(false, {
        goBack = helper.newPopFunction(self),
        startHost = function()
            startHost(self)
        end
    })
    self.scene:addElement(elem)
    self.elem = elem
    fitScreen(self)
end


Host:on("resize", function(self, x, y)
    self.scene:resize(x,y)
    fitScreen(self)
end)



Host:on("draw", function(self)
    self.scene:render()
end)



function Host:onExit()
end


function Host:onEnter()
    fitScreen(self)
end


return Host

