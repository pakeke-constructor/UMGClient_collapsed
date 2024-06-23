
local path = (...):gsub('%.[^%.]+$', '')



local cy = tools.SafeTable()

cy.World = require(path .. ".CyWorld")


return cy
