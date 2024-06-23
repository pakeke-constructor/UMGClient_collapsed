

local SettingsElement = LUI.Element()





function SettingsElement:init(options)
    tools.assertKeys(options, {
        "onQuit",
        "onReload"
    })

    local elems = ui.elements

    self.title = elems.Text(self, {
        text = "Paused",
        color = {1,1,1},
        outline = 4,
        outlineColor = {0,0,0}
    })

    self.hostButton = elems.PixelButton(self, {
        text = "Quit",
        image = "red_long",
        onClick = options.gotoHost
    })

    self.joinButton = elems.PixelButton(self, {
        text = "Reload",
        image = "blue_long",
        onClick = options.gotoJoin
    })

    self.sfxVolume = elems.Slider({
        min = 0, max = 1,
        onValueChanged = function(x)

        end
    })

    self.musicVolume = elems.Slider({
        min = 0, max = 1,
        onValueChanged = function(x)

        end
    })

    self.masterVolume = elems.Slider({
        min = 0, max = 1,
        onValueChanged = function(x)

        end
    })


end





local TITLE_PADDING = 0.1


function SettingsElement:onRender(x,y,w,h)
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





return SettingsElement
