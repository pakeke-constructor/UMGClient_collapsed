
local Slider = require("src.client.ui.elements.Slider")
local Text = require("src.client.ui.elements.Text")

local COMMON_COLOR = require("lootplot.common_color")
local COMMON_IMAGE = require("lootplot.common_image")
local StretchableBox = require("lootplot.elements.StretchableBox")
local StretchableButton = require("lootplot.elements.StretchableButton")
local ScrollBox = require("src.client.ui.elements.ScrollBox")

local sfx = require("lootplot.sfx")


local CreditsState = StateClass()

local CreditsScene = LUI.Element()



---@alias CreditSection {title:string, credits:string[]}

---@class CreditsTextBox
---@field credits CreditSection[]
local CreditsTextBox = LUI.Element()


function CreditsTextBox:init(credits)
    self.credits = credits
end


function CreditsTextBox:onRender(x,y,w,h)
    local limit = w
    local fontH = love.graphics.getFont():getHeight()

    local currY = y + fontH
    for _, creditSection in ipairs(self.credits) do
        love.graphics.printf(creditSection.title, x, currY, limit, "left", 0, 2, 2)

        currY = currY + 3 * fontH
        for _, txt in ipairs(creditSection.credits) do
            love.graphics.printf(txt, x, currY, limit, "left")
            currY = currY + fontH
        end

        currY = currY + 3 * fontH
    end
end

function CreditsTextBox:getHeight()
    local fontH = love.graphics.getFont():getHeight()
    local height = fontH
    for _, creditSection in ipairs(self.credits) do
        height = height + 3 * fontH
        for _ in ipairs(creditSection.credits) do
            height = height + fontH
        end
        height = height + 3 * fontH
    end
    return height
end




local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function splitLines(str)
    local lines = {}
    for s in str:gmatch("[^\r\n]+") do
        s = trim(s)
        if string.len(s) > 0 then
            table.insert(lines, s)
        end
    end
    return lines
end

local function alphabeticallyOrdered(list)
    local tabl = table.copy(list)
    table.sort(tabl)
    return tabl
end



function CreditsScene:init(args)
    assert(args.onClose)
    self.title = Text({text = "Credits", outline = 1})

    self.closeButton = StretchableButton({
        color = COMMON_COLOR.GREEN,
        text = "Apply",
        scale = 2,
        onClick = function()
            userService.saveSettings()
            sfx.click()
            return args.onClose()
        end,
    })

    self.box = StretchableBox(COMMON_IMAGE.WHITE_PRESSED_BIG, 8, {
        content = self.content,
        scale = 2,
        color = COMMON_COLOR.DARK_BROWN,
        stretchType = "repeat"
    })

    local credits = {
        {
            title = "Item Art",
            credits = splitLines[[
                RunninBlood - itch.io
                FinalBossblues - itch.io
                DantePixels - itch.io
                PixelEart
                Oli
            ]]
        },
        {
            title = "Slot Art",
            credits = {
                "PixelEart",
                "Oli",
            }
        },
        {
            title = "Coding and Design",
            credits = {
                "Oli",
                "AuahDark",
                "Skahd",
            }
        },
        {
            title = "Background Music",
            credits = {
                "Metta",
                "Ravi Lebgue",
            }
        },
        {
            title = "Love2D Developers",
            credits = splitLines[[
                Sasha Szpakowski
                Bart Van Strien
                Bill Meltsner
                martinfelis
                niki
                AuahDark
                ellraiser
                Matthias Richter
                Joel Schumacher
                (and others)
            ]]
        },
        {
            title = "Fonts",
            credits = {"somepx - itch.io"}
        },
        {
            title = "Other Art",
            credits = {
                "SnowyPandas - itch.io",
            }
        },
        {
            title = "Beta Testers",

            credits = alphabeticallyOrdered(splitLines[[
                xhohoo
                Juice_Baby
                Ravi Lebgue
                Tturna
                illogicalapple
                Juice_Baby
                Anoomi
                da_shreddah
                iamcheeseman
                Dot32
                pablomaybre
                nemene
                sugarsz
                pressbackspace
                Metta
            ]])
        },
        {
            title = "Sound Effects",
            credits = splitLines[[
                Roll Dice B by Bw2801 -- Attribution 4.0
                mouse click.wav by THE_bizniss -- Attribution 3.0
                Item Pickup by TreasureSounds -- Attribution 4.0
                Stick-Swoosh Whoosh  by Hitrison -- Attribution 4.0
                level up.wav by MakoFox -- Attribution 3.0
                rocker_switch.wav by joedeshon -- Attribution 4.0
                RBH Glass_Break 04.wav by RHumphries -- Attribution 4.0
            ]]
        },
        {
            title = "Other",
            credits = {
                "All other assets under CC0."
            }
        }
    }

    for _, t in ipairs(credits) do
        assert(t.credits and t.title)
        print("===================")
        print(t.title)
        print("===================")
        for _,v in ipairs(t.credits) do
            print("   ", v)
        end
    end

    assert(ui.elements)
    self.creditsScrollBox = ui.elements.ScrollBox({
        content = CreditsTextBox(credits)
    })

    self:addChild(self.box)
    self:addChild(self.title)
    self:addChild(self.creditsScrollBox)
    self:addChild(self.closeButton)
end



function CreditsScene:onRender(x, y, w, h)
    -- Make below state slightly darker
    local region = Region(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", region:get())

    local horizontalWindow = select(2, region:splitHorizontal(2, 7, 2))
    local verticalWindow = select(2, region:splitVertical(1, 9, 1))

    local window = horizontalWindow:intersection(verticalWindow)
    self.box:render(window:get())

    local windowRegion = window:padRatio(0.04)

    local title, content, closeButtonBase = windowRegion:splitVertical(2, 8, 2)

    self.creditsScrollBox:render(content:padRatio(0.1):get())

    self.title:render(title:padRatio(0.3, 0.3, 0.3, 0.1):get())

    local closeButton = closeButtonBase:padRatio(0, 0.2, 0, 0)
    self.closeButton:render(closeButton:get())
end


function CreditsState:init()
    self.scene = CreditsScene({
        onClose = function()
            return self:pop()
        end
    })
    self.scene:makeRoot()
end


CreditsState:on("update", function(self, dt)
    return self:broadcastBelow("update", dt)
end)

CreditsState:on("draw", function(self)
    love.graphics.setColor(1, 1, 1)
    self:broadcastBelow("draw")
    return self.scene:render(0, 0, love.graphics.getDimensions())
end)

local function forwardToScene(name)
    CreditsState:on(name, function(self, ...)
        return self.scene[name](self.scene, ...)
    end)
end

forwardToScene("mousepressed")
forwardToScene("mousereleased")
forwardToScene("mousemoved")

return CreditsState
