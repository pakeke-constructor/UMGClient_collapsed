
--[[

CY REFACTOR:
    previously called `cy_groups.lua`

]]
local path = (...):gsub("%.GroupManager", "")

local Group = require(path..".Group")


local GroupManager = tools.SafeClass()



local function register_group(self, group)
    self.group_to_bool[group] = true
    group.___groupManager = self
    table.insert(self.all_groups, group)
end


function GroupManager:init()
    self.rembuffer = tools.Set(--[[
        a set of entities that are being deleted
        from ALL groups next frame
    ]])

    self.group_to_bool = {
        -- to check if something is a group or not
        -- [group_object] = true
    }

    -- an array of all groups
    self.all_groups = {}

    -- A hasher that keeps track of all groups
    self.group_hash = {
        --[[
        ["component1:component2:component3"] = group
            where `:` is SEP_CHR
        ]]
    }

    -- A hasher that records all groups for every component
    self.component_to_groups = {
        --[[
            ["component_1"] : { group1, group2, group3 }
            ["component_2"] : { group3, group5 }
        ]]
    }

    self.all = Group({}) -- Group of ALL entities
    register_group(self, self.all)

    -- whether a group has been created or not.
    self.get_groups_called = false
end



local function update_comp_to_groups(self, components, group)
    --[[
        Updates group component hash with new components
    ]]
    for _,component in ipairs(components) do
        if not self.component_to_groups[component] then
            self.component_to_groups[component] = {group}
        else
            table.insert(self.component_to_groups[component], group)
        end
    end
end



local SEP_CHR = "@"

local function make_key(components)
    --[[
        makes a unique key from a set of components.
        The same list of components will produce the same key.
        Useful for hashing groups.
    ]]
    table.sort(components)
    return table.concat(components, SEP_CHR)
end



local out_of_order_err = "You must define all groups before you define any entities!"


local function make_new_group(self, components, key)
    -- Else, make a new one
    if self.get_groups_called then 
        --[[
            if we make a new group AFTER `group()` has been called,
            that implies that we have created an entity-type.

            If we create a group AFTER we create a group, the already-created
            group won't contain the etype.
            Which means that entities won't be added!!! uh oh!

            TODO: In future, we should automatically update existing groups 
            instead of erroring. It's possible to do, just a lot of work.
        ]]
        error(out_of_order_err)
    end
    local group = Group(components)
    self.group_hash[key] = group

    register_group(self, group)
    update_comp_to_groups(self, components, group)

    return group
end


function GroupManager:newGroup(...)
    local components = {...}

    if #components == 0 then
        return self.all -- return the mighty all group
    end
    
    -- First, check for already existing groups
    local key = make_key(components)

    if self.group_hash[key] then
        -- If this group already exists, return an existing one
        return self.group_hash[key]
    else
        return make_new_group(self, components, key)
    end
end


function GroupManager:get_all_groups()
    return self.all_groups
end


local function get_groups_for_component(self, comp_name)
    assert(type(comp_name) == "string", "component names must be strings")
    return self.component_to_groups[comp_name]
end


function GroupManager:clear()
    for i=1, #self.all_groups do
        local g = self.all_groups[i]
        g:_clear()
    end
end




function GroupManager:get_worthy_groups(entity_or_table)
    --[[
        gets worthy groups for an entity, with components.
        (This works on entityTypes too)
    ]]
    local buffer = {}
    for _, group in ipairs(self.all_groups) do
        if group:_is_worthy(entity_or_table) then
            table.insert(buffer, group)
        end
    end
    return buffer
end



function GroupManager:isGroup(obj)
    -- returns whether or not `obj` is a valid group or group-view
    -- that belongs to this Handler
    return self.group_to_bool[obj]
end




function GroupManager:addComponentInstantly(entity, compName)
    --[[
        This is called when an entity receives a new component,
        `compName`, and the entity is supposed
        to be added to new groups.

        This function will search through all neccessary groups,
        and add to all neccessary groups
    ]]
    self.get_groups_called = true
    local arr = get_groups_for_component(self, compName)
    if arr then
        for i=1, #arr do
            local group = arr[i]
            if group:_is_worthy(entity) then
                group:_add(entity)
            end
        end
    end
end



function GroupManager:removeComponentInstantly(entity, comp_name)
    --[[
        instantly removes an entity from all groups
        containing `comp_name`.
    ]]
    local arr = get_groups_for_component(self, comp_name)
    if arr then
        for i=1, #arr do
            local group = arr[i]
            group:_remove(entity)
        end
    end
end



function GroupManager:exists(ent)
    --[[
        returns true IFF the ent exists inside the all group.
    ]]
    return self.all:has(ent)
end




return GroupManager
