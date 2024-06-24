---@meta

---@class umg
umg = {}

---@param ent Entity
---@return boolean
function umg.exists(ent)
end

---@param ent any
---@return boolean
function umg.isEntity(ent)
end

---@param ... string
---@return EntityGroup
function umg.group(...)
end
umg.view = umg.group

---@param id integer
---@return Entity?
function umg.getEntity(id)
end

---@param etypeName string
---@param etypeTable table<string, any>
function umg.defineEntityType(etypeName, etypeTable)
end

---@param resource table
---@param alias string
function umg.register(resource, alias)
end

---@param ... any
---@return string
function umg.serialize(...)
end

---@param data string
---@return any
function umg.deserialize(data)
end

---@param ... any
---@return string
function umg.serializeVolatile(...)
end

---@param data string
---@return any
function umg.deserializeVolatile(data)
end

---@param packetName string
---@param options {dynamic:boolean,typelist:("number"|"string"|"boolean"|"entity")[]}
function umg.definePacket(packetName, options)
end

---@param clientId any
---@return table
function umg.getClientInfo(clientId)
end

---@return number
function umg.getWorldTime()
end

---@param str string
function umg.isNamespaced(str)
end

---@return {modname:string}?
function umg.getLoadingContext()
end

---@return string
function umg.getModName()
end

---@param name string
function umg.defineEvent(name)
end

---@param name string
---@return boolean
function umg.isEventDefined(name)
end

---@param name string
---@param ... any
function umg.call(name, ...)
end

---@param name string
---@param ... any
function umg.rawcall(name, ...)
end

---@param name string
---@param callback fun(...:any)
function umg.on(name, callback)
end

---@param question string
---@param reducer fun(...:any):...
function umg.defineQuestion(question, reducer)
end

---@param question string
---@return fun(...:any):...
function umg.getQuestionReducer(question)
end

---@param question string
---@param ... any
---@return any
function umg.ask(question, ...)
end

---@param question string
---@param callback fun(...:any):...
function umg.answer(question, callback)
end

umg.melt = error

---@param variable_name string
---@param value any
function umg.expose(variable_name, value)
end

---@alias Entity table<string, any>

---@class EntityGroup
local EntityGroup = {}

---@param callback fun(ent:Entity)
function EntityGroup:onAdded(callback)
end

---@param callback fun(ent:Entity)
function EntityGroup:onRemoved(callback)
end

---@param ent Entity
---@return boolean
function EntityGroup:has(ent)
end

return umg
