local sfx = {}

local SFX_DEF = {
    click = {
        source = love.audio.newSource("assets/sounds/ui/click.wav", "static"),
        volume = 0.35,
        pitch = 1.1
    }
}

for _, v in pairs(SFX_DEF) do
    v.source:setVolume(v.volume or 1)
    v.source:setPitch(v.pitch or 1)
end

---@param vol number
function sfx.setVolume(vol)
    for _, v in pairs(SFX_DEF) do
        v.source:setVolume((v.volume or 1) * vol)
    end
end

function sfx.click()
    SFX_DEF.click.source:clone():play()
end

return sfx
