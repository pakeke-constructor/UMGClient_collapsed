
local function make_loadstring(lobj)
    local env = lobj.env
    
    return function(string, chunkname)
        -- "t" options ensures that bytecode can't be loaded
        local chunk, err = loadstring(string, chunkname, "t")
        if chunk then
            setfenv(chunk, env)
        end
        return chunk, err
    end
end


return make_loadstring
