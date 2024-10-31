

--[[
    Same as event buses, but for asking/answering.

    This bus is responsible for `umg.ask` and `umg.answer`

=====================================

EXAMPLE USAGE:::
This is a pretty solid example, as it shows multiple independent
systems providing an answer.



-- Stun system
umg.answer("canAttack", function(ent)
    if ent.hasCoffee then
        return true
    end
    return not ent.stunned
end)


-- Sleep system.
umg.answer("canAttack", function(ent)
    return not ent.asleep
end)

-- Team handler system
umg.answer("canAttack", function(ent, targetEnt)
    return ent.team ~= targetEnt.team
end)


local reducer = function(a,b) return a and b end

local canAttack = umg.ask("canAttack", reducer, ent, targetEnt)

]]


local QuestionBus = tools.SafeClass()



function QuestionBus:init()
    self.answers = {
    --[[
        [answer] = { func1, func2, func3, ... }
    ]]
    }
end


local EMPTY = {}

function QuestionBus:ask(question, reducer, ...)
    local answers = self.answers[question] or EMPTY
    local len = #answers
    if len == 0 then
        return nil
    end

    local ans1, ans2, ans3 = answers[1](...)
    for i=2, len do
        local success
        local a1, a2, a3 = answers[i](...)
        success, ans1, ans2, ans3 = pcall(reducer, ans1,a1,  ans2,a2,  ans3,a3)

        if not success then
            local ansInfo = tools.get_func_info(answers[i])
            local redInfo = tools.get_func_info(reducer)
            error("error while calling reducer `"..redInfo.."` from answer `"..ansInfo.."`: "..ans1)
        end
    end

    return ans1, ans2, ans3
end




function QuestionBus:answer(question, func)
    self.answers[question] = self.answers[question] or {}
    table.insert(self.answers[question], func)
end



function QuestionBus:clear()
    -- clear answers
    self.answers = {}
end



local pth = tools.path(...)
if constants.TEST then
    require(pth..".tests")
end


return QuestionBus

