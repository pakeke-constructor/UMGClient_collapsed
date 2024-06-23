--[[

StringIdMapper:
maps strings to integer ids, and vice versa.

Useful when we want to compress known strings.

]]




local StringIdMapper = tools.SafeClass()




local function tryAdd(self, k,v)
    if type(k) == "number" and type(v) == "string" then
        self:add(k,v)
    end
end


function StringIdMapper:init(tabl)
    self.max_id = 0;
    self.id_to_name = {}
    self.name_to_id = {}
    tabl = tabl or {}
    for k,v in pairs(tabl) do
        tryAdd(self,k,v)
        tryAdd(self,v,k)
    end
end



local idStrTc = tc.assert(tc.int, tc.string)

function StringIdMapper:add(id, name)
    idStrTc(id, name)
    self.id_to_name[id] = name
    self.name_to_id[name] = id
    -- update maximum id
    self.max_id = math.max(self.max_id, id + 1)
end




function StringIdMapper:getId(name)
    return self.name_to_id[name]
end

function StringIdMapper:getName(id)
    return self.id_to_name[id]
end



function StringIdMapper:clone()
    local cloned = table.copy(self, true)
    return setmetatable(cloned, getmetatable(self))
end



function StringIdMapper:generate(name)
    local id = self.max_id
    if self.name_to_id[name] then
        return self.name_to_id[name]
    end
    self.id_to_name[id] = name
    self.name_to_id[name] = id
    self.max_id = self.max_id + 1
    return id
end



function StringIdMapper:serialize()
    return json.encode(self.name_to_id)
end


function StringIdMapper.deserialize(json_data)
    local succ, tabl = pcall(json.decode, json_data)
    if succ then
        return StringIdMapper(tabl)
    elseif constants.DEBUG then
        log.error("failed deser of broadcast cache: ", json_data)
        return nil, tabl
    end
end




return StringIdMapper
