


local path = tools.path(...)


-- game takes arguments:   (server_enet_object)
---@class ClientState: State
local ClientState = StateClass()


local Menu
if constants.CUSTOM_BOOT_STATE then
    -- use a custom boot state! (like POPGUN)
    Menu = require(constants.CUSTOM_BOOT_STATE)
else
    -- Default UMG boot:
    Menu = require("src.client.state.menu.menu")
end

local HosterSetup = require("src.client.state.setup.HosterSetup")

local BasicLoadingVisual = require("src.client.state.helper.BasicLoadingVisual")


function ClientState:init()
    self.menu = Menu()
    self:push(self.menu)
end

if false then
    ---@return ClientState
    function ClientState() end ---@diagnostic disable-line: cast-local-type, missing-return
end


function ClientState:joinGame()
    self:popAboveStates()
    umg.melt("nyi!")
end



---@param launchOptions table
function ClientState:startHost(launchOptions)
    self:popAboveStates()

    -- start host:
    local loadingVisual = BasicLoadingVisual()
    local hosterSetupState = HosterSetup(launchOptions, loadingVisual)
    self:push(hosterSetupState)
end



return ClientState
