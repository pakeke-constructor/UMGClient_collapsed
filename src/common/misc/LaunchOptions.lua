
--[[

This is an object that keeps track of launch options.

When we want to start hosting a server, we create one of these objects.
Comes with a few helpful methods.

(similar to mod_struct.)

]]


local mods = require("src.common.mods.mods")



local LaunchOptions = tools.Class()


local ONLINE_MODES = constants.ONLINE_MODES


local function assertWorldname(worldname)
    -- remove all non-alphanumeric characters
    assert(worldname:match("[%w_]+") == worldname, "worldname not ok: " .. tostring(worldname))
end


local KEYS = {"modlist", "onlineMode"}

function LaunchOptions:init(args)
    --[[
        {
            onlineMode = ENUM,
            modlist = {...}

            -- Everything else is situational / optional fields:
            worldname = "my_world",
            raw_port = 8945,
        }
    ]]
    tools.assertKeys(args, KEYS)
    tools.injectKeys(self, args)

    if not constants.ONLINE_MODES[self.onlineMode] then 
        error("Invalid online mode: " .. tostring(self.onlineMode))
    end
    if self.onlineMode == ONLINE_MODES.raw then
        assert(rawget(self,"port"), "Wasn't given port")
    end

    self.modstruct = mods.ModStruct(self.modlist)
    self.isPersistent = mods.is_world_persistent(self.modstruct) or false

    if self.isPersistent then
        assertWorldname(rawget(self,"worldname"))
    end
end




function LaunchOptions:isWorldPersistent()
    if rawget(self, "isPersistent") ~= nil then
        -- return cached, if we have cached value
        return self.isPersistent
    end

    local isPersistent = mods.is_world_persistent(self.modstruct)
    self.isPersistent = isPersistent
    return isPersistent
end




function LaunchOptions:serialize()
    local meta = getmetatable(self)
    setmetatable(self, nil) -- dont serialize metatable
    local mod_struct = nil -- dont serialize mod_struct
    self.modstruct = nil

    local data = json.encode(self)

    setmetatable(self, meta)
    self.modstruct = mod_struct
    return data
end




function LaunchOptions.deserialize(data)
    local ok, tabl = pcall(json.decode, data)
    local self
    if ok then
        ok, self = pcall(LaunchOptions, tabl)
        if ok then
            return self
        else
            local er1 = self
            return nil, er1
        end
    end
    local er = tabl
    return nil, er
end



return LaunchOptions

