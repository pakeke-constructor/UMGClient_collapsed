local ansicolor = require("src.common.ansicolor")

---@class log
local log = {}

---@alias log.level "trace"|"debug"|"info"|"warn"|"error"|"fatal"|"none"
---@class log.logger
---@field public level log.level Cannot be changed at runtime.
---@field public output fun(level:log.level,lineinfo:string,text:string)

---@type log.logger[]
local loggers = {}

local mainLogLevel = "none"

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

---@param log1 log.level
---@param log2 log.level
local function getHighestLevel(log1, log2)
    return modes[log1] < modes[log2] and log1 or log2
end

local function computeLogLevel()
    local level = "none"

    for _, logger in ipairs(loggers) do
        level = getHighestLevel(level, logger.level)
    end

    return level
end

---@param level log.level
local function makelogfunc(level)
    local levelid = assert(modes[level])

    ---@param ... any
    return function(...)
        if levelid >= modes[mainLogLevel] then
            local stringized = {}

            for i = 1, select("#", ...) do
                stringized[#stringized+1] = tostring((select(i, ...)))
            end

            local info = debug.getinfo(2, "Sl")
            log.logDirectly(
                level,
                tostring(info.short_src)..":"..tostring(info.currentline),
                table.concat(stringized, "\t")
            )
        end
    end
end

---@param logger log.logger
function log.registerLogger(logger)
    loggers[#loggers+1] = logger
    mainLogLevel = computeLogLevel()
end

---@param level log.level
---@param lineinfo string
---@param text string
function log.logDirectly(level, lineinfo, text)
    local levelid = modes[level]
    for _, logger in ipairs(loggers) do
        if levelid >= modes[logger.level] then
            logger.output(level, lineinfo, text)
        end
    end
end

local ansicodes = {
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

---Get log level
function log.getLevel()
    return mainLogLevel
end

---@param level log.level
---@param lineinfo string
---@param text string
local function formatLog(level, lineinfo, text)
    return string.format("[%-6s%s] %s: %s", level:upper(), os.date("%H:%M:%S"), lineinfo, text)
end

local function createConsoleLogger()
    return {
        level = "trace",
        output = function(level, lineinfo, text)
            return io.write(
                ansicolor.wrap(ansicodes[level], formatLog(level, lineinfo, text)), "\n"
            )
        end
    }
end

---@param f {write:fun(self:any,text:string),flush:fun(self:any)}
local function createWriteableFlushableLogger(f)
    return {
        level = "trace",
        output = function(level, lineinfo, text)
            f:write(formatLog(level, lineinfo, text).."\n")
            f:flush()
        end
    }
end

if CLIENT_SIDE then
    -- Setup console log level
    local consoleLogLevel = os.getenv(constants.CONSOLE_LOG_LEVEL_ENVVAR) or constants.DEFAULT_CONSOLE_LOG_LEVEL
    if not modes[consoleLogLevel] then
        consoleLogLevel = constants.DEFAULT_CONSOLE_LOG_LEVEL
    end

    -- Setup file log level
    local fileLogLevel = os.getenv(constants.FILE_LOG_LEVEL_ENVVAR) or constants.DEFAULT_FILE_LOG_LEVEL
    if not modes[fileLogLevel] then
        fileLogLevel = constants.DEFAULT_FILE_LOG_LEVEL
    end

    if consoleLogLevel ~= "none" then
        local logger = createConsoleLogger()
        logger.level = consoleLogLevel
        log.registerLogger(logger)
    end

    if fileLogLevel ~= "none" then
        assert(love.filesystem.createDirectory("logs"), "unable to create logs directory")
        local filename = os.date("logs/UMG_%Y_%m_%d_%H_%M_%S.txt")
        local file = assert(love.filesystem.openFile(filename, "a"))
        local logger = createWriteableFlushableLogger(file)
        logger.level = fileLogLevel
        log.registerLogger(logger)
    end
end

return log
