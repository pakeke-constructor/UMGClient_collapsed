local PixelButton = require("lootplot.elements.PixelButton")
local Text = require("src.client.ui.elements.Text")

local sfx = require("lootplot.sfx")


local DESCRIPTION = [[
We use analytics to
improve the game balance
and to diagnose crashes.

If you want to help us 
make the game better,
please allow analytics!
Thank you! :D
]]


local AnalyticsPopupScene = LUI.Element()

function AnalyticsPopupScene:init(state, save)
    local desc = DESCRIPTION:gsub("\r\n", "\n")

    self.title = Text("Analytics Consent")
    self.content = Text(desc)
    self.acceptButton = PixelButton({
        color = "green",
        text = "Allow",
        onClick = function()
            sfx.click()
            userService.setAnalyticsConsent(true)
            if save then
                userService.saveSettings()
            end
            return state:pop()
        end,
    })
    self.rejectButton = PixelButton({
        color = "red",
        text = "Deny",
        onClick = function()
            sfx.click()
            userService.setAnalyticsConsent(false)
            if save then
                userService.saveSettings()
            end
            return state:pop()
        end,
    })

    local status
    if userService.isAnalyticsConsentAsked() then
        status = userService.isUserConsentedForAnalytics() and "Enabled" or "Disabled"
    else
        status = "Undecided"
    end
    self.analyticsStatus = Text("Analytics status: "..status)

    self:addChild(self.title)
    self:addChild(self.content)
    self:addChild(self.analyticsStatus)
    self:addChild(self.acceptButton)
    self:addChild(self.rejectButton)
end

function AnalyticsPopupScene:onRender(x, y, w, h)
    -- Make below state slightly darker
    local region = Region(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", region:get())

    local horizontalWindow = select(2, region:splitHorizontal(2, 9, 2))
    local verticalWindow = select(2, region:splitVertical(1, 6, 1))
    local settingWindowRegionBase = horizontalWindow:intersection(verticalWindow)
    love.graphics.setColor(love.math.colorFromBytes(133, 81, 21))
    love.graphics.rectangle("fill", settingWindowRegionBase:get())

    local windowRegion = settingWindowRegionBase:pad(0.04)
    local titleBase, contentUnpad, status, buttonBase = windowRegion:splitVertical(3, 6, 1, 2)

    local title = titleBase:pad(0.01)
    love.graphics.setColor(1, 1, 1)
    self.title:render(title:get())

    local content = contentUnpad:pad(0.04)
    self.content:render(content:get())

    self.analyticsStatus:render(status:get())

    local allow, _, deny = select(2, buttonBase:pad(0.05):splitHorizontal(1, 4, 1, 4, 1))
    self.acceptButton:render(allow:get())
    self.rejectButton:render(deny:get())
end



local AnalyticsPopupState = StateClass()

function AnalyticsPopupState:init(save)
    self.scene = AnalyticsPopupScene(self, save)
    self.scene:makeRoot()
end

AnalyticsPopupState:on("update", function(self, dt)
    return self:broadcastBelow("update", dt)
end)

AnalyticsPopupState:on("draw", function(self)
    love.graphics.setColor(1, 1, 1)
    self:broadcastBelow("draw")
    return self.scene:render(0, 0, love.graphics.getDimensions())
end)

local function forwardToScene(name)
    AnalyticsPopupState:on(name, function(self, ...)
        return self.scene[name](self.scene, ...)
    end)
end
forwardToScene("mousepressed")
forwardToScene("mousereleased")
forwardToScene("mousemoved")

return AnalyticsPopupState
