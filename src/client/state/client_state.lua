


local path = tools.path(...)


-- game takes arguments:   (server_enet_object)
local ClientState = StateClass()


local Menu
if constants.CUSTOM_BOOT_STATE then
    -- use a custom boot state! (like POPGUN)
    Menu = require(constants.CUSTOM_BOOT_STATE)
else
    -- Default UMG boot:
    Menu = require(path..".menu.menu")
end

local HosterSetup = require("src.client.state.setup.HosterSetup")


function ClientState:init()
    self.menu = Menu()
    self:push(self.menu)
end



function ClientState:startGame()
    self:popAboveStates()
end




function ClientState:startHost(launchOptions)
    self:popAboveStates()

    -- start host:
    local hosterSetupState = HosterSetup(launchOptions)
    self:push(hosterSetupState)
end



return ClientState
