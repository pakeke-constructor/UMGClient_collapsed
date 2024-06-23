
--[[

UI module

]]

local path = tools.path(...)

local images = require(path .. ".images")


local ui = {}
-- gotta define global here so our elements can access ui table
rawset(_G, "ui", ui)

ui.style = require(path .. ".style")

ui.getImage = images.getImage


ui.elements = {} -- LUI elements
tools.load_tree("src/client/ui/elements", ui.elements)



ui.sound = require("src.client.ui.ui_sound")

return ui

