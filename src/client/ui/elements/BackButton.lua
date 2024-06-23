
--[[
    TODO: Change this to a proper back-button.
    currently, its just a pixel button.
]]



local BackButton = LUI.Element()


function BackButton:init(args)
    assert(args.goBack, "Need a `goBack` function")
    self.button = ui.elements.PixelButton({
        text = "Back",
        image = "yellow_long",
        onClick = args.goBack
    })
    self:addChild(self.button)
end



function BackButton:onRender(x,y,w,h)
    self.button:render(x,y,w,h)
end



return BackButton

