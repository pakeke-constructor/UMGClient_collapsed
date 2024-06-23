

local function test(newQuestionBus)
    --[[
        run some quick tests to ensure that the asker
        bus library is working correctly.
    ]]
    local qb = newQuestionBus()

    qb:answer("test", function(x, y)
        return x - y
    end)

    qb:answer("test", function(x, y)
        return x * y
    end)

    qb:answer("test", function(x, y)
        return 2*x + 2*y
    end)

    local X,Y = 3,4
    local result = qb:ask("test", function(x,y) return x + y end, X, Y)

    assert(result == (X-Y) + (X*Y) + (2*X+2*Y))
end


return test
