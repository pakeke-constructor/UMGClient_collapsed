
--[[

Universal texture atlas, where every asset gets put.
(Even mod textures!)

This atlas is cleared every time the mods reset

]]

local AutoAtlas = require("libs.AutoAtlas.AutoAtlas")
local atlas = AutoAtlas(4096, 4096)

return atlas
