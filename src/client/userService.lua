
--[[


userService

responsible for getting/setting username,
and providing clientId.


Right now, there is only ONE username / clientId per program.
Which means we can have userService be static.

]]

local userService = {}


local function getRandomUsername()
    return "plyr_" .. tostring(love.math.random(1000))
end


--[[
    In the future, we should save / load username from a file;
    So the player doesn't need to change username all the time.
    (And/Or we could use steams username by default)
]]
userService.username = getRandomUsername()


-- This should be a steam id!
userService.clientId = tostring(love.math.random(999999))
assert(type(userService.clientId) == "string")




local function parseUsername(username)
    -- Remove alphanumeric characters from username
    username = username:gsub(constants.INVALID_USERNAME_CHARACTERS,'')
    -- username can't be more than X characters:
    local maxSize = constants.MAX_USERNAME_LENGTH
    username = username:sub(1, math.min(#username, maxSize))
    return username
end


function userService.setUsername(name)
    name = parseUsername(name)
    userService.username = name
end


local SETTINGS_FILENAME = "umg_client_settings.json"

-- Configure variables here
local settings = {
    masterVolume = 100,
    sfxVolume = 50,
    bgmVolume = 30,
    analytics = 0, -- 0 = undecided, 1 = agree, 2 = deny
}

local function setupSettings()
    local currentValues
    local f = love.filesystem.openFile(SETTINGS_FILENAME, "r")

    if f then
        local status
        status, currentValues = pcall(json.decode, f:read())

        if not status then
            currentValues = nil
        end
    end

    if not currentValues then
        currentValues = {}
    end

    for k, v in pairs(settings) do
        local varType = type(v)
        local savedVar = currentValues[k]

        if type(savedVar) == varType then
            -- Use saved
            settings[k] = savedVar
        end
    end
end
setupSettings()

function userService.saveSettings()
    -- Save
    local jsondata = json.encode(settings)
    local f = love.filesystem.openFile(SETTINGS_FILENAME, "w")
    f:write(jsondata)
    f:close()
end


---@param volume integer
local function clampVolume(volume)
    return math.min(math.max(math.floor(volume + 0.5), 0), 100)
end

function userService.getMasterVolume()
    settings.masterVolume = clampVolume(settings.masterVolume)
    return settings.masterVolume
end

---@param volume integer
function userService.setMasterVolume(volume)
    assert(type(volume) == "number")
    settings.masterVolume = clampVolume(volume)
end

function userService.getSFXVolume()
    settings.sfxVolume = clampVolume(settings.sfxVolume)
    return settings.sfxVolume
end

---@param volume integer
function userService.setSFXVolume(volume)
    assert(type(volume) == "number")
    settings.sfxVolume = clampVolume(assert(volume))
end

function userService.getBGMVolume()
    settings.bgmVolume = clampVolume(settings.bgmVolume)
    return settings.bgmVolume
end

---@param volume integer
function userService.setBGMVolume(volume)
    assert(type(volume) == "number")
    settings.bgmVolume = clampVolume(assert(volume))
end


local function fixAnalyticsValue()
    local analytics = math.floor(settings.analytics)

    if analytics < 0 or analytics > 2 then
        analytics = 0
    end

    settings.analytics = analytics
    return analytics
end

function userService.isAnalyticsConsentAsked()
    return fixAnalyticsValue() > 0
end

function userService.isUserConsentedForAnalytics()
    -- Analytics is opt-in
    return fixAnalyticsValue() == 1
end

---@param consent boolean
function userService.setAnalyticsConsent(consent)
    settings.analytics = consent and 1 or 2
end


return userService

