local Progress = require("lootplot.states.Progress")

local TransitionState = StateClass()

local function easing(x)
    if x < 0.5 then
        return 16 * x * x * x * x * x
    else
        return 1 - (-2 * x + 2) ^ 5 / 2
    end
end

function TransitionState:init(to, duration)
    self.to = to
    self.stateChanged = false
    self.duration = duration
    self.fadeOutDuration = duration
    self.fadeInDuration = duration
end

TransitionState:on("update", function(self, dt)
    if self.stateChanged then
        if self.fadeOutDuration > 0 then
            self.fadeOutDuration = math.max(self.fadeOutDuration - dt, 0)
            return self:broadcastBelow("update", dt)
        else
            -- Finalize this state
            self:pop()
        end
    else
        if self.fadeInDuration > 0 then
            self.fadeInDuration = math.max(self.fadeInDuration - dt, 0)
            return self:broadcastBelow("update", dt)
        else
            -- Perform state transition
            self:replaceBelowWith(self.to)
            self.stateChanged = true
        end
    end
end)

TransitionState:on("draw", function(self)
    love.graphics.setColor(1, 1, 1)
    self:broadcastBelow("draw")

    local width, height = love.graphics.getDimensions()
    local rectX = width * easing((self.duration - self.fadeOutDuration) / self.duration)
    local rectW = width * easing((self.duration - self.fadeInDuration) / self.duration) - rectX
    love.graphics.setColor(Progress.COLOR)
    love.graphics.rectangle("fill", rectX, 0, rectW, height)
end)

return TransitionState
