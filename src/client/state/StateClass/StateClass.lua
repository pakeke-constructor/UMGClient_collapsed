
---@class State
---@field package stateStack State[]
---@field package localListeners table<string,fun(self:State,...:any)>
---@field package listeners table<string,fun(self:State,...:any)>
local State = {}


local inspect = require("libs.nm_inspect.inspect")



local function newState(stateCls, ...)
    --[[
        IMPORTANT: This function is used for creating 
        ACTUAL State instances, NOT StateClasses!
        Remember that a StateClass is a metaclass for state-classes!
    ]]
    local self = setmetatable({
        --[[
            self.localListeners are event listeners that are relative
            to THIS SPECIFIC STATE INSTANCE.

            self.listeners are event listeners that are relative
            to the class instance
        ]]
        localListeners = {}
    }, {__index = stateCls})

    self.stateStack = tools.Array()

    if self.init then
        self:init(...)
    end
    return self
end

---@param self State
local function getTop(self)
    --[[
        gets the active state.
        The active state is always the top of the stack.
    ]]
    local stack = self.stateStack
    return stack[stack:size()]
end


local validCallbacks = {
    onEnter = true,
    onExit = true
}

local function tryCall(self, methodName)
    assert(validCallbacks[methodName], "Unknown callback")
    if not self then
        return
    end

    local func = self[methodName]
    if func then
        func(self)
    end
end


---@return State
function State:getRoot()
    return self.stateStack[1]
end

---@param state State
function State:push(state)
    --[[
        pushes a new state onto the stack
    ]]
    state.stateStack = self.stateStack
    local current = getTop(self)
    tryCall(current, "onExit") -- suspend current state
    self.stateStack:add(state)
    tryCall(state, "onEnter") -- enter new state
end



function State:pop()
    --[[
        pops this state from the stack.
        This is kinda equivalent to "exiting" the state,
        and returning control to the state above.
    ]]
    if not self:isActive() then
        error("Attempted to pop state without owning context")
        return
    end
    local top = getTop(self)
    tryCall(top, "onExit") -- exit top state
    self.stateStack:pop()
    top = getTop(self)
    tryCall(top, "onEnter")
end



function State:popAboveStates()
    --[[
        pops all states ABOVE this state,
        such that this state is at the top of the stack.

        Useful for instantly returning control to the `self` state.
    ]]
    local top = getTop(self)
    while top and top ~= self do
        top:pop()
        top = getTop(self)
    end
end



local transitionTc = tc.assert("table", "table")
---@param state State
function State:transition(state)
    transitionTc(self, state)
    --[[
        Transitions to another state.
        (pops self, and pushes another state)
    ]]
    assert(self:isActive(), "State must be active to transition")
    self:pop()
    self:push(state)
end


---@param event string
---@param func fun(self:State,...:any)
function State:on(event, func)
    if self.localListeners then
        assert(not self.localListeners[event], "Overwriting listener")
        self.localListeners[event] = func
    else
        assert(not self.listeners[event], "Overwriting listener")
        self.listeners[event] = func
    end
end


--[[
    broadcasts an event directly to a state.
]]
---@param self State
---@param event string
---@param ... any
local function call(self, event, ...)
    local func = self.localListeners[event]
    if func then
        func(self, ...)
    end
    func = self.listeners[event]
    if func then
        func(self, ...)
    end
end


---@param event string
---@param ... any
function State:broadcast(event, ...)
    --[[
        broadcasts an event to the active state
        (ie. the state at the top of the stack)
    ]]
    local top = getTop(self)
    call(top, event, ...)
end


---@param self State
local function findIndex(self)
    --[[
        finds the index of `self` within the state stack
    ]]
    local arr = self.stateStack
    for i=1, #arr do
        if arr[i] == self then
            return i
        end
    end
end

---@param event string
---@param ... any
function State:broadcastBelow(event, ...)
    --[[
        broadcasts an event to the state that is BENEATH self.
        Useful for stuff like pause states, 
        when we want to draw the scene, just not update it.
    ]]
    local i = findIndex(self) - 1
    local state = self.stateStack[i]
    if state then
        call(state, event, ...)
    end
end


---@param event string
---@param ... any
function State:broadcastToAll(event, ...)
    for _, state in ipairs(self.stateStack) do
        call(state, event, ...)
    end
end



function State:isActive()
    -- a state is active if is top of the stack
    return getTop(self) == self
end


---@param new State
function State:replaceBelowWith(new)
    assert(self:isActive(), "Cannot replace below without owning context")
    local sze = self.stateStack:size()
    local i = sze - 1
    local oldState = self.stateStack[i]
    assert(oldState, "No state to replace!")
    tryCall(oldState, "onExit")
    self.stateStack[i] = new
    new.stateStack = self.stateStack
end


---@return State? (return nil if current state is root)
function State:getSecondTop()
    local i = self.stateStack:size() - 1
    return self.stateStack[i]
end

--[[
------------
Method overrides:
------------
]]
function State:init()
end

function State:onEnter()
    -- Called when the state is made active
    -- (push or wakeup)
end
function State:onExit()
    -- Called when the state is deactivated
    -- (popped or suspended)
end

--[[
-------------
]]







---@return State
local function newStateClass()
    local StateCls = setmetatable({}, {
        __call = newState
    })

    -- listeners belong to the StateClass,
    -- NOT THE STATE!!!
    StateCls.listeners = {--[[
        [event] -> function
    ]]}

    for k,v in pairs(State) do
        StateCls[k] = v
    end

    return StateCls
end


return newStateClass
