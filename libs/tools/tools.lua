
local socket = require("socket")


local tools = {}

function tools.path(...)
    return (...):gsub('%.[^%.]+$', '')
end




local ip = require(tools.path(...)..".ip")
tools.ip_to_i32 = ip.ip_to_i32
tools.i32_to_ip = ip.i32_to_ip

function tools.u32port_to_ipport(ip_u32, port)
    return tools.i32_to_ip(ip_u32) .. ":" .. tostring(port)
end

function tools.ipport_to_ip_port(ipport)
    local f = ipport:find(":")
    assert(f)
    return ipport:sub(1, f-1), tonumber(ipport:sub(f+1))
end


function tools.is_valid_ip(ipp)
    if ipp == nil or type(ipp) ~= "string" then
        return false
    end

    local a,b,c,d,e = ipp:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    if a and b and c and d and (not e) then
        a = tonumber(a); b=tonumber(b); c=tonumber(c); d=tonumber(d)
        return not ((a<0) or (b<0) or (c<0) or (d<0) or (a>255) or (b>255) or (c>255) or (d>255))
    end
end


function tools.is_valid_port(port)
    if type(port) ~= "number" then return false end
    if math.floor(port) ~= port then return false end
    return port > 0 and port < (2^16)
end





--[[
    TODO: Move this to server-side Connection module or something?
]]
function tools.peer_to_ipport(peer)
    if (peer.get_socket_address) then
        return peer:get_socket_address()
    else
        local ipport = tostring(peer)
        local _, dots = string.gsub(ipport, "%.", "")
        local _, colons = string.gsub(ipport, "%:", "")
        assert(dots == 3 and colons == 1, "incorrect format.. uh oh")
        return ipport
    end
end

function tools.peer_to_ip(peer)
    -- ahh this is a bad way of doing it, o well
    return tools.peer_to_ipport(peer):match(".+%:"):sub(1,-2)
end



function tools.get_computer_ip()
    return socket.dns.toip(socket.dns.gethostname()) 
end



tools.nullFunction = function() end

tools.identity = function(x) return x end

tools.load_tree = require("libs.load_tree.load_tree")

tools.Set = require(tools.path(...)..".set")
tools.Array = require(tools.path(...)..".array")
tools.Class = require(tools.path(...)..".class")
tools.Struct = require(tools.path(...)..".struct")
tools.SafeTable = require(tools.path(...)..".SafeTable")
tools.SafeClass = require(tools.path(...)..".SafeClass")



function tools.assertKeys(tabl, keys)
    --[[
        asserts that `tabl` is a table, 
        and that it has all of the keys listed in the `keys` table.
    ]]
    if type(tabl) ~= "table" then
        error("Expected table, got: " .. type(tabl), 2)
    end
    for _, key in ipairs(keys) do
        if tabl[key] == nil then
            error("Missing key: " .. tostring(key), 2)
        end
    end
end


function tools.injectKeys(tabl, keyTable)
    for k,v in pairs(keyTable) do
        tabl[k] = v
    end
end


function tools.inlineMethods(self)
    --[[
        inline all methods in an object for efficiency,
        such that there is no __index overhead.
        (Just copies over key-vals)
    ]]
    local mt = getmetatable(self)
    for k,v in pairs(mt.__index) do
        self[k] = v
    end
end




local SEP_PATTERN = "%" .. constants.UMG_NAMESPACE_SEPARATOR

function tools.toNamespaced(modName, str)
    --  "modname", "str"  --->   "modname:str"
    if modName:find(SEP_PATTERN) then
        error("Invalid modname: " .. modName)
    end
    return modName .. constants.UMG_NAMESPACE_SEPARATOR .. str
end

function tools.fromNamespaced(namespacedStr)
    --  "modname:str"  --->  "modname", "str"
    local s,_ = namespacedStr:find(SEP_PATTERN)
    if s then
        return namespacedStr:sub(1,s-1), namespacedStr:sub(s+1)
    end
end





tools.hash = function(str)
    if not str then
        error("tool.hash(str) first arg is nil!")
    end
    return str:len() -- TODO; do this properly later.
    -- (apparently md5 is a good hashfunc for short strings?)
    -- it also may be a good idea to test hash distribution against
    -- minecraft usernames.
end



function tools.is_valid_filename(fname)
    --[[
        if `fname` is a valid filename, returns true.
        Else, returns false.
    ]]
    if type(fname)~="string" then
        return false
    end
    local invalids = "[\"%*%/%:%<%>%?\\%|%+%,%;%=%[%]]"
    local len_before = #fname
    local subbed = fname:gsub(invalids, "")
    if #subbed == len_before then
        return true
    end
end



function tools.remove_extension(fname)
    return fname:gsub("(.*)%..*$","%1")
end

function tools.get_extension(fname)
    return fname:match("%.[^%.]*$")
end

function tools.get_filename(fullpath)
    return fullpath:match("[^/]*$")
end



function tools.get_callable(x)
    if type(x) == "function" then
        return x
    end
    local mt = getmetatable(x)
    if mt then
        return mt.__call
    end

    return nil
end

function tools.get_func_info(x)
    local func = assert(tools.get_callable(x), "not callable")
    local info = debug.getinfo(func, "nS")
    local source

    if info.source and info.linedefined then
        source = info.source..":"..info.linedefined
    else
        -- Yeah fallback
        source = tostring(func)
    end

    return source
end



if constants.TEST then
    -- tests of exten functions
    local exten_tests = {
        ["abc.lua"] = ".lua",
        ["aba.XYZ.xxt"] = ".xxt",
        ["a.a"] = ".a",
        ["000.abc"] = ".abc",
        ["lua."] = "."
    }
    for fname, exten in pairs(exten_tests) do
        if not (tools.get_extension(fname) == exten) then
            error("test failed: " .. fname .. "  " .. exten .. " :: " .. tools.get_extension(fname))
        end
    end
end


return tools

