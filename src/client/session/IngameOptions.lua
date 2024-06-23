

--[[

This is just a table passed into ingame-setup state.
(It holds a data relevant to clientside setup.)


IngameOptions {
    -- Passed into IngameSetup state.
    -- IngameSetup state will use this to create an `IngameSession`

    modlist = {...},

    ip = IP, -- ip-port of the server to join.
    port = PORT, -- (can be local ipport)

    isHosting = true or false
}


]]


local KEYS = {
    "ip", "port", "modlist", "isHosting"
}

local function assertValid(options)
    tools.assertKeys(options, KEYS)
    assert(type(options.ip) == "string")
    assert(type(options.port) == "number")
    assert(type(options.modlist) == "table")
    return options
end

return assertValid

