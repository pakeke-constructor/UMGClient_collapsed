

local allowed = {
    "insert", "remove", "sort", -- lua functions

    "shuffle", "clear", "reverse", "copy" -- functions from batteries
    -- we also take `.pick_random` and rename it to `.random`
}

return function()
    local tabl = {}

    for _, key in ipairs(allowed)do
        tabl[key] = table[key]
    end

    -- table.random() picks a random value from the table.
    tabl.random = table.pick_random

    return tabl
end
