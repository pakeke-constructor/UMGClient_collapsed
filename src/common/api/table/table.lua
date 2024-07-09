

local allowed = {
    -- lua functions
    "insert", "remove", "sort", "foreach", "concat", "move",
}

return function()
    local tabl = {}

    for _, key in ipairs(allowed)do
        tabl[key] = table[key]
    end

    tabl.shallowCopy = table.shallow_copy
    tabl.deepCopy = table.copy
    tabl.clear = table.clear
    tabl.shuffle = table.shuffle

    -- table.random() picks a random value from the table.
    tabl.random = table.pick_random

    return tabl
end
