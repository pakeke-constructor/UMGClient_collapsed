

# SETUP STATES:
Setup pipeline for the game state.

Handles stuff like connection polling, modloading, worldloading,
cache setup, etc etc.


## GameSetupState:
Takes `IngameOptions` as input ->
Creates an IngameSession in return.
Initializes mods and everything along the way.

## HosterSetupState:
Takes `LaunchOptions` as input ->
Starts hosting a server according to the launch-options,
and creates `IngameOptions` according to the ip-port.















# PLANNING:
Q: Should we have setup as states...?
A: Yes, we probably do, because it allows for easy separation.

---

IDEA:<br/>
At the start, all states are instantiated, and pushed onto the state-stack.

When each state is done, it pops itself off the stack.
The UMGSession (or IngameSession) should be mutated appropriately.

----

### STATE IDEA: 

**Push/pop states:**
PROS:
- When popping, states don't need to know about the upper details
Yes, this is blatantly the correct way to do it.



## ok, secondary problem:
game-setup and hoster-setup is a bit weird,
how should we structure these?

IDEA:
Have a `setup` module, with nice functions to create states for setting these up.
```lua
local st = setup.GameSetupState(ingameOptions)
myState:push(st)

local st = setup.HosterGameSetupState(launchOptions)
myState:push(st)
--[[
Internally, HosterGameSetupState creates ingameOptions,
and pushes GameSetupState state onto the stack.
]] 
```






