
--[[

the parent element that holds the "host" screen

]]


local MenuElement = LUI.Element()




function MenuElement:init(options)
    tools.assertKeys(options, {"onPlay"})

    local elems = ui.elements

    self.playButton = elems.PixelButton({
        text = "Play",
        image = "red_long",
        onClick = options.onPlay
    })
    self:addChild(self.playButton)
    self:makeRoot()
end



function MenuElement:onRender(x,y,w,h)
    local region = Region(x,y,w,h)
    local a,_ = region:splitHorizontal(0.3,0.7)
    a,_ = a:splitVertical(0.2,0.8):pad(0.1)

    self.playButton:render(region:pad(0.25):get())
end





return MenuElement

