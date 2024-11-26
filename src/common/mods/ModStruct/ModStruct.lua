

--[[

mod_struct

mod_struct's are objects that contain information about the current mod setup.
(It's basically a list of mods.)


]]


local tsort = require("libs.nm_topo_sort.topo_sort")


local mod_struct = {}
local mt = {__index = mod_struct}

local mods, mod_identifiers



local function assert_modules_loaded()
    -- avoid circular require loop
    mods = mods or require("src.common.mods.mods")
    mod_identifiers = mod_identifiers or require("src.common.mods.mod_identifiers")
end



function mod_struct:get_modlist()
    return self.modlist
end


function mod_struct:serialize()
    local meta = getmetatable(self)
    setmetatable(self, nil)
    local data = json.encode(self)
    setmetatable(self, meta)
    return data
end



local add_dependencies_to_graph_tc = tc.assert("string", "table", "table")
--[[
    finds mod dependencies, and adds them to the dependency graph.
    (The graph is eventually topologically sorted)
]]
local function add_dependencies_to_graph(mod_iden, seen_deps, graph)
    add_dependencies_to_graph_tc(mod_iden, seen_deps, graph)
    if seen_deps[mod_iden] then
        return
    end
    seen_deps[mod_iden] = true
    local depend_mods = mods.get_shallow_dependencies(mod_iden)
    if (not depend_mods) or (#depend_mods <= 1) then
        -- No dependencies, therefore, add an unconnected node.
        graph:add(mod_iden)
        return
    end

    for _, dep_iden in ipairs(depend_mods) do
        -- add dependencies to graph
        if mod_iden ~= dep_iden then
            graph:add(mod_iden, dep_iden)
        end
        add_dependencies_to_graph(dep_iden, seen_deps, graph)
    end
end



function mod_struct:get_topo_sorted_dependencies()
    --[[
        returns modlist, topologically sorted
    ]]
    assert_modules_loaded()
    local modlist = self:get_modlist()
    local graph = tsort.new()

    local seen_deps = {} -- ensure we don't do duplicates

    for _, mod_iden in ipairs(modlist) do
        add_dependencies_to_graph(mod_iden, seen_deps, graph)
    end

    local tabl = graph:sort()
    if not tabl then
        -- TODO: What the fuck do we do here? we should prolly return nil + error, no??
        log.error("Circular dependency in the mod list!")
        return {}
    end
    table.reverse(tabl)
    return tabl
end



local function new_mod_struct(modlist_or_jsondata)
    local modlist
    assert_modules_loaded()

    if type(modlist_or_jsondata) == "string" then
        local data = modlist_or_jsondata
        local tabl = json.json5_decode(data)
        return setmetatable(tabl, mt)
    else
        modlist = modlist_or_jsondata
    end

    if type(modlist) ~= "table" then
        error("mod_struct ctor requires a list of mods!")
    end

    for i, mod_iden in ipairs(modlist) do
        -- parse mod identifiers
        local iden = mod_identifiers.parse_mod_identifier(mod_iden)
        if not iden then
            return nil, "invalid mod identifier: " .. tostring(mod_iden)
        end
        modlist[i] = iden
    end

    return setmetatable({
        modlist = modlist
    }, mt)
end





--[[
    checks if a mod is fully ready to load.
    (i.e. it's deps are loaded too.)

    If ready, returns true.
    otherwise, returns false, missing_mod_iden
]]
local is_mod_and_deps_ready_tc = tc.assert("string", "table")
local function is_mod_and_deps_ready(mod_iden, seen)
    is_mod_and_deps_ready_tc(mod_iden, seen)
    assert_modules_loaded()
    mod_iden = mod_identifiers.parse_mod_identifier(mod_iden)

    -- check if the mod is ready:
    if not mods.mod_is_ready(mod_iden) then
        return false, mod_iden
    end
    seen[mod_iden] = true

    -- Check if all dependencies are ready:
    local arr = mods.get_shallow_dependencies(mod_iden)
    for _, dep_iden in ipairs(arr) do
        if not seen[dep_iden] then
            local ok, missing_iden = is_mod_and_deps_ready(dep_iden, seen)
            if not ok then
                return false, missing_iden
            end
        end
    end
    return true
end



function mod_struct:get_mod_to_download()
    local seen = {}
    for _, mod_iden in ipairs(self.modlist) do
        local ok, missing_iden = is_mod_and_deps_ready(mod_iden, seen)
        if not ok then
            -- We need to download this mod before continuing
            return missing_iden
        end
    end
    -- Everything is ready! no mods to download.
    return nil
end




return new_mod_struct
