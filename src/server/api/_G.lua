
--[[

This file holds the environment for the serverside modding API.

Whitelist all the functions and stuff here.

]]


local common_path = "src.common.api."
local server_path = "src.server.api."




return function(lobj)
    -- lobj, see api_loader_object.lua!
    assert(lobj, "needs api_loader_object")

    local ENV = {}

    local shared_env = require(common_path .. "_G")(lobj)
    table.shallow_copy(shared_env, ENV)
    
    ENV.server = require(server_path .. "server.server")(lobj)
    ENV.entities = ENV.server.entities
    
    return ENV
end


