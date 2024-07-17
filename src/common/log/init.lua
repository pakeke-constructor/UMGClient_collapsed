local ansicolor = require("src.common.ansicolor")

---@class log
local log = {}

---@alias log.level "trace"|"debug"|"info"|"warn"|"error"|"fatal"|"none"
---@class log.logger
---@field public level log.level
---@field public output fun(level:log.level,lineinfo:string,text:string)

---@type log.level
local mainLogLevel = "trace"

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
    "none"
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

log.ansicodes = {
    trace = ansicolor.BLUE,
    debug = ansicolor.CYAN,
    info  = ansicolor.GREEN,
    warn  = ansicolor.YELLOW,
    error = ansicolor.RED,
    fatal = ansicolor.MAGENTA,
}

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
        return false
    end
    mainLogLevel = level
    return true
end

---Get main log level
function log.getLevel()
    return mainLogLevel
end

---@param ... log.level
function log.getHighestLevel(...)
    local currentHighest = ...

    for i = 2, select("#", ...) do
        local loglevel = select(i, ...)
        if modes[loglevel] < modes[currentHighest] then
            currentHighest = loglevel
        end
    end

    return currentHighest
end

---lowest level index has highest priority
---@param loglevel string
---@return integer?
function log.getLevelIndex(loglevel)
    return modes[loglevel]
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

    return {
        level = "trace",
        output = function(level, lineinfo, text)
            return io.write(
                ansicolor.wrap(log.ansicodes[level],
                    string.format(
                        "[%-6s%s] %s: %s",
                        level:upper(),
                        os.date("%H:%M:%S"),
                        lineinfo,
                        text
                    )
                ), "\n"
            )
        end
    }
end

---@param f {write:fun(self:any,text:string),flush:fun(self:any)}
function log.createWriteableFlushableLogger(f)
    return {
        level = "trace",
        output = function(level, lineinfo, text)
            f:write(log.formatLog(level, lineinfo, text).."\n")
            f:flush()
        end
    }
end

---@param level log.level
---@param lineinfo string
---@param text string
function log.formatLog(level, lineinfo, text)
    return string.format("[%-6s%s] %s: %s", level:upper(), os.date("%H:%M:%S"), lineinfo, text)
end

return log
