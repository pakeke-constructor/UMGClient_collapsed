local ansicolor = require("src.common.ansicolor")

---@class log
local log = {}

---@alias log.level "trace"|"debug"|"info"|"warn"|"error"|"fatal"|"none"
---@class log.logger
---@field public level log.level
---@field public output fun(level:log.level,lineinfo:string,text:string)



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


function log.setup()
    
end


local function getLogInfo(...)
    local stringized = {}

    for i = 1, select("#", ...) do
        stringized[#stringized+1] = tostring((select(i, ...)))
    end

    local info = debug.getinfo(3, "Sl")
    local logstring = table.concat(stringized, "\t")
    local lineinfo = tostring(info.short_src)..":"..tostring(info.currentline)
    return logstring, lineinfo
end


---@param level log.level
local function makelogfunc(level)
local levelid = assert(modes[level])

---@param ... any
    return function(...)
        local logstring --string representation of log is lazily created
        local lineinfo

        if levelid >= modes[logger.level] then
            if not logstring then
                logstring, lineinfo = getLogInfo(...)
            end

            logToConsole(level, lineinfo, logstring)
            logToFile(level, lineinfo, logstring)
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
            local txt = log.formatLog(level, lineinfo, text)
            if usecolor then
                txt = ansicolor.wrap(log.ansicodes[level], txt)
            end
            return io.write(txt, "\n")
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
