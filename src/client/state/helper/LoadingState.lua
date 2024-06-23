
--[[

LoadingState:
Takes an AsyncTask as input, and loads until the AsyncTask is completed.

]]

local helper

local LoadingState = StateClass()


local DUMMY = function() end






local LoadingElement = LUI.Element()
local BG_COLOR = {0.54,0.54,0.54, 0.91}

function LoadingElement:init(asyncTask)
    local elems = ui.elements
    self.text = elems.Text(self, {
        text = "",
        outline = 3
    })
    self.asyncTask = asyncTask
end

local lg = love.graphics
local function loadingBar(region, progress)
    progress = math.max(math.min(1, progress), 0)
    local x,y,w,h = region:get()
    lg.setColor(1,0,0, 0.3)
    lg.rectangle("fill", region:get())
    lg.setColor(1,0,0)
    lg.rectangle("fill", x,y, w*progress, h)
    lg.setColor(0,0,0)
    lg.setLineWidth(2)
    lg.rectangle("line", region:get())
end

function LoadingElement:onRender(x,y,w,h)
    local region = Region(x,y,w,h)
    local atask = self.asyncTask

    lg.setColor(BG_COLOR)
    lg.rectangle("fill", x,y,w,h)

    self.text:setText(atask.description)
    local progress = atask.progress

    region = region:pad(0.15, 0.2)
    local top, bot = region:splitVertical(0.5, 0.5)

    loadingBar(top:pad(0.1), progress)

    self.text:render(bot:pad(0.1):get())
end








function LoadingState:init(asyncTask, options)
    options = options or {}
    -- gotta require here to avoid loop:
    helper = helper or require("src.client.state.helper")
    self.asyncTask = asyncTask
    self.onSucceed = options.onSucceed or DUMMY
    self.onFail = options.onFail or DUMMY

    self.scene = LUI.Scene()
    helper.injectInput(self, self.scene)
    local elem = LoadingElement(false, self.asyncTask)
    elem:setView(0,0,love.graphics.getDimensions())
    self.scene:addElement(elem)
end



LoadingState:on("update", function(self)
    local atask = self.asyncTask
    if atask:isFinished() then
        self:pop() 
        -- pop first, so the controlling state is top of the stack
        -- when the callbacks are emitted
        if atask:hasFailed() then
            self.onFail()
        elseif atask:hasSucceeded() then
            self.onSucceed()
        end
        return
    end

    atask:resume()
end)


LoadingState:on("draw", function(self)
    self:broadcastBelow("draw")
    self.scene:render()
end)





return LoadingState

