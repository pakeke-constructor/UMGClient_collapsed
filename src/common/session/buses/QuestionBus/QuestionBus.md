
# Asker module:

The `asker` bus is the exact same as an event bus,
except it gathers information, instead of broadcasting information.


Ideally, asking a question should NOT change the state of the program.
The "answer" functions should be pure.


**EXAMPLE USAGE:**
This is a pretty solid example, as it shows multiple independent
systems providing an answer to the question: *"canAttack"*

```lua

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



-- Now we can ask a question, provided a reducer function
local reducer = function(a,b) return a and b end

local canAttack = umg.ask("canAttack", reducer, ent, targetEnt)

```
