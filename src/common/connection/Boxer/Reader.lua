

local Reader = tools.SafeClass()

local KEYS = {"boxer"}

function Reader:init(buffer, options)
    tools.assertKeys(options, KEYS)
    self.boxer = options.boxer
    self.buffer = buffer
    self.failed = false
    self.i = 1
end





local function getRegularData(reader, num_args)
    -- Gets data from a regular packet
    --[[
        TODO:
        Convert this to a table-based switch
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




local function readPacketData(reader, boxer, packetName)
    --[[
        Transforms a regular packet, checks types,
        then returns data.

        transforms the next packet within the reader,
        assuming that it's a regular packet.

        (Basically just transforms strings/numbers 
            into entities when appropriate)
    ]]
    local i = reader.i
    local buffer = reader.buffer
    local typelist = boxer.nameToPacketTypelist[packetName]
    local dataToEntity = boxer.dataToEntity

    local packetSize = #typelist -- packet-size indicated by size of typelist

    i = i + 1
    reader.i = i

    for u=i, (i+packetSize)-1 do
        -- transform everything
        local j = (u - i) + 1
        local typ = typelist[j]
        if typ == "entity" then
            buffer[u] = dataToEntity(buffer[u])
        end
        local val = buffer[u]

        if SERVER_SIDE then
            -- only do checks on server-side
            local ok, er = boxer.typechecker(val, typ)
            -- its an error!
            if not ok then
                log.error("Error reading packet: ", er)
                reader:fail()
                return
            end
        end
    end

    return getRegularData(reader, packetSize)
end




local rawget = _G.rawget

function Reader:read()
    --[[
        reads the next packet in the buffer,
        and increments the reader position.
    ]]
    local boxer = self.boxer
    local id = self.buffer[self.i]
    if not id then
        self:finish()
        return nil
    end

    local packetName, a,b,c,d,e,f
    packetName = boxer:getPacketName(id)
    if not packetName then
        self:fail()
        log.error("Unknown packet id: " .. tostring(id))
        return nil
    end

    a,b,c,d,e,f = readPacketData(self, boxer, packetName)
    if self:hasFailed() then
        return nil
    end
    return packetName, a,b,c,d,e,f
end


function Reader:isFinished()
    return self.finished
end

function Reader:hasFailed()
    return self.failed
end

function Reader:fail()
    self.failed = true
    self:finish()
end

function Reader:finish()
    self.finished = true
end



return Reader
