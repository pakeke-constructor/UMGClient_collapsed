
--[[

A bunch of globals that are shared between client and server.

(Serves as a single source of truth, instead of defining globals
    on client AND server independently)

]]

require("src.common.misc.sandbox")

rawset(_G, "enet",      require "enet" )

require("table.new")
require("table.clear")

rawset(_G, "constants", require "src.common.constants")
rawset(_G, "variables", require "src.common.variables")

-- debug tools
if constants.TEST or constants.DEBUG then 
    rawset(_G, "inspect",   require "libs.nm_inspect.inspect")
end

rawset(_G, "json", require "src.common.json")

rawset(_G, "ffi", require "ffi")

rawset(_G, "table", require("libs.nm_batteries.tablex"))
rawset(_G.string, "buffer", require("string.buffer")) -- luaJIT's string.buffer

rawset(_G, "tools",     require "libs.tools.tools" )
rawset(_G, "tc",        require "libs.typecheck.typecheck")
rawset(_G, "log",     require("src.common.log"))

rawset(_G, "AsyncTask", require("src.common.misc.AsyncTask"))
rawset(_G, "StateClass", require("src.client.state.StateClass.StateClass"))
rawset(_G, "StringIdMapper", require("src.common.misc.StringIdMapper"))

rawset(_G, "luasteam", require("src.common.misc.luasteam"))

rawset(_G, "translate", require "src.common.translate.translate")

rawset(_G, "channelService", require "src.common.misc.channel_service")

rawset(_G, "UMGSession", require "src.common.session.UMGSession")

rawset(_G, "ModLoader", require "src.common.session.ModLoader.ModLoader")

