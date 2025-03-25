
local assert = assert
local error = error

local select = select
local pairs = pairs

local getmetatable = getmetatable
local setmetatable = setmetatable

local rawget = rawget

local type = type
local concat = table.concat

local table_unpack = unpack
local unpack = love.data.unpack
local pack = love.data.pack

local abs = math.abs
local floor = math.floor

local byte = string.byte
local len = string.len
local sub = string.sub

local pcall = pcall




local USMALL = 230 -- there is another uint8 following this. 
-- This means that `usmall` can be between 0 - 58880, and only take up 2 bytes!
local MAX_USMALL = 58880
local USMALL_NUM = 230


-- local I16 = "\237" -- Don't serialize I16s, it will just waste time;
        -- we already have USMALL which covers most of the I16.

local I32 = "\234"
local I64 = "\235"

local U32 = "\236"
local U64 = "\237"

local NUMBER = "\238"

local NIL   = "\239"

local TRUE  = "\240"
local FALSE = "\241"

local STRING = "\242"
local STRING_REF_LEN = 4 -- strings must be at least X chars long 
                        -- to be counted as a reference.

local TABLE_WITH_META = "\244" -- ( table // flat-table // array, metatable )

-- These are all the possible table headers
local ARRAY   = "\246" -- (just values)
local ARRAY_END = "\247"

local TABLE   = "\249" -- (table data; must use `pairs` to serialize)

local TABLE_END = "\250" -- NULL terminator for tables.

local RESOURCE  = "\252" -- (ANY_TYPE alias_ref)
local REF = "\253" -- (uint ref)

local ENT_ID  = "\254" -- cy Ent id 
local ENT = "\255"  -- cy ENT:   ENT  ent_type_name  template_data



local PREFIX = ">!1"



-- unique values for equality checks
local UNIQUE_TABLE_END = {}
local UNIQUE_ARRAY_END = {}

-- unique key for ref hashers.
local COUNT = {"reference_counter"}


---@class PckrState
local PckrState = {}
local PckrState_mt = {__index = PckrState}



local function assertCallbacks(cbs)
    -- These are required:
    assert(cbs.canSerializeEntity)
    assert(cbs.getEntityById)
    assert(cbs.deserializeEntity)
    assert(cbs.shouldSerializeEntityById)
end


---@param options {canSerializeEntity:function,getEntityId:function,deserializeEntity:function,shouldSerializeEntityById:function}
---@return PckrState
local function newPckrState(options)
    --[[
        creates a new pckr state.
    ]]
    local self = setmetatable({}, PckrState_mt)
    self:init(options)
    return self
end

---@param options {canSerializeEntity:function,getEntityId:function,deserializeEntity:function,shouldSerializeEntityById:function}
function PckrState:init(options)
        -- resource registration:
    self.alias_to_resource = {}
    self.resource_to_alias = {}

    self.is_entity_mt = {--[[
        [mt] --> true / false
        whether `mt` is a metatable of an entity or not.
    ]]}

    self.typename_to_etype = {--[[
        [etypename] -> etype
        maps etype-names to entity-types
    ]]}

    -- callbacks:
    assertCallbacks(options)
    self.canSerializeEntity = options.canSerializeEntity
    self.getEntityById = options.getEntityById
    self.deserializeEntity = options.deserializeEntity
    self.shouldSerializeEntityById = options.shouldSerializeEntityById
    self.serializeEntity = options.serializeEntity

    -- options:
    assert(options.shouldSerializeIdOfEntity ~= nil)
    self.shouldSerializeIdOfEntity = options.shouldSerializeIdOfEntity
end




local function get_ser_funcs(type_, is_bytedata)
    local container = "string"
    if is_bytedata then
        container = is_bytedata
    end
    local format = PREFIX .. type_

    local ser = function(data)
        return pack(container, format, data)
    end

    local deser = function(data)
        local no_err, val, errstr = pcall(unpack, format, data)
        if no_err then
            return val
        else
            return nil, errstr
        end
    end

    return ser, deser
end







function PckrState:register(resource, alias, options)
    options = options or {}
    assert(alias, "register(resource, alias): Not given an alias")
    if type(resource) == "number" or type(resource) == "nil" or type(resource) == "boolean" then
        error("register(resource, alias): You cannot register bools, numbers, or nil.")
    end
    if type(alias) == "table" then 
        error("incorrect register usage")
    end
    if (not options.allow_override) and self.alias_to_resource[alias] then
        error("Duplicate registration of resource: " .. alias)
    end
    self.alias_to_resource[alias] = resource
    self.resource_to_alias[resource] = alias
end




---@param etype_name string
---@param etype table
function PckrState:registerEntityType(etype_name, etype)
    assert(type(etype_name) == "string")
    assert(type(etype) == "table")
    
    local entity_mt = etype:getEntityMt()

    self.is_entity_mt[entity_mt] = true
    self.typename_to_etype[etype_name] = etype

    -- we need to register the etype itself,
    self:register(etype, etype_name)

    -- and we should prolly register the etype mt too.
    self:register(entity_mt, etype_name .. "_@entity_mt")
end






local function get_res_alias(self, res_or_alias)
    -- gets resource, alias  tuple with either res or alias.
    -- returns nil if neither are registered
    local res, alias
    if self.resource_to_alias[res_or_alias] then
        res = res_or_alias
        alias = self.resource_to_alias[res_or_alias]
    elseif self.alias_to_resource[res_or_alias] then
        alias = res_or_alias
        res = self.alias_to_resource
    end
    return res, alias
end


function PckrState:unregister(res_or_alias)
    if not res_or_alias then
        error("expects either a name, resource, or metatable")
    end
    local res, alias = get_res_alias(self, res_or_alias)
    if self.alias_to_resource[alias] then
        self.alias_to_resource[alias] = nil
        self.resource_to_alias[res] = nil
        unregister_low(self, res)
        return true
    end
    return false
end







local serializers = {}

local deserializers = {}




--[[

Serializers:

]]

local function add_ref(buffer, x)
    local refs = buffer.refs
    local new_count = refs[COUNT] + 1
    refs[x] = new_count
    refs[COUNT] = new_count
end




local function push_str(buffer, x)
    -- pushes `x` onto the buffer
    local newlen = buffer.len + 1
    buffer[newlen] = x
    buffer.len = newlen
end



local function push_ref(buffer, ref_num)
    push_str(buffer, REF)
    serializers.number(buffer, ref_num)
end



local function push_resource(buffer, res)
    local alias = buffer.self.resource_to_alias[res]
    assert(alias, "No alias given!")
    push_str(buffer, RESOURCE)
    serializers[type(alias)](buffer, alias)
end


local function try_push_resource(buffer, res)
    local alias = buffer.self.resource_to_alias[res]
    if alias then
        push_str(buffer, RESOURCE)
        serializers[type(alias)](buffer, alias)
        return true
    end
    return false
end



local function func_error(x)
    local info = debug.getinfo(x)
    local src = info.source or "(unknown file)"
    if #src > 60 then
        -- then the function was probably loaded from a string.
        -- see https://www.lua.org/pil/23.1.html
        src = "(unknown file)"
    end
    local line = info.linedefined or "(unknown line)"
    error("Attempt to serialize illegal type- function: " .. src .. ":" .. line .. ":")
end


local function force_push_resource(buffer, x)
    --[[
        `x` is a type that can't be serialized.
        Thus, we must push it as a resource.
        if X is not a resource, raise error.
    ]]
    if not try_push_resource(buffer, x) then
        if type(x) == "function" then
            func_error(x)
        else
            error("Attempt to serialize illegal type: " .. type(x))
        end
    end
end

--[[
=================
    set a default serialization function for unknown types.
=================
]]
setmetatable(serializers, {__index = function() return force_push_resource end})




local MAX_ARRAY_SIZE = 200000

local function push_array_to_buffer(buffer, x)
    push_str(buffer, ARRAY)
    local arr_len = 1
    --[[
    we cant use `#` here, because there could be gaps.
    # operator doesn't guarantee no gaps, which kinda sucks
    ]]
    for i=1, MAX_ARRAY_SIZE do
        local val = rawget(x,i)
        if val then
            serializers[type(val)](buffer, val)
        else
            push_str(buffer, ARRAY_END)
            arr_len = i-1
            return arr_len
        end
    end

    push_str(buffer, ARRAY_END)
    return MAX_ARRAY_SIZE
end


local function should_skip(arr_len, key)
    -- returns whether this key should be skipped because it's in the array
    return arr_len and type(key) == "number" and 
                floor(key) == key and key <= arr_len and key > 0
end


local function serialize_raw(buffer, x)
    local arr_len
    if rawget(x, 1) then
        arr_len = push_array_to_buffer(buffer, x)
        print("ARR-LEN: ", arr_len)
    end

    push_str(buffer, TABLE)
    for k,v in pairs(x) do
        if not should_skip(arr_len, k) then
            serializers[type(k)](buffer, k)
            serializers[type(v)](buffer, v)
        end
    end
    push_str(buffer, TABLE_END)
end



--[[     anatomy:

`ARRAY`  --> denotes a list of values. <val1, val2, ...>
`TABLE` --> denotes a key-val relation:  <key1, val1, key2, val2, ...>


possible types:

`TABLE_WITH_META`  (`ARRAY` <arr_data> `TABLE` <table_data> TABLE_END)    <meta>
`TABLE_WITH_META`  (`TABLE` <data> TABLE_END)    <meta>
note that template can't have regular keys afterwards   

]]


local function serialize_with_meta(buffer, x, meta)
    push_str(buffer, TABLE_WITH_META)
    serialize_raw(buffer, x)
    serializers.table(buffer, meta)
end



local function serialize_entity(buffer, ent, meta)
    local self = buffer.self
    local ok, er = self.canSerializeEntity(ent)
    if not ok then
        error("Cannot serialize entity: " .. er, 3)
    end

    if self.shouldSerializeEntityById(ent) then
        push_str(buffer, ENT_ID)
        if not ent.id then
            error("Attempt to serialize entity (or send entity over the network) that doesn't exist.\nRemember that entities aren't created instantly, they are created inbetween frames!")
        end
        serializers.number(buffer, ent.id)
    else -- not reference mode!
        push_str(buffer, ENT)
        local etype = ent:getEntityType()
        if not etype then
            error("Attempted to serialize unknown entity type: " .. tostring(meta), 3)
        end

        local typename = etype:getTypename()
        serializers.string(buffer, typename)

        add_ref(buffer, ent)

        local old_id = ent.id
        if not self.shouldSerializeIdOfEntity then
            -- Then we don't serialize the entity id
            ent.id = nil
        end
        for comp_name, comp_value in ent:components() do
            serializers[type(comp_name)](buffer, comp_name)
            serializers[type(comp_value)](buffer, comp_value)
        end
        ent.id = old_id
        push_str(buffer, TABLE_END)
    end

    if self.serializeEntity then
        self.serializeEntity(ent)
    end
end




function serializers.table(buffer, x)
    local self = buffer.self
    if self.resource_to_alias[x] and try_push_resource(buffer, x) then
        -- (This first condition before the `and` is just a shortcut check, saves us a stack frame)
        return -- It's a resource- hooray
    elseif buffer.refs[x] then
        push_ref(buffer, buffer.refs[x])
    else
        local meta = getmetatable(x)
        if meta then
            if self.is_entity_mt[meta] then
                serialize_entity(buffer, x, meta)
            else
                add_ref(buffer, x)
                serialize_with_meta(buffer, x, meta)
            end
        else
            add_ref(buffer, x)
            serialize_raw(buffer, x)
        end
    end
end


serializers["nil"] = function(buffer, _)
    push_str(buffer, NIL)
end

serializers.boolean = function(buffer, x)
    if x then
        push_str(buffer, TRUE)
    else
        push_str(buffer, FALSE)
    end
end


-- Number serialization:
local sUSMALL, dUSMALL = get_ser_funcs("I2")
local sU32, dU32 = get_ser_funcs("I4")
local sU64, dU64 = get_ser_funcs("I8")
local sI32, dI32 = get_ser_funcs("i4")
local sI64, dI64 = get_ser_funcs("i8")
local sN, dN = get_ser_funcs("n")


function serializers.number(buffer, x)
    if floor(x) == x then
        -- then is integer
        if x > 0 then
            -- serialize unsigned
            if x < MAX_USMALL then
                push_str(buffer, sUSMALL(x))
            elseif x < (2^32 - 1) then
                push_str(buffer, U32)
                push_str(buffer, sU32(x))
            else -- x is U64
                push_str(buffer, U64)
                push_str(buffer, sU64(x))
            end
        else
            -- serialize signed
            local mag = abs(x)
            if mag < (2 ^ 31 - 2) then -- 32 bit signed num
                push_str(buffer, I32)
                push_str(buffer, sI32(x))
            else
                push_str(buffer, I64) -- else its 64 bit.
                push_str(buffer, sI64(x))
            end
        end
    else
        push_str(buffer, NUMBER)
        push_str(buffer, sN(x))
    end
end


--[[
    STRING
    <string len>
    <..... string data ...........>
]]
function serializers.string(buffer, x)
    if buffer.refs[x] then
        push_ref(buffer, buffer.refs[x])
    elseif buffer.self.resource_to_alias[x] then
        push_resource(buffer, x)
    else
        push_str(buffer, STRING)
        local slen = len(x)
        serializers.number(buffer, slen)
        push_str(buffer, x)

        if slen >= STRING_REF_LEN then
            add_ref(buffer, x)
        end
    end
end













--[[

deserializers

]]


local function popn(reader, n)
    local i = reader.index
    local data = reader.data
    reader.index = i + n -- `reader.index` is the index of the NEXT byte to be read.
    -- i + n - 1 is the index of the most recent byte read.
    if len(data) >= (i + n - 1) then
        return reader.data:sub(i, i + n - 1)
    else
        return nil, "popn(reader, n): data string too short"
    end
end


local function peek(reader)
    local i = reader.index
    return sub(reader.data, i,i)
end



---@param reader PckrReader
local function pull(reader)
    local i = reader.index
    local ccode = byte(reader.data, i)
    if not ccode then
        return nil, "pull(re) ran out of data; (serialization data too short of malformed)"
    end
    if ccode <= USMALL_NUM then
        return deserializers[USMALL](reader)
    end

    local chr = sub(reader.data, i, i)
    local fn = deserializers[chr]
    if not fn then
        return nil, "pull(re): Serialization char not found: " .. tostring(chr:byte(1,1))
    end
    reader.index = i + 1
    local val, err = fn(reader)
    if err then
        return nil, err
    end
    
    return val
end



local function pull_ref(reader, x)
    -- adds a new reference to the reader.
    local refs = reader.refs
    refs[COUNT] = refs[COUNT] + 1
    refs[refs[COUNT]] = x
end

local function get_ref(reader, index)
    return reader.refs[index]
end



local function make_number_deserializer(deser_func, n_bytes)
    return function(re)
        local data, er1 = popn(re, n_bytes)
        if not data then
            return nil, er1
        end

        local num, er2 = deser_func(data)
        if not num then
            return nil, er2
        end
        return num
    end
end



deserializers[USMALL] = make_number_deserializer(dUSMALL, 2)

deserializers[U32] = make_number_deserializer(dU32, 4)
deserializers[I32] = make_number_deserializer(dI32, 4)

deserializers[I64] = make_number_deserializer(dI64, 8)
deserializers[U64] = make_number_deserializer(dU64, 8)

local size_NUMBER = love.data.getPackedSize(PREFIX .. "n") -- i forgot size :P
deserializers[NUMBER] = make_number_deserializer(dN, size_NUMBER)


deserializers[NIL] = function(_)
    return nil
end

deserializers[TRUE] = function(_)
    return true
end

deserializers[FALSE] = function(_)
    return false
end


deserializers[STRING] = function(re)
    local string_len, err = pull(re)
    if err then
        return nil, "deserializers[STRING] - " .. err
    end
    
    local i = re.index
    local end_i = i + string_len - 1

    if len(re.data) >= (end_i) then
        -- then we OK
        local res = sub(re.data, i, end_i)
        if len(res) >= STRING_REF_LEN then
            -- then we put as a ref
            pull_ref(re, res)
        end
        re.index = end_i + 1
        return res
    else
        return nil, "deserializers[STRING]: recieved data does not have enough space to account for this string size: " .. tostring(string_len)
    end
end





deserializers[TABLE_WITH_META] = function(re)
    --[[
        format is like this:
        TABLE_WITH_META
        TABLE / ARRAY (...)
         <<metatable>>

        The template must be after the metatable, else pckr won't know
        what the template is!
    ]]
    local tabl, err = pull(re)
    if err then
        return nil, "deserializers[TABLE_WITH_META] - " .. err
    end
    if type(tabl) ~= "table" then
        return nil, "TABLE_WITH_META requires the signature: [tabl],[metatab]. `tabl` was of type: " .. type(tabl)
    end

    local meta, er2 = pull(re)
    if er2 then
        return nil, "deserializers[TABLE_WITH_META] - " .. er2
    end
    if type(meta) ~= "table" then
        return nil, "TABLE_WITH_META requires the signature: [tabl],[metatab]. `metatab` was of type: " .. type(meta)
    end

    return setmetatable(tabl, meta)
end




local ALLOWED_TOKENS_AFTER_ARRAY = {
    [TABLE] = true;
}

local tinsert = table.insert


-- There is possibly an infinite loop to do with the while loops
-- within pckr. This is just some debug infra to try fix it.
local MAX_LOOP = 200000


deserializers[ARRAY] = function(re, tabl, mt_or_nil)
    -- Remember for an array: 
    -- TABLE, or TABLE_END could all follow!
    -- We must account for that; `ARRAY` should automatically pull these extra
    -- headers.
    if not tabl then
        tabl = {}
        pull_ref(re, tabl)
    end

    --while true do
    for _=1, MAX_LOOP do
        local x, err = pull(re)
        if err then
            return nil, "deserializers[ARRAY] - " .. tostring(err)
        end
        if x == UNIQUE_ARRAY_END then
            local key, er = popn(re, 1)
            if er then
                return nil, "deserializers[ARRAY]: error in popn: " .. er
            end
            if not ALLOWED_TOKENS_AFTER_ARRAY[key] then
                return nil, "deserializers[ARRAY] - malformed token after ARRAY_END: \\" .. tostring(key:byte(1,1))
            end

            return deserializers[key](re, tabl, mt_or_nil)
        end
        tinsert(tabl, x)
    end

    error("Infinite loop! " .. inspect(tabl))
end



deserializers[TABLE] = function(re, tabl_or_nil)
    local tabl
    if tabl_or_nil then
        tabl = tabl_or_nil
    else
        tabl = {}
        pull_ref(re, tabl)
    end

    --while true do
    for _=1, MAX_LOOP do
        local key, er1 = pull(re)
        if er1 then
            return nil, er1
        end
        if key == nil then
            return nil, "deserializers[TABLE] - key was nil"
        end

        if key == UNIQUE_TABLE_END then
            return tabl
        else
            local val, er2 = pull(re)
            if er2 then
                return nil, er2
            end
            tabl[key] = val
        end
    end
    error("Infinite loop! " .. inspect(tabl))
end


---@param re PckrReader
deserializers[ENT] = function(re)
    local etypename, err = pull(re)
    if err then
        return nil, "deserializers[ENT] - " .. err
    end
    local self = re.self
    local etype = self.typename_to_etype[etypename]
    if not etype and re.options.entityTypeFallbackHandler then
        etype = re.options.entityTypeFallbackHandler(etypename)
    end

    if not etype then
        return nil, "deserializers[ENT]: etype was not registered: `" .. tostring(etypename) .. "`\nAre you sure all the entity types are loaded?"
    end

    local ent = etype:entityFromData({})
    pull_ref(re, ent)

    --while true do
    local i=MAX_LOOP
    while i>0 do
        local comp_name, er2 = pull(re)
        if er2 then
            return nil, "deserializers[ENT] couldnt deserialize - " .. er2
        end
        if comp_name == UNIQUE_TABLE_END then
            break -- done!
        end
        local comp_value, er3 = pull(re)
        if er3 then
            return nil, "deserializers[ENT] couldn't deserialize value - " .. er3
        end
        ent:rawsetComponent(comp_name, comp_value)

        i=i-1 -- only for debug purposes.
    end
    
    if i <= 0 then
        error("Infinite loop! " .. inspect(re))
    end

    ent = self.deserializeEntity(ent)
    return ent
end


deserializers[ENT_ID] = function(re)
    -- assumes that an ent already exists!
    local x, err = pull(re)
    if err then
        return nil, "deserializers[ENT_ID] - " .. tostring(err)
    end
    local res = re.self.getEntityById(x)
    if not res then
        return nil, "deserializers[ENT_ID] No entity with id found"
    end
    return res
end



deserializers[ARRAY_END] = function(_)
    return UNIQUE_ARRAY_END
end

deserializers[TABLE_END] = function(_)
    return UNIQUE_TABLE_END
end



deserializers[REF] = function(re)
    local index, er = pull(re)
    if er then
        return nil, "deserializers[REF] error - " .. er
    end
    if type(index) ~= "number" then
        return nil, "deserializers[REF] - Reference not a number"
    end
    local val = get_ref(re, index)
    if not val then
        return nil, "deserializers[REF] - Non existant reference: " .. tostring(index)
    end
    return val
end




deserializers[RESOURCE] = function(re)
    local alias, er = pull(re)
    if er then
        return nil, "deserializers[RESOURCE] - " .. er
    end

    local val = re.self.alias_to_resource[alias]
    if not val and re.options.resourceFallbackHandler then
        val = re.options.resourceFallbackHandler(alias)
    end
    if not val then
        return nil, "deserializers[RESOURCE] - unknown resource alias: " .. tostring(alias)
    end
    return val
end




local function newBuffer(self)
    local buffer = {
        self = self,
        len = 0;
        refs = {[COUNT] = 0} -- count = the number of references.
    }
    return buffer
end


---@param self PckrState
---@param data string
---@param options table?
local function newReader(self, data, options)
    ---@class PckrReader
    local t = {
        self = self,
        refs = {[COUNT] = 0}; -- [ref_num] --> object

        data = data;
        index = 1,

        options = options or {}
    }
    return t
end




local function serialize(buffer, ...)
    local arglen = select("#", ...)
    for i=1, arglen do
        local x = select(i, ...)
        serializers[type(x)](buffer, x)
    end
    return concat(buffer)
end


function PckrState:serialize(...)
    local buffer = newBuffer(self)
    return serialize(buffer, ...)
end



local OPTIONS = {
    "dontSerializeEntityId", -- true if we should ignore entity-id.
}

function PckrState:serializeWithOptions(options, ...)
    local buffer = newBuffer(self)
    for _,opt in ipairs(OPTIONS) do
        if options[opt] then
            buffer[opt] = true
        end
    end
    return serialize(buffer, ...)
end



function PckrState:deserialize(data, options)
    local reader = newReader(self, data, options)
    local results = {}

    local i=MAX_LOOP
    while i>0 and data:len() >= reader.index do
        local val, err = pull(reader)
        if err then
            return nil, err
        end
        table.insert(results, val)

        i=i-1
    end

    if i<=0 then
        error("Infinite loop! " .. data)
    end

    -- TODO: ISSUE HERE!
    -- If theres a `nil` value in the middle of the array,
    -- unpack doesn't unpack the whole thing.
    -- (There could be an extra arg to unpack though, so take a look)
    return table_unpack(results)
end


return newPckrState

