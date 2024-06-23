

local HomeElement = LUI.Element()




local TITLE = "UNTITLED MOD\n    GAME"


function HomeElement:init(options)
    tools.assertKeys(options, {
        "gotoHost", "gotoJoin", "gotoCreate"
    })

    local elems = ui.elements

    self.title = elems.Text(self, {
        text = TITLE,
        color = {1,1,1},
        outline = 4,
        outlineColor = {0,0,0}
    })

    self.hostButton = elems.PixelButton(self, {
        text = "Host",
        image = "red_long",
        onClick = options.gotoHost
    })

    self.joinButton = elems.PixelButton(self, {
        text = "Join",
        image = "blue_long",
        onClick = options.gotoJoin
    })

    self.createButton = elems.PixelButton(self, {
        text = "Create",
        image = "green_long",
        onClick = options.gotoCreate
    })
end





local TITLE_PADDING = 0.1


function HomeElement:onRender(x,y,w,h)
    local region = Region(x,y,w,h)

    local header, bot = region:splitVertical(0.45, 0.55)

    -- Draw title:
    local titleRegion = header
        :centerX(region)
        :pad(TITLE_PADDING)
    self.title:render(titleRegion:get())

     -- split into 3 equal parts
    local join, host, create = bot:pad(0.1):splitVertical(1,1,1)
    local PAD = 0.2
    self.hostButton:render(host:pad(PAD):get())
    self.joinButton:render(join:pad(PAD):get())
    self.createButton:render(create:pad(PAD):get())
end





return HomeElement
