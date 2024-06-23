

local Bufferer = tools.SafeClass()


function Bufferer:init()
    self.addBuffer = tools.Set()
    self.remBuffer = tools.Set()
end


function Bufferer:addBuffered(ent)
    self.remBuffer:remove(ent)
    self.addBuffer:add(ent)
end


function Bufferer:removeBuffered(ent)
    self.addBuffer:remove(ent)
    self.remBuffer:add(ent)
end


function Bufferer:clear()
    self.addBuffer:clear()
    self.remBuffer:clear()
end

return Bufferer

