
--[[

the parent element that holds the "host" screen

]]


local HostElement = LUI.Element()




function HostElement:init(options)
    tools.assertKeys(options, {"goBack", "startHost"})

    local elems = ui.elements
    self.backButton = elems.BackButton(self, {
        goBack = options.goBack
    })

    self.hostButton = elems.PixelButton(self, {
        text = "Start server",
        image = "red_long",
        onClick = options.startHost
    })
end



function HostElement:onRender(x,y,w,h)
    local region = Region(x,y,w,h)
    local a,_ = region:splitHorizontal(0.3,0.7)
    a,_ = a:splitVertical(0.2,0.8):pad(0.1)

    self.backButton:render(a:get())

    self.hostButton:render(region:pad(0.25):get())
end





return HostElement

