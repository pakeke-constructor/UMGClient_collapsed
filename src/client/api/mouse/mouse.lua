

---@param obj any
---@param t string
---@return boolean
local function isLOVEType(obj, t)
    return type(obj) == "userdata" and obj.typeOf and obj:typeOf(t)
end



local function convert_first_arg_to_filedata(lobj, func)
    --[[
        we need to restrict the user so they can't load arbitrary
        files on the system.
        We do this by checking if the first arg is a string,
        and if so, mangle it.
    ]]
    return function(a,...)
        local t = type(a)
        if t == "string"  then
            -- its a filename, convert first arg to filedata
            local path = a
            local filedata = lobj.fsysObj:newFileData(path)
            return func(filedata, ...)
        elseif not isLOVEType(a, "FileData") then
            if isLOVEType(a, "Object") then
                ---@cast a love.Object
                t = a:type()
            end

            error("argument type '"..t.."' is not allowed")
        end

        return func(a,...) -- a is not a path, so OK.
    end
end



return function(lobj)
    local mouse = {}

    for k,v in pairs(love.mouse)do
        mouse[k] = v
    end

    mouse.newCursor = convert_first_arg_to_filedata(lobj, mouse.newCursor)

    return mouse
end

