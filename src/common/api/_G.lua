
--[[

These functions are exported to the global
namespace on both serverside and clientside.

]]

local path = tools.path(...)



return function(lobj)
    -- lobj, see LObj.lua!
    assert(lobj, "needs api_loader_object")

    local G = {}

    G.umg = require(path .. ".umg.umg")(lobj)

    G.math = require(path .. ".math.math")(lobj)
    G.table = require(path .. ".table.table")(lobj)
    G.debug = require(path .. ".debug")(lobj)

    G.love = {
        physics = require(path .. ".physics.physics")(lobj),
        timer = require(path .. ".timer.timer")(lobj),
        data = require(path .. ".data.data")(lobj);
        filesystem = require(path .. ".filesystem.filesystem")(lobj),
        math = G.math,
        getVersion = love.getVersion
    }

    G.json = json

    G.print = print
    G.error = error
    G.assert = assert

    local m = require(path .. ".metatable") -- make get/setmetatable safer
    G.setmetatable = m.setmetatable
    G.getmetatable = m.getmetatable

    G.pairs = function(x)
        -- override for safety reasons.
        if G.umg.isEntity(x) then
            error("pairs cannot be used on entities! Use ent:components() instead.", 2)
        else
            return pairs(x)
        end
    end

    G.next = next
    G.ipairs = ipairs
    G.type = type
    G.rawget = rawget
    G.rawset = rawset
    G.pcall = pcall
    G.unpack = unpack or table.unpack
    G.select = select

    G.tostring = tostring
    G.tonumber = tonumber

    G.json = {
        decode = json.decode,
        encode = json.encode
    }

    -- TODO: Ensure these other ones are fully safe
    G.string = string

    -- TODO!!! I'm pretty sure this isn't safe, since the coroutine
    -- can access globals from UMGClient.
    G.coroutine = coroutine

    G.bit = require("bit")

    G.utf8 = require("utf8")

    G.loadstring = require(path .. ".loadstring")(lobj)

    local make_require = require(path .. ".require")
    G.require = make_require(lobj, G.loadstring, {
        love = G.love,
        utf8 = G.table.deepCopy(require("utf8")),
        bit = G.table.deepCopy(require("bit"))
    })

    G._G = lobj.env

    return G
end


