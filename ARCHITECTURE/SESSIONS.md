

# Session architecture:

When a game is active, ALL state is encapsulated in session objects.<br/>
There are two main ones that contain all others:<br/>
`ServerSession` and `IngameSession`.


<br/>
<br/>
<br/>


# IngameSession:
represents a game session on client-side.
```mermaid
flowchart TD
    IngameSession --> ClientConnection
    IngameSession --> UMGSession
    IngameSession --> HostContext[HostContext or nil]
    IngameSession -. can create, pass in Connection .-> ModLoader
```

---
<br/>
<br/>

# ServerSession:
Represents a game session on server-side.
```mermaid
flowchart TD
    ServerSession --> ServerConnection
    ServerSession --> UMGSession
    ServerSession --> LaunchOptions
    ServerSession --> WorldLoader
    ServerSession -. can create, pass in Connection .-> ModLoader
```

---
<br/>




-----
<br/>

# UMGSessions:
UMGSessions are used on client AND server, when a game is active.  
They pretty much represent the engine context.

```mermaid
flowchart TD
    UMGSession --> CyWorld
    UMGSession --> EventBus
    UMGSession --> QuestionBus
    UMGSession --> Packer
```

----
<br/>
<br/>
<br/>



# Packer object:
Responsible for serializing / deserializing data.<br/>
Also holds information about which entities have been serialized, to ensure we send by `id` when appropriate. (Previously, `entity_add_remove` was in charge of this.)

(Decouple pckr from cy. should never have been coupled in the first place.)
```mermaid
flowchart TD
    Packer --> pckr_volatile
    Packer --> pckr_stable

```

---
<br/>
<br/>
<br/>

# Cy worlds:
Pretty self-explanatory: holds the cy ECS context.<br/>
```mermaid
flowchart TD
    cyWorld --> GroupManager
    cyWorld --> EntityManager

```

---
<br/>
<br/>
<br/>


# Connection Objects:
```mermaid

flowchart TD
    Connection[Connection]

    Connection -- inherit --> server
    Connection -- inherit --> client

    subgraph server
        ServerConnection
    end

    subgraph client
        ClientConnection
    end

    Connection --> Boxer
    Connection --> Packer
```



<br/>
<br/>
<br/>


## Modloading:
The "benefit" of globals is that we can access shit from anywhere. We need to restructure the modloader's internal loader objects a bit to compensate for our stuff no longer being global.

Each APILoaderObj needs to be able to access the `UMGSession`.

```mermaid
flowchart TD
    ModLoader --> UMGSession
    ModLoader --> Connection[Server/Client Connection]
    ModLoader --> loaders["Api loader objects, one per mod"]
    loaders --> A1[APILoaderObj]
    loaders --> A2[APILoaderObj]
    loaders --> A3[APILoaderObj]
    loaders --> A4[APILoaderObj]
```

