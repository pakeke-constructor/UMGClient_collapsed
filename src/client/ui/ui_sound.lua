

local sounds = {}

local SOUND_FOLDER = "assets/sounds/ui"


for _, filename in ipairs(love.filesystem.getDirectoryItems(SOUND_FOLDER)) do
    local source = love.audio.newSource(SOUND_FOLDER .. "/" .. filename, "static")
    local proper_name = tools.remove_extension(filename)
    sounds[proper_name] = source
end


local volume_modifiers = {
    -- [sound_enum] = volume
    -- built-in volume modifiers; since some srcs are louder/quieter than others.
    click = 1,
    deselect = 0.4,
    select = 0.8,
    deny = 0.8
}

local function get_volume(sound_enum)
    return variables.menu_sfx_volume * (volume_modifiers[sound_enum] or 1)
end



local function play(sound_enum)
    assert(sounds[sound_enum], "Bad sound enum: " .. sound_enum)
    local src = sounds[sound_enum]
    local vol = get_volume(sound_enum)
    src:setVolume(vol)
    love.audio.play(sounds[sound_enum])
end

return play

