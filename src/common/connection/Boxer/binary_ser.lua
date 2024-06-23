
--[[

Binary serialization, (for interacting with C or C++ across sockets)

Note that it doesn't really matter how fast this code is,
since this is just the lua side of it all.


]]



local serializers = {}

local deserializers = {}



local buffer = string.buffer


local floor = math.floor

local string_char = string.char
local string_byte = string.byte

local bor = bit.bor
local band = bit.band
local bnot = bit.bnot
local lshift = bit.lshift
local rshift = bit.rshift


local BYTE = 0xff

local function to_u32(x)
    return string_char(
        band(rshift(x, 24), BYTE),
        band(rshift(x, 16), BYTE),
        band(rshift(x, 8), BYTE),
        band(x, BYTE)
    )
end

local function to_u16(x)
    return string_char(
        band(rshift(x, 8), BYTE),
        band(x, BYTE)    
    )
end

local function to_u8(x)
    return string_char(x)
end


local function to_string0(str)
    --[[
        assumes that `str` does not contain a null-terminator
    ]]
    return str .. "\0"
end


local function to_array(array, array_def)
    local i = 1
    local compsize = #array_def
    local buf = {false}
    assert((#array % compsize) == 0, "Bad array size!")
    while i <= #array do
        local dat = serializers[array_def[((i-1) % compsize) + 1]](array[i])
        table.insert(buf, dat)
        i = i + 1
    end
    buf[1] = serializers.u8(#array / compsize)
    return table.concat(buf)
end



local function from_u32(str, i)
    return string_byte(str, i) * (2^24) + string_byte(str, i + 1) * (2^16)
            + string_byte(str, i + 2) * (2^8) + string_byte(str, i + 3), i + 4
end


local function from_u16(str, i)
    return string_byte(str, i) * (2^8) + string_byte(str, i + 1), i + 2
end

local function from_u8(str, i)
    return string_byte(str, i), i + 1
end


local function from_string0(str, i)
    --[[
        Welp, this is gonna be such bad performance lua side. oh well!! :p
    ]]
    for j=i, str:len() do
        if str:sub(j,j) == "\0" then
            -- gottem
            return str:sub(i,j-1), j + 1
        end
    end
    return nil, "No null terminator for string"
end



local function from_array(str, i, array_def)
    local buf = {}
    local compsize = #array_def
    local arr_size,er_or_i = deserializers.u8(str, i)
    if not arr_size then
        return nil, er_or_i
    end
    i = er_or_i
    
    for u=1, arr_size do
        for k=1, compsize do
            local typ = array_def[k]
            local val, err_or_i = deserializers[typ](str, i)
            if val then
                table.insert(buf, val)
                i = err_or_i
            else
                if constants.DEBUG then
                    return nil, "Error in deserializing box array, or definition: " .. inspect(array_def) .. "\nand string index of: " .. tostring(i) .. "  with error: " .. err_or_i
                end
                return nil, "Error in deserializing binary_ser array"
            end
        end        
    end
    return buf, i
end


local function check(cond,x)
    if not cond then
        error("Bad value: " .. type(x) .. " - " .. tostring(x))
    end
end


if constants.DEBUG then
    serializers.u32 = function(x)
        check(type(x) == "number" and x >= 0 and floor(x) == x, x)
        return to_u32(x)
    end
    serializers.u16 = function(x)
        check(type(x) == "number" and x >= 0 and floor(x) == x and x < (2^16), x)
        return to_u16(x)
    end
    serializers.u8 = function(x)
        check(type(x) == "number" and x >= 0 and floor(x) == x and x < (2^8), x)
        return to_u8(x)
    end
    serializers.string0 = function(x)
        assert(type(x) == "string", "???")
        return to_string0(x)
    end
    serializers.array = function(array, array_def)
        assert(type(array) == "table", "boxing array ser expected table")
        assert(#array % #array_def == 0, "boxing array invalid multiple")
        return to_array(array, array_def)
    end
else
    serializers.u32 = to_u32
    serializers.u16 = to_u16
    serializers.u8  = to_u8
    serializers.array = to_array
end



deserializers.u32 = function(str, i)
    if #str < i + 3 then
        return nil, "deserialize for u32 too small"
    end
    return from_u32(str, i)
end

deserializers.u16 = function(str, i)
    if #str < i + 1 then
        return nil, "deserialize for u16 too small"
    end
    return from_u16(str, i)
end

deserializers.u8 = function(str, i)
    if #str < i then
        return nil, "deserialize for u8 too small"
    end
    return from_u8(str, i)
end

deserializers.string0 = from_string0

deserializers.array = from_array



if constants.TEST then
    local types = {"u8", "u16", "u32", "string0"}
    for _, typ in ipairs(types) do
        assert(serializers[typ])
        assert(deserializers[typ])
    end

    for _, t in ipairs{"u8", "u16", "u32"} do
        for i=0,2 do
            assert(deserializers[t](serializers[t](i), 1) == i)
        end
    end
    for _, t in ipairs{"u16", "u32"} do
        for i = 4530,4531 do
            assert(deserializers[t](serializers[t](i), 1) == i, t)
        end
    end
end



return {
    serializers = serializers;
    deserializers = deserializers
}

