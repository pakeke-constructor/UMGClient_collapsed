

# FULL UMG SETUP PIPELINE:


Full overview of the UMG setup pipeline,<br/>
for BOTH server AND client.


<br/>
<br/>
<br/>
<br/>

# Server launch pipeline:
```mermaid
flowchart TD
    Reboot.json --Provides--> LaunchOptions
    Host_UI --Provides--> LaunchOptions
    LaunchOptions --Passed into via ChannelService --> ServerThread([ServerThread])
    ServerThread --ServerThread uses LaunchOptions to create ServerSession --> ServerSession
    subgraph id1 [Inside server thread]
    ServerThread
    ServerSession
    ServerSession --> SSSetup[ServerSession:setup is called]
    DONE
    end
    SSSetup --> DONE
    DONE -- Main loop --> DONE
```
(Recall that `ServerSession` contains a `UMGSession`)
<br/>
<br/>
<br/>

<br/>
<br/>
<br/>

----

# Ingame pipeline:
```mermaid
flowchart TD
    Host_UI -- LaunchOptions --> HosterSetup([hoster-setup state; creates Server-thread])
    Reboot -- LaunchOptions --> HosterSetup
    Join_UI -- Creates --> IngameOptions[IngameOptions]
    HosterSetup -- Creates --> IngameOptions
    IngameOptions --Passed into --> GameSetup([IngameSetup state; creates IngameSession])
    GameSetup --> GameSetupA[Setting up!]
    GameSetupA --> GameSetup
    GameSetup -- When ready, transfers to --> Ingame([ingame])
    Ingame -- MainLoop --> Ingame
```

<br/>
<br/>
<br/>
<br/>
<br/>

---

# hoster-setup state:
If hosting a server, (or offline,) goto hoster-setup

```mermaid
flowchart TD
    A([hoster-setup])
    START -- pass LaunchOptions --> A
    A --> Serv
    Serv --> X
    X --> Y

    subgraph id2 [Hoster setup]
        Serv[START SERVER THREAD]
    end
    X[Client waits for local-port]
    Y([Done; create IngameOptions, pass to ingame-setup])
```

<br/>
<br/>
<br/>
<br/>

-----

Now, ingame calls a bunch of setup-actions that sets shit up.
(Ingame will pass in `IngameSession`, to each action obviously)
```mermaid
flowchart TD
    GameSetup([IngameSetup state]) -- Creates --> IngameSession

    IngameSession --> A

    A[IngameSession:startSetupPipeline called by IngameSetup]

    A -- Creates SetupPipeline object:--> SetupPipeline

    subgraph SetupPipeline [SetupPipeline object]
        N0[send connectJson for auth]
        N05[Request/receive packet-id-cache]
        N1[Request mods :: NYI]
        N2[Download Mods :: NYI]
        N3[Modloader]
        N4[World setup]
    end

    N0 --> N05
    N05 --> N1
    N1 --> N2
    N1 --> N3
    N2 --> N3
    N3 --> N4
    SetupPipeline -- success --> DONE
    SetupPipeline -- failure --> FAIL

    subgraph DONE
        done1([onDone callback called.])
        done2[Transition to Ingame]
        done1 --> done2
    end

    subgraph FAIL
        fail1([onFail called!])
        fail2[pop state.]
        fail1 --> fail2
    end
```


<br/>
<br/>
<br/>
<br/>
<br/>
