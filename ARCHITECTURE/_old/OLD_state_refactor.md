
# State refactor Old diagrams:

# UMGSessions:
UMGSessions are used on client AND server, when a game is active.  
They pretty much represent the engine context.

```mermaid
flowchart TD
    UmgSession --> cyWorld
    UmgSession --> eventBus
    UmgSession --> questionBus
    UmgSession --> EntitySyncer
```

----
<br/>


# Cy worlds:
Pretty self-explanatory. Holds the cy ECS context.<br/>
Note that cyWorlds also contain `pckrStates`.

```mermaid
flowchart TD
    cyWorld --> GroupManager
    cyWorld --> EntityManager
    cyWorld --> Packer
    Packer --> pckr_volatile
    Packer --> pckr_stable

```

---
<br/>


# IngameSession:
represents a game session on client-side.
```mermaid
flowchart TD
    IngameSession --> clientConnectionObj
    IngameSession --> UmgSession
```

---
<br/>

# ServerSession:
Represents a game session on server-side.
```mermaid
flowchart TD
    ServerSession --> serverConnectionObj
    ServerSession --> UmgSession
    ServerSession --> launchOptions
```

---
<br/>

## Modloading:
The "benefit" of globals is that we can access shit from anywhere. We need to restructure the modloader's internal loader objects a bit to compensate for our stuff no longer being global.

Each APILoaderObj needs to be able to access the `UmgSession`.

```mermaid
flowchart TD
    GlobalAPILoader --> UmgSession
    GlobalAPILoader --> loaders["Api loader objects, per mod"]
    loaders --> APILoaderObj_1
    loaders --> APILoaderObj_2
    loaders --> APILoaderObj_3
    loaders --> APILoaderObj_etc
```


