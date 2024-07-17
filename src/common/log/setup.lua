local log = require("src.common.log")
local clientLogger = {}

assert(CLIENT_SIDE, "client side only")

-- Setup console log level
local consoleLogLevel = os.getenv(constants.CONSOLE_LOG_LEVEL_ENVVAR) or constants.DEFAULT_CONSOLE_LOG_LEVEL
if not log.getLevelIndex(consoleLogLevel) then
    consoleLogLevel = constants.DEFAULT_CONSOLE_LOG_LEVEL
end

-- Setup file log level
local fileLogLevel = os.getenv(constants.FILE_LOG_LEVEL_ENVVAR) or constants.DEFAULT_FILE_LOG_LEVEL
if not log.getLevelIndex(fileLogLevel) then
    fileLogLevel = constants.DEFAULT_FILE_LOG_LEVEL
end

if consoleLogLevel ~= "none" then
    local logger = log.createConsoleLogger()
    logger.level = consoleLogLevel
    log.registerLogger(logger)
    clientLogger.console = logger
end

if fileLogLevel ~= "none" then
    assert(love.filesystem.createDirectory("logs"), "unable to create logs directory")
    local filename = os.date("logs/UMG_%Y_%m_%d_%H_%M_%S.txt")
    local file = assert(love.filesystem.openFile(filename, "a"))
    local logger = log.createWriteableFlushableLogger(file)
    logger.level = fileLogLevel
    log.registerLogger(logger)
    clientLogger.file = logger
end

log.setLevel(log.getHighestLevel(consoleLogLevel, fileLogLevel))

return clientLogger
