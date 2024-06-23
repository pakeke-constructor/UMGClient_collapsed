

--[[


IMPORTANT:

There are two things at play here:
Groups, and Views.

Groups: internal representation of groups, passed around by 



]]

local Group = tools.Class()


--[[
==================================================

Public Group API:

==================================================
]]

function Group:size()
   return self._size
end

Group.length = Group.size -- Aliases
Group.len = Group.size

function Group:has(ent)
   return self.pointers[ent]
end


-- callback for when entities are added  (signature:  (ent))
function Group:onAdded(func)
    self.added_cbs:add(func)
end

-- callback for when entities are removed (signature:  (ent))
function Group:onRemoved(func)
    self.removed_cbs:add(func)
end

function Group:deleteCallback(func)
    -- deletes this callback from both `onAdded` and `onRemoved`
    self.added_cbs:remove(func)
    self.removed_cbs:remove(func)
end


function Group:has(obj)
   return self.pointers[obj]
end

Group.contains = Group.has


function Group:ipairs()
   return ipairs(self)
end


function Group:__tostring()
    return self.tostring_value or "<entity Group UNKNOWN>"
end

Group.iter = Group.ipairs












--[[
==================================================

Private Group API;
uses internally by cy ECS

==================================================
]]


local function make_tostring(has_component)
    local tostr_value = "<entity Group("
    local buffer = {}
    for component,_ in pairs(has_component) do
        table.insert(buffer, component)
    end
    if #buffer == 0 then
        return "<entity Group(ALL_GROUP)>"
    end
    table.sort(buffer)
    for i=1, #buffer-1 do
        tostr_value = tostr_value .. "'" .. buffer[i] .. "'" .. ", "
    end
    tostr_value = tostr_value .. "'" .. buffer[#buffer] .. "')>"
    return tostr_value
end


function Group:init(components)
    local has_component = {}
    for _, comp in ipairs(components) do
        if comp == "id" then
            error("ent.id is a reserved component! (All entities have components)")
        end
        has_component[comp] = true
    end

    self.added_cbs = tools.Set() -- Added and removed callbacks
    self.removed_cbs = tools.Set()

    self.tostring_value = make_tostring(has_component)

    self.pointers  = {--[[  [ent] -> index    ]]}
    self._size      = 0
    self.has_f  = has_component -- used interally by cy_groups.
    self.components = components -- used internally too.

    return self
end




function Group:_clear() -- private method
    -- be nice on GC
    local obj
    local ptrs = self.pointers
    local list = self
    for i=1, #list do
        obj = list[i]
        ptrs[obj] = nil
        list[i] = nil
    end
    self.pointers = {}
    self._size     = 0
    return self
end



function Group:_add(ent) -- private method
    if self.pointers[ent] then
        -- already has ent
        return self
    end

    local size = self._size + 1

    self.pointers[ent] = size
    self._size          = size
    table.insert(self, ent)

    for i=1, self.added_cbs:size() do
        local onAddedCallback = self.added_cbs[i]
        onAddedCallback(ent)
    end

    return self
end



function Group:_remove(ent) -- private method
    if not self.pointers[ent] then
        return nil
    end

    local index = self.pointers[ent]
    local size  = self._size

    local other = self[size]

    self[index]  = other
    self.pointers[other] = index

    self[size] = nil

    self.pointers[ent] = nil
    self._size = size - 1

    for i=1, self.removed_cbs:size() do
        local onRemovedCallback = self.removed_cbs[i]
        onRemovedCallback(ent)
    end

    return self
end




function Group:_is_worthy(entity_or_table)
    -- TODO:
    -- This can be faster with bitops.
    for _, comp in ipairs(self.components) do
        if not entity_or_table[comp] then
            return false
        end
    end
    return true
end



return Group
