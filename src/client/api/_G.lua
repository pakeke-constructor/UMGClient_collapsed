
--[[

Creates the environment for the clientside modding API.

Whitelist all the functions and stuff here.

]]


local common_path = "src.common.api."
local client_path = "src.client.api."



local function make_love(lobj)
    local love = {}
    love.graphics = require(client_path .. "graphics.graphics")(lobj);
    love.mouse = require(client_path .. "mouse.mouse")(lobj);
    love.keyboard = require(client_path .. "keyboard.keyboard")(lobj);
    love.audio = require(client_path .. "audio.audio")(lobj);
    love.image = require(client_path .. "image.image")(lobj);
    love.system = require(client_path .. "system.system")(lobj);
    love.window = require(client_path .. "window.window")(lobj);
    return love
end


local function make_env(lobj)
    -- lobj, see api_loader_object.lua!
    assert(lobj, "needs api_loader_object")
    local ENV = {}
    
    ENV.client = require(client_path .. "client.client")(lobj);

    local shared_env = require(common_path .. "_G")(lobj)
    table.shallow_copy(shared_env, ENV)

    for k,v in pairs(make_love(lobj)) do
        ENV.love[k] = v
    end

    return ENV
end




return make_env
