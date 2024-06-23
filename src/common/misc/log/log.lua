

local log = require("libs.nm_log.log")


if (not love.system) or love.system.getOS() == "Windows" then
    log.usecolor = false
end

log.level = "trace"


local logLevels = {
    trace = true,
    debug = true,
    info = true,
    warn = true,
    error = true,
    fatal = true,
}


-- monkeypatch: 
function log.setLevel(level)
    if not (level and logLevels[level]) then
        error("Invalid log level: " .. tostring(level))
    end
    log.level = level
end


log.setLevel(constants.DEFAULT_LOG_LEVEL)


return log
