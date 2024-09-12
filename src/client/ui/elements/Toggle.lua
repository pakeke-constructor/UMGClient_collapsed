local Button = require("src.client.ui.elements.Button")
local Text = require("src.client.ui.elements.Text")

local Toggle = LUI.Element()

function Toggle:init(args)
    assert(args.onValueChanged)
    assert(args.value ~= nil)
    self.value = not not args.value

    self.label = Text({
        text = assert(args.label),
        color = args.labelColor
    })
    self.image = {
        [false] = love.graphics.newImage("src/client/ui/images/toggle/tiny_red_toggle.png"),
        [true] = love.graphics.newImage("src/client/ui/images/toggle/tiny_green_toggle.png")
    }
    self.button = Button({
        image = self.image[self.value],
        onClick = function()
            self.value = not self.value
            args.onValueChanged(self.value)
            -- Uh oh
            self.button.imageElement.image = self.image[self.value]
        end
    })

    self:addChild(self.label)
    self:addChild(self.button)
end

function Toggle:onRender(x,y,w,h)
    local r = Region(x,y,w,h)

    local toggle = r:shrinkToAspectRatio(1, 1):attachToRightOf(r)
    toggle.x = toggle.x - toggle.w

    self.label:render(x, y, w - toggle.w, h)
    self.button:render(toggle:get())
end

return Toggle
