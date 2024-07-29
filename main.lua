
love.graphics.setDefaultFilter("nearest", "nearest")

love.filesystem.setIdentity("umg")


setmetatable(_G, {__index = function(_,k)
    error("Undefined variable: "..tostring(k))
end;
__newindex = function(_,k,_)
    error("Non local created: " .. tostring(k))
end})



rawset(_G, "CLIENT_SIDE", true)
rawset(_G, "SERVER_SIDE", false)
-- we are on client-side


-----
-----============================
----- Common globals
-----
----- Shared between client/server for consistency,
----- (And so that there's a single source of truth)
require("src.common.globals")
-----=============================
-----

assert(ffi.abi("le"), "Bad endianness. This game will not run on your computer.")


rawset(_G, "Slab",    require "libs.nm_Slab")
rawset(_G, "Region",    require "libs.kirigami.region")
rawset(_G, "LUI",       require "libs.LUI")

rawset(_G, "LoadingLogo", require "src.client.misc.LoadingLogo.LoadingLogo")


rawset(_G, "ui",        require "src.client.ui.ui")


rawset(_G, "userService", require("src.client.userService"))


require("src.client.client")

