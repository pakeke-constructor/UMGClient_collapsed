
return function()
    local string_lib = {}

    for key,val in pairs(string)do
        string_lib[key] = val
    end

    return string_lib
end

