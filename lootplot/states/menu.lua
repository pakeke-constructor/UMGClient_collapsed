

local ui = require("src.client.ui.ui")

local path = tools.path(...)


local LaunchOptions = require("src.common.misc.LaunchOptions")

local MenuElement = require(path .. ".MenuElement")
local helper = require("src.client.state.helper")

local HosterSetup = require("src.client.state.setup.HosterSetup")

local lg = love.graphics


local Host = StateClass()



local function startHost(self)
    --[[
        starts hosting a server with test mod loaded
    ]]
    local launchOptions = LaunchOptions({
        modlist = {"lootplot.main"},
        onlineMode = "offline",
    })
    local hosterSetupState = HosterSetup(launchOptions)
    self:push(hosterSetupState)
end


local function getScreenView()
    return 0,0,lg.getDimensions()
end


function Host:init()
    self.scene = MenuElement({
        onPlay = function()
            startHost(self)
        end
    })
    helper.injectInput(self, self.scene)
end



Host:on("draw", function(self)
    self.scene:render(getScreenView())
end)


return Host

