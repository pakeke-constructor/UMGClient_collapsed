---@meta

---Server-side api
server = {}

---@type table<string, fun():Entity>
server.entities = {}

---broadcasts an event to clients
---@param event_name string
---@param ... any
function server.broadcast(event_name, ...)
end

---unicasts to one client
---@param username string
---@param event_name string
---@param ... any
function server.unicast(username, event_name, ...)
end

---lazy broadcast: efficient, arrival not guaranteed
---@param event_name string
---@param ... any
function server.lazyBroadcast(event_name, ...)
end

---lazy unicast: efficient, arrival not guaranteed 
---@param username string
---@param event_name string
---@param ... any
function server.lazyUnicast(username, event_name, ...)
end

---Returns writable (potentially persistent) filesystem object for the particular mod.
---@return umg.FilesystemObject
function server.getSaveFilesystem()
end

---@return string
function server.getHostClient()
end

---@param rate integer
function server.setTickrate(rate)
end

---@return integer
function server.getTickrate()
end

function server.shutdown()
end

return server
