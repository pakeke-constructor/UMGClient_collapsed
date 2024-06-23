
--[[
    Writer is a structure that serializes multiple packets efficiently,
    using luaJIT's string buffers.
]]

local Writer = tools.SafeClass()



function Writer:init(options)
    tools.inlineMethods(self)
    
    self.boxer = options.boxer

    self.buffer = {} -- where the packets actually live
    self.size = 0
end




local encode = string.buffer.encode

function Writer:flush()
    local data = encode(self.buffer)
    self.buffer = {}
    self.size = 0
    return data
end


local add = table.insert



local function push6(self, id, a,b,c,d,e,f)
    local buf = self.buffer
    self.size = self.size + 7
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
    add(buf, d)
    add(buf, e)
    add(buf, f)
end

local function push5(self, id, a,b,c,d,e)
    local buf = self.buffer
    self.size = self.size + 6
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
    add(buf, d)
    add(buf, e)
end

local function push4(self, id, a,b,c,d)
    local buf = self.buffer
    self.size = self.size + 5
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
    add(buf, d)
end

local function push3(self, id, a,b,c)
    local buf = self.buffer
    self.size = self.size + 4
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
end

local function push2(self, id, a,b)
    local buf = self.buffer
    self.size = self.size + 3
    add(buf, id)
    add(buf, a)
    add(buf, b)
end

local function push1(self, id, a)
    local buf = self.buffer
    self.size = self.size + 2
    add(buf, id)
    add(buf, a)
end

local function push(self, id)
    local buf = self.buffer
    self.size = self.size + 1
    add(buf, id)
end



local pushers = {
    [0] = push,
    [1] = push1,
    [2] = push2,
    [3] = push3,
    [4] = push4,
    [5] = push5,
    [6] = push6
}




local DO_TYPECHECK = constants.DEBUG

local function assertType(self, packetName, val, typ, typeIndex)
    local ok, er = self.boxer.typechecker(val, typ)
    if not ok then
        error(("Bad packet value: %s, arg %d :: %s"):format(packetName, typeIndex, er))
    end
end




function Writer:write(packetName, a,b,c,d,e,f)
    local boxer = self.boxer
    local buffer = self.buffer
    local typelist = boxer:getPacketTypelist(packetName)

    if not typelist then
        error("Unknown packet: " .. tostring(packetName))
    end

    local args = #typelist
    local id = boxer:getPacketId(packetName)
    if not id then
        error("packetName was not registered: " .. packetName)
    end

    local fn = pushers[args]
    fn(self, id, a,b,c,d,e,f)

    local start, finish = (self.size-args) + 1, self.size

    for i=start, finish do
        local typeIndex = (i-start) + 1
        local typ = typelist[typeIndex]

        if DO_TYPECHECK then
            assertType(self, packetName, buffer[i], typ, typeIndex)
        end

        if typ == "entity" then
            local ent = buffer[i]
            -- transform the entity to be serialized "properly":
            local data = boxer.entityToData(ent)
            buffer[i] = data -- will either be a number, or pckr string,
            -- representing the serialized ent
        end
    end
end




return Writer

