

local ui = require("src.client.ui.ui")

local path = tools.path(...)
local balls = require(path .. ".balls")


local spath = "src.client.state.menu"
local Join = require(spath..".join.join")
local Host = require(spath..".host.host")
local Create = require(spath..".create.create")

local HomeElement = require(path .. ".HomeElement")



local Home = StateClass()



local helper = require("src.client.state.helper")




--[[

TESTING ONLY:

]]

local TestAsyncTask = AsyncTask()

local N = 2000
function TestAsyncTask:run()
    for i=1, N do
        self:setProgress(i/N, "number: " .. i)
        self:yield()
    end
end



function Home:init()
    -- "child" states:
    local join = Join()
    local host = Host()
    local create = Create()

    self.scene = LUI.Scene()
    helper.injectInput(self, self.scene)

    local elem = HomeElement(false, {
        gotoHost = helper.newPushFunction(self, host),
        --gotoCreate = helper.newPushFunction(self, create),
        gotoCreate = function()
            local lstate = helper.LoadingState(TestAsyncTask())
            self:push(lstate)
        end,
        gotoJoin = helper.newPushFunction(self, join),
    })
    elem:setView(0,0,love.graphics.getDimensions())
    self.scene:addElement(elem)
end




Home:on("draw", function(self)
    balls.draw()
    self.scene:render()
end)


Home:on("update", function(self, dt)
    balls.update(dt)
end)



for _=1,40 do
    balls.makeBall()
end


function Home:onExit()
    
end


function Home:onEnter()
    
end


return Home
