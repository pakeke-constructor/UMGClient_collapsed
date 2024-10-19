

local Bufferer = tools.SafeClass()


function Bufferer:init()
    self.addBuffer = tools.Set()
    self.remBuffer = tools.Set()
end


function Bufferer:addBuffered(ent)
    if self.remBuffer:has(ent) then
        self.remBuffer:remove(ent)
    else
        self.addBuffer:add(ent)
    end
end


function Bufferer:removeBuffered(ent)
    if self.addBuffer:has(ent) then
        self.addBuffer:remove(ent)
        return false
    else
        self.remBuffer:add(ent)
        return true
    end
end


function Bufferer:clear()
    self.addBuffer:clear()
    self.remBuffer:clear()
end

return Bufferer

