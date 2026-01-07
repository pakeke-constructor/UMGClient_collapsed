local PixelButton = require("lootplot.elements.PixelButton")
local Text = require("src.client.ui.elements.Text")

local sfx = require("lootplot.sfx")
local COMMON_COLOR = require("lootplot.common_color")
local COMMON_IMAGE = require("lootplot.common_image")
local StretchableBox = require("lootplot.elements.StretchableBox")
local StretchableButton = require("lootplot.elements.StretchableButton")



local loc = localization.localize



local LanguageSelectScene = LUI.Element()

function LanguageSelectScene:init(state)
    -- Always create the FixedSYS + Chinese fallback font.
    local font = love.graphics.newFont("assets/fonts/FSEX300.ttf", 32, "mono", 1)
    font:setFilter("nearest", "nearest")
    local chineseFont = love.graphics.newFont("assets/fonts/Chinese_Simplified_YRDZST_Semibold.ttf", 32, "mono", 1)
    chineseFont:setFilter("nearest", "nearest")
    font:setFallbacks(chineseFont)

    self.title = Text(loc"Language Select (Need Restart)")

    self.langList = localization.getLanguageList()
    self.languageButtons = {}
    for _, lang in ipairs(self.langList) do
        local selected = userService.getLanguage() == lang
        local langtext = lang
        if localization.NAMES[lang] then
            langtext = string.format("%s (%s)", localization.NAMES[lang], lang)
        end

        local elem = StretchableButton({
            color = selected and COMMON_COLOR.BLUE or COMMON_COLOR.WHITE,
            text = langtext,
            font = font,
            scale = 2,
            onClick = function()
                sfx.click()
                userService.setLanguage(lang)
                return state:pop()
            end,
        })
        self.languageButtons[#self.languageButtons+1] = elem
        self:addChild(elem)
    end


    self:addChild(self.title)
end

function LanguageSelectScene:onRender(x, y, w, h)
    local r = Region(x, y, w, h)

    local windowR = r:padRatio(0.04)
    local titleR, contentBaseR = windowR:splitVertical(1, 4)

    local title = titleR:padRatio(0.01)
    love.graphics.setColor(1, 1, 1)
    self.title:render(title:get())

    -- Draw as grid
    local grid = contentBaseR:grid(1, #self.languageButtons)
    for i, button in ipairs(self.languageButtons) do
        button:render(grid[i]:padUnit(4):get())
    end
end



local LanguageSelectPopupSceneRoot = LUI.Element()

function LanguageSelectPopupSceneRoot:init(...)
    self.content = LanguageSelectScene(...)
    self.box = StretchableBox(COMMON_IMAGE.WHITE_PRESSED_BIG, 8, {
        content = self.content,
        scale = 2,
        color = COMMON_COLOR.DARK_BROWN,
        stretchType = "repeat"
    })

    self:addChild(self.box)
end

function LanguageSelectPopupSceneRoot:onRender(x, y, w, h)
    -- Make below state slightly darker
    local r = Region(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", r:get())

    local horzWindowR = select(2, r:splitHorizontal(2, 9, 2))
    local vertWindowR = select(2, r:splitVertical(1, 6, 1))
    local settingWindowBaseR = horzWindowR:intersection(vertWindowR)
    return self.box:render(settingWindowBaseR:get())
end



local LanguageSelectPopupState = StateClass()

function LanguageSelectPopupState:init(save)
    self.scene = LanguageSelectPopupSceneRoot(self, save)
    self.scene:makeRoot()
end

LanguageSelectPopupState:on("update", function(self, dt)
    return self:broadcastBelow("update", dt)
end)

LanguageSelectPopupState:on("draw", function(self)
    love.graphics.setColor(1, 1, 1)
    self:broadcastBelow("draw")
    return self.scene:render(0, 0, love.graphics.getDimensions())
end)

local function forwardToScene(name)
    LanguageSelectPopupState:on(name, function(self, ...)
        return self.scene[name](self.scene, ...)
    end)
end
forwardToScene("mousepressed")
forwardToScene("mousereleased")
forwardToScene("mousemoved")

return LanguageSelectPopupState
