

local localization = {}

---@type table<string, string>
local mapping = {}

local dumps = {}



local function getLangCode(locale)
    return locale:lower():match("^[^-^_]+")
end

assert(getLangCode("BR-br") == "br")
assert(getLangCode("Br-br") == "br")
assert(getLangCode("Br_br") == "br")
assert(getLangCode("EN_br") == "en")
assert(getLangCode("eN-br") == "en")


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



function localization.isRussian()
    return userService.getLanguage() == "ru"
end


function localization.isChinese()
    return userService.getLanguage() == "zh"
end



function localization.load()
    local locale = userService.getLanguage()
    local mapp = tryLoadJson(locale)
    if mapp then
        log.info("SUCCESS LOADING LOCALE: ", locale)
        mapping = mapp
        return
    end
end


function localization.dump()
    if constants.DEV_MODE then
        love.filesystem.write("UMGCLIENT_LOCALIZATION_STRINGS.json", json.encode(dumps))
    end
end


---@param txt string
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


local languageListCache
---@return string[]
function localization.getLanguageList()
    if not languageListCache then
        local list = {en = true}

        for _, name in ipairs(love.filesystem.getDirectoryItems("assets/localization")) do
            if name:sub(-5) == ".json" then
                list[getLangCode(name:sub(1, -6))] = true
            end
        end

        languageListCache = {}
        for k in pairs(list) do
            languageListCache[#languageListCache+1] = k
        end
        table.sort(languageListCache)
    end

    return languageListCache
end



return localization
