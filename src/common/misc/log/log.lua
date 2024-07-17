local log = {}

---@alias log.level "trace"|"debug"|"info"|"warn"|"error"|"fatal"
---@class log.logger
---@field public level log.level
---@field public output fun(level:log.level,lineinfo:string,text:string)

---@type log.level
local mainLogLevel = constants.DEFAULT_LOG_LEVEL

---@type log.logger[]
local loggers = {}

---@param logger log.logger
function log.registerLogger(logger)
    loggers[#loggers+1] = logger
end

---@param logger log.logger
function log.unregisterLogger(logger)
    for i, l in ipairs(loggers) do
        if l == logger then
            table.remove(loggers, i)
        end
    end
end

local modes = {
    "trace",
    "debug",
    "info",
    "warn",
    "error",
    "fatal",
}

for i, v in ipairs(modes) do
    modes[v] = i
end

---@param level log.level
local function makelogfunc(level)
    local levelid = assert(modes[level])

    ---@param ... any
    return function(...)
        if levelid >= modes[mainLogLevel] then
            local logstring --string representation of log is lazily created
            local lineinfo

            for _, logger in ipairs(loggers) do
                if levelid >= modes[logger.level] then
                    if not logstring then
                        local stringized = {}

                        for i = 1, select("#", ...) do
                            stringized[#stringized+1] = tostring((select(i, ...)))
                        end

                        local info = debug.getinfo(2, "Sl")
                        logstring = table.concat(stringized, "\t")
                        lineinfo = tostring(info.short_src)..":"..tostring(info.currentline)
                    end

                    logger.output(level, lineinfo, logstring)
                end
            end
        end
    end
end

log.trace = makelogfunc("trace")
log.debug = makelogfunc("debug")
log.info = makelogfunc("info")
log.warn = makelogfunc("warn")
log.error = makelogfunc("error")
log.fatal = makelogfunc("fatal")

-- monkeypatch: 
---@param level log.level
function log.setLevel(level)
    if not modes[level] then
        error("Invalid log level: " .. tostring(level))
    end
    mainLogLevel = level
end

---Get main log level
function log.getLevel()
    return mainLogLevel
end

---@param usecolor boolean?
function log.createConsoleLogger(usecolor)
    if usecolor == nil then
        local los = love.system.getOS()
        if los == "Windows" then
            usecolor = not not os.getenv("WT_PROFILE_ID")
        elseif los ~= "Android" and los ~= "iOS" then
            -- Assume false
            usecolor = false
        else
            -- Assume true
            usecolor = true
        end
    end

    local writelog
    if usecolor then
        function writelog(ansicolor, text)
            io.write(ansicolor, text, "\27[0m", "\n")
        end
    else
        function writelog(ansicolor, text)
            io.write(text, "\n")
        end
    end

    local ansicodes = {
        trace = "\27[34m",
        debug = "\27[36m",
        info  = "\27[32m",
        warn  = "\27[33m",
        error = "\27[31m",
        fatal = "\27[35m",
    }

    return {
        level = mainLogLevel,
        output = function(level, lineinfo, text)
            return writelog(
                ansicodes[level],
                string.format(
                    "[%-6s%s] %s: %s",
                    level:upper(),
                    os.date("%H:%M:%S"),
                    lineinfo,
                    text
                )
            )
        end
    }
end

local envlog = os.getenv(constants.PRINT_LEVEL_ENVIRONMENT_VARIABLE)
if envlog and modes[envlog] then
    log.setLevel(envlog)
end

log.registerLogger(log.createConsoleLogger())

return log
