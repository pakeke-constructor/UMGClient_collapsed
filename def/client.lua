---@meta

-- Client-side api
client = {}

---( holds image and sound assets )
client.assets = {
    ---( where quads are loaded )
    ---@type table<string, love.Quad>
    images = {},
    ---( where sounds are loaded )
    ---@type table<string, love.Source>
    sounds = {},
}

---@type table<string, EntityType>
client.entities = {}

---sends a message to server_thread
---@param event_name string
function client.send(event_name, ...)
end

---listens to a message from server
---@param event_name string
---@param func fun(...):...
function client.on(event_name, func)
end

---lazy send: arrival not guaranteed
---@param event_name string
function client.lazySend(event_name, ...)
end

---@return boolean
function client.isPaused()
end

---gets client username
---@return string
function client.getClient()
end


---@return number
function client.getMasterVolume()
end
---@return number
function client.getSFXVolume()
end
---@return number
function client.getMusicVolume()
end


---@param x number
function client.setMasterVolume(x)
end
---@param x number
function client.setSFXVolume(x)
end
---@param x number
function client.setMusicVolume(x)
end




---@return string
function client.getLanguage()
end

function client.disconnect()
end




---Returns writable (potentially persistent) filesystem object for the particular mod. Data stored in here is shared
---across all servers.
---@return umg.FilesystemObject
function client.getSaveFilesystem()
end

---access to global texture atlas
---@class Atlas
client.atlas = {}

---Images are automatically put in the texture atlas,
---and are auto-batched.
---draws quad.
---@param quad love.Quad
---@param x number?
---@param y number?
---@param r number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
function client.atlas:draw(quad, x,y, r, sx,sy, ox,oy, kx,ky)
end

---@return love.Texture
function client.atlas:getTexture() end

return client
