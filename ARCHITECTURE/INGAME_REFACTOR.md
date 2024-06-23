

# Ingame Refactor

A bit of planning for `IngameSession`


```lua


IngameOptions {
    --[[
        Passed into IngameSetup state.

        IngameSetup state will use this to create an `IngameSession`
    ]]
    modlist = {...},

    ip = IP, -- ip-port of the server to join.
    port = PORT, -- (can be local ipport)

    isHosting = true or false
}



-- Only used clientside, whilst ingame
IngameSession {
    umgSession = UMGSession()
    clientConnection = ClientConnectionObject()

    isHosting = true or false,
    isPaused = true or false,
    canSaveWorld = true or false,
    isWorldPersistent = true or false,
    worldname = true or false,

    modlist = modlist
}


-- Only used serverside
ServerSession {
    launchOptions = LaunchOptions

    connectionObject = ServerConnectionObject()
    umgSession = UmgSession()
}

```



# What needs to be passed in?
Server: needs `LaunchOptions`
    - With LaunchOptions, creates a `ServerSession`

Ingame: needs `IngameOptions`
    - With `IngameOptions`, creates a `IngameSession`



