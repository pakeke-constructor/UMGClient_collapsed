

local path = tools.path(...)

local parse = require(path .. ".parse")

string.buffer = require("string.buffer")



local box = {}





local function clear_buffer(buffer)
    for i=1, #buffer do
        buffer[i] = nil
    end
end

local function push_buffer(buffer, x)
    buffer[#buffer + 1] = x
end

local function push6_buffer(buffer, a,b,c,d,e,f)
    local l = #buffer
    buffer[l+1] = a
    buffer[l+2] = b
    buffer[l+3] = c
    buffer[l+4] = d
    buffer[l+5] = e
    buffer[l+6] = f
end


local function concate_buffer(buffer)
    return table.concat(buffer, "")
end



local binary_ser = require(path .. ".binary_ser")
local sers = binary_ser.serializers
local desers = binary_ser.deserializers


local binary_buf = {}

function box.box(box_type, a, b, c, d, e, f)
    local id = parse.boxtype_to_id[box_type]
    clear_buffer(binary_buf)
    push_buffer(binary_buf, sers.u8(id))
    push6_buffer(binary_buf, a,b,c,d,e,f)
    local typelist = parse.boxtype_to_typelist[box_type]

    for i=2, #binary_buf do
        if binary_buf[i] and typelist[i-1] then
            local typ = typelist[i-1]
            if type(typ) == "table" then
                binary_buf[i] = sers.array(binary_buf[i], typ)
            else
                binary_buf[i] = sers[typelist[i-1]](binary_buf[i])
            end
        else
            break
        end
    end
    local data = concate_buffer(binary_buf)

    return data
end


local function make_err(box_type, err)
    return "[boxing/box]: unbox issue for boxtype: " .. box_type .. "\n" .. err
end


function box.unbox(data, start_i)
    --[[
        We don't care about speed for this, its just on the lua side
    ]]
    local i = start_i or 1
    local id
    id, i = desers.u8(data, i)
    if (not id) then
        return nil, "box data was empty!"
    end
    
    local box_type = parse.id_to_boxtype[id]

    if not box_type then
        return nil, "Recieved unrecognized box id"
    end

    local types = parse.boxtype_to_typelist[box_type]
    
    local buf = {
        -- I Don't care about performance for this!!!!
    }

    for _, typ in ipairs(types) do
        local val, err_or_i
        if type(typ) == "table" then
            -- we got an array type! 
            val, err_or_i = desers.array(data, i, typ)
            if not val then
                return nil, err_or_i
            end
        else
            -- Else its just normal
            val, err_or_i = desers[typ](data, i)
            i = err_or_i
            if not val then
                return nil, make_err(box_type, err_or_i)
            end
        end
        i = err_or_i
        table.insert(buf, val)
    end

    return box_type, unpack(buf)
end





local boxtype_to_id = parse.boxtype_to_id
local id_to_boxtype = parse.id_to_boxtype
local boxtype_to_typelist = parse.boxtype_to_typelist

local table_insert = table.insert

local function push(buffer, box_type, a,b,c,d,e,f)
    local ptr = buffer.ptr
    if not (boxtype_to_id[box_type]) then
        error("Invalid boxtype: " .. tostring(box_type))
    end
    buffer[ptr] = boxtype_to_id[box_type]
    local boxsize = #boxtype_to_typelist[box_type]

    -- TODO: Convert this to a table-based switch.
    -- a table-based switch WILL be faster under LJIT I think.
    if boxsize == 1 then
        table_insert(buffer, a)
    elseif boxsize == 2 then
        table_insert(buffer, a)
        table_insert(buffer, b)
    elseif boxsize == 3 then
        table_insert(buffer, a)
        table_insert(buffer, b)
        table_insert(buffer, c)
    elseif boxsize == 4 then
        table_insert(buffer, a)
        table_insert(buffer, b)
        table_insert(buffer, c)
        table_insert(buffer, d)
    elseif boxsize == 5 then
        table_insert(buffer, a)
        table_insert(buffer, b)
        table_insert(buffer, c)
        table_insert(buffer, d)
        table_insert(buffer, e)
    elseif boxsize == 6 then
        table_insert(buffer, a)
        table_insert(buffer, b)
        table_insert(buffer, c)
        table_insert(buffer, d)
        table_insert(buffer, e)
        table_insert(buffer, f)
    end
    buffer.ptr = ptr + #boxtype_to_typelist[box_type] + 1
end



local encode = string.buffer.encode



local function flush(buffer)
    local old_len = buffer.ptr
    buffer.push = nil
    buffer.ptr = nil
    buffer.flush = nil

    local data = encode(buffer)
    
    for i=1, old_len do
        buffer[i] = nil
    end
    buffer.push = push
    buffer.ptr = 1
    buffer.flush = flush   
    return data
end


function box.box_many()
    local buffer = {
        ptr = 1;
        push = push;
        flush = flush
    }

    return buffer
end


function box.box_single(boxname, ...)
    --[[
        slow function used to box a singular value.
    ]]
    local b = box.box_many()
    b:push(boxname, ...)
    return b:flush()
end




local function getData(reader, num_args)
    --[[
        I suspect that the JIT will make this code trace extremely fucking hot.
    ]]
    local buffer = reader.buffer
    local i = reader.i
    reader.i = i + num_args

    if num_args == 0 then
        return
    elseif num_args == 1 then
        return buffer[i]
    elseif num_args == 2 then
        return buffer[i], buffer[i + 1]
    elseif num_args == 3 then
        return buffer[i], buffer[i + 1], buffer[i + 2]
    elseif num_args == 4 then
        return buffer[i], buffer[i + 1], buffer[i + 2], buffer[i+3]
    elseif num_args == 5 then
        return buffer[i], buffer[i + 1], buffer[i + 2], buffer[i+3], buffer[i+4]
    elseif num_args == 6 then
        return buffer[i],  buffer[i + 1], buffer[i + 2],
                buffer[i+3], buffer[i+4], buffer[i+5]
    end
end


local function poll(reader)
    local id = reader.buffer[reader.i]
    if not id then
        return nil
    end
    
    reader.i = reader.i + 1
    
    local box_type = id_to_boxtype[id]
    if not box_type then
        return nil, "Unknown id"
    end

    if not boxtype_to_typelist[box_type] then
        log.warn("Unknown box type:  ", box_type)
        return nil, "Unknown box type"
    else
        local num_args = #boxtype_to_typelist[box_type]
        return box_type, getData(reader, num_args)
    end
end


local decode = string.buffer.decode


function box.unbox_many(data)
    assert(data, "no data!")
    local reader = {poll = poll; i=1}
    local success, buffer = pcall(decode, data)
    if success then
        reader.buffer = buffer
    else
        reader.buffer = ""
    end
    return reader
end



function box.is_valid(box_name)
    return parse.boxtype_to_id[box_name]
end




return box

