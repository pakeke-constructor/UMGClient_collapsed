
require("src.client.run")


print(("="):rep(50))
print(("-"):rep(50))
print(" ")
print("\tUMG CLIENT VERSION " .. constants.VERSION)
print(" ")
print(("-"):rep(50))
print(("="):rep(50))


local path = tools.path(...)

local hoster = require("src.client.hoster")


--love.graphics.setDefaultFilter("nearest", "nearest")

if constants.TEST then
    require("src.common.connection.Boxer.test")
    require("src.common.session.cy.cy_tests")
end




local files = require("src.common.files.files")
files.clear_temp_folder()
files.ensure_game_folders_exist()




local localization = require("src.client.localization")
localization.load()






local font

if localization.isChinese() then
    -- FixedSys font:
    font = love.graphics.newFont("assets/fonts/FSEX300.ttf", 32, "mono", 1)
    font:setFilter("linear", "linear")
    local chineseFont = love.graphics.newFont("assets/fonts/Chinese_Simplified_YRDZST_Semibold.ttf", 32, "mono", 1)
    chineseFont:setFilter("linear", "linear")
    font:setFallbacks(chineseFont)

elseif localization.isRussian() then
    font = love.graphics.newFont("assets/fonts/FSEX300.ttf", 32, "mono",1)
    font:setFilter("linear", "linear")

else
    font = assert(love.graphics.newImageFont("assets/fonts/font.png",
    ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789><:$,.!@()|_?#;/\\[]       '))
    font:setFilter("nearest", "nearest")
end



love.graphics.setFont(font)
--font:setFilter("nearest", "nearest")




-- remap love events
local ClientState = require("src.client.state.client_state")
local clientState = ClientState()


function love.update(dt)
    hoster.update()
    clientState:broadcast("update", dt)
end

function love.threaderror(thread, errstr)
    hoster.threaderror(thread, errstr)
    clientState:broadcast("threaderror", thread, errstr)
end

function love.resize(x,y)
    clientState:broadcastToAll("resize", x, y)
end


for _, ev in ipairs(constants.LOVE_EVENTS) do
    if not love[ev] then
        love[ev] = function(...)
            clientState:broadcast(ev, ...)
        end
    end
end




local reboot = require("src.client.misc.reboot")

if reboot.should_reboot() then
    local launch_options, er = reboot.read_options()
    if launch_options then
        -- Then we should reboot.
        -- change to host state, and enact quick_start argument: (a bit hacky)
        clientState:startHost(launch_options)
    else
        log.error("Couldn't reboot: ", er)
    end
end

reboot.clear_options()





if constants.SHOW_SPLASH then
    error([[
        TODO:
        We should instantiate (and push) a splash-state
        onto the clientState here.
        That would be super clean :)
    ]])
    local otenone = require("libs.nm_splash")
    local splash = otenone({background={0.1,0.1,0.1}})
    splash.onDone = startClient
end


