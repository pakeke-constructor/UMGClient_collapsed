

## StateClass

`StateClass` is a class that keeps track of the


The old states are a bit unweildy and yucky.
Do some planning.

What do we want?

We want:
- ability to push/pop states
- States as objects as opposed to singletons



```lua

local MyState = StateClass()


MyState:on("update" function(dt)
    ...
end)

MyState:on("draw" function(dt)
    ...
end)


MyState:push(state) -- pushes a new state 
MyState:pop() -- pops current state

MyState:broadcast(event, ...)
-- broadcasts an event to the entire state heirarchy




function MyState:init(...)
    --[[
        called when the state is initialized
    ]]
end


function MyState:onEnter()
    print("entered state: ", self)
end


function MyState:onExit()
    print("exited state: ", self)
end



--[[
    Instantiation:
]]
state = MyState(1,2,"foobar")


```





















# SPECIFIC PLANNING:


### THINKING:
How would we represent `transition` states?
ie. fade to black, then go-to next state?

IDEA:
Create a wrapper state that transitions itself when done:
Example:
```lua
local function transitionWithFade(self)
    local fadeWrapper = FadeState({
        onCompleteState = menuState
    })

    self:transition(fadeWrapper)

    --[[
        Order of events:

        self state is top of the stack.
        self state calls this function, `transitionWithFade`
        
        self state popped
        FadeWrapper pushed
        (FadeWrapper runs for a few seconds, then completes)
        FadeWrapper pops itself, and pushes menuState
    ]]
end
```


## Thinking 2:
How would we transition to `Ingame` from `Host` state?

The direct operations required are
```
Host:
    pop
    pop
    push(IngameSetup)
```
But this is really hacky and bad, since it requires `Host` to know about the workings of the upper layer.
Also, the double-pop() is hardcoded.
It wouldn't work if there are 3 states inbetween!!! BAD!

PROPOSED SOLUTION: 
Add a `InMenu:startGame()` method that `Host` can use.
Also add `:getRoot()` function to get the root state.

we would need a `popChildren` method that pops all states below self.
So, the new operations would be:
```
Host:
    self:getRoot():startIngame()

startIngame():
    popChildren()
    pop() -- InMenu pops self
    push(IngameSetup)
```


--[[

QUESTION:
Should we have clientState as a global...??

=================================

clientState global:

PROS:
- Access from anywhere
- no need for circular dep managing
- Easy for child states to use
- Single source of truth for the project

CONS:
- Globals bad!
- States lose a bit of their elegance, since when making calls,
    they are ASSUMING that clientState contains them.



IDEA:
Have a `State:getRoot(self)` function that returns the base State.
Then we do:
self:getRoot():startGame()

^^^ Yes, this is cleaner

]]



