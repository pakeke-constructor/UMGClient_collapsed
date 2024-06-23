
--[[

Client menu util functions

]]

local helper = {}


local LUI_INPUT_EVENTS = {
    "mousepressed", "mousereleased",
    "mousemoved", "wheelmoved",
    "keypressed", "textinput", "keyreleased",
}


function helper.injectInput(state, luiElem)
    --[[
        injects input events into the LUI scene
    ]]
    assert(luiElem:isRoot(), "?")
    for _, event in ipairs(LUI_INPUT_EVENTS) do
        state:on(event, function(_, a,b,c,d,e,f,g)
            local method = luiElem[event]
            method(luiElem, a,b,c,d,e,f,g)
        end)
    end

    state:on("resize", function(_, x,y)
        luiElem:resize(x,y)
        state:broadcastBelow("resize", x,y)
    end)
end



local twoStateTc = tc.assert("table", "table")
local stateTc = tc.assert("table")


function helper.newTransitionFunction(state, newState)
    twoStateTc(state, newState)
    --[[
        creates a state transition function,
            state --> newState
    ]]
    return function()
        if state:isActive() then
            state:transition(newState)
        else
            log.error("State wasn't active, couldn't transition")
        end
    end
end


function helper.newPushFunction(state, newState)
    twoStateTc(state, newState)
    --[[
        creates a state push function,
            state --> newState
    ]]
    return function()
        if state:isActive() then
            state:push(newState)
        else
            log.error("State wasn't active, couldn't push")
        end
    end
end


function helper.newPopFunction(state)
    --[[
        creates a state pop function
    ]]
    stateTc(state)
    return function()
        if state:isActive() then
            state:pop()
        else
            log.error("State wasn't active, couldn't pop")
        end
    end
end



local t = tools.load_tree("src/client/state/helper")
for k,v in pairs(t) do
    if helper[k] then
        error("overwriting key: " .. k)
    end
    helper[k] = v
end



return helper
