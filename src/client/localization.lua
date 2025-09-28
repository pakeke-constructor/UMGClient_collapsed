

local localization = {}


local mapping = {}

local dumps = {}



local function getLangCode(locale)
    return locale:match("^[^-^_]+")
end


local function tryLoadJson(locale)
    local langCode = getLangCode(locale)
    local pth = "assets/localization/" .. langCode .. ".json"
    if love.filesystem.getInfo(pth, "file") then
        local data = love.filesystem.read(pth)
        if data then
            return json.decode(data)
        else
            log.error("Couldn't load: ", pth)
        end
    else
        log.error("Couldn't find file: ", pth)
    end
end




function localization.load()
    for _, locale in ipairs(love.system.getPreferredLocales())do
        local mapp = tryLoadJson(locale)
        if mapp then
            mapping = mapp
        end
    end
end


function localization.dump()
    if constants.DEV_MODE then
        love.filesystem.write("UMGCLIENT_LOCALIZATION_STRINGS.json", json.encode(dumps))
    end
end


function localization.localize(txt)
    if constants.DEV_MODE then
        dumps[txt] = txt
    end

    if mapping[txt] then
        return mapping[txt]
    end

    -- else, fallback to english
    return txt
end



return localization
