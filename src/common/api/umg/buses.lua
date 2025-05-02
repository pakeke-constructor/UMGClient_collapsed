


local sf_check = tc.assert("string", "function")


local event_define_check = tc.assert("string")

local question_define_check = tc.assert("string", "function")


for _, event in ipairs(constants.KNOWN_UMG_EVENTS) do
    assert(event:sub(1,1) == "@", "wot wot, events must start with @")
end


















local function add_questions_to_api(api, lobj)
    local known_questions = lobj.modLoader.knownQuestions

    local question_to_reducer = {--[[
        A mapping of questions -> reducer
        This only includes events that are defined for THIS mod!

        [question] -> reducer_func
    ]]}

    function api.getQuestionReducer(question)
        --[[
            returns a table of userdata that was passed into `defineQuestion`
            or nil if question isnt defined
        ]]
        return known_questions[question]
    end

    function api.defineQuestion(question, reducer)
        --[[
            info_tabl argument is optional, and stores metadata about the event.
            Good for futureproofing. (could use for docs in future)
        ]]
        question_define_check(question, reducer)
        if not lobj:isNamespaced(question) then
            error(("Question needs to be namespaced by %s.\nNot the case for: %s"):format(lobj.modname, question), 2)
        end
        if known_questions[question] then
            error("Attempted to redefine a question: " .. question, 2)
        end

        question_to_reducer[question] = reducer
        known_questions[question] = reducer
    end

    local questionBus = lobj.modLoader.umgSession.questionBus

    function api.ask(question, ...)
        local reducer = question_to_reducer[question]
        if type(reducer) ~= "function" then
            error("Undefined question: " .. tostring(question) .. " with reducer " .. tostring(reducer), 2)
        end
        return questionBus:ask(question, reducer, ...)
    end

    function api.rawask(question, ...)
        error("Not yet implemented.", 2)
    end

    function api.answer(question, func)
        sf_check(question, func)
        if not known_questions[question] then
            error("Undefined question: " .. tostring(question), 2)
        end
        return questionBus:answer(question, func)
    end
end







local function add_events_to_api(api, lobj)
    -- known_events is a table of ALL known events, shared by ALL mods.
    local knownEvents = lobj.modLoader.knownEvents

    local callable_events = {--[[
        a hasher of all events.
        This only includes events that are defined for THIS mod!
        
        [eventName] = true
    ]]}

    function api.isEventDefined(evnt)
        --[[
            returns the info-table that was passed into `defineEvent`
            (or nil if the event isnt defined)
        ]]
        return knownEvents[evnt]
    end
    
    function api.defineEvent(evnt)
        --[[
            info_tabl argument is optional, and stores metadata about the event.
            Good for futureproofing. (could use for docs in future)
        ]]
        event_define_check(evnt)

        if not lobj:isNamespaced(evnt) then
            error(("Event needs to be namespaced by %s, (or have no namespace.)\nNot the case for: %s"):format(lobj.modname, evnt), 2)
        end
        if knownEvents[evnt] then
            error("Attempted to redefine an event: " .. evnt, 2)
        end
        knownEvents[evnt] = true
        callable_events[evnt] = true
    end

    -- bit of a code-smell here, but oh well
    local eventBus = lobj.modLoader.umgSession.eventBus

    function api.call(evnt, ...)
        if not callable_events[evnt] then
            error("Undefined event: " .. tostring(evnt), 2)
        end
        return eventBus:call(evnt, ...)
    end

    function api.rawcall(evnt, ...)
        -- calls an event without any checks.
        -- Allows for calling events that arent defined for this mod.
        return eventBus:call(evnt, ...)
    end

    local on_tc = tc.assert("string", "function|number", "function?")
    function api.on(evnt, func, priority)
        --[[
            can be called either way:

            umg.on("event", ...)
            umg.on("modname:event", ...)
        ]]
        on_tc(evnt, func, priority)
        if (not knownEvents[evnt]) then
            error("Undefined event: " .. tostring(evnt), 2)
        end
        return eventBus:on(evnt, func, priority)
    end
end






local function new_api(lobj)
    local api = {}
    add_events_to_api(api, lobj)
    add_questions_to_api(api, lobj)
    return api
end

return new_api
