---@meta

---@class umg
umg = {}

---@param ent any
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

---@alias UMGCallback string
---| "@tick"
---| "@load" 
---| "@createWorld"
---| "@playerJoin" 
---| "@playerLeave"
---| "@quit"
---| "@draw" 
---| "@update"
---| "@keypressed" 
---| "@textinput" 
---| "@keyreleased"
---| "@resize"
---| "@wheelmoved" 
---| "@mousepressed" 
---| "@mousereleased" 
---| "@mousemoved"
---| "@entityInit" 
---| "@newEntityType"
---| "@debugComponentAccess" 
---| "@debugComponentChange"

---@param name UMGCallback
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

---@class EntityClass
---@field public id integer
local EntityClass = {}

---@return string
function EntityClass:type()
end

---deletes an entity through buffering
function EntityClass:shallowDelete()
end

---deletes an entity, and also deletes all entities inside of `Entity`
function EntityClass:delete()
end

---shallow clones an entity
---@return Entity
function EntityClass:shallowClone()
end

---deep clones an entity
---@return Entity
function EntityClass:clone()
end

---adds components
---@param compName string
---@param value any
function EntityClass:addComponent(compName, value)
end

---@param compName string
function EntityClass:removeComponent(compName)
end

---@return fun(t: table<string, any>, idx?: string):(string, any), table<string, any>
function EntityClass:components()
end

---@param compName string
---@return any
function EntityClass:getComponent(compName)
end

---@param compName string
---@return boolean
function EntityClass:hasComponent(compName)
end

---checks if component is a shared component
---@param compName string
---@return boolean
function EntityClass:isSharedComponent(compName)
end

---checks if component is a regular component
---@param compName string
---@return boolean
function EntityClass:isRegularComponent(compName)
end

---@return boolean
function EntityClass:isDeleted()
end

---entities are ALWAYS owned on the server
---@return boolean
function EntityClass:isOwned()
end

---@return boolean
function EntityClass:isClientSide()
end

---@alias Entity EntityClass|table<string, any>

---@class EntityGroupClass
local EntityGroupClass = {}

---@param callback fun(ent:Entity)
function EntityGroupClass:onAdded(callback)
end

---@param callback fun(ent:Entity)
function EntityGroupClass:onRemoved(callback)
end

---@param ent Entity
---@return boolean
function EntityGroupClass:has(ent)
end

---@return integer
function EntityGroupClass:size()
end

---@alias EntityGroup EntityGroupClass|Entity[]

return umg
