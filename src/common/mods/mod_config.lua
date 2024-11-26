

local mod_config = {}


local rpath = tools.path(...)

local mod_identifiers = require(rpath .. ".mod_identifiers")






local function parse_mod_idens(t)
    local new = {}
    for i, mod_iden in ipairs(t) do
        local iden = mod_identifiers.parse_mod_identifier(mod_iden)
        if iden then
            table.insert(new, iden)
        end
    end
    return new
end




local SEP = constants.FILE_SEP
local MOD_TYPES = constants.MOD_TYPES
local DEFAULT_MOD_TYPE = constants.DEFAULT_MOD_TYPE



local function check_mod_type(config, pth)
    -- Checking .type:
    if not config.type then
        config.type = DEFAULT_MOD_TYPE
    else
        config.type = tostring(config.type):lower()
        if not MOD_TYPES[config.type] then
            log.warn("Bad mod type in config.json: ", pth)
            config.type = DEFAULT_MOD_TYPE
        end
    end
end



local function assert_table(x)
    if type(x) == "table" then
        return x
    end
    return {}
end



local function update_uses(config)
    -- checking that `uses` contains everything from `needs`:
    local uses_hash = {--[[ [mod_iden] -> true ]]}

    config.uses = parse_mod_idens(assert_table(config.uses))
    config.needs = parse_mod_idens(assert_table(config.needs))

    for _, m_iden in ipairs(config.uses) do
        uses_hash[m_iden] = true
    end

    -- everything from `needs`, add it to `uses`:
    for _, m_iden in ipairs(config.needs) do
        if not uses_hash[m_iden] then
            table.insert(config.uses, m_iden)
        end
    end
end






function mod_config.get_mod_config_from_path(pth, is_local)
    local json_pth = pth .. SEP .. constants.MOD_CONFIG_FILE
    local contents = nil

    if is_local then
        contents = love.filesystem.read(json_pth)
    else
        local f = io.open(json_pth, "rb")
        if f then
            contents = f:read("*a")
            f:close()
        end
    end

    local succ, config = pcall(json.json5_decode, contents)
    if succ then
        check_mod_type(config, pth)
        update_uses(config)
        return config
    else
        log.error("Error loading config json data:", json_pth)
        return {
            type = MOD_TYPES.unknown,
            uses = {}
        }
    end
end





function mod_config.get_mod_config(mod_iden)
    local pth, is_local = mod_identifiers.get_path(mod_iden)
    if not pth then
        return nil, is_local 
    end
    return mod_config.get_mod_config_from_path(pth, is_local)
end





function mod_config.set_mod_config(mod_iden, mod_options)
    -- only works for local mods!
    local json_path = constants.LOCAL_MOD_PATH .. mod_iden .. SEP .. constants.MOD_CONFIG_FILE
    assert(love.filesystem.getInfo(json_path))
    local tabl = mod_config.get_mod_config(mod_iden)
    for k,v in pairs(mod_options) do
        tabl[k] = v
    end
    local data = json.encode(tabl)
    love.filesystem.write(json_path, data)
end



return mod_config
